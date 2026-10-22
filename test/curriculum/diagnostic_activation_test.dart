/// Activation des diagnostics D1 a D8 dans le parcours.
///
/// Ces tests verrouillent une chose precise : le moteur ne recoit que des
/// faits STRICTEMENT lisibles dans la reponse et dans l'enonce. Un resultat
/// faux ne suffit pas, a lui seul, a affirmer une cause.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/diagnostic_engine.dart';
import 'package:relio/domain/curriculum/observation_collector.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/rules/feedback_selection.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Chapter1Service service;
  var counter = 0;

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    service = Chapter1Service(
      LearningEventRepository(db),
      idGenerator: () => 'diag-${++counter}',
    );
  });

  Future<AttemptRecord> attempt(String exerciseId, String answer) async {
    final exercise = Chapter1Bank.findExercise(exerciseId)!;
    return service.recordAttempt(exercise: exercise, rawAnswer: answer);
  }

  ObservationReport observe(AttemptRecord record, String exerciseId) {
    return collectObservations(
      record: record,
      exercise: Chapter1Bank.findExercise(exerciseId)!,
    );
  }

  group('Faits strictement lisibles', () {
    test('ex8 : le PGCD est donne, seul le PPCM faux est observable', () async {
      final record = await attempt(ExerciseIds.ex8, '0');
      final report = observe(record, ExerciseIds.ex8);

      expect(report.facts, contains(ObservedFacts.pgcdCorrectPpcmFaux));
      expect(
        report.facts,
        isNot(contains(ObservedFacts.confusionPgcdPpcm)),
        reason: 'la reponse 0 n’est pas le PGCD fourni',
      );
    });

    test('ex9 : repondre le PGCD donne rend la confusion observable', () async {
      final record = await attempt(ExerciseIds.ex9, '4');
      final report = observe(record, ExerciseIds.ex9);

      expect(report.facts, contains(ObservedFacts.pgcdCorrectPpcmFaux));
      expect(report.facts, contains(ObservedFacts.confusionPgcdPpcm));
    });

    test(
      'ex6 : un reste intermediaire non nul est un arret observable',
      () async {
        final record = await attempt(ExerciseIds.ex6, '12');
        final report = observe(record, ExerciseIds.ex6);

        expect(report.facts, contains(ObservedFacts.arretAvecResteNonNul));
      },
    );

    test('ex2 : zero est la trace d’une poursuite apres egalite', () async {
      final record = await attempt(ExerciseIds.ex2, '0');
      final report = observe(record, ExerciseIds.ex2);

      expect(report.facts, contains(ObservedFacts.poursuitApresValeursEgales));
    });

    test('ex2 : un PGCD negatif est une soustraction inversee', () async {
      final record = await attempt(ExerciseIds.ex2, '-5');
      final report = observe(record, ExerciseIds.ex2);

      expect(report.facts, contains(ObservedFacts.soustractionFausse));
    });

    test('ex1 sans diagnostic lie ne produit aucun fait, meme faux', () async {
      final record = await attempt(ExerciseIds.ex1, '9');
      final report = observe(record, ExerciseIds.ex1);

      expect(report.facts, isEmpty);
    });
  });

  group('Panneaux C et D', () {
    test(
      'D5 seul ouvre une intervention (C) et non une clarification',
      () async {
        final record = await attempt(ExerciseIds.ex8, '0');
        final outcome = service.diagnose(
          observation: AttemptObservation(
            facts: observe(record, ExerciseIds.ex8).facts,
          ),
          failedExerciseId: ExerciseIds.ex8,
        );

        expect(outcome.caseIds, contains('D5'));
        expect(outcome.clarificationQuestion, isNull);

        final selection = selectDiagnosisFeedback(outcome);
        expect(selection.panel, FeedbackPanel.intervention);
        expect(selection.showRetry, isTrue);
        expect(selection.message, isNotEmpty);
        expect(selection.message, isNot(contains('D5')));
      },
    );

    test(
      'D5 + D6 demandent une clarification (D), puis reviennent a C',
      () async {
        final record = await attempt(ExerciseIds.ex9, '4');
        final outcome = service.diagnose(
          observation: AttemptObservation(
            facts: observe(record, ExerciseIds.ex9).facts,
          ),
          failedExerciseId: ExerciseIds.ex9,
        );

        expect(outcome.caseIds, containsAll(<String>['D5', 'D6']));
        expect(outcome.clarificationQuestion, isNotNull);

        final question = selectDiagnosisFeedback(outcome);
        expect(question.panel, FeedbackPanel.clarification);
        expect(question.message, outcome.clarificationQuestion);
        expect(question.clarificationOptions, isNotEmpty);

        final apres = service.submitClarification(
          diagnosis: outcome,
          answer: question.clarificationOptions.first,
        );
        expect(apres.clarificationQuestion, isNull);

        final intervention = selectDiagnosisFeedback(apres);
        expect(intervention.panel, FeedbackPanel.intervention);
        expect(intervention.showRetry, isTrue);
      },
    );

    test('une erreur non reliee reste en panneau E', () async {
      final record = await attempt(ExerciseIds.ex1, '9');
      final selection = selectFeedback(
        record: record,
        exerciseId: ExerciseIds.ex1,
        rawAnswer: '9',
      );

      expect(selection.panel, FeedbackPanel.noInformation);
      expect(selection.message, isNotEmpty);
    });
  });

  group('Liaison banque / diagnostics', () {
    test('les exercices concernes portent leurs cas', () {
      expect(
        Chapter1Bank.findExercise(ExerciseIds.ex2)!.diagnosticCaseIds,
        <String>['D1', 'D2'],
      );
      expect(
        Chapter1Bank.findExercise(ExerciseIds.ex6)!.diagnosticCaseIds,
        <String>['D3', 'D4'],
      );
      expect(
        Chapter1Bank.findExercise(ExerciseIds.ex8)!.diagnosticCaseIds,
        <String>['D5', 'D6'],
      );
      expect(
        Chapter1Bank.findExercise(ExerciseIds.ex9)!.diagnosticCaseIds,
        <String>['D5', 'D6'],
      );
    });

    test('les PGCD donnes sont ceux des enonces', () {
      expect(Chapter1Bank.findExercise(ExerciseIds.ex8)!.givenPgcd, 6);
      expect(Chapter1Bank.findExercise(ExerciseIds.ex9)!.givenPgcd, 4);
      expect(12 * 18 ~/ 6, 36);
      expect(8 * 12 ~/ 4, 24);
    });
  });
}
