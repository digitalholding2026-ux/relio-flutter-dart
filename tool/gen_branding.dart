/// Generateur des SVG de marque Relio.
///
/// Le SVG est GENERE, jamais ecrit a la main : toutes les valeurs viennent de
/// `RelioMarkGeometry` et `RelioWordmarkGeometry`, sources de verite uniques.
/// Apres toute modification de la geometrie :
///
/// ```
/// dart run tool/gen_branding.dart
/// ```
///
/// Les SVG servent a l'impression, au web et a toute sortie hors Flutter. Le
/// rendu a l'ecran passe par `RelioMarkPainter` et `RelioWordmarkPainter`. Le
/// test `test/branding/mark_geometry_test.dart` compare les deux et interdit
/// qu'ils divergent.
///
/// Ce generateur n'importe QUE les geometries, en Dart pur : c'est ce qui lui
/// permet de tourner hors de Flutter. Les couleurs sont donc re-declarees ici
/// en hexadecimal, et `test/branding/mark_geometry_test.dart` echoue des que
/// elles divergent de `RelioBrand`.
library;

import 'dart:io';

import 'package:relio/presentation/branding/relio_mark_geometry.dart';
import 'package:relio/presentation/branding/relio_wordmark_geometry.dart';

/// Couleurs de la marque, en hexadecimal exact.
///
/// Re-declarees ici parce que `RelioBrand` vit dans la couche Flutter. La
/// duplication est verifiee par `test/branding/mark_geometry_test.dart`.
const String cOrange = '#FE7904';
const String cNavy = '#0E1821';
const String cBlack = '#000000';
const String cWhite = '#FFFFFF';

/// Nombre de decimales conserve dans les SVG.
///
/// Les valeurs de la specification sont donnees a une ou deux decimales ;
/// arrondir a 3 evite d'ecrire `31.700000000000003`, tout en gardant une
/// precision tres superieure au pixel au plus grand rendu.
String n(double v) {
  final double r = (v * 1000).roundToDouble() / 1000;
  return r == r.roundToDouble() ? r.toStringAsFixed(1) : r.toString();
}

/// Les deux couleurs effectivement employees par une declinaison.
({String base, String accent}) colorsOf(String variant) => switch (variant) {
      'onLight' => (base: cNavy, accent: cOrange),
      'onNavy' => (base: cWhite, accent: cOrange),
      'monoBlack' => (base: cBlack, accent: cBlack),
      'monoWhite' => (base: cWhite, accent: cWhite),
      _ => throw 'Declinaison inconnue : $variant',
    };

/// Le `d` d'un trace, avec les memes commandes que la geometrie.
///
/// Aucune conversion : les noeuds sont M, L, Q et Z, qui sont deja du SVG.
/// C'est ce qui rend le fichier GENERE et non RECONSTITUE.
String pathData(List<RelioMarkNode> nodes) {
  final StringBuffer out = StringBuffer();
  for (final RelioMarkNode node in nodes) {
    switch (node) {
      case RelioMarkMoveTo(:final double x, :final double y):
        out.write('M${n(x)} ${n(y)}');
      case RelioMarkLineTo(:final double x, :final double y):
        out.write('L${n(x)} ${n(y)}');
      case RelioMarkQuadTo(
          :final double cx,
          :final double cy,
          :final double x,
          :final double y,
        ):
        out.write('Q${n(cx)} ${n(cy)} ${n(x)} ${n(y)}');
      case RelioMarkClose():
        out.write('Z');
    }
  }
  return out.toString();
}

/// Le groupement SVG du mark, seul, aux coordonnees de la grille.
String markBody(String variant) {
  final ({String base, String accent}) c = colorsOf(variant);
  final StringBuffer out = StringBuffer();
  for (final RelioMarkPart part in RelioMarkGeometry.parts) {
    final String fill = part.role == RelioMarkRole.accent ? c.accent : c.base;
    out.write('\n    <path id="${part.id}" d="${pathData(part.nodes)}" fill="$fill"/>');
  }
  return out.toString();
}

/// Le groupement SVG du wordmark, seul, aux coordonnees de sa grille.
String wordmarkBody(String variant) {
  final ({String base, String accent}) c = colorsOf(variant);
  final StringBuffer out = StringBuffer();
  for (final RelioMarkPart part in RelioWordmarkGeometry.parts) {
    final String fill = part.role == RelioMarkRole.accent ? c.accent : c.base;
    out.write('\n    <path id="${part.id}" d="${pathData(part.nodes)}" fill="$fill"/>');
  }
  return out.toString();
}

