/// Tests de ce que le moteur peut — et ne peut PAS — observer.
///
/// Deux questions structurantes, toutes deux Hitchhiker's :
///
///  1. Quelles observations la banque peut-elle réellement produire à partir
///     d'une tentative d'interface ? Réponse : une seule, et ce test
///     garantit qu'aucune autre n'apparaît.
///
///  2. Une tâche de vérification est-elle associée à un exercice du parcours
///     nominal ? Réponse : non, et ce test verrouille ce « non » tant qu'un
///     document pédagogique n'a pas tranché.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/diagnostic_case.dart';
import 'package:relio/domain/curriculum/diagnostic_engine.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/observation_collector.dart';
import 'package:relio/domain/curriculum/transfer_verification.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import '../helpers/test_database.dart';

late AppDatabase db;
late Chapter1Service service;

Future<Chapter1Service> serviceFrais() async {
  db = await openTestDatabase();
  registerTestDatabase(db);
  _counter = 0;
  service = Chapter1Service(
    LearningEventRepository(db),
    clock: () => DateTime.utc(2026, 1, 1),
    idGenerator: _sequence,
  );
  return service;
}

var _counter = 0;
String _sequence() => 'id-${_counter++}';

void main() {

  group('Observations — ce qui est réellement observable', () {
    test('une réussite AUTONOME ne produit AUCUN fait', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '6',
      );

      final report = collectObservations(
        record: record,
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
      );

      expect(report.facts, isEmpty,
          reason: 'sans fait, le moteur ne conclut rien : c\'est le '
              'comportement attendu, pas une lacune');
      expect(
        s.diagnose(
          observation: AttemptObservation(facts: report.facts),
          failedExerciseId: ExerciseIds.ex1,
        ),
        isA<DiagnosisOutcome>().having(
          (DiagnosisOutcome o) => o.caseIds,
          'cas de diagnostic',
          isEmpty,
        ),
      );
    });

    test('une réussite APRÈS indice produit le seul fait observable', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '6',
        hintOrders: <int>{1},
      );

      final report = collectObservations(
        record: record,
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
      );

      expect(report.facts, <String>{ObservedFacts.reussiteApresIndice});

      // Ce fait unique déclenche D7, et rien d'autre.
      final outcome = s.diagnose(
        observation: AttemptObservation(facts: report.facts),
        failedExerciseId: ExerciseIds.ex1,
      );
      expect(outcome.caseIds, <String>['D7']);
      expect(outcome.hypotheses.single.confidence, HypothesisConfidence.likely);
      // D7 n'affirme qu'une « procédure en cours d'acquisition », jamais
      // une cause d'erreur de calcul.
      expect(
        outcome.hypotheses.map((h) => h.label),
        everyElement(isNot(contains('calcul'))),
      );
    });

    test('une réponse FAUSSE ne produit AUCUNE cause conceptuelle', () async {
      final s = await serviceFrais();

      for (final saisie in <String>['9', '12', '0', '100']) {
        final record = await s.recordAttempt(
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
          rawAnswer: saisie,
        );
        final report = collectObservations(
          record: record,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        );

        expect(report.facts, isEmpty,
            reason: 'une valeur fausse n\'informe sur AUCUNE cause : '
                'déduire « soustraction fausse » serait inventer le '
                'raisonnement de l\'élève (saisie « $saisie »)');
      }
    });

    test('aucun fait produit n\'est inconnu de la banque', () async {
      final s = await serviceFrais();
      const attendusParLaBanque = <String>{
        'soustraction_fausse',
        'poursuit_apres_valeurs_egales',
        'mauvais_couple_repris',
        'arret_avec_reste_non_nul',
        'pgcd_correct_ppcm_faux',
        'confusion_pgcd_ppcm',
        'reussite_apres_indice',
        'reponse_correcte_sans_demarche',
      };

      for (final element in Chapter1Bank.exercises) {
        for (final indices in <Set<int>>[{}, {1}]) {
          final record = await s.recordAttempt(
            exercise: element,
            rawAnswer: '6',
            hintOrders: indices,
          );
          final report = collectObservations(
            record: record,
            exercise: element,
          );
          expect(
            report.facts.difference(attendusParLaBanque),
            isEmpty,
            reason: 'fait hors nomenclature pour ${element.id}',
          );
        }
      }
    });

    test('les faits hors de portée sont listés, pas forgets', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '6',
      );

      final report = collectObservations(
        record: record,
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
      );

      expect(report.unreachableFacts, contains('soustraction_fausse'));
      expect(report.unreachableFacts, contains('confusion_pgcd_ppcm'));
      expect(report.unreachableFacts, contains('reponse_correcte_sans_demarche'));
    });

    test('D8 n\'est jamais déclenché : la démarche n\'est pas captée', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '6',
      );
      final report = collectObservations(
        record: record,
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
      );

      expect(
        s.diagnose(
          observation: AttemptObservation(facts: report.facts),
          failedExerciseId: ExerciseIds.ex1,
        ).caseIds,
        isNot(contains('D8')),
      );
    });
  });

  group('Vérification de transfert — associations réelles', () {
    test('AUCUN exercice du parcours n\'a de tâche de vérification', () async {
      for (final exercise in Chapter1Bank.exercises) {
        expect(
          TransferVerification.taskFor(exercise.id),
          isNull,
          reason: '${exercise.id} : aucune tâche de contrôle ne lui est '
              'rattachée dans la banque',
        );
      }
    });

    test('les suivis déclarés pointent tous vers un EXERCICE, pas une tâche', () {
      final avecSuivi = Chapter1Bank.exercises
          .where((e) => e.followUpTask != null)
          .toList();

      expect(avecSuivi, isNotEmpty, reason: 'la banque déclare bien des suivis');
      for (final exercise in avecSuivi) {
        final cible = Chapter1Bank.findExercise(exercise.followUpTask!);
        expect(cible, isNotNull);
        expect(
          cible!.kind,
          BankElementKind.exercise,
          reason: 'le suivi de ${exercise.id} est un exercice du parcours, '
              'pas une tâche de vérification : ce n\'est pas un contrôle',
        );
      }
    });

    test('les six tâches de contrôle ne sont joignables que par D1 à D6', () {
      const viaDiagnostic = <String>[
        ExerciseIds.verifyPgcd16And12,
        ExerciseIds.verifyPgcd14And7,
        ExerciseIds.verifyPgcd24And16,
        ExerciseIds.verifyPgcd35And20,
        ExerciseIds.verifyPpcm10And15,
        ExerciseIds.verifyPpcm6And8,
      ];

      final viaSuiviExercice = Chapter1Bank.exercises
          .map((e) => e.followUpTask)
          .whereType<String>()
          .toSet();

      for (final id in viaDiagnostic) {
        expect(viaSuiviExercice, isNot(contains(id)),
            reason: '$id ne doit pas être atteignable par le parcours');
        expect(
          Chapter1Bank.findExercise(id)!.kind,
          BankElementKind.verificationTask,
        );
      }

      // Elles sont bien déclarées par les cas de diagnostic D1 à D6.
      // D7 et D8 font exception : leur suivi est un EXERCICE du parcours
      // (ex3 et ex6), ce qui est cohérent — ces deux cas ne Bornent pas
      // une remédiation mais une réutilisation sans indice.
      for (final cas in Chapter1Bank.diagnosticCases) {
        final suivi = cas.followUp.exerciseId;
        if (viaDiagnostic.contains(suivi)) {
          expect(cas.id, anyOf('D1', 'D2', 'D3', 'D4', 'D5', 'D6'),
              reason: '${cas.id} pointe vers une tâche de contrôle');
        } else {
          expect(
            Chapter1Bank.findExercise(suivi)!.kind,
            BankElementKind.exercise,
            reason: '${cas.id} : un suivi non listed doit être un exercice',
          );
        }
      }
    });

    test('aucun cas de diagnostic ne mène à lui-même', () {
      for (final cas in Chapter1Bank.diagnosticCases) {
        final cible = Chapter1Bank.findExercise(cas.followUp.exerciseId);
        expect(cible, isNotNull, reason: '${cas.id} : suivi introuvable');
        expect(cas.followUp.exerciseId, isNot(cas.id));
      }
    });
  });

  group('Vérification de transfert — règle d\'affichage', () {
    test('une réussite autonome reste SANS vérification faute de liaison',
        () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '6',
      );

      final decision = TransferVerification.decide(record);

      expect(record.isAutonomous, isTrue);
      expect(decision.available, isFalse);
      expect(decision.reason, TransferUnavailable.noLinkedTask);
    });

    test('une réussite AVEC indice n\'est jamais présentée comme autonome',
        () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '6',
        hintOrders: <int>{1},
      );

      final decision = TransferVerification.decide(record);

      expect(record.isAutonomous, isFalse);
      expect(decision.available, isFalse);
      expect(decision.reason, TransferUnavailable.notAutonomous,
          reason: 'la raison autonome prime : même avec une tâche liée, '
              'une réussite assistée ne se vérifie pas comme une réussite');
    });

    test('un échec ne donne jamais lieu à une vérification', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: Chapter1Bank.findExercise(ExerciseIds.ex1)!,
        rawAnswer: '9',
      );

      final decision = TransferVerification.decide(record);

      expect(record.outcome, AnswerOutcome.incorrect);
      expect(decision.available, isFalse);
      expect(decision.reason, TransferUnavailable.notSuccessful);
    });

    test('aucun bouton de vérification n\'est affiché sur les 11 exercices',
        () async {
      final s = await serviceFrais();
      for (final exercise in Chapter1Bank.exercises) {
        final reponse = exercise.correction.acceptedValues.isEmpty
            ? 'ppcm = produit / pgcd'
            : '${exercise.correction.acceptedValues.first}';
        final record = await s.recordAttempt(exercise: exercise, rawAnswer: reponse);

        expect(
          TransferVerification.decide(record).available,
          isFalse,
          reason: '${exercise.id} : aucune vérification ne doit être proposée',
        );
      }
    });
  });
}