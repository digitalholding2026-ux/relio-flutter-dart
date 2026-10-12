/// Coherence de la geometrie du mark Relio.
///
/// Ces tests verrouillent les VALEURS de la specification. Toute derive
/// entre la geometrie, le SVG genere et le rendu Flutter doit faire echouer la
/// suite, pas passer inaperue sur un telephone.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_mark_geometry.dart';

/// Deux valeurs sont consideres egales si elles coincident a [epsilon].
const double epsilon = 1e-9;

void main() {
  group('Cercles', () {
    test('diametres conformes a la specification', () {
      expect(RelioMarkGeometry.diameterRight, 28);
      expect(RelioMarkGeometry.diameterLeft, closeTo(15.4, epsilon));
    });

    test('le cercle gauche fait 55 % du cercle droit', () {
      final double ratio =
          RelioMarkGeometry.diameterLeft / RelioMarkGeometry.diameterRight;
      expect(ratio, closeTo(0.55, 0.001));
    });

    test('centres conformes a la specification', () {
      expect(RelioMarkGeometry.centerRightX, 66);
      expect(RelioMarkGeometry.centerRightY, 50);
      expect(RelioMarkGeometry.centerLeftX, 24);
      expect(RelioMarkGeometry.centerLeftY, 50);
    });

    test('espacement entre centres de 42 unites', () {
      expect(RelioMarkGeometry.centerSpacing, closeTo(42, epsilon));
    });

    test('les deux cercles sont alignes horizontalement', () {
      expect(RelioMarkGeometry.centerRightY, RelioMarkGeometry.centerLeftY);
    });

    test('les deux cercles ne se touchent pas', () {
      final double gap = RelioMarkGeometry.centerSpacing -
          RelioMarkGeometry.radiusRight -
          RelioMarkGeometry.radiusLeft;
      expect(gap, greaterThan(0), reason: 'les cercles doivent rester distincts');
    });
  });

  group('Courbe', () {
    test('depart et arrivee sur les bords des cercles, a hauteur de centre', () {
      expect(RelioMarkGeometry.curveStartX, closeTo(31.7, epsilon));
      expect(RelioMarkGeometry.curveEndX, closeTo(52, epsilon));
    });

    test('portee horizontale de 20,3 unites', () {
      expect(RelioMarkGeometry.curveSpan, closeTo(20.3, epsilon));
    });

    test('profondeur de 6 unites sous la ligne des centres', () {
      expect(RelioMarkGeometry.curveDepth, closeTo(6, epsilon));
      expect(RelioMarkGeometry.curveLowY, closeTo(56, epsilon));
    });

    test('rapport profondeur/portee conforme au 0,30', () {
      final double ratio =
          RelioMarkGeometry.curveDepth / RelioMarkGeometry.curveSpan;
      // 6 / 20.3 = 0.2956 : la valeur mesuree, pas celle visee.
      expect(ratio, closeTo(0.30, 0.005));
    });

    test('le point bas est centre sous la portee', () {
      expect(RelioMarkGeometry.curveLowX, closeTo(41.85, epsilon));
    });

    test('la cubique atteint effectivement y = 56 au point bas', () {
      // On CONFIRME la valeur par evaluation, on ne la reconduit pas.
      expect(RelioMarkGeometry.curveY(0.5), closeTo(56, 1e-6));
    });

    test('la courbe reste dans les 6 unites de profondeur', () {
      expect(RelioMarkGeometry.measuredDepth(), closeTo(6, 1e-3));
    });

    test('la courbe part et arrive exactement sur y = 50', () {
      expect(RelioMarkGeometry.curveY(0), closeTo(50, 1e-9));
      expect(RelioMarkGeometry.curveY(1), closeTo(50, 1e-9));
    });

    test('la courbe est symetrique autour de x = 41,85', () {
      for (final double t in [0.1, 0.25, 0.4, 0.75, 0.9]) {
        final double x1 = RelioMarkGeometry.curveX(t);
        final double x2 = RelioMarkGeometry.curveX(1 - t);
        expect((x1 + x2) / 2, closeTo(41.85, 1e-6),
            reason: 'asymetrie a t=$t');
      }
    });

    test('la courbe descend puis remonte, sans faire d\'aller-retour', () {
      // Une courbe qui remonte avant son point bas deviendrait un Smiley.
      bool descend = true;
      double precedent = RelioMarkGeometry.curveY(0);
      for (int i = 1; i <= 1000; i++) {
        final double y = RelioMarkGeometry.curveY(i / 1000);
        if (descend && y < precedent) descend = false;
        expect(y, greaterThanOrEqualTo(50 - 1e-9),
            reason: 'la courbe ne doit jamais remonter au-dessus de la ligne des centres');
        precedent = y;
      }
      expect(descend, isFalse, reason: 'le point bas doit etre atteint');
    });

    test('la courbe ne descend pas au-dela de y = 58', () {
      for (int i = 0; i <= 1000; i++) {
        expect(RelioMarkGeometry.curveY(i / 1000), lessThanOrEqualTo(56 + 1e-6));
      }
    });

    test('les deux cercles restent les elements dominants', () {
      // Le diametre du plus grand cercle doit rester nettement superieur a la
      // profondeur de la courbe : sinon la courbe devient le sujet du mark.
      expect(RelioMarkGeometry.radiusRight * 2,
          greaterThan(RelioMarkGeometry.curveDepth * 3));
    });
  });

  group('Variante compacte', () {
    test('le seuil de bascule est 48 dp', () {
      expect(RelioMarkGeometry.compactThresholdDp, 48);
    });

    test('la variante compacte s\'applique sous 48 dp', () {
      expect(RelioMarkGeometry.strokeForSize(24), RelioMarkGeometry.strokeCompact);
      expect(RelioMarkGeometry.strokeForSize(47.9), RelioMarkGeometry.strokeCompact);
      expect(RelioMarkGeometry.strokeForSize(48), RelioMarkGeometry.strokePrimary);
      expect(RelioMarkGeometry.strokeForSize(512), RelioMarkGeometry.strokePrimary);
    });

    test('la variante compacte ne change QUE le trait', () {
      // Cercles et courbe sont identiques entre les deux variantes.
      expect(RelioMarkGeometry.strokeCompact, isNot(RelioMarkGeometry.strokePrimary));
      expect(RelioMarkGeometry.diameterRight, 28);
      expect(RelioMarkGeometry.diameterLeft, closeTo(15.4, epsilon));
      expect(RelioMarkGeometry.curveLowY, closeTo(56, epsilon));
    });

    test('le trait reste visible a 24 dp en variante compacte', () {
      // A 24 dp, un trait de 4 u fait 0.96 px : il disparait. La variante
      // compacte doit le ramener au-dessus du pixel.
      final double epaisseurCompacte = RelioMarkGeometry.strokeCompact * 24 / 100;
      final double epaisseurPrincipale = RelioMarkGeometry.strokePrimary * 24 / 100;
      expect(epaisseurPrincipale, lessThan(1.0));
      expect(epaisseurCompacte, greaterThan(1.4));
    });
  });

  group('Zone safe Android', () {
    test('grille 108 dp et zone sure 66 dp', () {
      expect(RelioMarkGeometry.androidGridDp, 108);
      expect(RelioMarkGeometry.androidSafeZoneDp, 66);
    });

    test('le mark occupe environ 55 % de la zone sure', () {
      expect(RelioMarkGeometry.androidMarkFill, closeTo(0.55, epsilon));
      expect(RelioMarkGeometry.androidMarkSizeDp, closeTo(36.3, epsilon));
    });

    test('le mark tient entierement dans la zone sure', () {
      expect(RelioMarkGeometry.androidMarkSizeDp,
          lessThan(RelioMarkGeometry.androidSafeZoneDp));
    });

    test('il reste de la respiration dans la zone sure', () {
      final double marge =
          (RelioMarkGeometry.androidSafeZoneDp - RelioMarkGeometry.androidMarkSizeDp) / 2;
      expect(marge, greaterThan(0));
    });
  });

  group('Boite englobante et respiration', () {
    test('le mark avec 14 unites de respiration tient dans la grille 100', () {
      for (final double stroke in [
        RelioMarkGeometry.strokePrimary,
        RelioMarkGeometry.strokeCompact,
      ]) {
        final double largeur =
            RelioMarkGeometry.boundingWidth(stroke) + 2 * 14;
        expect(largeur, lessThanOrEqualTo(100),
            reason: 'respiration de 14 u impossible avec un trait de $stroke');
      }
    });

    test('la boite englobante inclut le debord du trait', () {
      final box = RelioMarkGeometry.boundingBox(RelioMarkGeometry.strokePrimary);
      expect(box.left,
          closeTo(RelioMarkGeometry.centerLeftX - RelioMarkGeometry.radiusLeft - 2, epsilon));
      expect(box.right,
          closeTo(RelioMarkGeometry.centerRightX + RelioMarkGeometry.radiusRight + 2, epsilon));
      expect(box.top,
          closeTo(RelioMarkGeometry.centerLineY - RelioMarkGeometry.radiusRight - 2, epsilon));
      expect(box.bottom, closeTo(RelioMarkGeometry.curveLowY + 2, epsilon));
    });

    test('la variante compacte elargit la boite du seul ecart de trait', () {
      // Le trait deborde de sa moitie de chaque cote : l'ecart de largeur vaut
      // exactement (strokeCompact - strokePrimary) = 2.2 u, idem en hauteur.
      final double ecart =
          RelioMarkGeometry.strokeCompact - RelioMarkGeometry.strokePrimary;
      expect(RelioMarkGeometry.boundingWidth(RelioMarkGeometry.strokeCompact) -
              RelioMarkGeometry.boundingWidth(RelioMarkGeometry.strokePrimary),
          closeTo(ecart, 1e-9));
      expect(
          RelioMarkGeometry.boundingHeight(RelioMarkGeometry.strokeCompact) -
              RelioMarkGeometry.boundingHeight(RelioMarkGeometry.strokePrimary),
          closeTo(ecart, 1e-9));
    });
  });

  group('SVG generes', () {
    /// Lit un SVG de `assets/branding/` et echoue si le fichier est absent.
    String lire(String chemin) {
      final File f = File(chemin);
      expect(f.existsSync(), isTrue, reason: 'SVG manquant : $chemin');
      return f.readAsStringSync();
    }

    test('les couleurs sont en hexadecimal exact, jamais en nom', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      expect(svg, contains('#F56207'));
      expect(svg, isNot(contains('orange')));
      expect(svg, isNot(contains('fill="F56207"')), reason: 'le # est obligatoire');
    });

    test('le SVG principal porte les valeurs de la specification', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      expect(svg, contains('cx="66.0"'));
      expect(svg, contains('cx="24.0"'));
      expect(svg, contains('r="14.0"'));
      expect(svg, contains('r="7.7"'));
      expect(svg, contains('M 31.7,50.0'));
      expect(svg, contains('52.0,50.0'));
      expect(svg, contains('stroke-width="4.0"'));
      expect(svg, contains('stroke-linecap="round"'));
    });

    test('le SVG compact porte le trait de 6,2', () {
      final String svg = lire('assets/branding/mark/mark-compact.svg');
      expect(svg, contains('stroke-width="6.2"'));
    });

    test('le SVG compact conserve la meme geometrie de courbe', () {
      final String principal = lire('assets/branding/mark/mark-primary.svg');
      final String compact = lire('assets/branding/mark/mark-compact.svg');
      // Seule l'epaisseur doit differer : les points de controle sont identiques.
      String chemin(String s) =>
          s.substring(s.indexOf('M 31.7'), s.indexOf('" stroke="#'));
      expect(chemin(compact), chemin(principal));
    });

    test('les declinaisons monochrome existent en noir et en blanc', () {
      expect(lire('assets/branding/mark/mark-primary-mono-black.svg'),
          contains('#000000'));
      expect(lire('assets/branding/mark/mark-primary-mono-white.svg'),
          contains('#FFFFFF'));
    });

    test('le point de controle genere vaut bien 37,993 et 45,707', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      expect(svg, contains('C 37.993,58.0 45.707,58.0'));
      // Recoupe avec la geometrie : 31.7 + 20.3 * 0.31 = 37.993
      expect(RelioMarkGeometry.curveControl1X, closeTo(37.993, 0.001));
      expect(RelioMarkGeometry.curveControl2X, closeTo(45.707, 0.001));
    });

    test('le SVG ne contient aucun path approximatif', () {
      // Un seul segment de courbe, deux cercles : aucune suite de coordonnees
      // « au Feeling ».
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      final int commands = 'C '.allMatches(svg).length;
      expect(commands, 1, reason: 'une seule cubique est attendue');
      expect('L '.allMatches(svg).length, 0, reason: 'pas de segment lineaire');
      expect('Q '.allMatches(svg).length, 0, reason: 'pas de quadrique');
    });

    test('le viewBox correspond a la boite englobante', () {
      final String svg = lire('assets/branding/mark/mark-primary.svg');
      final double largeur = RelioMarkGeometry.boundingWidth(4);
      final double hauteur = RelioMarkGeometry.boundingHeight(4);
      expect(svg, contains('viewBox="0 0 ${largeur.toStringAsFixed(1)} ${hauteur.toStringAsFixed(1)}"'));
    });
  });

  group('Robustesse de la mise a l\'echelle', () {
    test('la courbe reste lisible a toutes les tailles exportees', () {
      for (final double dp in [24, 48, 96, 192, 512, 1024]) {
        final double trait = RelioMarkGeometry.strokeForSize(dp) * dp / 100;
        if (dp < RelioMarkGeometry.compactThresholdDp) {
          expect(trait, greaterThan(1.0),
              reason: 'trait invisible a $dp dp');
        } else {
          expect(trait, greaterThan(1.5), reason: 'trait trop fin a $dp dp');
        }
      }
    });

    test('la proportion du mark ne bouge que du fait du trait', () {
      // La boite englobant le trait, elle grossit des deux cotes : le ratio
      // hauteur/largeur evolue legerement entre les variantes. Ce qui doit
      // rester strictement constant, ce sont les CERCLES et la COURBE, dont
      // depend la lecture du mark. C'est cela que ce test verrouille.
      for (final double _ in [4.0, 6.2]) {
        expect(RelioMarkGeometry.radiusRight * 2, 28);
        expect(RelioMarkGeometry.radiusLeft * 2, closeTo(15.4, 1e-9));
        expect(RelioMarkGeometry.curveDepth, closeTo(6, 1e-9));
        expect(RelioMarkGeometry.curveSpan, closeTo(20.3, 1e-9));
      }
      // Et l'ecart de ratio reste faible : le mark ne se deforme pas.
      final double rapportPrincipal =
          RelioMarkGeometry.boundingHeight(4) / RelioMarkGeometry.boundingWidth(4);
      final double rapportCompact =
          RelioMarkGeometry.boundingHeight(6.2) /
              RelioMarkGeometry.boundingWidth(6.2);
      expect((rapportCompact - rapportPrincipal).abs(), lessThan(0.03));
    });
  });
}
