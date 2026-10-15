/// Verification MESUREE de l'icone de lanceur.
///
/// L'icone ne se verifie pas en la regardant : un mark trop petit passe
/// inapercu a l'oeil, et un fond de la mauvaise couleur se remarque a peine
/// dans une liste d'applications. On mesure donc les pixels reels des PNG
/// produits.
///
/// Ce que ces tests verrouillent :
///  - le fond est INDIGO, ce qui rend le mark blanc lisible ;
///  - le mark occupe bien ~36 dp de LARGEUR reelle dans la grille de 108 dp ;
///  - le mark tient entierement dans la zone sure de 66 dp ;
///  - le premier plan porte blanc ET orange, pas une couleur unique ;
///  - la couche monochrome est noire, sans trace de couleur.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_mark.dart';
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

/// Vrai si le pixel est franchement indigo de marque.
bool _estIndigo(_Pixel p) =>
    p.a > 128 && p.b > 0x50 && p.r < 0x60 && p.g < 0x60;

/// Vrai si le pixel est franchement blanc opaque.
bool _estBlanc(_Pixel p) =>
    p.a > 128 && p.r > 0xF0 && p.g > 0xF0 && p.b > 0xF0;

/// Vrai si le pixel est franchement noir opaque.
bool _estNoir(_Pixel p) =>
    p.a > 128 && p.r < 0x30 && p.g < 0x30 && p.b < 0x30;

/// Vrai si le pixel porte quoi que ce soit.
bool _estPeint(_Pixel p) => p.a > 128;

