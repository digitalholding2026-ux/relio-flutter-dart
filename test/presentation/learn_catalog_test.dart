/// Tests de l'onglet « Apprendre » — catalogue de progression et vue des
/// leçons du chapitre 1.
///
/// Ce que ces tests vérifient :
///  - le catalogue affiche le programme et sa progression factice ;
///  - un chapitre indisponible reste inerte ;
///  - la vue des leçons montre les trois états et les décomptes ;
///  - une leçon ouvre S2, et le retour ramène au catalogue ;
///  - la recherche annonce qu'elle n'est pas encore disponible ;
///  - toutes les cartes actives ont l'effet d'appui demandé (0,97).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter2_bank.dart';
import 'package:relio/presentation/home/pressable_scale.dart';
import 'package:relio/presentation/screens/app_shell_nav.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/screens/learn_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/widgets/relio_progress_bar.dart';

import '../helpers/test_database.dart';

/// Ouvre l'application sur un écran assez haut pour tout le parcours.
Future<AppDatabase> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = await openTestDatabase();
  registerTestDatabase(db);
  await tester.pumpWidget(RelioApp(database: db, showIntro: false));
  await tester.pumpAndSettle();
  return db;
}

/// Bascule sur l'onglet Apprendre.
Future<void> openLearnTab(WidgetTester tester) async {
  await tester.tap(find.text(RelioTab.learn.label).last);
  await tester.pumpAndSettle();
}

/// Ouvre le chapitre 1 depuis le catalogue.
Future<void> openChapter(WidgetTester tester) async {
  await openLearnTab(tester);
  await tester.tap(find.text(RelioStrings.chapter1CardTitle));
  await tester.pumpAndSettle();
}