/// Le mark seul, en SVG.
///
/// Le `viewBox` est la boite englobante reelle : le fichier est donc rogne au
/// plus juste, sans transparence peripherique inutile.
String markSvg({
  required String variant,
  String title = 'Relio',
  String nom = 'principale',
}) {
  const double g = RelioMarkGeometry.grid;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(g)} ${n(g)}" width="${n(g)}" height="${n(g)}" role="img" aria-label="$title">
  <title>$title</title>
  <desc>Mark Relio, declinaison $nom. Grille de reference 100 x 100 ; boite englobante ${n(RelioMarkGeometry.inkWidth)} x ${n(RelioMarkGeometry.inkHeight)} unites. Traces pleines (fill-rule evenodd).</desc>
  <g fill-rule="evenodd">${markBody(variant)}
  </g>
</svg>
''';
}

/// Le wordmark seul, en SVG.
String wordmarkSvg({
  required String variant,
  String title = 'relio',
  String nom = 'principale',
}) {
  const double g = RelioWordmarkGeometry.grid;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(g)} ${n(g)}" width="${n(g)}" height="${n(g)}" role="img" aria-label="$title">
  <title>$title</title>
  <desc>Wordmark « relio » trace, declinaison $nom. Grille de reference 100 x 100 ; boite ${n(RelioWordmarkGeometry.inkWidth)} x ${n(RelioWordmarkGeometry.inkHeight)} unites. Traces pleines (fill-rule evenodd).</desc>
  <g fill-rule="evenodd">${wordmarkBody(variant)}
  </g>
</svg>
''';
}

/// Lockup horizontal : mark a gauche, bloc mot + signature a droite.
///
/// Seules les geometries du mark et du mot sont decrites ; la signature est
/// posee par l'application (« Apprendre aujourd’hui, réussir demain »).
String lockupHorizontalSvg({required String variant}) {
  const double g = RelioMarkGeometry.grid;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(g)} ${n(g)}" width="${n(g)}" height="${n(g)}" role="img" aria-label="Relio">
  <title>Relio — lockup horizontal</title>
  <desc>Geometrie du mark et du mot trace. A droite du mark, le bloc de texte est pose par l'application : le mot trace, a ${relioLockupGapHorizontal.toStringAsFixed(1)} unites du mark ; dessous, la signature « Apprendre aujourd’hui, réussir demain », hauteur au ${(relioSignatureRatio * 100).toStringAsFixed(1)} % de celle du mot, a ${relioSignatureGapRatioText.toStringAsFixed(3)} hauteur de mot de son bas.</desc>
  <g fill-rule="evenodd">${markBody(variant)}
  </g>
</svg>
''';
}

/// Lockup vertical : mark au-dessus, bloc mot + signature en dessous.
///
/// Comme pour le lockup horizontal, seules les geometries sont decrites ;
/// le texte de signature est pose par l'application.
String lockupVerticalSvg({required String variant}) {
  const double g = RelioMarkGeometry.grid;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(g)} ${n(g)}" width="${n(g)}" height="${n(g)}" role="img" aria-label="Relio">
  <title>Relio — lockup vertical</title>
  <desc>Geometrie du mark, centre dans la grille 100 x 100. Sous le mark, le bloc de texte est pose par l'application, a ${relioLockupGapVertical.toStringAsFixed(1)} unites d'ecartement, centre horizontalement : le mot trace, puis la signature « Apprendre aujourd’hui, réussir demain ».</desc>
  <g fill-rule="evenodd">${markBody(variant)}
  </g>
</svg>
''';
}

