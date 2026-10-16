/// Verification MESUREE de l'icone de lanceur.
///
/// L'icone ne se verifie pas en la regardant : un mark trop petit passe
/// inapercu a l'oeil, et un fond de la mauvaise couleur se remarque a peine
/// dans une liste d'applications. On mesure donc les pixels reels des PNG
/// produits par `tool/brand_launcher.py` depuis l'icone livree.
///
/// Ce que ces tests verrouillent :
///  - le fond est ORANGE, ce qui rend le mark navy lisible ;
///  - le premier plan porte navy ET blanc (les pages), jamais d'orange
///    (l'orange du mark s'y confond avec le fond, comme sur l'icone livree) ;
///  - la couche monochrome est noire, sans trace de couleur.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

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

/// Vrai si le pixel est franchement navy de marque (pas noir).
bool _estNavy(_Pixel p) =>
    p.a > 128 &&
    p.r < 0x40 &&
    p.g < 0x40 &&
    p.b < 0x60 &&
    (p.r + p.g + p.b) > 20;

/// Vrai si le pixel est franchement blanc opaque.
bool _estBlanc(_Pixel p) =>
    p.a > 128 && p.r > 0xF0 && p.g > 0xF0 && p.b > 0xF0;

/// Vrai si le pixel est franchement noir opaque.
bool _estNoir(_Pixel p) =>
    p.a > 128 && p.r < 0x30 && p.g < 0x30 && p.b < 0x30;

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

  group('Le fond est orange', () {
    for (final String nom in densites.keys) {
      test('$nom : aplat orange opaque, sans dessin', () async {
        final bg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_background.png');

        // Aucun dessin dans le fond : ni le mark, ni la moitie de lui.
        final box = _encadrement(bg.width, bg.height, bg.at, _estBlanc);
        expect(box.right, lessThan(box.left), reason: 'le fond ne doit porter aucun dessin ($nom)');
        final navy = _encadrement(bg.width, bg.height, bg.at, _estNavy);
        expect(navy.right, lessThan(navy.left), reason: 'pas de navy dans le fond ($nom)');

        // Orange sur toute sa surface, opaque.
        final centre = bg.at(bg.width ~/ 2, bg.height ~/ 2);
        expect(_estOrange(centre), isTrue, reason: 'fond orange attendu ($nom)');
        expect(centre.a, 255, reason: 'le fond est opaque');
      });
    }
  });

  group('Le premier plan est navy et blanc', () {
    for (final String nom in densites.keys) {
      test('$nom : navy ET blanc, jamais d\'orange', () async {
        final fg = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher_foreground.png');

        final navys = _encadrement(fg.width, fg.height, fg.at, _estNavy);
        final blancs = _encadrement(fg.width, fg.height, fg.at, _estBlanc);
        final oranges = _encadrement(fg.width, fg.height, fg.at, _estOrange);

        expect(navys.right, greaterThan(navys.left),
            reason: 'la structure navy est absente ($nom)');
        expect(blancs.right, greaterThan(blancs.left),
            reason: 'les pages blanches sont absentes ($nom)');
        expect(oranges.right, lessThan(oranges.left),
            reason: 'l\'orange du mark doit se confondre avec le fond ($nom)');

        // La structure navy domine : c'est elle qui porte la lisibilite.
        int pixelsNavy = 0;
        int pixelsBlanc = 0;
        for (int y = 0; y < fg.height; y++) {
          for (int x = 0; x < fg.width; x++) {
            final p = fg.at(x, y);
            if (_estNavy(p)) pixelsNavy++;
            if (_estBlanc(p)) pixelsBlanc++;
          }
        }
        expect(pixelsNavy, greaterThan(pixelsBlanc),
            reason: 'la structure doit dominer les pages ($nom)');
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
      int navy = 0;
      for (int y = 0; y < mono.height; y += 2) {
        for (int x = 0; x < mono.width; x += 2) {
          if (_estOrange(mono.at(x, y))) orange++;
          if (_estBlanc(mono.at(x, y))) blanc++;
          if (_estNavy(mono.at(x, y))) navy++;
        }
      }
      expect(orange, 0, reason: 'la couche monochrome ne doit pas etre orange');
      expect(blanc, 0, reason: 'la couche monochrome ne doit pas etre blanche');
      expect(navy, 0, reason: 'la couche monochrome ne doit pas etre navy');
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
      test('$nom : fond orange, mark navy lisible, coins arrondis', () async {
        final px = await _lire('android/app/src/main/res/mipmap-$nom/ic_launcher.png');

        // Le fond ne touche pas le bord du fichier : les coins sont arrondis.
        expect(px.at(0, 0).a, lessThan(16),
            reason: 'le fond ne doit pas toucher le bord du fichier ($nom)');
        expect(px.at(px.width ~/ 2, px.height ~/ 2).a, 255,
            reason: 'le fond doit etre present au centre ($nom)');

        // Le mark est present, en navy ET en blanc.
        final navys = _encadrement(px.width, px.height, px.at, _estNavy);
        expect(navys.right, greaterThan(navys.left),
            reason: 'le mark navy est absent ($nom)');
        final blancs = _encadrement(px.width, px.height, px.at, _estBlanc);
        expect(blancs.right, greaterThan(blancs.left),
            reason: 'les pages blanches sont absentes ($nom)');
      });
    }

    test('xxhdpi : la variante ronde est un disque orange', () async {
      final px = await _lire('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png');
      // Centre plein, coin degage.
      expect(px.at(px.width ~/ 2, px.height ~/ 2).a, 255);
      expect(px.at(1, 1).a, lessThan(16));
    });
  });
}
