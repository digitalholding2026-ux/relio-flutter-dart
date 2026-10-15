/// Capture du rendu réel des écrans du parcours d'entrée.
///
/// Produit des PNG à la résolution de référence (360 x 640) afin que le
/// RENDU soit inspectable, et pas seulement l'arbre de widgets.
///
/// C'est la réponse au blocage qui a été constaté sur téléphone : un écran
/// dont les blocs sont à `Opacity 0` produit une image BLANCHE, même si tous
/// les `find.text(...)` passent. Une capture le montre immédiatement.
///
/// Ce n'est PAS un lancement sur appareil : c'est le moteur de rendu du
/// moteur, dans l'environnement de test, à la taille de référence.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_intro_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/screens/onboarding/welcome_page.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

const Size kTaille = Size(360, 640);
const String kSortie = 'build/parcours-captures';

Future<void> capturer(WidgetTester tester, String nom, Widget ecran) async {
  tester.view.physicalSize = kTaille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final GlobalKey cle = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: cle,
      child: RelioPaletteScope(
        palette: RelioPalette.standard(),
        child: MaterialApp(home: ecran),
      ),
    ),
  );

  // Les animations sont RÉDUITES : la capture doit montrer l'état FINAL de
  // chaque écran, pas une image prise au milieu d'un fondu.
  await tester.pump();
  for (int i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  final RenderRepaintBoundary boundary =
      cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: 2);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  expect(data, isNotNull);

  final File fichier = File('$kSortie/$nom.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
  debugPrint('capture : ${fichier.path} (${data.lengthInBytes} octets)');
}

void main() {
  // La police est chargée EXPLICITEMENT : sans cela, le moteur ne connaît pas
  // la famille et dessine des rectangles à la place des lettres. Une capture
  // faite sans cette étape montrerait un rendu que personne ne verra jamais.
  setUpAll(() async {
    final FontLoader loader = FontLoader('Inter')
      ..addFont(
        Future<ByteData>.value(
          ByteData.sublistView(
            File('assets/fonts/Inter-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    await loader.load();
  });

  testWidgets('bienvenue', (WidgetTester tester) async {
    await capturer(
      tester,
      '2-bienvenue',
      WelcomePage(onStart: () async {}, reduceAnimations: true),
    );
  });

  testWidgets('introduction au questionnaire', (WidgetTester tester) async {
    await capturer(
      tester,
      '3-introduction',
      EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
    );
  });

  testWidgets('prénom', (WidgetTester tester) async {
    await capturer(
      tester,
      '4-prenom',
      NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
    );
  });

  testWidgets('clôture', (WidgetTester tester) async {
    await capturer(
      tester,
      '6-cloture',
      ClosingPage(
        name: 'Awa',
        onConfirm: () async {},
        reduceAnimations: true,
      ),
    );
  });
}