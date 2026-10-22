/// Protocole de signalement d'erreur du tuteur.
///
/// Le modele ne peut pas ouvrir un diagnostic avec une phrase ambigue : il
/// doit produire un code d'une liste fermee. Ces tests verrouillent le
/// retrait du marqueur de l'affichage et le refus des codes inconnus.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/observation_collector.dart';
import 'package:relio/domain/tutor/tutor_error_signal.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';

void main() {
  group('Lecture du signal', () {
    test('un code valide est extrait et retire du texte', () {
      final signal = parseTutorErrorSignal(
        'Tu as inversé la soustraction. '
        '[[relio-erreur:soustraction_fausse]]',
      );

      expect(signal.text, 'Tu as inversé la soustraction.');
      expect(signal.facts, <String>{ObservedFacts.soustractionFausse});
    });

    test('un code inconnu est retire mais n’ouvre aucun diagnostic', () {
      final signal = parseTutorErrorSignal(
        'Je ne suis pas sûr. [[relio-erreur:cause_inventee]]',
      );

      expect(signal.text, 'Je ne suis pas sûr.');
      expect(signal.facts, isEmpty);
    });

    test('plusieurs codes valides sont conservés', () {
      final signal = parseTutorErrorSignal(
        'Deux choses. [[relio-erreur:pgcd_correct_ppcm_faux]]'
        '[[relio-erreur:confusion_pgcd_ppcm]]',
      );

      expect(
        signal.facts,
        containsAll(<String>[
          ObservedFacts.pgcdCorrectPpcmFaux,
          ObservedFacts.confusionPgcdPpcm,
        ]),
      );
      expect(signal.text, 'Deux choses.');
    });

    test('sans marqueur, le texte reste intact', () {
      final signal = parseTutorErrorSignal('Continue, tu y es presque.');

      expect(signal.text, 'Continue, tu y es presque.');
      expect(signal.facts, isEmpty);
    });
  });

  group('Prompt du tuteur', () {
    test('le protocole et les codes sont transmis au modèle', () {
      final prompt = systemPromptFor(
        TutorExerciseContext.fromExercise(
          Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        ),
      );

      expect(prompt, contains('[[relio-erreur:CODE]]'));
      for (final fact in kTutorReportableFacts) {
        expect(prompt, contains(fact), reason: 'code absent du prompt : $fact');
      }
    });

    test('le cerveau pédagogique validé reste en tête du prompt', () {
      final prompt = systemPromptFor(
        const TutorExerciseContext(
          statement: 'Énoncé',
          expectedAnswer: 'Réponse',
        ),
      );

      expect(prompt, startsWith('Rôle :'));
      expect(prompt, contains('[[relio-erreur:CODE]]'));
    });
  });
}