/// Boite englobante des pixels verifiant [test], en px.
({int left, int top, int right, int bottom}) _encadrement(
  int w,
  int h,
  _Pixel Function(int, int) at,
  bool Function(_Pixel) test,
) {
  int left = w, top = h, right = -1, bottom = -1;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (test(at(x, y))) {
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

  group('Le fond est indigo', () {
    for (final String nom in densites.keys) {
      test('$nom : aplat indigo opaque, sans dessin', () async {
        final bg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_background.png');

        // Aucun dessin dans le fond : ni le mark, ni le moitie de lui.
        final box = _encadrement(bg.width, bg.height, bg.at, _estBlanc);
        expect(box.right, lessThan(box.left), reason: 'le fond ne doit porter aucun dessin ($nom)');

        // Indigo sur toute sa surface, opaque.
        final centre = bg.at(bg.width ~/ 2, bg.height ~/ 2);
        expect(_estIndigo(centre), isTrue, reason: 'fond indigo attendu ($nom)');
        expect(centre.a, 255, reason: 'le fond est opaque');
      });
    }
  });

  group('Le mark occupe la largeur attendue', () {
    for (final String nom in densites.keys) {
      test('$nom : largeur reelle d\'environ 36 dp, dans la zone sure', () async {
        final facteur = densites[nom]!;
        final fg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_foreground.png');

        // On mesure l'ENCRE, c'est-a-dire tout ce qui est peint : le « R »
        // blanc et les accents orange.
        final box = _encadrement(fg.width, fg.height, fg.at, _estPeint);
        expect(box.right, greaterThan(box.left), reason: 'aucun mark trouve ($nom)');

        final double largeurDp = (box.right - box.left + 1) / facteur;
        final double hauteurDp = (box.bottom - box.top + 1) / facteur;

        expect(largeurDp, closeTo(RelioMarkGeometry.androidMarkWidthDp, 2.0),
            reason: 'largeur du mark en dp ($nom)');

        // Ce qui compte vraiment : le mark est visible, pas un point.
        expect(largeurDp, greaterThan(30), reason: 'mark trop petit ($nom)');
        expect(hauteurDp, greaterThan(30), reason: 'mark trop plat ($nom)');

        // Le mark est plus haut que large : c'est un « R », pas une pastille.
        expect(hauteurDp, greaterThan(largeurDp), reason: 'proportion anormale ($nom)');
        expect(hauteurDp / largeurDp, closeTo(
            RelioMarkGeometry.inkHeight / RelioMarkGeometry.inkWidth, 0.08),
            reason: 'le rapport de forme du mark a derive ($nom)');

        // Il est centre dans la grille de 108 dp.
        final double centreX = (box.left + box.right) / 2 / facteur;
        final double centreY = (box.top + box.bottom) / 2 / facteur;
        expect(centreX, closeTo(54, 1.5), reason: 'le mark doit etre centre ($nom)');
        expect(centreY, closeTo(54, 1.5), reason: 'le mark doit etre centre ($nom)');

        // Il tient entierement dans la zone sure de 66 dp.
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

  group('Le premier plan est bichrome', () {
    for (final String nom in densites.keys) {
      test('$nom : blanc ET orange, jamais une couleur unique', () async {
        final fg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_foreground.png');

        final blancs = _encadrement(fg.width, fg.height, fg.at, _estBlanc);
        final oranges = _encadrement(fg.width, fg.height, fg.at, _estOrange);

        expect(blancs.right, greaterThan(blancs.left),
            reason: 'le « R » blanc est absent ($nom)');
        expect(oranges.right, greaterThan(oranges.left),
            reason: 'l\'accent orange est absent ($nom)');

        // Le « R » blanc est le sujet : il occupe nettement plus de surface que
        // les accents, qui n'en sont que trois traits courts.
        int pixelsBlanc = 0;
        int pixelsOrange = 0;
        for (int y = 0; y < fg.height; y++) {
          for (int x = 0; x < fg.width; x++) {
            final p = fg.at(x, y);
            if (_estBlanc(p)) pixelsBlanc++;
            if (_estOrange(p)) pixelsOrange++;
          }
        }
        expect(pixelsBlanc, greaterThan(pixelsOrange * 2),
            reason: 'la structure doit dominer les accents ($nom)');
      });
    }
  });

  group('Calques', () {
    test('le premier plan a un canal alpha, l\'arriere-plan non', () async {
      final fg = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png');
      final bg = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_background.png');

      // Le coin du premier plan est transparent : c'est ce qui permet au fond
      // de transparaitre et aux masques constructeur d'agir.
      expect(fg.at(1, 1).a, lessThan(16),
          reason: 'le premier plan doit avoir un fond transparent');
      expect(bg.at(1, 1).a, 255);
    });

    test('la couche monochrome est noire, sans aucune couleur', () async {
      final mono = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_monochrome.png');
      int orange = 0;
      int blanc = 0;
      int indigos = 0;
      for (int y = 0; y < mono.height; y += 2) {
        for (int x = 0; x < mono.width; x += 2) {
          if (_estOrange(mono.at(x, y))) orange++;
          if (_estBlanc(mono.at(x, y))) blanc++;
          if (_estIndigo(mono.at(x, y))) indigos++;
        }
      }
      expect(orange, 0, reason: 'la couche monochrome ne doit pas etre orange');
      expect(blanc, 0, reason: 'la couche monochrome ne doit pas etre blanche');
      expect(indigos, 0, reason: 'la couche monochrome ne doit pas etre indigo');
    });

    test('la couche monochrome porte bien le mark', () async {
      final mono = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_monochrome.png');
      final box = _encadrement(mono.width, mono.height, mono.at, _estNoir);
      expect(box.right, greaterThan(box.left),
          reason: 'Android 13+ teinte cette couche : elle doit porter le mark');
    });
  });

  group('Icone legacy', () {
    for (final String nom in densites.keys) {
      test('$nom : fond indigo, mark blanc lisible, coins arrondis', () async {
        final px = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher.png');

        // Le fond occupe presque tout le carre : il est en retrait de 12/512,
        // et non colle aux bords.
        expect(px.at(0, 0).a, lessThan(16),
            reason: 'le fond ne doit pas toucher le bord du fichier ($nom)');
        expect(px.at(px.width ~/ 2, px.height ~/ 2).a, 255,
            reason: 'le fond doit etre present au centre ($nom)');

        // Le mark est present, en blanc ET en orange.
        final blancs = _encadrement(px.width, px.height, px.at, _estBlanc);
        expect(blancs.right, greaterThan(blancs.left),
            reason: 'le mark blanc est absent ($nom)');
      });
    }

    test('xxhdpi : la variante ronde est un disque indigo', () async {
      final px = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png');
      // Centre plein, coin degage.
      expect(px.at(px.width ~/ 2, px.height ~/ 2).a, 255);
      expect(px.at(1, 1).a, lessThan(16));
    });
  });
}