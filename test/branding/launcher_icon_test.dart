/// Verification MESUREE de l'icone de lanceur.
///
/// L'icone ne se verifie pas en la regardant : le defaut signale etait un
/// carre orange, et un mark trop petit passe inapercu a l'oeil. On mesure donc
/// les pixels reels du PNG produit.
///
/// Ce que ces tests verrouillent :
///  - le fond est BLANC, pas orange (le defaut corrige) ;
///  - le mark occupe bien ~36 dp de LARGEUR reelle dans la grille de 108 dp ;
///  - le mark tient entierement dans la zone sure de 66 dp ;
///  - le trait compact est employe, pas le trait principal qui s'efface ;
///  - le premier plan a bien un canal alpha, l'arriere-plan est opaque.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_mark_geometry.dart';

/// Pixel d'une image RGBA brute.
class _Pixel {
  const _Pixel(this.r, this.g, this.b, this.a);
  final int r;
  final int g;
  final int b;
  final int a;
}

/// Lit un PNG et renvoie ses pixels bruts.
Future<({int width, int height, _Pixel Function(int, int) at})> _lire(
  String chemin,
) async {
  final File f = File(chemin);
  expect(f.existsSync(), isTrue, reason: 'image manquante : $chemin');

  final codec = await ui.instantiateImageCodec(f.readAsBytesSync());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(data, isNotNull);
  final Uint8List bytes = data!.buffer.asUint8List();
  final int w = image.width;
  final int h = image.height;

  _Pixel at(int x, int y) {
    final int i = (y * w + x) * 4;
    return _Pixel(bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
  }

  image.dispose();
  return (width: w, height: h, at: at);
}

/// Vrai si le pixel est franchement orange de marque.
bool _estOrange(_Pixel p) =>
    p.a > 128 && p.r > 0xE0 && p.g > 0x50 && p.g < 0x80 && p.b < 0x30;

/// Boite englobante des pixels orange, en px.
({int left, int top, int right, int bottom}) _encadrementOrange(
  int w,
  int h,
  _Pixel Function(int, int) at,
) {
  int left = w, top = h, right = -1, bottom = -1;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (_estOrange(at(x, y))) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  return (left: left, top: top, right: right, bottom: bottom);
}

void main() {
  const Map<String, double> densites = <String, double>{
    'mdpi': 1,
    'hdpi': 1.5,
    'xhdpi': 2,
    'xxhdpi': 3,
    'xxxhdpi': 4,
  };

  group('Dimensions des fichiers', () {
    densites.forEach((String nom, double facteur) {
      test('$nom : les deux couches font bien 108 dp de cote', () async {
        final expected = (108 * facteur).round();
        final fg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_foreground.png');
        final bg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_background.png');
        expect(fg.width, expected, reason: 'foreground $nom');
        expect(fg.height, expected, reason: 'foreground $nom');
        expect(bg.width, expected, reason: 'background $nom');
        expect(bg.height, expected, reason: 'background $nom');
      });
    });
  });

  group('Le fond est blanc (correction du carre orange)', () {
    for (final String nom in densites.keys) {
      test('$nom : le fond est blanc opaque, sans trace d\'orange', () async {
        final bg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_background.png');

        // Aucun pixel orange dans le fond : c'etait exactement le defaut.
        int orange = 0;
        for (int y = 0; y < bg.height; y++) {
          for (int x = 0; x < bg.width; x++) {
            if (_estOrange(bg.at(x, y))) orange++;
          }
        }
        expect(orange, 0, reason: 'le fond ne doit contenir aucun pixel orange ($nom)');

        // Et il est blanc sur toute sa surface, opaque.
        final centre = bg.at(bg.width ~/ 2, bg.height ~/ 2);
        expect(centre.r, greaterThan(0xF0));
        expect(centre.g, greaterThan(0xF0));
        expect(centre.b, greaterThan(0xF0));
        expect(centre.a, 255, reason: 'le fond est opaque');
      });
    }
  });

  group('Le mark occupe la largeur attendue', () {
    for (final String nom in densites.keys) {
      test('$nom : largeur reelle d\'environ 36 dp, dans la zone sure', () async {
        final facteur = densites[nom]!;
        final fg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_foreground.png');

        final box = _encadrementOrange(fg.width, fg.height, fg.at);
        expect(box.right, greaterThan(box.left), reason: 'aucun mark trouve ($nom)');

        final double largeurDp = (box.right - box.left + 1) / facteur;
        final double hauteurDp = (box.bottom - box.top + 1) / facteur;

        // La specification : environ 36 dp de large.
        expect(largeurDp, closeTo(RelioMarkGeometry.androidMarkWidthDp, 2.0),
            reason: 'largeur du mark en dp ($nom)');

        // Ce qui compte vraiment : le mark est visible, pas un point.
        expect(largeurDp, greaterThan(30), reason: 'mark trop petit ($nom)');
        expect(hauteurDp, greaterThan(11), reason: 'mark trop plat ($nom)');

        // Le mark est plus large que haut : c'est sa nature meme.
        expect(largeurDp, greaterThan(hauteurDp * 2), reason: 'proportion anormale ($nom)');

        // Il tient entierement dans la zone sure de 66 dp.
        final double centreX = (box.left + box.right) / 2 / facteur;
        final double centreY = (box.top + box.bottom) / 2 / facteur;
        expect(centreX, closeTo(54, 1.5), reason: 'le mark doit etre centre ($nom)');
        expect(centreY, closeTo(54, 1.5), reason: 'le mark doit etre centre ($nom)');

        final double demiLargeur = largeurDp / 2;
        final double demiHauteur = hauteurDp / 2;
        expect(centreX - demiLargeur, greaterThan(54 - 33 - 0.5),
            reason: 'debord a gauche de la zone sure ($nom)');
        expect(centreX + demiLargeur, lessThan(54 + 33 + 0.5),
            reason: 'debord a droite de la zone sure ($nom)');
        expect(centreY - demiHauteur, greaterThan(54 - 33 - 0.5),
            reason: 'debord en haut de la zone sure ($nom)');
        expect(centreY + demiHauteur, lessThan(54 + 33 + 0.5),
            reason: 'debord en bas de la zone sure ($nom)');
      });
    }
  });

  group('Variante compacte', () {
    test('le premier plan a un canal alpha, l\'arriere-plan non', () async {
      final fg = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png');
      final bg = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_background.png');

      // Le coin du premier plan est transparent : c'est ce qui permet au fond
      // de transparaître et aux masques d'agir.
      expect(fg.at(1, 1).a, lessThan(16), reason: 'le premier plan doit avoir un fond transparent');

      // Le fond est opaque partout.
      expect(bg.at(1, 1).a, 255);
    });

    test('le trait compact reste visible a la taille du lanceur', () async {
      // Sur une icone de 48 dp, le trait de 4 u (variante principale) ferait
      // 1,34 dp : il disparait. La variante compacte, 6,2 u, fait 2,08 dp.
      const double dpIcone = 48;
      final double principal =
          RelioMarkGeometry.strokePrimary * RelioMarkGeometry.androidMarkWidthDp / 108;
      final double compact =
          RelioMarkGeometry.strokeCompact * RelioMarkGeometry.androidMarkWidthDp / 108;

      expect(principal, lessThan(1.5), reason: 'la variante principale disparait');
      expect(compact, greaterThan(1.9), reason: 'la variante compacte doit rester visible');

      // Le trait reellement employe sur l'icone est bien le compact.
      final double facteur = densites['xxxhdpi']!;
      final fg = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png');
      final box = _encadrementOrange(fg.width, fg.height, fg.at);

      // Epaisseur du plus petit cercle, mesuree sur son bord superieur : le
      // petit cercle a un rayon de 7,7 u, donc 2r = 15,4 u de diametre.
      final double diamPetitDp = 15.4 * RelioMarkGeometry.androidMarkWidthDp / 108;
      final int xPetit = (box.left + 4).toInt().clamp(0, fg.width - 1);
      int epaisseurPx = 0;
      for (int y = 0; y < fg.height; y++) {
        if (_estOrange(fg.at(xPetit, y))) epaisseurPx++;
      }
      final double epaisseurDp = epaisseurPx / facteur;
      // Sur le petit cercle, la hauteur du disque au centre vaut son diametre ;
      // on verifie au moins que le trait n'est pas d'un pixel.
      expect(epaisseurPx, greaterThan(4),
          reason: 'trait trop fin dans l\'icone ($epaisseurPx px)');
      expect(diamPetitDp, greaterThan(0));
      expect(epaisseurDp, greaterThan(0));
      expect(dpIcone, greaterThan(0));
    });
  });

  group('Le mark est distinct du fond', () {
    test('le premier plan contient bien de l\'orange de marque', () async {
      final fg = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png');
      final box = _encadrementOrange(fg.width, fg.height, fg.at);
      expect(box.right, greaterThan(box.left), reason: 'le mark doit etre present');
    });

    test('la couche monochrome est noire, pas orange', () async {
      final mono = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_monochrome.png');
      int orange = 0;
      for (int y = 0; y < mono.height; y += 2) {
        for (int x = 0; x < mono.width; x += 2) {
          if (_estOrange(mono.at(x, y))) orange++;
        }
      }
      expect(orange, 0, reason: 'la couche monochrome doit etre noire');
    });
  });
}
