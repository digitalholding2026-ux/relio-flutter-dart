/// Coherence de la geometrie du mark Relio.
///
/// Ces tests verrouillent la STRUCTURE et les VALEURS de la specification.
/// Toute derive entre la geometrie, le SVG genere et le rendu Flutter doit
/// faire echouer la suite, pas passer inapercue sur un telephone.
///
/// Le mark n'est plus parametrique : il est decrit par des traces. Les tests
/// ne verifient donc plus des rapports de cercles, mais que les traces lues
/// par le generateur SVG et par le painter Flutter sont bien les memes, et que
/// les SVG presents sur le disque correspondent a la geometrie actuelle.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_lockup.dart';
import 'package:relio/presentation/branding/relio_mark.dart';

/// Deux valeurs sont consideres egales si elles coincident a [epsilon].
const double epsilon = 1e-9;

/// Nombre de decimales employe par le generateur.
String _n(double v) {
  final double r = (v * 1000).roundToDouble() / 1000;
  return r == r.roundToDouble() ? r.toStringAsFixed(1) : r.toString();
}

/// Reconstitue le `d` d'une trace depuis les noeuds de la geometrie.
///
/// REIMPLEMENTATION DELIBEREE du generateur : si les deux convergent sur la
/// meme chaine, c'est qu'elles lisent la meme definition. Si elles divergeaient,
/// ce test le verrait — ce que ne ferait pas un appel direct a la fonction du
/// generateur, qui ne prouverait qu'elle est egale a elle-meme.
String _attendu(List<RelioMarkNode> nodes) {
  final StringBuffer out = StringBuffer();
  for (final RelioMarkNode node in nodes) {
    switch (node) {
      case RelioMarkMoveTo(:final double x, :final double y):
        out.write('M${_n(x)} ${_n(y)}');
      case RelioMarkLineTo(:final double x, :final double y):
        out.write('L${_n(x)} ${_n(y)}');
      case RelioMarkQuadTo(
          :final double cx,
          :final double cy,
          :final double x,
          :final double y,
        ):
        out.write('Q${_n(cx)} ${_n(cy)} ${_n(x)} ${_n(y)}');
      case RelioMarkClose():
        out.write('Z');
    }
  }
  return out.toString();
}

/// Lit un SVG de `assets/branding/` et echoue si le fichier est absent.
String lire(String chemin) {
  final File f = File(chemin);
  expect(f.existsSync(), isTrue, reason: 'SVG manquant : $chemin');
  return f.readAsStringSync();
}

