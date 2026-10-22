/// Tests des séances courtes de l'accueil : échauffement et « J'ai 5 minutes ».
///
/// La pioche est vérifiée séparément, sur un vivier fixe : les tests
/// d'interface ne dépendent donc jamais du hasard. Ils portent sur ce que
/// l'élève voit et sur la navigation, pas sur le contenu pédagogique.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/learning/quick_practice.dart';
import 'package:relio/presentation/rules/v1_screen_rules.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/screens/quick_session_end_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/widgets/relio_progress_bar.dart';

import '../helpers/test_database.dart';

/// Trois exercices numériques de la banque : la file est donc entièrement
/// répondable par un test, sans jamais dépendre du tirage aléatoire.
final List<Exercise> _troisExercices = <Exercise>[
  Chapter1Bank.findExercise(ExerciseIds.ex1)!,
  Chapter1Bank.findExercise(ExerciseIds.ex2)!,
  Chapter1Bank.findExercise(ExerciseIds.ex3)!,
];

/// Progression où la leçon 1 est « en cours » et les autres non commencées.
LearnerProgress _lecon1EnCours() => const LearnerProgress(
  startedLessonIds: <String>{'lecon-1'},
  lessonExerciseTotals: <String, int>{
    'lecon-1': 4,
    'lecon-2': 4,
    'lecon-3': 3,
  },
);

/// Pompe l'application avec une pioche déterministe.
Future<void> _pumpAccueil(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);

  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    RelioApp(
      database: db,
      showIntro: false,
      quickPracticePicker: QuickPracticePicker(
        random: Random(7),
        catalogue: _troisExercices,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Exercice dont l'énoncé est affiché.
Exercise _exerciceAffiche(WidgetTester tester) {
  return V1ScreenRules.exercises.firstWhere(
    (exercise) => find.text(exercise.statement).evaluate().isNotEmpty,
    orElse: () => throw StateError('Aucun énoncé de la banque à l’écran.'),
  );
}

/// Répond juste à l'exercice affiché, puis valide.
Future<void> _repondreJuste(WidgetTester tester) async {
  final exercise = _exerciceAffiche(tester);
  final answer = exercise.correction.acceptedValues.first.toString();

  await tester.enterText(find.byType(TextField), answer);
  await tester.pump();
  await tester.tap(find.text(RelioStrings.validate));
  await tester.pumpAndSettle();
}

/// Tape un bouton du panneau, après l'avoir amené dans la zone visible.
Future<void> _taperPanneau(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  group('Pioche des séances courtes', () {
    test('l’échauffement tire un seul exercice de la leçon en cours', () {
      final picker = QuickPracticePicker(random: Random(1));

      final session = picker.warmup(_lecon1EnCours());

      expect(session.length, 1);
      expect(session.position, 1);
      expect(session.hasNext, isFalse);
      expect(session.current.lesson.id, 'lecon-1');
    });

    test('« J’ai 5 minutes » prépare trois exercices distincts', () {
      final picker = QuickPracticePicker(random: Random(3));

      final session = picker.fiveMinutes(_lecon1EnCours());

      expect(session.length, 3);
      expect(
        session.exercises.map((e) => e.id).toSet(),
        hasLength(3),
      );
      for (final exercise in session.exercises) {
        expect(exercise.lesson.id, 'lecon-1');
      }
    });

    test('sans leçon commencée, le chapitre entier sert de vivier', () {
      final picker = QuickPracticePicker(random: Random(5));

      final session = picker.fiveMinutes(LearnerProgress.empty);

      expect(session.length, 3);
      expect(
        session.exercises.every(
          (e) => e.kind == BankElementKind.exercise,
        ),
        isTrue,
      );
    });

    test('la file avance d’un cran sans dépasser la fin', () {
      final session = QuickPracticePicker(
        random: Random(2),
        catalogue: _troisExercices,
      ).fiveMinutes(LearnerProgress.empty);

      final second = session.next();
      expect(second.position, 2);
      expect(second.ratio, closeTo(2 / 3, 1e-9));
      expect(second.current.id, isNot(session.current.id));

      final third = second.next();
      expect(third.position, 3);
      expect(third.hasNext, isFalse);
      // Après le dernier, la file ne bouge plus.
      expect(third.next().position, 3);
    });
  });

  group('Échauffement', () {
    testWidgets('ouvre S2 en mode échauffement, puis revient à l’accueil',
        (tester) async {
      await _pumpAccueil(tester);

      await tester.tap(find.text(RelioStrings.quickWarmupTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);
      expect(find.text(RelioStrings.quickWarmupScreenTitle), findsOneWidget);

      // La flèche de retour ramène à l'accueil, pas à S1.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(ExercisePage), findsNothing);
      expect(find.byType(ChapterAccessPage), findsNothing);
    });

    testWidgets('après validation, le panneau propose le retour à l’accueil',
        (tester) async {
      await _pumpAccueil(tester);

      await tester.tap(find.text(RelioStrings.quickWarmupTitle));
      await tester.pumpAndSettle();
      await _repondreJuste(tester);

      expect(find.text(RelioStrings.successTitle), findsOneWidget);
      expect(find.text(RelioStrings.quickBackHome), findsOneWidget);

      await _taperPanneau(tester, RelioStrings.quickBackHome);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(ExercisePage), findsNothing);
    });
  });

  group('« J’ai 5 minutes »', () {
    testWidgets('affiche la position dans la session et sa barre',
        (tester) async {
      await _pumpAccueil(tester);

      await tester.tap(find.text(RelioStrings.quickFiveTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      expect(find.text(RelioStrings.quickSessionProgress(1, 3)), findsOneWidget);
      expect(find.text(RelioStrings.quickSessionTitle), findsOneWidget);

      final bar = tester.widget<RelioProgressBar>(
        find.byType(RelioProgressBar),
      );
      expect(bar.ratio, closeTo(1 / 3, 1e-9));
    });

    testWidgets('enchaîne les trois exercices puis affiche la fin de session',
        (tester) async {
      await _pumpAccueil(tester);

      await tester.tap(find.text(RelioStrings.quickFiveTitle));
      await tester.pumpAndSettle();

      // Question 1 → 2.
      await _repondreJuste(tester);
      await _taperPanneau(tester, RelioStrings.quickSessionNext);

      expect(find.text(RelioStrings.quickSessionProgress(2, 3)), findsOneWidget);
      expect(
        tester.widget<RelioProgressBar>(find.byType(RelioProgressBar)).ratio,
        closeTo(2 / 3, 1e-9),
      );

      // Question 2 → 3.
      await _repondreJuste(tester);
      await _taperPanneau(tester, RelioStrings.quickSessionNext);

      expect(find.text(RelioStrings.quickSessionProgress(3, 3)), findsOneWidget);
      expect(
        tester.widget<RelioProgressBar>(find.byType(RelioProgressBar)).ratio,
        closeTo(1, 1e-9),
      );

      // Question 3 : la session se termine.
      await _repondreJuste(tester);
      await _taperPanneau(tester, RelioStrings.quickSessionFinish);

      expect(find.byType(QuickSessionEndPage), findsOneWidget);
      expect(find.text(RelioStrings.quickSessionEndTitle), findsOneWidget);
      expect(find.text(RelioStrings.quickSessionEndMessage), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);

      await tester.tap(find.text(RelioStrings.quickBackHome));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(QuickSessionEndPage), findsNothing);
    });
  });
}