void main() {
  group('Catalogue — chapitre 1', () {
    testWidgets('affiche le titre de l’écran et la loupe', (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);

      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.text(RelioStrings.learnTitle), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    test('le titre de carte est littéral, jamais une closure interpolée', () {
      expect(RelioStrings.chapter1CardTitle, 'Chapitre 1 : Arithmétique');
    });

    testWidgets('la carte du chapitre 1 porte titre, avancement et barre',
        (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);

      expect(find.text(RelioStrings.chapter1CardTitle), findsOneWidget);
      expect(
        find.text(RelioStrings.chapterLessonsValidated(0, 3)),
        findsOneWidget,
      );

      // Une barre par chapitre ouvert : chapitres 1 et 2. Le chapitre 3
      // n'a aucun avancement à montrer.
      expect(find.byType(RelioProgressBar), findsNWidgets(2));
      final bar = tester.widget<RelioProgressBar>(
        find.byType(RelioProgressBar).first,
      );
      // Nouvel élève : aucune leçon validée, donc une barre vide.
      expect(bar.ratio, 0);
      expect(bar.color.toARGB32(), 0xFFF56207);
    });

    testWidgets('le chapitre 2 est ouvert, le chapitre 3 reste inerte',
        (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);

      expect(find.text(RelioStrings.chapter2CardTitle), findsOneWidget);
      expect(find.text('Chapitre 3'), findsOneWidget);
      expect(find.text(RelioStrings.chapterComingSoon), findsOneWidget);

      // Deux chevrons : les chapitres 1 et 2 sont ouvrables.
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

      await tester.tap(find.text('Chapitre 3'));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterAccessPage), findsNothing);
      expect(find.byType(LearnPage), findsOneWidget);
    });

    testWidgets('le chapitre 2 s’ouvre sur ses deux leçons', (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);

      await tester.tap(find.text(RelioStrings.chapter2CardTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);
      expect(find.text('Chapitre 2'), findsOneWidget);
      expect(find.text(RelioStrings.chapterThales), findsOneWidget);
      expect(find.byType(LessonCard), findsNWidgets(2));
      expect(
        find.text('Propriété directe (Calculer des longueurs)'),
        findsOneWidget,
      );
      expect(
        find.text('Propriété réciproque (Justifier le parallélisme)'),
        findsOneWidget,
      );
    });

    testWidgets('le chapitre 1 s’ouvre au tap et se referme par la flèche',
        (tester) async {
      await pumpApp(tester);
      await openChapter(tester);

      expect(find.byType(ChapterAccessPage), findsOneWidget);
      expect(find.byType(LearnPage), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(LearnPage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);
    });

    testWidgets('la loupe annonce que la recherche arrive', (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.text(RelioStrings.searchComingSoon), findsOneWidget);
    });

    testWidgets('les cartes actives ont l’effet d’appui 0,97',
        (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);

      final effects = tester.widgetList<PressableScale>(
        find.descendant(
          of: find.byType(ChapterCard),
          matching: find.byType(PressableScale),
        ),
      );
      // Deux cartes sont cliquables : chapitres 1 et 2 ; la troisième ne
      // l'est pas et n'a pas d'effet.
      expect(effects, hasLength(2));
      for (final effect in effects) {
        expect(effect.scale, 0.97);
      }
    });
  });

  group('Vue des leçons — chapitre 2', () {
    testWidgets('affiche les deux leçons et leurs décomptes', (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);
      await tester.tap(find.text(RelioStrings.chapter2CardTitle));
      await tester.pumpAndSettle();

      expect(find.byType(LessonCard), findsNWidgets(2));
      expect(find.text(RelioStrings.statusNotStarted), findsNWidgets(2));
      expect(
        find.text(RelioStrings.lessonExerciseProgress(0, 1)),
        findsNWidgets(2),
      );
      expect(find.byType(RelioProgressBar), findsNWidgets(2));
    });

    testWidgets('une leçon du chapitre 2 ouvre son exercice', (tester) async {
      await pumpApp(tester);
      await openLearnTab(tester);
      await tester.tap(find.text(RelioStrings.chapter2CardTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LessonCard).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      final page = tester.widget<ExercisePage>(find.byType(ExercisePage));
      expect(page.exercise.id, Chapter2ExerciseIds.ex2);
    });
  });

  group('Vue des leçons — chapitre 1', () {
    testWidgets('affiche les trois leçons et leurs états', (tester) async {
      await pumpApp(tester);
      await openChapter(tester);

      expect(find.byType(LessonCard), findsNWidgets(3));
      // Aucun fait : les trois leçons sont « À commencer », aucune n'est
      // présentée comme entamée ou maîtrisée.
      expect(find.text(RelioStrings.statusNotStarted), findsNWidgets(3));
      expect(find.text(RelioStrings.statusInProgress), findsNothing);
      expect(find.text(RelioStrings.statusToReview), findsNothing);
      expect(find.text(RelioStrings.statusMastered), findsNothing);

      // Une barre par leçon.
      expect(find.byType(RelioProgressBar), findsNWidgets(3));
    });

    testWidgets('affiche les décomptes d’exercices', (tester) async {
      await pumpApp(tester);
      await openChapter(tester);

      // Les totaux viennent de la banque validée : 4, 3 et 4 exercices.
      // Aucun n'est terminé : les décomptes partent de zéro.
      expect(find.text(RelioStrings.lessonExerciseProgress(0, 4)), findsNWidgets(2));
      expect(find.text(RelioStrings.lessonExerciseProgress(0, 3)), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('une leçon ouvre S2 sur son premier exercice', (tester) async {
      await pumpApp(tester);
      await openChapter(tester);

      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);
    });

    testWidgets('les cartes de leçon ont l’effet d’appui 0,97',
        (tester) async {
      await pumpApp(tester);
      await openChapter(tester);

      final effects = tester.widgetList<PressableScale>(
        find.descendant(
          of: find.byType(LessonCard),
          matching: find.byType(PressableScale),
        ),
      );
      expect(effects, hasLength(3));
      for (final effect in effects) {
        expect(effect.scale, 0.97);
      }
    });

    testWidgets('aucun débordement à 360 x 640 avec un texte agrandi',
        (tester) async {
      // Petit écran et échelle 1,3 : le pire cas lisible sur téléphone.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final db = await openTestDatabase();
      registerTestDatabase(db);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: RelioApp(database: db, showIntro: false),
        ),
      );
      await tester.pumpAndSettle();

      await openLearnTab(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(RelioStrings.chapter1CardTitle));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

