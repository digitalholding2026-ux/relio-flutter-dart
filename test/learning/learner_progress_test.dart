/// Tests de la projection d'avancement — la seule source des décomptes.
///
/// Ce que ces tests protègent :
///  - un historique vide donne des zéros, jamais une valeur d'attente ;
///  - une tentative fausse marque la leçon comme commencée mais ne termine
///    aucun exercice ;
///  - une réussite termine l'exercice, une seule fois même si elle est rejouée ;
///  - une leçon dont tous les exercices ont été réussis est maîtrisée ;
///  - les totaux viennent de la banque validée, pas d'une constante inventée.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/learning/learning_event.dart';

/// Événement de tentative, réduit à ce que la projection lit.
LearningEvent _attempt(
  String id, {
  required ArithmeticLesson lesson,
  required String exerciseId,
  required AnswerOutcome outcome,
}) {
  return LearningEvent(
    id: id,
    type: kLearnerAttemptEventType,
    occurredAt: DateTime.utc(2026, 10, 21),
    notionIds: <String>['lecon-${lesson.id}'],
    attempt: ExerciseAttempt(
      exerciseId: exerciseId,
      startedAt: DateTime.utc(2026, 10, 21),
      outcome: outcome,
    ),
    metadata: <String, Object?>{'lessonId': lesson.id},
  );
}

/// Identifiants officiels des exercices d'une leçon, dans l'ordre du programme.
List<String> _exerciseIdsOf(ArithmeticLesson lesson) {
  return Chapter1Bank.exercises
      .where(
        (exercise) =>
            exercise.kind == BankElementKind.exercise &&
            exercise.lesson == lesson,
      )
      .map((exercise) => exercise.id)
      .toList();
}

void main() {
  group('LearnerProgress — historique vide', () {
    test('un nouvel élève n’a rien commencé et n’a aucun décompte', () {
      final progress = LearnerProgress.fromEvents(const <LearningEvent>[]);

      expect(progress.hasStarted, isFalse);
      expect(progress.completedExercises, 0);
      expect(progress.masteredNotions, 0);
      expect(progress.startedLessonIds, isEmpty);
    });

    test('les totaux sont ceux de la banque validée — 4, 3 et 4', () {
      final totals = LearnerProgress.officialChapter1ExerciseTotals();

      expect(totals[ArithmeticLesson.lesson1Subtractions.id], 4);
      expect(totals[ArithmeticLesson.lesson2Euclid.id], 3);
      expect(totals[ArithmeticLesson.lesson3PpcmPgcdRelation.id], 4);
    });
  });

  group('LearnerProgress — tentative', () {
    test('une tentative fausse commence la leçon sans terminer l’exercice', () {
      final lesson = ArithmeticLesson.lesson1Subtractions;
      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        _attempt(
          'a1',
          lesson: lesson,
          exerciseId: _exerciseIdsOf(lesson).first,
          outcome: AnswerOutcome.incorrect,
        ),
      ]);

      expect(progress.hasStarted, isTrue);
      expect(progress.startedLesson(lesson.id), isTrue);
      expect(progress.completedExercises, 0);
      expect(progress.completedIn(lesson.id), 0);
    });

    test('une réussite termine l’exercice, une seule fois', () {
      final lesson = ArithmeticLesson.lesson1Subtractions;
      final exerciseId = _exerciseIdsOf(lesson).first;
      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        _attempt(
          'a1',
          lesson: lesson,
          exerciseId: exerciseId,
          outcome: AnswerOutcome.incorrect,
        ),
        _attempt(
          'a2',
          lesson: lesson,
          exerciseId: exerciseId,
          outcome: AnswerOutcome.correct,
        ),
        _attempt(
          'a3',
          lesson: lesson,
          exerciseId: exerciseId,
          outcome: AnswerOutcome.correct,
        ),
      ]);

      expect(progress.completedExercises, 1);
      expect(progress.completedIn(lesson.id), 1);
      expect(progress.masteredNotions, 0);
    });

    test('une leçon entièrement réussie est maîtrisée', () {
      final lesson = ArithmeticLesson.lesson1Subtractions;
      final ids = _exerciseIdsOf(lesson);

      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        for (final (index, id) in ids.indexed)
          _attempt(
            'a$index',
            lesson: lesson,
            exerciseId: id,
            outcome: AnswerOutcome.correct,
          ),
      ]);

      expect(progress.completedExercises, ids.length);
      expect(progress.completedIn(lesson.id), ids.length);
      expect(progress.masteredNotions, 1);
    });

    test('les événements d’un autre type ne comptent pas', () {
      final lesson = ArithmeticLesson.lesson2Euclid;
      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        LearningEvent(
          id: 'h1',
          type: 'hint_offered',
          occurredAt: DateTime.utc(2026, 10, 21),
          metadata: <String, Object?>{'lessonId': lesson.id},
        ),
      ]);

      expect(progress.hasStarted, isFalse);
      expect(progress.completedExercises, 0);
    });

    test('une tentative sans leçon identifiable est ignorée', () {
      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        LearningEvent(
          id: 'a1',
          type: kLearnerAttemptEventType,
          occurredAt: DateTime.utc(2026, 10, 21),
          attempt: ExerciseAttempt(
            exerciseId: 'inconnu',
            startedAt: DateTime.utc(2026, 10, 21),
            outcome: AnswerOutcome.correct,
          ),
        ),
      ]);

      expect(progress.hasStarted, isFalse);
      expect(progress.completedExercises, 0);
    });
  });

  group('LearnerProgress — reprise d’une leçon', () {
    final lesson = ArithmeticLesson.lesson1Subtractions;

    test('un nouvel élève reprend au premier exercice', () {
      final progress = LearnerProgress.fromEvents(const <LearningEvent>[]);
      final ids = _exerciseIdsOf(lesson);

      expect(progress.isLessonMastered(lesson.id), isFalse);
      expect(progress.resumeExerciseForLesson(lesson.id)?.id, ids.first);
    });

    test('le premier exercice terminé est sauté', () {
      final ids = _exerciseIdsOf(lesson);
      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        _attempt(
          'a1',
          lesson: lesson,
          exerciseId: ids.first,
          outcome: AnswerOutcome.correct,
        ),
      ]);

      expect(progress.isLessonMastered(lesson.id), isFalse);
      expect(progress.resumeExerciseForLesson(lesson.id)?.id, ids[1]);
    });

    test('une leçon maîtrisée reprend au premier exercice, en révision', () {
      final ids = _exerciseIdsOf(lesson);
      final progress = LearnerProgress.fromEvents(<LearningEvent>[
        for (final (index, id) in ids.indexed)
          _attempt(
            'a$index',
            lesson: lesson,
            exerciseId: id,
            outcome: AnswerOutcome.correct,
          ),
      ]);

      expect(progress.isLessonMastered(lesson.id), isTrue);
      expect(progress.resumeExerciseForLesson(lesson.id)?.id, ids.first);
    });
  });
}
