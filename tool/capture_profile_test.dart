/// Capture du rendu réel de l'écran Profil.
///
/// Produit un PNG à la largeur de référence (360), sur une hauteur qui contient
/// les quatre cartes : le rendu est ainsi inspectable d'un seul coup, au lieu
/// de dépendre de la seule arborescence de widgets.
///
/// Ce n'est PAS un lancement sur appareil : c'est le moteur de rendu de test,
/// à la taille de référence.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/screens/profile_page.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

const Size kTaille = Size(360, 1000);
const String kSortie = 'build/profile-captures';

Future<void> capturer(
  WidgetTester tester,
  String nom,
  LearnerSettings settings,
) async {
  tester.view.physicalSize = kTaille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final GlobalKey cle = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: cle,
      child: RelioPaletteScope(
        palette: RelioPalette.of(highContrast: settings.highContrast),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RelioTheme.build(settings: settings),
          home: ProfilePage(
            settings: settings,
            onChanged: (LearnerSettings _) {},
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final RenderRepaintBoundary boundary =
      cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  final ByteData? data = await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return bytes;
  });
  expect(data, isNotNull);

  final File fichier = File('$kSortie/$nom.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
  debugPrint('capture : ${fichier.path} (${data.lengthInBytes} octets)');
}

/// Remonte depuis l'exécutable Dart jusqu'à la racine du SDK Flutter.
///
/// `Platform.environment['FLUTTER_ROOT']` n'est pas toujours défini quand le
/// test est lancé par l'outil. Dans ce cas, on cherche le dossier d'artefacts
/// en remontant l'arborescence de l'exécutable.
String _racineFlutter() {
  final String? env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && Directory(env).existsSync()) return env;

  Directory dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    if (Directory('${dir.path}/bin/cache/artifacts/material_fonts')
        .existsSync()) {
      return dir.path;
    }
    final Directory parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return '';
}

void main() {
  // La police est chargée explicitement : sans cela, le moteur dessine des
  // rectangles à la place des lettres.
  setUpAll(() async {
    for (final String poids in <String>[
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      final FontLoader loader = FontLoader('Inter')
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(
              File('assets/fonts/Inter-$poids.ttf').readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
    }

    // Les icônes Material vivent dans le SDK, pas dans le dépôt. Sans elles,
    // la capture montre des carrés vides à la place des icônes.
    final File icones = File(
      '${_racineFlutter()}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
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

  testWidgets('profil — prénom renseigné', (WidgetTester tester) async {
    await capturer(tester, 'profil', const LearnerSettings(name: 'Awa'));
  });

  testWidgets('profil — prénom vide', (WidgetTester tester) async {
    await capturer(tester, 'profil-vide', LearnerSettings.defaults);
  });

  testWidgets('profil — contraste renforcé', (WidgetTester tester) async {
    await capturer(
      tester,
      'profil-contraste',
      const LearnerSettings(name: 'Awa', highContrast: true),
    );
  });
}