/// Icone applicative : fond orange a coins arrondis, mark navy.
///
/// Les parties orange du mark se confondent avec le fond, comme sur l'icone
/// livree : seules les parties navy sont dessinees. Le fond est genere, lui
/// aussi : un fond peint a la main deriverait du mark, et l'icone serait la
/// seule declinaison non regeneree.
String appIconSvg() {
  const double g = RelioMarkGeometry.grid;
  const double canvas = 512;
  final double inset = RelioMarkGeometry.iconBackgroundInsetRatio * canvas;
  final double side = canvas - 2 * inset;
  final double radius = RelioMarkGeometry.iconCornerRadiusRatio * canvas;

  // Le mark est centre dans le carre de fond, a son echelle de grille.
  final double scale = side / g;
  final double drawn = RelioMarkGeometry.inkWidth * scale;
  final double dx = inset + (side - drawn) / 2;
  final double dy = inset + (side - RelioMarkGeometry.inkHeight * scale) / 2;

  final StringBuffer navy = StringBuffer();
  for (final RelioMarkPart part in RelioMarkGeometry.parts) {
    if (part.role != RelioMarkRole.base) continue;
    navy.write('\n    <path id="${part.id}" d="${pathData(part.nodes)}" fill="$cNavy"/>');
  }

  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(canvas)} ${n(canvas)}" width="${n(canvas)}" height="${n(canvas)}" role="img" aria-label="Relio">
  <title>Relio — icône d'application</title>
  <desc>Icone applicative. Fond orange a coins arrondis, structure navy : les parties orange se confondent avec le fond, comme sur l'icone livree. Les deux calques sont regenerables separement : ce fichier n'est qu'un apercu plat.</desc>
  <rect x="${n(inset)}" y="${n(inset)}" width="${n(side)}" height="${n(side)}" rx="${n(radius)}" fill="$cOrange"/>
  <g transform="translate(${n(dx)} ${n(dy)}) scale(${n(scale)})" fill-rule="evenodd">$navy
  </g>
</svg>
''';
}

/// Ecartement mark ↔ bloc de texte du lockup horizontal, en unites de grille.
///
/// Repris de la specification. Le generateur ne peut pas importer la couche
/// Flutter, donc la valeur est re-declaree ici et verifiee par
/// `test/branding/mark_geometry_test.dart`, qui echoue des que les deux
/// divergent.
const double relioLockupGapHorizontal = 4.5;

/// Ecartement mark ↔ bloc de texte du lockup vertical, en unites de grille.
const double relioLockupGapVertical = 4.5;

/// Taille de la signature, en fraction de la hauteur du mot.
const double relioSignatureRatio = 0.14;

/// Ecartement mot ↔ signature, en fraction de la hauteur du mot.
const double relioSignatureGapRatioText = 0.153;

/// Rapport entre la hauteur du mark et celle du wordmark.
const double relioMarkToWordmarkRatio = 1.637;

void main() {
  const String br = 'assets/branding';

  void write(String path, String content) {
    File(path).writeAsStringSync(content);
    stdout.writeln('ecrit  $path');
  }

  // --- mark : quatre declinaisons ----------------------------------------
  write('$br/mark/mark-primary.svg', markSvg(variant: 'onLight', nom: 'principale, sur fond clair'));
  write('$br/mark/mark-inverse.svg', markSvg(variant: 'onNavy', title: 'Relio', nom: 'inverse, sur fond navy'));
  write('$br/mark/mark-mono-black.svg', markSvg(variant: 'monoBlack', nom: 'monochrome noir'));
  write('$br/mark/mark-mono-white.svg', markSvg(variant: 'monoWhite', nom: 'monochrome blanc'));

  // --- wordmark : quatre declinaisons ------------------------------------
  write('$br/mark/wordmark-primary.svg', wordmarkSvg(variant: 'onLight', nom: 'principale, sur fond clair'));
  write('$br/mark/wordmark-inverse.svg', wordmarkSvg(variant: 'onNavy', title: 'relio', nom: 'inverse, sur fond navy'));
  write('$br/mark/wordmark-mono-black.svg', wordmarkSvg(variant: 'monoBlack', nom: 'monochrome noir'));
  write('$br/mark/wordmark-mono-white.svg', wordmarkSvg(variant: 'monoWhite', nom: 'monochrome blanc'));

  // --- lockups ----------------------------------------------------------
  write('$br/lockup/lockup-horizontal.svg', lockupHorizontalSvg(variant: 'onLight'));
  write('$br/lockup/lockup-horizontal-mono-black.svg', lockupHorizontalSvg(variant: 'monoBlack'));
  write('$br/lockup/lockup-horizontal-mono-white.svg', lockupHorizontalSvg(variant: 'monoWhite'));
  write('$br/lockup/lockup-vertical.svg', lockupVerticalSvg(variant: 'onLight'));
  write('$br/lockup/lockup-vertical-mono-black.svg', lockupVerticalSvg(variant: 'monoBlack'));
  write('$br/lockup/lockup-vertical-mono-white.svg', lockupVerticalSvg(variant: 'monoWhite'));

  // --- icone applicative -------------------------------------------------
  write('$br/icon/relio-app-icon.svg', appIconSvg());

  stdout.writeln('\nGenerateur termine.');
}
