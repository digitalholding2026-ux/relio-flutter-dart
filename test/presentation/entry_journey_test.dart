/// Parcours RÉEL, de la première ouverture à l'accueil.
///
/// C'est le test que la mission réclame : pas « chaque écran s'affiche », mais
/// **l'enchaînement complet**, avec les cinq questions répondues et l'arrivée
/// à l'accueil.
///
/// Les animations sont RÉDUITES ici, délibérément. Ce test vérifie la
/// navigation et la persistance ; la question « le contenu est-il visible ? »
/// est traitée par `onboarding_visibility_test.dart`, qui joue avec les
/// animations activées. Mélanger les deux rendrait les deux tests fragiles :
/// ici, une attente fixe est une hypothèse ; là, l'opacité est une mesure.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/screens/app_shell.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

/// Résumé de ce qui est visible, pour un échec exploitable.
String _resume(WidgetTester tester) {
  final Iterable<String> textes = tester
      .widgetList<Text>(find.byType(Text))
      .map((Text t) => t.data)
      .whereType<String>()
      .where((String s) => s.isNotEmpty);
  return textes.take(8).join(' | ');
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    settings = SettingsRepository(db);
  });

  /// Monte l'application avec les animations réduites et la taille de
  /// référence (360 x 640).
  Future<void> monter(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final SettingsController controller = SettingsController(settings);
    await controller.load();
    await controller.apply(
      controller.settings.copyWith(reduceAnimations: true),
    );

    await tester.pumpWidget(
      RelioApp(database: db, settingsController: controller),
    );
    await tester.pump();
  }

  /// Laisse les lectures asynchrones se propager.
  Future<void> laisserResoudre(WidgetTester tester) async {
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Avance jusqu'à l'étape attendue, ou échoue en nommant l'étape atteinte.
  Future<void> attendre(WidgetTester tester, String etape) async {
    for (int i = 0; i < 40; i++) {
      if (find.text(etape).evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('jamais atteint : « $etape ». Contenu affiché : ${_resume(tester)}');
  }

  /// Répond à la question courante : saisie numérique, ou choix.
  Future<void> repondre(
    WidgetTester tester, {
    String? numerique,
    String? choix,
  }) async {
    if (choix != null) {
      await tester.tap(find.text(choix));
      await tester.pump();
    } else {
      await tester.enterText(find.byType(TextField), numerique!);
      await tester.pump();
    }
    await tester.tap(find.text(RelioStrings.entryContinue));
    await tester.pump();
    await laisserResoudre(tester);
  }

  testWidgets('A → G : première ouverture jusqu\'à l\'accueil',
      (WidgetTester tester) async {
    // A — première ouverture, aucun prénom.
    await monter(tester);

    // D — de l'ouverture à l'écran de présentation.
    await attendre(tester, RelioStrings.welcomeTitle);
    await tester.tap(find.text(RelioStrings.welcomeStart));
    await tester.pump();
    await laisserResoudre(tester);

    // E — l'explication du test.
    await attendre(tester, RelioStrings.entryIntroTitle);
    await tester.tap(find.text(RelioStrings.entryIntroStart));
    await tester.pump();
    await laisserResoudre(tester);

    // F — saisie du prénom.
    await attendre(tester, RelioStrings.nameTitle);
    await tester.enterText(find.byType(TextField), 'awa');
    await tester.pump();
    await tester.tap(find.text(RelioStrings.nameContinue));
    await tester.pump();
    await laisserResoudre(tester);

    // F — les cinq questions, dans l'ordre validé.
    await attendre(tester, '1 sur 5');
    await repondre(tester, numerique: '7');

    await attendre(tester, '2 sur 5');
    await repondre(tester, choix: '2/4');

    await attendre(tester, '3 sur 5');
    await repondre(tester, numerique: '2');

    await attendre(tester, '4 sur 5');
    await repondre(tester, numerique: '7');

    await attendre(tester, '5 sur 5');
    await repondre(tester, numerique: '5');

    // G — la clôture, puis l'accueil.
    await attendre(tester, RelioStrings.closingDiscover);
    expect(
      find.textContaining('Merci Awa'),
      findsOneWidget,
      reason: 'le prénom est capitalisé et repris dans la phrase',
    );

    await tester.tap(find.text(RelioStrings.closingDiscover));
    await tester.pump();
    await laisserResoudre(tester);

    expect(find.byType(AppShell), findsOneWidget,
        reason: 'l\'accueil doit être atteint');
    expect(await settings.hasCompletedFirstLaunch(), isTrue);

    // Le prénom a bien été enregistré, et il est revenu à la bonne forme.
    expect((await settings.load()).name, 'Awa');
  });

  testWidgets('C — onboarding terminé : l\'accueil s\'ouvre directement',
      (WidgetTester tester) async {
    await settings.markEntryScreenSeen();
    await settings.markFirstLaunchCompleted();

    await monter(tester);
    await laisserResoudre(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text(RelioStrings.welcomeTitle), findsNothing);
    expect(find.text(RelioStrings.nameTitle), findsNothing);
  });

  testWidgets('B — prénom connu, parcours inachevé : le test reprend',
      (WidgetTester tester) async {
    await settings.setName('Awa');
    await settings.markEntryScreenSeen();

    await monter(tester);
    await laisserResoudre(tester);

    // Le parcours NE redemande pas le prénom, et ne rejoue pas l'ouverture.
    expect(find.text(RelioStrings.nameTitle), findsNothing);
    expect(find.text(RelioStrings.entryIntroTitle), findsNothing);
    expect(find.text('1 sur 5'), findsOneWidget);
  });

  testWidgets('H — abandon au milieu : le parcours reprend où il s\'est arrêté',
      (WidgetTester tester) async {
    await monter(tester);
    await attendre(tester, RelioStrings.welcomeTitle);
    await tester.tap(find.text(RelioStrings.welcomeStart));
    await tester.pump();
    await laisserResoudre(tester);
    await attendre(tester, RelioStrings.entryIntroTitle);
    await tester.tap(find.text(RelioStrings.entryIntroStart));
    await tester.pump();
    await laisserResoudre(tester);
    await attendre(tester, RelioStrings.nameTitle);
    await tester.enterText(find.byType(TextField), 'awa');
    await tester.pump();
    await tester.tap(find.text(RelioStrings.nameContinue));
    await tester.pump();
    await laisserResoudre(tester);
    await attendre(tester, '1 sur 5');
    await repondre(tester, numerique: '7');
    await attendre(tester, '2 sur 5');
    await repondre(tester, choix: '2/4');

    // L'application est fermée et rouverte : deux réponses ont été saisies.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await monter(tester);
    await laisserResoudre(tester);

    expect(find.text('3 sur 5'), findsOneWidget,
        reason: 'la troisième question est la suivante, pas la première');
    expect(find.text('1 sur 5'), findsNothing);
    expect(find.text('2 sur 5'), findsNothing);
  });
}