void main() {
  group('Structure du mark', () {
    test('le mark est compose de sept traces', () {
      expect(RelioMarkGeometry.parts, hasLength(7));
      expect(
        RelioMarkGeometry.parts.map((RelioMarkPart p) => p.id).toList(),
        <String>[
          'cap',
          'stem',
          'body',
          'base',
          'page-upper',
          'page-lower',
          'tassel',
        ],
      );
    });

    test('les identifiants sont uniques : ils nomment les noeuds du SVG', () {
      final Set<String> ids = <String>{
        ...RelioMarkGeometry.parts.map((RelioMarkPart p) => p.id),
      };
      expect(ids, hasLength(7));
    });

    test('les roles chromatiques sont répartis comme dans la specification', () {
      expect(RelioMarkGeometry.cap.role, RelioMarkRole.base);
      expect(RelioMarkGeometry.stem.role, RelioMarkRole.base);
      expect(RelioMarkGeometry.body.role, RelioMarkRole.base);
      expect(RelioMarkGeometry.base.role, RelioMarkRole.base);
      expect(RelioMarkGeometry.pageUpper.role, RelioMarkRole.accent);
      expect(RelioMarkGeometry.pageLower.role, RelioMarkRole.accent);
      expect(RelioMarkGeometry.tassel.role, RelioMarkRole.accent);
    });

    test('chaque trace est fermee', () {
      for (final RelioMarkPart part in RelioMarkGeometry.parts) {
        expect(part.nodes.last, isA<RelioMarkClose>(),
            reason: '${part.id} doit finir par Z');
      }
    });

    test('aucune trace n\'est vide', () {
      for (final RelioMarkPart part in RelioMarkGeometry.parts) {
        expect(part.nodes, isNotEmpty, reason: part.id);
      }
    });
  });

  group('Boite englobante', () {
    test('elle se lit directement sur les parties', () {
      double left = double.infinity;
      double top = double.infinity;
      double right = double.negativeInfinity;
      double bottom = double.negativeInfinity;

      void ajouter(RelioMarkPart p) {
        left = p.box.left < left ? p.box.left : left;
        top = p.box.top < top ? p.box.top : top;
        right = p.box.right > right ? p.box.right : right;
        bottom = p.box.bottom > bottom ? p.box.bottom : bottom;
      }

      for (final RelioMarkPart p in RelioMarkGeometry.parts) {
        ajouter(p);
      }

      expect(RelioMarkGeometry.boundingBox.left, closeTo(left, 0.002));
      expect(RelioMarkGeometry.boundingBox.top, closeTo(top, 0.002));
      expect(RelioMarkGeometry.boundingBox.right, closeTo(right, 0.002));
      expect(RelioMarkGeometry.boundingBox.bottom, closeTo(bottom, 0.002));
    });

    test('le mark remplit la grille en hauteur et laisse de l\'air en largeur', () {
      expect(RelioMarkGeometry.inkHeight, closeTo(100, 0.002));
      expect(RelioMarkGeometry.inkWidth, closeTo(87.552, 0.002));
      expect(RelioMarkGeometry.inkWidth, lessThan(100));
      expect(RelioMarkGeometry.inkHeight, greaterThan(RelioMarkGeometry.inkWidth));
    });

    test('le mark est centre horizontalement dans la grille', () {
      expect(RelioMarkGeometry.inkCenterX, closeTo(50, 0.01));
      expect(
        100 - RelioMarkGeometry.boundingBox.right,
        closeTo(RelioMarkGeometry.boundingBox.left, 0.01),
        reason: 'les marges gauche et droite doivent etre egales',
      );
    });

    test('aucune partie ne deborde de la grille', () {
      for (final RelioMarkPart part in RelioMarkGeometry.parts) {
        expect(part.box.left, greaterThanOrEqualTo(-epsilon), reason: part.id);
        expect(part.box.top, greaterThanOrEqualTo(-epsilon), reason: part.id);
        expect(part.box.right, lessThanOrEqualTo(100 + epsilon), reason: part.id);
        expect(part.box.bottom, lessThanOrEqualTo(100 + epsilon), reason: part.id);
      }
    });
  });

  group('Composition du mark', () {
    test('le chapeau coiffe la structure', () {
      expect(RelioMarkGeometry.cap.box.top, closeTo(0, 0.002));
      expect(RelioMarkGeometry.cap.box.bottom,
          lessThan(RelioMarkGeometry.body.box.top + 10));
    });

    test('le gland pend a droite, au-dessus des pages', () {
      expect(RelioMarkGeometry.tassel.box.top,
          greaterThan(RelioMarkGeometry.cap.box.top));
      expect(RelioMarkGeometry.tassel.box.bottom,
          lessThan(RelioMarkGeometry.pageUpper.box.top));
    });

    test('les pages s\'ouvrent entre la courbe et le balayage', () {
      expect(RelioMarkGeometry.pageUpper.box.top,
          greaterThan(RelioMarkGeometry.body.box.top));
      expect(RelioMarkGeometry.pageLower.box.bottom,
          lessThan(RelioMarkGeometry.base.box.bottom));
    });
  });

  group('Zone sure Android', () {
    test('grille 108 dp et zone sure 66 dp', () {
      expect(RelioMarkGeometry.androidGridDp, 108);
      expect(RelioMarkGeometry.androidSafeZoneDp, 66);
    });

    test('le mark occupe environ 55 % de la zone sure', () {
      expect(RelioMarkGeometry.androidMarkFill, closeTo(0.55, epsilon));
      expect(RelioMarkGeometry.androidMarkSizeDp, closeTo(36.3, epsilon));
      expect(RelioMarkGeometry.androidMarkSizeDp,
          lessThan(RelioMarkGeometry.androidSafeZoneDp));
    });

    test('la hauteur du mark est plus grande que sa largeur', () {
      // Le mark n'est pas carre : traiter 36,3 dp comme un cote de carre le
      // ferait deborder de la zone sure en hauteur.
      expect(RelioMarkGeometry.androidMarkHeightDp,
          greaterThan(RelioMarkGeometry.androidMarkWidthDp));
      expect(RelioMarkGeometry.androidMarkHeightDp,
          lessThan(RelioMarkGeometry.androidSafeZoneDp));
    });
  });

  group('Icone applicative', () {
    test('le fond est un carre a coins arrondis, en retrait', () {
      expect(RelioMarkGeometry.iconCornerRadiusRatio, closeTo(0.206, 0.005));
      expect(RelioMarkGeometry.iconBackgroundInsetRatio, closeTo(0.061, 0.005));
      expect(RelioMarkGeometry.iconCornerRadiusRatio, greaterThan(0.15));
      expect(RelioMarkGeometry.iconCornerRadiusRatio, lessThan(0.3));
    });
  });

  group('SVG generes', () {
    test('les couleurs sont en hexadecimal exact, jamais en nom', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      expect(svg, contains('#FE7904'));
      expect(svg, contains('#0E1821'));
      expect(svg, isNot(contains('orange')));
      expect(svg, isNot(contains('navy')));
      expect(svg, isNot(contains('indigo')));
      expect(svg, isNot(contains('fill="FE7904"')), reason: 'le # est obligatoire');
    });

    test('le SVG principal porte exactement les traces de la geometrie', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      for (final RelioMarkPart part in RelioMarkGeometry.parts) {
        expect(svg, contains('id="${part.id}"'),
            reason: 'partie ${part.id} absente du SVG');
        expect(svg, contains('d="${_attendu(part.nodes)}"'),
            reason: 'trace ${part.id} divergente : le SVG est perime');
      }
      expect(svg, isNot(contains('<circle')),
          reason: 'la nouvelle marque ne porte pas de point');
    });

    test('toutes les declinaisons portent la MEME geometrie', () {
      final List<String> fichiers = <String>[
        'mark-primary.svg',
        'mark-inverse.svg',
        'mark-mono-black.svg',
        'mark-mono-white.svg',
      ];
      final Set<String> traces = <String>{
        for (final String f in fichiers)
          lire('assets/branding/mark/$f')
              .split('\n')
              .where((String l) => l.contains('<path'))
              .map((String l) => l.replaceAll(RegExp(r'fill="#[0-9A-F]{6}"'), ''))
              .join(),
      };
      expect(traces, hasLength(1),
          reason: 'les declinaisons ne doivent differer que par la couleur');
    });

    test('la declinaison inverse est blanche sur fond navy', () {
      final String svg = lire('assets/branding/mark/mark-inverse.svg');
      expect(svg, contains('#FFFFFF'));
      expect(svg, contains('#FE7904'));
    });

    test('les declinaisons monochrome existent en noir et en blanc', () {
      expect(lire('assets/branding/mark/mark-mono-black.svg'), contains('#000000'));
      expect(lire('assets/branding/mark/mark-mono-white.svg'), contains('#FFFFFF'));
    });

    test('les traces sont pleines : fill-rule evenodd', () {
      expect(lire('assets/branding/mark/mark-primary.svg'),
          contains('fill-rule="evenodd"'));
    });

    test('le SVG ne contient que les commandes prevues', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      // Aucune cubique, aucune polyligne : le mark est decrit par M, L, Q, Z.
      expect('C'.allMatches(svg), isEmpty, reason: 'pas de cubique attendue');
      expect('H'.allMatches(svg), isEmpty, reason: 'H est converti en L');
      expect('V'.allMatches(svg), isEmpty, reason: 'V est converti en L');
    });

    test('le viewBox est la grille de reference', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      expect(svg, contains('viewBox="0 0 100.0 100.0"'));
    });

    test('l\'icone applicative est generee : fond orange a coins arrondis', () {
      final String svg = lire('assets/branding/icon/relio-app-icon.svg');
      expect(svg, contains('viewBox="0 0 512.0 512.0"'));
      expect(
        svg,
        contains('rx="${_n(RelioMarkGeometry.iconCornerRadiusRatio * 512)}"'),
      );
      expect(svg, contains('fill="#FE7904"'));
      expect(svg, contains('fill="#0E1821"'));
    });

    test('les lockups existent et ne contiennent que la geometrie', () {
      for (final String f in <String>[
        'lockup-horizontal.svg',
        'lockup-vertical.svg',
        'lockup-horizontal-mono-black.svg',
        'lockup-horizontal-mono-white.svg',
        'lockup-vertical-mono-black.svg',
        'lockup-vertical-mono-white.svg',
      ]) {
        final String svg = lire('assets/branding/lockup/$f');
        expect(svg, contains('id="${RelioMarkGeometry.cap.id}"'), reason: f);
        expect(svg, isNot(contains('<text')),
            reason: 'le mot est pose par l\'application, pas dans le SVG ($f)');
      }
    });

    test('le lockup cite la signature qu\'il decrit', () {
      expect(lire('assets/branding/lockup/lockup-horizontal.svg'),
          contains(RelioSignature.text));
    });

    test('le wordmark genere porte exactement les lettres tracees', () {
      final String svg = lire('assets/branding/mark/wordmark-primary.svg');
      for (final RelioMarkPart part in RelioWordmarkGeometry.parts) {
        expect(svg, contains('id="${part.id}"'),
            reason: 'lettre ${part.id} absente du SVG');
        expect(svg, contains('d="${_attendu(part.nodes)}"'),
            reason: 'lettre ${part.id} divergente : le SVG est perime');
      }
    });
  });

  group('Le generateur et la couche Flutter ne se divisent pas', () {
    test('les couleurs hexadecimales du generateur sont celles de RelioBrand', () {
      final String gen = File('tool/gen_branding.dart').readAsStringSync();
      String hexOf(Color c) =>
          '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

      expect(gen, contains("cOrange = '${hexOf(RelioBrand.mark)}'"));
      expect(gen, contains("cNavy = '${hexOf(RelioBrand.wordmark)}'"));
      expect(gen, contains("cBlack = '${hexOf(RelioBrand.monoBlack)}'"));
      expect(gen, contains("cWhite = '${hexOf(RelioBrand.monoWhite)}'"));
    });

    test('les ecarts de lockup sont declares a l\'identique des deux cotes', () {
      final String gen = File('tool/gen_branding.dart').readAsStringSync();
      // Le generateur ne peut pas importer la couche Flutter : il re-declare les
      // ecarts. On relit donc sa declaration et on compare les VALEURS, sans
      // imposer la forme textuelle du litteral.
      double? generateur(String nom) => RegExp(
            'const double $nom = ([0-9.]+);',
          ).firstMatch(gen)?.group(1) !=
          null
          ? double.parse(RegExp('const double $nom = ([0-9.]+);').firstMatch(gen)!.group(1)!)
          : null;

      expect(generateur('relioLockupGapHorizontal'),
          closeTo(RelioBrand.horizontalGap, epsilon));
      expect(generateur('relioLockupGapVertical'),
          closeTo(RelioBrand.verticalGap, epsilon));

      // Les rapports sont mesures sur le logo livre. On compare les valeurs,
      // pas leur forme textuelle.
      expect(RelioBrand.signatureCapRatio, closeTo(0.14, 1e-12));
      expect(RelioBrand.signatureGapRatio, closeTo(0.153, 1e-12));
      expect(gen, contains('const double relioSignatureRatio = 0.14;'));
      expect(gen, contains('const double relioSignatureGapRatioText = 0.153;'));

      expect(RelioBrand.horizontalGap, kHorizontalGap);
      expect(RelioBrand.verticalGap, kVerticalGap);
    });

    test('le painter traduit bien toutes les especes de noeuds', () {
      // Si une espece de noeud nouvelle etait ajoutee a la geometrie sans etre
      // traitee, le rendu s'arreterait au dernier noeud connu. On verifie donc
      // que la `Path` construite couvre toute la trace.
      final Path path = relioMarkPath(RelioMarkGeometry.stem.nodes);
      expect(path.computeMetrics().length, greaterThanOrEqualTo(1),
          reason: 'le fût doit produire au moins un contour');
      expect(path.contains(const Offset(10, 50)), isTrue);
      final Rect bounds = path.getBounds();
      expect(bounds.left, closeTo(RelioMarkGeometry.stem.box.left, 0.5));
      expect(bounds.right, closeTo(RelioMarkGeometry.stem.box.right, 0.5));
    });

    test('les declinaisons ne different que par la couleur', () {
      expect(relioMarkColors(RelioMarkVariant.onLight).base, RelioBrand.wordmark);
      expect(relioMarkColors(RelioMarkVariant.onLight).accent, RelioBrand.mark);
      expect(relioMarkColors(RelioMarkVariant.onIndigo).base, RelioBrand.monoWhite);
      expect(relioMarkColors(RelioMarkVariant.onIndigo).accent, RelioBrand.mark);
      expect(relioMarkColors(RelioMarkVariant.monoBlack).base,
          relioMarkColors(RelioMarkVariant.monoBlack).accent);
      expect(relioMarkColors(RelioMarkVariant.monoWhite).base,
          relioMarkColors(RelioMarkVariant.monoWhite).accent);
    });
  });
}