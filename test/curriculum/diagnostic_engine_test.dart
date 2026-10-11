/// Tests du moteur de diagnostic D1 a D8.
///
/// Couvre les points 8, 9, 10 et 12 des tests obligatoires :
///  8. declenchement approprie des diagnostics D1 a D8 ;
///  9. comportement specifique de D5 ;
/// 10. comportement specifique de D6 ;
/// 12. gestion d'un diagnostic incertain sans repetition excessive.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/diagnostic_case.dart';
import 'package:relio/domain/curriculum/diagnostic_engine.dart';

void main() {
  const engine = DiagnosticEngine();

  DiagnosisOutcome diagnose(
    Set<String> facts, {
    String failedExerciseId = 'exercice-echoue',
    int clarifications = 0,
  }) {
    return engine.diagnose(
      DiagnosticContext(
        observation: AttemptObservation(facts: facts),
        failedExerciseId: failedExerciseId,
        clarificationAlreadyAsked: clarifications,
      ),
    );
  }

  group('8. Declenchement des diagnostics D1 a D8', () {
    final scenarios = <String, (Set<String> facts, String expectedCase)>{
      'D1': (<String>{'soustraction_fausse'}, 'D1'),
      'D2': (<String>{'poursuit_apres_valeurs_egales'}, 'D2'),
      'D3': (<String>{'mauvais_couple_repris'}, 'D3'),
      'D4': (<String>{'arret_avec_reste_non_nul'}, 'D4'),
      'D5': (<String>{'pgcd_correct_ppcm_faux'}, 'D5'),
      'D6': (<String>{'confusion_pgcd_ppcm'}, 'D6'),
      'D7': (<String>{'reussite_apres_indice'}, 'D7'),
      'D8': (<String>{'reponse_correcte_sans_demarche'}, 'D8'),
    };

    scenarios.forEach((label, scenario) {
      final (facts, expectedCase) = scenario;

      test('$label se declenche sur son observation', () {
        final outcome = diagnose(facts);

        expect(outcome.caseIds, contains(expectedCase));
        expect(outcome.observedFacts, facts,
            reason: 'les faits sont conserves tels quels');
      });
    });

    test('les 8 cas de la banque sont bien distincts', () {
      expect(Chapter1Bank.diagnosticCases, hasLength(8));
      expect(
        Chapter1Bank.diagnosticCases.map((c) => c.id).toSet(),
        {'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8'},
      );
    });

    test('chaque cas fournit une intervention non vide ou unFelicitations',
        () {
      for (final diagnostic in Chapter1Bank.diagnosticCases) {
        final hasQuestion = diagnostic.intervention.question.trim().isNotEmpty;
        expect(
          hasQuestion || diagnostic.intervention.reassuresProgress,
          isTrue,
          reason: '${diagnostic.id} sans intervention',
        );
      }
    });

    test('chaque cas fournit au moins une hypothese', () {
      for (final diagnostic in Chapter1Bank.diagnosticCases) {
        expect(diagnostic.hypothesis, isNotEmpty, reason: diagnostic.id);
      }
    });

    test('les questions d\'intervention restent courtes pour la voix', () {
      // Le document source impose des questions courtes, destinees a l'oral.
      for (final diagnostic in Chapter1Bank.diagnosticCases) {
        final question = diagnostic.intervention.question;
        if (question.isEmpty) continue;
        expect(
          question.length,
          lessThanOrEqualTo(70),
          reason: '${diagnostic.id} : question trop longue pour l\'oral',
        );
      }
    });
  });

  group('9. Comportement specifique de D5', () {
    test('D5 se declenche sur un PPCM faux malgre un PGCD correct', () {
      final outcome = diagnose(<String>{'pgcd_correct_ppcm_faux'});

      expect(outcome.caseIds, contains('D5'));
      expect(outcome.caseIds, isNot(contains('D6')),
          reason: 'D5 et D6 sont des difficultes distinctes');
    });

    test('D5 reste une hypothese, pas un fait', () {
      final outcome = diagnose(<String>{'pgcd_correct_ppcm_faux'});

      // Le fait est « le PPCM est faux », pas « l\'eleve ne sait pas
      // isoler l\'inconnue ».
      expect(outcome.observedFacts, <String>['pgcd_correct_ppcm_faux']);
      expect(outcome.hypotheses.first.label, contains('Isolement'));
      expect(outcome.hypotheses.first.confidence,
          isNot(HypothesisConfidence.indicated),
          reason: 'une hypothese n\'est jamais etablie sans preuve');
    });

    test('D5 pose la question d\'isolement prevue par la banque', () {
      final outcome = diagnose(<String>{'pgcd_correct_ppcm_faux'});

      expect(outcome.intervention.question,
          'Dans la relation, que dois-tu diviser par quoi ?');
    });

    test('D5 se distingue de D6 : isolement vs confusion conceptuelle', () {
      final d5 = diagnose(<String>{'pgcd_correct_ppcm_faux'});
      final d6 = diagnose(<String>{'confusion_pgcd_ppcm'});

      // Deux hypotheses distinctes pour deux observations distinctes.
      expect(d5.hypotheses.first.label, isNot(d6.hypotheses.first.label));
      expect(d5.intervention.question, isNot(d6.intervention.question));
    });

    test('D5 ne confond pas les deux competences', () {
      // Avec les deux observations, le diagnostic doit rester OUVERT :
      // on ne peut pas conclure entre isolement algébrique et confusion.
      final outcome = diagnose(<String>{
        'pgcd_correct_ppcm_faux',
        'confusion_pgcd_ppcm',
      });

      expect(outcome.caseIds, containsAll(<String>['D5', 'D6']));
      expect(outcome.staysOpen, isTrue,
          reason: 'D5 + D6 : il faut separer les deux competences');
      expect(outcome.clarificationQuestion, isNotNull);
      expect(outcome.hypotheses.length, greaterThanOrEqualTo(2));
    });

    test('la tache de suivi de D5 est differente de l\'exercice echoue', () {
      final outcome = diagnose(<String>{'pgcd_correct_ppcm_faux'});

      expect(outcome.followUp!.exerciseId, ExerciseIds.verifyPpcm10And15);
      expect(outcome.followUp!.label, 'PPCM de 10 et 15, avec PGCD 5');
    });
  });

  group('10. Comportement specifique de D6', () {
    test('D6 se declenche sur une confusion PGCD / PPCM', () {
      final outcome = diagnose(<String>{'confusion_pgcd_ppcm'});

      expect(outcome.caseIds, contains('D6'));
    });

    test('D6 conserve plusieurs causes possibles', () {
      final outcome = diagnose(<String>{'confusion_pgcd_ppcm'});

      // Une seule erreur ne prouve pas une confusion conceptuelle.
      expect(outcome.hypotheses.length, greaterThanOrEqualTo(2));
      expect(outcome.isUnresolved, isTrue,
          reason: 'le diagnostic doit rester incertain');
    });

    test('D6 pose la question prevue par la banque', () {
      final outcome = diagnose(<String>{'confusion_pgcd_ppcm'});

      expect(
        outcome.intervention.question,
        'Cherches-tu un diviseur commun ou un multiple commun ?',
      );
    });

    test('D6 propose la verification prevue dans la banque', () {
      final outcome = diagnose(<String>{'confusion_pgcd_ppcm'});

      expect(outcome.followUp!.label, 'Distinguer PGCD et PPCM de 6 et 8');
      expect(outcome.followUp!.exerciseId, ExerciseIds.verifyPpcm6And8);
    });

    test('D6 ne conclut pas definitivement sur une seule erreur', () {
      final outcome = diagnose(<String>{'confusion_pgcd_ppcm'});

      for (final hypothesis in outcome.hypotheses) {
        expect(hypothesis.confidence, isNot(HypothesisConfidence.indicated),
            reason: 'conclure sur une seule erreur serait une faute');
      }
    });

    test('la verification de D6 exige les DEUX valeurs', () {
      final task = Chapter1Bank.findExercise(ExerciseIds.verifyPpcm6And8)!;

      // PGCD(6, 8) = 2 et PPCM(6, 8) = 24 : les nommer distingue les notions.
      expect(task.correction.accepts(24), isTrue);
      expect(
        task.correction.acceptedExpressions
            .any((e) => e.contains('pgcd=2')),
        isTrue,
        reason: 'la tache doit nommer explicitement le PGCD et le PPCM',
      );
    });
  });

  group('12. Diagnostic incertain sans repetition excessive', () {
    test('une observation unique declencheant plusieurs cas reste ouverte', () {
      // Un fait qui correspond a plusieurs cas : le moteur ne tranche pas.
      final outcome = diagnose(<String>{'reponse_correcte_sans_demarche'});

      expect(outcome.caseIds, isNotEmpty);
    });

    test('au-dela du seuil, aucune nouvelle question n\'est posee', () {
      final ambiguous = <String>{
        'pgcd_correct_ppcm_faux',
        'confusion_pgcd_ppcm',
      };

      // Le diagnostic est incertain : une question est posee.
      final first = diagnose(ambiguous, clarifications: 0);
      expect(first.staysOpen, isTrue);
      expect(first.clarificationQuestion, isNotNull);

      // Au-dela du seuil de clarifications, on cesse de questionner.
      final exhausted = diagnose(ambiguous, clarifications: 5);
      expect(exhausted.clarificationQuestion, isNull,
          reason: 'pas de succession indefinie de mini-questions');
    });

    test('le seuil de clarifications est borne', () {
      expect(DiagnosticContext.maxClarifications, lessThanOrEqualTo(2),
          reason: 'la banque interdit l\'enchainement de mini-questions');
    });

    test('sans fait, aucune question n\'est posee', () {
      final outcome = diagnose(<String>{});

      expect(outcome.clarificationQuestion, isNull);
      expect(outcome.intervention.question, isEmpty);
      expect(outcome.followUp, isNull);
    });

    test('une observation inconnue ne declenche aucune question', () {
      final outcome = diagnose(<String>{'comportement_inconnu'});

      expect(outcome.caseIds, isEmpty);
      expect(outcome.clarificationQuestion, isNull);
      expect(outcome.intervention.question, isEmpty);
    });

    test('D7 ne pose pas de question : il felicite le progres', () {
      final outcome = diagnose(<String>{'reussite_apres_indice'});

      expect(outcome.intervention.reassuresProgress, isTrue);
      expect(outcome.intervention.question, isEmpty,
          reason: 'une reussite avec aide n\'appelle pas de question');
    });
  });
}
