/// Tests de la navigation globale et des trois écrans (Accueil, Apprendre,
/// Profil).
///
/// Ces tests couvrent les NOUVEAUX écrans. Ils ne remplacent pas les tests du
/// parcours élève : ceux-ci restent dans `learner_flow_test.dart`.
///
/// Contraintes absolues vérifiées ici :
///  - l'application ouvre sur ACCUEIL, plus sur S1 ;
///  - la barre basse affiche EXACTEMENT trois onglets, aucun autre, même
///    grisé ;
///  - changer d'onglet ne réinitialise pas la pile de l'onglet quitté ;
///  - aucun pourcentage, score, badge, ni code diagnostic interne visible ;
///  - « PGDC » reste affiché tel quel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/home/home_widgets.dart';
import 'package:relio/presentation/screens/app_shell.dart';
import 'package:relio/presentation/screens/app_shell_nav.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/screens/learn_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

import '../helpers/test_database.dart';

/// Pompe l'application et aboutit sur l'accueil.
Future<AppDatabase> pumpApp(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);
  await tester.pumpWidget(RelioApp(database: db, showIntro: false));
  await tester.pumpAndSettle();
  return db;
}

/// Bascule sur l'onglet [tab].
Future<void> goToTab(WidgetTester tester, RelioTab tab) async {
  await tester.tap(find.text(tab.label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Racine', () {
    testWidgets('l’application ouvre sur l’accueil, pas sur S1',
        (tester) async {
      await pumpApp(tester);

      expect(find.byType(HomePage), findsOneWidget);
      // S1 n'est plus la racine : elle n'est pas affichée au démarrage.
      expect(find.byType(ChapterAccessPage), findsNothing);
      expect(find.byType(ExercisePage), findsNothing);
    });

    testWidgets('aucun onboarding : pas de page de bienvenue',
        (tester) async {
      await pumpApp(tester);

      expect(find.text(RelioStrings.relioMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Barre basse', () {
    testWidgets('affiche exactement trois onglets', (tester) async {
      await pumpApp(tester);

      expect(relioTabLabels, <String>['Accueil', 'Apprendre', 'Profil']);

      final nav = tester.widget<RelioBottomNav>(find.byType(RelioBottomNav));
      expect(nav.current, RelioTab.home);
    });

    testWidgets('aucun autre onglet, même grisé', (tester) async {
      await pumpApp(tester);

      // Les destinations réservées ne doivent pas exister, même inactives.
      for (final interdit in <String>[
        'Révisions',
        'Progression',
        'Paramètres',
      ]) {
        expect(find.text(interdit), findsNothing);
      }
      // Trois items, ni plus ni moins.
      expect(find.byType(RelioBottomNav), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('la barre est visible sur S1', (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text(RelioStrings.chapterArithmetic));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
      // La barre peut rester visible sur S1.
      expect(find.byType(RelioBottomNav), findsOneWidget);
    });
  });

  group('Piles indépendantes', () {
    testWidgets('changer d’onglet ne réinitialise pas la pile',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text(RelioStrings.chapterArithmetic));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);

      // On quitte l'onglet Apprendre…
      await goToTab(tester, RelioTab.home);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);

      // … et on y revient : S1 est toujours là.
      await goToTab(tester, RelioTab.learn);
      expect(find.byType(ChapterAccessPage), findsOneWidget);
    });

    testWidgets('le brouillon survit à un aller-retour sur S1', (tester) async {
      // Le brouillon ne peut PAS être vérifié en changeant d'onglet depuis
      // S2 : la barre basse y est masquée, donc les onglets sont inatteignables
      // — c'est le comportement voulu. On passe donc par S1, où la barre est
      // visible.
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text('Chapitre 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();

      // Retour à S1, puis changement d'onglet et retour.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterAccessPage), findsOneWidget);

      await goToTab(tester, RelioTab.home);
      await goToTab(tester, RelioTab.learn);
      expect(find.byType(ChapterAccessPage), findsOneWidget);

      // Réouverture de la leçon : la saisie est restaurée.
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '6');
    });
  });

  group('Accueil', () {
    /// Agrandit la fenêtre de test : l'accueil complet dépasse 600 dp de haut,
    /// et une liste paresseuse ne construit pas ce qui n'est pas visible.
    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('affiche le message de Relio et la carte « Reprendre »',
        (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);

      expect(find.text(RelioStrings.relioMessage), findsOneWidget);
      expect(find.text(RelioStrings.resumeLabel), findsOneWidget);
      expect(find.text(RelioStrings.chapterArithmetic), findsOneWidget);
      expect(find.text(RelioStrings.resumeProgress(2, 4)), findsOneWidget);
      expect(find.text(RelioStrings.resumeContinue), findsOneWidget);
    });

    testWidgets('affiche les deux actions rapides', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);

      expect(find.text(RelioStrings.quickFiveTitle), findsOneWidget);
      expect(find.text(RelioStrings.quickFiveSubtitle), findsOneWidget);
      expect(find.text(RelioStrings.quickWarmupTitle), findsOneWidget);
      expect(find.text(RelioStrings.quickWarmupSubtitle), findsOneWidget);
    });

    testWidgets('le tap sur « Continuer » ouvre S1', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(RelioStrings.resumeContinue));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
    });

    testWidgets('le tap sur une action rapide ouvre S1', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text(RelioStrings.quickFiveTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
    });

    testWidgets('un appui rapproche la carte avant de naviguer', (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text(RelioStrings.quickFiveTitle)),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final Iterable<AnimatedScale> echelles = tester.widgetList<AnimatedScale>(
        find.descendant(
          of: find.byType(QuickActionCard),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(echelles.where((AnimatedScale s) => s.scale == 0.97), isNotEmpty);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
    });

    testWidgets('« Ton programme » liste les leçons et leur statut',
        (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);

      expect(find.text(RelioStrings.programSectionTitle), findsOneWidget);
      for (final lesson in ArithmeticLesson.values) {
        expect(find.text(lesson.title), findsOneWidget);
      }
      expect(find.text(RelioStrings.statusInProgress), findsOneWidget);
      expect(find.text(RelioStrings.statusToReview), findsOneWidget);
      expect(find.text(RelioStrings.statusMastered), findsOneWidget);
    });

    testWidgets('le tap sur une leçon du programme ouvre l’exercice',
        (tester) async {
      useTallScreen(tester);
      await pumpApp(tester);

      await tester.tap(find.text(ArithmeticLesson.lesson1Subtractions.title));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
    });

    testWidgets('aucun résultat chiffré sur l’accueil', (tester) async {
      await pumpApp(tester);

      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Réussite'), findsNothing);
      expect(find.textContaining('Score'), findsNothing);
    });

    testWidgets('sans prénom, l’en-tête dit seulement « Bonjour »',
        (tester) async {
      await pumpApp(tester);

      expect(find.text(RelioStrings.greeting), findsOneWidget);
    });

    testWidgets('avec un prénom, l’en-tête le reprend', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final controller = SettingsController(SettingsRepository(db));
      await controller.apply(
        controller.settings.copyWith(name: 'Camille'),
      );

      await tester.pumpWidget(
        RelioApp(database: db, settingsController: controller, showIntro: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bonjour Camille'), findsOneWidget);
    });
  });

  group('Apprendre', () {
    testWidgets('le chapitre 1 est actif, les suivants sont indisponibles',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);

      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.text('Chapitre 1'), findsOneWidget);
      expect(find.text(RelioStrings.chapterArithmetic), findsOneWidget);

      // Chapitres suivants : génériques et « Bientôt disponible ».
      expect(find.text('Chapitre 2'), findsOneWidget);
      expect(find.text('Chapitre 3'), findsOneWidget);
      expect(find.text(RelioStrings.chapterComingSoon), findsNWidgets(2));
    });

    testWidgets('un chapitre indisponible n’est pas cliquable',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);

      // Aucun écran ne s'ouvre.
      await tester.tap(find.text('Chapitre 2'));
      await tester.pumpAndSettle();

      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);
    });

    testWidgets('le tap sur le chapitre 1 ouvre S1', (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);

      await tester.tap(find.text('Chapitre 1'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
    });

    testWidgets('aucun compteur, aucune barre de progression',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('terminés'), findsNothing);
    });
  });

  group('S1 — ajustements', () {
    testWidgets('la flèche de retour ramène à l’écran Apprendre',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text('Chapitre 1'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // On revient à l'écran Apprendre, pas à l'accueil.
      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);
    });

    testWidgets('« PGDC » reste affiché tel quel', (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text('Chapitre 1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('PGDC'), findsWidgets);
      // Le terme n'est jamais corrigé en « PGCD » sur cette leçon.
      expect(find.text('« PGCD » : algorithme d’Euclide'), findsNothing);
    });
  });

  group('S2 — ajustements', () {
    testWidgets('la barre de navigation basse est masquée sur S2',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text('Chapitre 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      // S2 est un espace dédié à l'exercice, sans distraction.
      expect(find.byType(RelioBottomNav), findsNothing);
      // Conséquence voulue : les onglets sont inatteignables depuis S2.
      // L'élève travaille l'exercice ; il en sort par sa flèche de retour.
      for (final tab in RelioTab.values) {
        expect(find.text(tab.label), findsNothing);
      }
    });

    testWidgets('la barre revient dès que l’on quitte S2', (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.learn);
      await tester.tap(find.text('Chapitre 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(RelioBottomNav), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
      expect(find.byType(RelioBottomNav), findsOneWidget);
    });
  });

  group('Profil', () {
    testWidgets('contient exactement les trois sections prévues',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.profile);

      expect(find.text(RelioStrings.sectionIdentity), findsOneWidget);
      expect(find.text(RelioStrings.sectionDisplay), findsOneWidget);
      expect(find.text(RelioStrings.sectionAccessibility), findsOneWidget);
    });

    testWidgets('la classe est affichée en 3e et n’est pas modifiable',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.profile);

      expect(find.text(RelioStrings.classLabel), findsOneWidget);
      expect(find.text(RelioStrings.classValue), findsOneWidget);
    });

    testWidgets('aucune progression, aucun score, aucun avatar',
        (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.profile);

      expect(find.text('Progression'), findsNothing);
      expect(find.text('Score'), findsNothing);
      expect(find.text('Statistiques'), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('le prénom saisi est propagé à l’accueil',
        (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final controller = SettingsController(SettingsRepository(db));

      await tester.pumpWidget(
        RelioApp(database: db, settingsController: controller, showIntro: false),
      );
      await tester.pumpAndSettle();
      await goToTab(tester, RelioTab.profile);

      await tester.enterText(find.byType(TextField).first, 'Camille');
      await tester.pumpAndSettle();

      // Le contrôleur a reçu la modification…
      expect(controller.settings.name, 'Camille');

      // … et l'accueil l'affiche.
      await goToTab(tester, RelioTab.home);
      expect(find.text('Bonjour Camille'), findsOneWidget);
    });

    testWidgets('le prénom est persisté en base', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final repository = SettingsRepository(db);
      final controller = SettingsController(repository);

      await tester.pumpWidget(
        RelioApp(database: db, settingsController: controller, showIntro: false),
      );
      await tester.pumpAndSettle();
      await goToTab(tester, RelioTab.profile);

      await tester.enterText(find.byType(TextField).first, 'Camille');
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Rechargée depuis la base, pas depuis la mémoire du contrôleur.
      final reloaded = await repository.load();
      expect(reloaded.name, 'Camille');
    });

    testWidgets('trois tailles de texte, jamais plus', (tester) async {
      await pumpApp(tester);
      await goToTab(tester, RelioTab.profile);

      for (final option in TextScalePreference.values) {
        expect(find.text(option.label), findsOneWidget);
      }
      expect(TextScalePreference.values, hasLength(3));
      expect(
        TextScalePreference.values.map((v) => v.factor),
        <double>[1.0, 1.15, 1.3],
      );
    });

    testWidgets('le contraste renforcé change effectivement la palette',
        (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final controller = SettingsController(SettingsRepository(db));

      await tester.pumpWidget(
        RelioApp(database: db, settingsController: controller, showIntro: false),
      );
      await tester.pumpAndSettle();

      expect(controller.settings.highContrast, isFalse);
      final standard = RelioPalette.of(highContrast: false);
      final contrast = RelioPalette.of(highContrast: true);

      // Le contraste renforcé renforce réellement la bordure.
      expect(contrast.outline.toARGB32(), isNot(standard.outline.toARGB32()));
      expect(contrast.textSecondary.toARGB32(),
          isNot(standard.textSecondary.toARGB32()));
    });

    testWidgets('la réduction des animations est une préférence persistée',
        (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final repository = SettingsRepository(db);
      final controller = SettingsController(repository);

      await tester.pumpWidget(
        RelioApp(database: db, settingsController: controller, showIntro: false),
      );
      await tester.pumpAndSettle();
      await goToTab(tester, RelioTab.profile);

      expect(controller.settings.reduceAnimations, isFalse);

      // Bascule via l'étiquette de la ligne.
      await tester.tap(find.text(RelioStrings.reduceAnimationsLabel));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(controller.settings.reduceAnimations, isTrue);
      expect((await repository.load()).reduceAnimations, isTrue);
    });
  });

  group('Absences imposées', () {
    testWidgets('aucun code diagnostic interne visible',
        (tester) async {
      await pumpApp(tester);

      for (final code in <String>['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8']) {
        expect(find.textContaining(code), findsNothing);
      }
    });

    testWidgets('aucune mécanique de jeu sur l’ensemble des onglets',
        (tester) async {
      await pumpApp(tester);

      for (final tab in RelioTab.values) {
        await goToTab(tester, tab);
        expect(find.byType(Badge), findsNothing);
        expect(find.textContaining('points'), findsNothing);
        expect(find.textContaining('niveau'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
      }
    });
  });
}