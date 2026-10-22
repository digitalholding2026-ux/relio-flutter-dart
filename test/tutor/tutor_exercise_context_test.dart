/// Le contexte transmet l'énoncé et la correction VALIDÉE, sans rien inventer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';
import 'package:relio/domain/tutor/tutor_prompt.dart';

/// Exercice de test : la valeur et l'explication viennent du champ
/// `correction`, comme dans la banque réelle.
Exercise _exercise({
  String statement = 'Calcule le PGCD de 18 et 12.',
  CorrectionCriterion correction = const CorrectionCriterion(
    acceptedValues: <int>[6],
    acceptedExpressions: <String>['6'],
    explanation: 'Le PGCD de 18 et 12 est 6.',
  ),
}) {
  return Exercise(
    id: 'test-exercice',
    lesson: ArithmeticLesson.lesson1Subtractions,
    statement: statement,
    correction: correction,
  );
}

void main() {
  group('Contexte de l’exercice', () {
    test('reprend l’énoncé et la correction validée', () {
      final context = TutorExerciseContext.fromExercise(_exercise());

      expect(context.statement, 'Calcule le PGCD de 18 et 12.');
      expect(context.expectedAnswer, contains('Valeurs acceptées : 6.'));
      expect(context.expectedAnswer, contains('Expressions acceptées : 6.'));
      expect(context.expectedAnswer, contains('Le PGCD de 18 et 12 est 6.'));
    });

    test('signale une correction absente plutôt que d’inventer', () {
      final context = TutorExerciseContext.fromExercise(
        _exercise(correction: const CorrectionCriterion()),
      );

      expect(context.expectedAnswer, 'Aucune correction explicite fournie.');
    });

    test('le prompt complet contient le cerveau, l’énoncé et la réponse', () {
      final prompt = systemPromptFor(
        TutorExerciseContext.fromExercise(_exercise()),
      );

      expect(prompt, startsWith(kTutorSystemPrompt));
      expect(prompt, contains('Calcule le PGCD de 18 et 12.'));
      expect(prompt, contains('Le PGCD de 18 et 12 est 6.'));
      expect(prompt, contains('à ne jamais révéler'));
    });
  });
}
