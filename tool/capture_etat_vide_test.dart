/// Captures de l'état vide et du tuteur, à la taille d'un téléphone.
///
/// Règle 11 : un `find.text` qui passe ne prouve pas que l'écran est lisible.
/// Ces captures montrent ce que voit un nouvel élève :
///
///  - Accueil : carte « COMMENCER », message des premiers pas, zéros ;
///  - Apprendre : trois leçons « À commencer », barre du chapitre vide ;
///  - Profil : « 0 Exercice terminé », « 0 Notion maîtrisée » ;
///  - Tuteur : panneau de conversation à 75 % de la hauteur.
///
/// ```bash
/// flutter test tool/capture_etat_vide_test.dart
/// ```
///
/// Les images sortent dans `build/etat-vide-captures/`.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/domain/tutor/tutor_client.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';
import 'package:relio/presentation/home/home_state.dart';
import 'package:relio/presentation/learn/learn_state.dart';
import 'package:relio/presentation/screens/app_shell_nav.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/screens/learn_page.dart';
import 'package:relio/presentation/screens/profile_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/relio_tutor_sheet.dart';

import '../test/helpers/test_database.dart';

const String kSortie = 'build/etat-vide-captures';

/// Fontes réelles, sans quoi la capture montre des rectangles.
const List<String> kFontes = <String>[
  'assets/fonts/Inter-Regular.ttf',
  'assets/fonts/Inter-Medium.ttf',
  'assets/fonts/Inter-SemiBold.ttf',
  'assets/fonts/Inter-Bold.ttf',
];

/// Écrit un PNG de [ecran] et rend le chemin du fichier.
///
/// [enveloppe] vaut `false` pour un écran qui porte déjà son `MaterialApp` et
/// sa palette — c'est le cas de `RelioApp`, qu'il ne faut pas emboîter.
Future<void> capturer(
  WidgetTester tester, {
  required String nom,
  required Size taille,
  required Widget ecran,
  bool enveloppe = true,
  Future<void> Function(WidgetTester tester)? apresMontage,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final GlobalKey cle = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: cle,
      child: enveloppe
          ? RelioPaletteScope(
              palette: RelioPalette.standard(),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: RelioTheme.build(),
                home: ecran,
              ),
            )
          : ecran,
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  if (apresMontage != null) {
    await apresMontage(tester);
    await tester.pump(const Duration(milliseconds: 400));
  }

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

  testWidgets('accueil à l’état vide, 360 x 980', (tester) async {
    await capturer(
      tester,
      nom: 'accueil-vide',
      taille: const Size(360, 980),
      ecran: HomePage(
        name: 'Camille',
        homeState: HomeState.empty(),
        reduceAnimations: true,
        onContinue: () {},
        onFiveMinutes: () {},
        onWarmup: () {},
        onOpenLesson: (_) {},
      ),
    );
  });

  testWidgets('apprendre à l’état vide, 360 x 980', (tester) async {
    await capturer(
      tester,
      nom: 'apprendre-vide',
      taille: const Size(360, 980),
      ecran: LearnPage(
        learnState: LearnState.empty(),
        reduceAnimations: true,
        onOpenChapter1: () {},
      ),
    );
  });

  testWidgets('profil à l’état vide, 360 x 900', (tester) async {
    await capturer(
      tester,
      nom: 'profil-vide',
      taille: const Size(360, 900),
      ecran: ProfilePage(
        settings: LearnerSettings.defaults,
        progress: LearnerProgress.empty,
        onChanged: (_) {},
      ),
    );
  });

  testWidgets('exercice S2 — aide et tuteur, 360 x 640', (tester) async {
    final AppDatabase db = await openTestDatabase();
    registerTestDatabase(db);

    await capturer(
      tester,
      nom: 's2-exercice',
      taille: const Size(360, 640),
      enveloppe: false,
      ecran: RelioApp(database: db, showIntro: false),
      apresMontage: (WidgetTester tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text(RelioTab.learn.label).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(RelioStrings.chapter1CardTitle));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(LessonCard).first);
        await tester.pumpAndSettle();
        expect(find.text(RelioStrings.askRelio), findsOneWidget);
      },
    );
  });

  testWidgets('tuteur ouvert, 360 x 640', (tester) async {
    await capturer(
      tester,
      nom: 'tuteur',
      taille: const Size(360, 640),
      ecran: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: RelioPalette.standard().homeBackground,
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRelioTutorSheet(
                  context,
                  client: const UnavailableTutorClient(),
                  exercise: const TutorExerciseContext(
                    statement: '',
                    expectedAnswer: '',
                  ),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          );
        },
      ),
      apresMontage: (WidgetTester tester) async {
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();
        expect(find.byType(RelioTutorSheet), findsOneWidget);
      },
    );
  });
}
