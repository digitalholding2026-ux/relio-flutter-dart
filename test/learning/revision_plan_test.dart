/// Tests du plan de révision.
///
/// Les faiblesses ne sont pas une opinion : elles viennent d'erreurs
/// réellement observées sur des tentatives corrigées comme fausses, dans une
/// séquence ANTÉRIEURE à celle du jour.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/learning/learning_event.dart';
import 'package:relio/domain/learning/observed_error.dart';
import 'package:relio/domain/learning/revision_plan.dart';

/// Date de référence : octobre 2026 → séquence 2.
final DateTime _october = DateTime(2026, 10, 22);

LearningEvent _attempt({
  required String id,
  required String lessonId,
  required AnswerOutcome outcome,
  bool withError = true,
  String type = kLearnerAttemptEventType,
}) {
  final DateTime at = DateTime(2026, 9, 15);
  return LearningEvent(
    id: id,
    type: type,
    occurredAt: at,
    metadata: <String, Object?>{'lessonId': lessonId},
    attempt: ExerciseAttempt(
      exerciseId: 'ex-$id',
      startedAt: at,
      outcome: outcome,
      error: withError
          ? ObservedError(id: 'err-$id', occurredAt: at, errorType: 'test')
          : null,
    ),
  );
}

List<Exercise> _exercisesOf(ArithmeticLesson lesson) {
  return Chapter1Bank.exercises
      .where(
        (exercise) =>
            exercise.kind == BankElementKind.exercise &&
            exercise.lesson == lesson,
      )
      .toList();
}

