/// Verification de l'icone de lanceur, telle que le lanceur la composera.
///
/// Les deux corrections ne se verifient pas dans l'application : l'icone n'apparait
/// QUE dans le lanceur Android, hors du processus de l'app. On compose donc
/// ici les couches exactement comme le fait le systeme, pour verifier ce que
/// l'eleve verra reellement.
///
/// Ce fichier n'est pas un test : c'est un outil de controle visuel. Il ecrit
/// une image de comparaison dans `assets/branding/render/`.
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show instantiateImageCodec;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compose un fond et un premier plan, comme le fait le lanceur.
Future<ui.Image> _composer({
  required double cote,
  required ui.Image fond,
  required ui.Image premierPlan,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  // Le fond, puis le premier plan par-dessus — l'ordre de l'adaptive-icon.
  final ui.Image fondDecode = fond;
  final ui.Image fgDecode = premierPlan;

  canvas.drawImageRect(
    fondDecode,
    Rect.fromLTWH(0, 0, fondDecode.width.toDouble(), fondDecode.height.toDouble()),
    Rect.fromLTWH(0, 0, cote, cote),
    Paint(),
  );
  canvas.drawImageRect(
    fgDecode,
    Rect.fromLTWH(0, 0, fgDecode.width.toDouble(), fgDecode.height.toDouble()),
    Rect.fromLTWH(0, 0, cote, cote),
    Paint(),
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(cote.round(), cote.round());
  picture.dispose();
  return image;
}

Future<void> _ecrire(ui.Image image, String chemin) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(chemin)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

Future<ui.Image> _chargerPng(String chemin) async {
  final bytes = File(chemin).readAsBytesSync();
  final codec = await instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void main() {
  testWidgets('composition de l\'icone telle que le lanceur la voit', (WidgetTester tester) async {
    await tester.runAsync(() async {
      const String res = 'android/app/src/main/res';
      const String sortie = 'assets/branding/render';

      // xxxhdpi : grille de 108 dp x 4 = 432 px.
      const double cote = 432;
      final ui.Image fond = await _chargerPng('$res/mipmap-xxxhdpi/ic_launcher_background.png');
      final ui.Image fg = await _chargerPng('$res/mipmap-xxxhdpi/ic_launcher_foreground.png');

      final ui.Image compose = await _composer(
        cote: cote,
        fond: fond,
        premierPlan: fg,
      );
      await _ecrire(compose, '$sortie/launcher-compose-xxxhdpi.png');

      // Taille reelle d'une icone de lanceur : ~48 dp, donc 192 px en xxxhdpi.
      // C'est a CETTE taille que le mark doit rester lisible.
      final ui.Image reduite = await _composer(
        cote: 192,
        fond: fond,
        premierPlan: fg,
      );
      await _ecrire(reduite, '$sortie/launcher-compose-48dp.png');

      // Et au strict minimum : 48 dp en mdpi, soit 48 px — la taille ou le
      // contre du « R » se referme a peine.
      final ui.Image min48 = await _composer(
        cote: 48,
        fond: fond,
        premierPlan: fg,
      );
      await _ecrire(min48, '$sortie/launcher-compose-mdpi-48.png');
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
