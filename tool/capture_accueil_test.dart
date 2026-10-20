/// Capture du rendu réel de l'écran d'accueil.
///
/// Produit des PNG à la taille de référence d'un téléphone, afin que la mise
/// en page soit INSPECTABLE — et pas seulement l'arbre de widgets.
///
/// Un `find.text` qui passe ne prouve rien sur ce que l'élève voit : un
/// chevauchement, une carte rognée ou un texte hors cadre restent invisibles
/// aux assertions (règle 11). Une capture les montre.
///
/// ```bash
/// flutter test tool/capture_accueil_test.dart
/// ```
///
/// Les images sortent dans `build/accueil-captures/`.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/home/home_state.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

const String kSortie = 'build/accueil-captures';

/// Familles de fichiers à charger : sans elles, le moteur dessine des
/// rectangles à la place des lettres et la capture ne montre rien de réel.
const List<String> kFontes = <String>[
  'assets/fonts/Inter-Regular.ttf',
  'assets/fonts/Inter-Medium.ttf',
  'assets/fonts/Inter-SemiBold.ttf',
  'assets/fonts/Inter-Bold.ttf',
];

Future<void> capturer(
  WidgetTester tester, {
  required String nom,
  required Size taille,
  double defilement = 0,
  HomeState? etat,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final GlobalKey cle = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: cle,
      child: RelioPaletteScope(
        palette: RelioPalette.standard(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RelioTheme.build(),
          home: HomePage(
            name: 'Camille',
            homeState: etat,
            // Les animations sont coupées : la capture montre l'état FINAL,
            // jamais une image prise au milieu d'un remplissage.
            reduceAnimations: true,
            onContinue: () {},
            onFiveMinutes: () {},
            onWarmup: () {},
            onOpenLesson: (_) {},
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  if (defilement > 0) {
    await tester.drag(find.byType(ListView), Offset(0, -defilement));
    await tester.pump();
  }

  final RenderRepaintBoundary boundary =
      cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // L'encodage PNG est une opération du MOTEUR, asynchrone et hors de la zone
  // de temps simulé du test. Sans `runAsync`, l'attente ne se résout jamais et
  // le test reste bloqué après avoir écrit l'image. `runAsync` rend la main à
  // la vraie boucle d'événements le temps de l'encodage.
  final ByteData? data = await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes;
  });
  expect(data, isNotNull);

  final File fichier = File('$kSortie/$nom.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
  debugPrint('capture : ${fichier.path} (${data.lengthInBytes} octets)');
}

void main() {
  setUpAll(() async {
    for (final String chemin in kFontes) {
      final FontLoader loader = FontLoader('Inter')
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(File(chemin).readAsBytesSync()),
          ),
        );
      await loader.load();
    }

    // La fonte d'icônes de Material n'est pas chargée par défaut dans les
    // tests : sans elle, chaque icône sort en carré vide. On la charge depuis
    // le cache du SDK pour que la capture montre ce que l'élève verra.
    final File icones = File(
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
      'material_fonts/MaterialIcons-Regular.otf',
    );
    if (icones.existsSync()) {
      final FontLoader loader = FontLoader('MaterialIcons')
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(icones.readAsBytesSync()),
          ),
        );
      await loader.load();
    }
  });

  testWidgets('accueil complet, 360 x 980', (tester) async {
    // Toute la page tient en une image : c'est la vue de contrôle.
    await capturer(
      tester,
      nom: 'accueil-complet',
      taille: const Size(360, 980),
    );
  });

  testWidgets('accueil sur petit écran, 360 x 640', (tester) async {
    // Ce que voit l'élève à l'ouverture, sans défiler.
    await capturer(
      tester,
      nom: 'accueil-360x640',
      taille: const Size(360, 640),
    );
  });

  testWidgets('accueil avec mémoire, 360 x 980', (tester) async {
    // Variante contextuelle : Relio rappelle une hésitation récente. Seule la
    // phrase change — l'objectif et la carte « Reprendre » restent identiques.
    await capturer(
      tester,
      nom: 'accueil-memoire',
      taille: const Size(360, 980),
      etat: HomeState.mock(recentBlock: RecentBlockCodes.subtractionWrong),
    );
  });
}