void main() {
  const RevisionPlanBuilder builder = RevisionPlanBuilder();

  group('faiblesses', () {
    test('une erreur d’une séquence antérieure devient une faiblesse', () {
      final plan = builder.build(
        date: _october,
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.incorrect,
          ),
          _attempt(
            id: 'b',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.incorrect,
          ),
          _attempt(
            id: 'c',
            lessonId: ArithmeticLesson.lesson2Euclid.id,
            outcome: AnswerOutcome.incorrect,
          ),
        ],
      );

      expect(plan.sequence.number, 2);
      expect(plan.weaknesses, hasLength(2));
      expect(plan.weaknesses.first.lesson, ArithmeticLesson.lesson1Subtractions);
      expect(plan.weaknesses.first.errorCount, 2);
      expect(plan.weakExercises, isNotEmpty);
    });

    test('une réponse juste n’est jamais une faiblesse', () {
      final plan = builder.build(
        date: _october,
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.correct,
          ),
        ],
      );

      expect(plan.weaknesses, isEmpty);
    });

    test('une tentative non évaluée n’est pas une erreur', () {
      final plan = builder.build(
        date: _october,
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.notEvaluated,
          ),
        ],
      );

      expect(plan.weaknesses, isEmpty);
    });

    test('une tentative sans erreur observée n’entre pas dans le compte', () {
      final plan = builder.build(
        date: _october,
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.incorrect,
            withError: false,
          ),
        ],
      );

      expect(plan.weaknesses, isEmpty);
    });

    test('une erreur de la séquence en cours reste dans le programme', () {
      // En septembre, la séquence 1 est celle du jour : une erreur sur
      // l'arithmétique ne peut pas être une « révision ».
      final plan = builder.build(
        date: DateTime(2026, 9, 10),
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.incorrect,
          ),
        ],
      );

      expect(plan.sequence.number, 1);
      expect(plan.weaknesses, isEmpty);
    });

    test('un autre type d’événement est ignoré', () {
      final plan = builder.build(
        date: _october,
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.incorrect,
            type: 'hint_requested',
          ),
        ],
      );

      expect(plan.weaknesses, isEmpty);
    });
  });

  group('exercices disponibles', () {
    test('les chapitres de la séquence 2 n’ont pas encore d’exercice', () {
      final plan = builder.build(date: _october, events: const <LearningEvent>[]);

      expect(plan.currentExercises, isEmpty);
    });

    test('en septembre, le chapitre d’arithmétique fournit les exercices', () {
      final plan = builder.build(
        date: DateTime(2026, 9, 10),
        events: const <LearningEvent>[],
      );

      expect(plan.sequence.number, 1);
      expect(plan.currentExercises, isNotEmpty);
      expect(plan.usesFallback, isFalse);
    });

    test('sans section pourvue, le vivier de secours prend le relais', () {
      final plan = builder.build(
        date: _october,
        events: const <LearningEvent>[],
      );

      expect(plan.hasSectionExercises, isFalse);
      expect(plan.usesFallback, isTrue);
      expect(plan.fallbackExercises, isNotEmpty);
      expect(plan.canStart, isTrue);

      final List<Exercise> picked = plan.pickPreparation(
        random: Random(1),
        count: 3,
      );
      expect(picked, hasLength(3));
      expect(picked.map((exercise) => exercise.id).toSet(), hasLength(3));
    });

    test('le vivier de secours disparaît dès qu’une section est pourvue', () {
      final plan = builder.build(
        date: _october,
        events: <LearningEvent>[
          _attempt(
            id: 'a',
            lessonId: ArithmeticLesson.lesson1Subtractions.id,
            outcome: AnswerOutcome.incorrect,
          ),
        ],
      );

      expect(plan.hasSectionExercises, isTrue);
      expect(plan.usesFallback, isFalse);
      expect(plan.fallbackExercises, isEmpty);
    });
  });

  group('préparation de trois exercices', () {
    test('puise dans les DEUX sections quand elles sont pourvues', () {
      final List<Exercise> current = _exercisesOf(
        ArithmeticLesson.lesson1Subtractions,
      ).take(2).toList();
      final List<Exercise> weak = _exercisesOf(
        ArithmeticLesson.lesson2Euclid,
      ).take(2).toList();

      final plan = RevisionPlan(
        sequence: builder.build(
          date: DateTime(2026, 9, 10),
          events: const <LearningEvent>[],
        ).sequence,
        weaknesses: const <RevisionWeakness>[],
        currentExercises: current,
        weakExercises: weak,
        fallbackExercises: const <Exercise>[],
      );

      for (int seed = 0; seed < 20; seed++) {
        final List<Exercise> picked = plan.pickPreparation(
          random: Random(seed),
          count: 3,
        );

        expect(picked, hasLength(3));
        expect(picked.map((exercise) => exercise.id).toSet(), hasLength(3));
        expect(
          picked.any((exercise) => current.contains(exercise)),
          isTrue,
          reason: 'graine $seed : aucun exercice du programme actuel',
        );
        expect(
          picked.any((exercise) => weak.contains(exercise)),
          isTrue,
          reason: 'graine $seed : aucun exercice des points faibles',
        );
      }
    });

    test('une seule section pourvue suffit à remplir la préparation', () {
      final List<Exercise> weak = _exercisesOf(
        ArithmeticLesson.lesson1Subtractions,
      ).take(3).toList();

      final plan = RevisionPlan(
        sequence: builder.build(
          date: _october,
          events: const <LearningEvent>[],
        ).sequence,
        weaknesses: const <RevisionWeakness>[],
        currentExercises: const <Exercise>[],
        weakExercises: weak,
        fallbackExercises: const <Exercise>[],
      );

      final List<Exercise> picked = plan.pickPreparation(
        random: Random(2),
        count: 3,
      );
      expect(picked, hasLength(3));
      expect(picked.every(weak.contains), isTrue);
    });

    test('aucun exercice ne donne aucune préparation', () {
      final plan = RevisionPlan(
        sequence: builder.build(
          date: _october,
          events: const <LearningEvent>[],
        ).sequence,
        weaknesses: const <RevisionWeakness>[],
        currentExercises: const <Exercise>[],
        weakExercises: const <Exercise>[],
        fallbackExercises: const <Exercise>[],
      );

      expect(plan.canStart, isFalse);
      expect(plan.pickPreparation(), isEmpty);
    });
  });
}
