/// Reprise d'une leçon et enchaînement DANS la leçon.
///
/// Ces tests partent d'un historique réel : les exercices sont réussis par le
/// service, puis l'application est ouverte sur la même base. Ils vérifient le
/// comportement visible de S1 et de « Exercice suivant », pas une convention
/// interne aux écrans.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

/// Réussit les exercices fournis, avec leur réponse attendue.
Future<void> _seed(AppDatabase db, List<Exercise> exercises) async {
  final service = Chapter1Service(LearningEventRepository(db));
  for (final exercise in exercises) {
    final answer = exercise.correction.acceptedValues.first.toString();
    await service.recordAttempt(exercise: exercise, rawAnswer: answer);
  }
}

List<Exercise> _lesson1Exercises({int count = 4}) {
  return Chapter1Bank.exercises
      .where(
        (exercise) => exercise.lesson == ArithmeticLesson.lesson1Subtractions,
      )
      .take(count)
      .toList();
}

Future<void> _openLesson1(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(RelioApp(database: db, showIntro: false));
  await tester.pumpAndSettle();

  await tester.tap(find.text(RelioStrings.tabLearn).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(RelioStrings.chapter1CardTitle));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(LessonCard).at(0));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String answer) async {
  await tester.enterText(find.byType(TextField).first, answer);
  await tester.pump();
  await tester.tap(find.text(RelioStrings.validate));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('après un exercice réussi, la leçon reprend au suivant', (
    tester,
  ) async {
    final db = await openTestDatabase();
    registerTestDatabase(db);
    final exercises = _lesson1Exercises();
    await _seed(db, <Exercise>[exercises.first]);

    await _openLesson1(tester, db);

    expect(find.text(exercises[1].statement), findsOneWidget);
    expect(find.text(exercises.first.statement), findsNothing);
  });

  testWidgets(
    '« Exercice suivant » reste dans la leçon ; le dernier ramène à S1',
    (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final exercises = _lesson1Exercises();
      // Les trois premiers sont réussis : la leçon reprend au quatrième.
      await _seed(db, exercises.take(3).toList());

      await _openLesson1(tester, db);
      expect(find.text(exercises[3].statement), findsOneWidget);

      await _submit(tester, '4');
      expect(find.text(RelioStrings.nextExercise), findsOneWidget);

      await tester.tap(find.text(RelioStrings.nextExercise));
      await tester.pumpAndSettle();

      // Dernier exercice de la leçon : S1, pas l'exercice 5 de la leçon 2.
      expect(find.byType(ChapterAccessPage), findsOneWidget);
      expect(find.byType(ExercisePage), findsNothing);
      expect(
        find.text(Chapter1Bank.findExercise(ExerciseIds.ex5)!.statement),
        findsNothing,
      );
    },
  );

  testWidgets('une leçon maîtrisée se rouvre en révision', (tester) async {
    final db = await openTestDatabase();
    registerTestDatabase(db);
    final exercises = _lesson1Exercises();
    await _seed(db, exercises);

    await _openLesson1(tester, db);

    expect(find.text(exercises.first.statement), findsOneWidget);
    expect(find.text(RelioStrings.revision), findsOneWidget);
  });
}
