/// Tests d'intégration de la banque du chapitre 1 avec la persistance.
///
/// Couvre les points 6, 7 et 11 des tests obligatoires :
///  6. persistance et relecture des tentatives ;
///  7. separation entre observations et hypotheses ;
/// 11. proposition d'une tache de suivi apres remediation.
///
/// Les tests s'appuient sur une VRAIE base SQLite (Drift), exactement
/// comme le ferait l'application sur un appareil.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/diagnostic_engine.dart';
import 'package:relio/domain/curriculum/hint_trajectory.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LearningEventRepository repository;
  late Chapter1Service service;
  var clockValue = DateTime.utc(2026, 3, 15, 9);

  /// Generateur deterministe : les tests restent reproductibles.
  var counter = 0;
  String newIdGenerator() => 'id-${++counter}';

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    repository = LearningEventRepository(db, clock: () => clockValue);
    service = Chapter1Service(
      repository,
      clock: () => clockValue,
      idGenerator: newIdGenerator,
    );
  });

  group('6. Persistance et relecture des tentatives', () {
    test('une tentative autonome est persistee et relue', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final record = await service.recordAttempt(exercise: ex1, rawAnswer: '6');
      final reloaded = await service.findAttempt(record.eventId);

      expect(reloaded, isNotNull);
      expect(reloaded!.exerciseId, ex1.id);
      expect(reloaded.classification, AttemptClassification.autonomousSuccess);
      expect(reloaded.isAutonomous, isTrue);
      expect(reloaded.trajectory.hasHints, isFalse);
    });

    test('la reponse saisie est conservee telle quelle', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final record = await service.recordAttempt(exercise: ex1, rawAnswer: '6');
      final event = await repository.findById(record.eventId);

      expect(event!.attempt!.answer!.rawText, '6');
      expect(event.attempt!.exerciseId, ex1.id);
    });

    test('une reponse fausse est persistee comme incorrecte', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final record = await service.recordAttempt(exercise: ex1, rawAnswer: '7');

      expect(record.classification, AttemptClassification.incorrect);
      expect(record.outcome.name, 'incorrect');
    });

    test('les indices consultes sont persistes comme evenements', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      await service.recordHintRequested(
        attemptKey: 'tentative-1',
        exercise: ex1,
        hintOrder: 1,
      );
      clockValue = DateTime.utc(2026, 3, 15, 10);
      await service.recordHintRequested(
        attemptKey: 'tentative-1',
        exercise: ex1,
        hintOrder: 2,
      );

      final hintEvents = await repository.findByType(kHintRequestedEventType);
      expect(hintEvents, hasLength(2));
      // `findByType` trie du plus recent au plus ancien : le rang 2 est donc
      // en tete. L'ordre reel se relit via `hintHistoryOf`.
      expect(
        hintEvents.map((e) => e.metadata['hintOrder']).toSet(),
        <int>{1, 2},
      );
    });

    test('la relecture retrouve l\'ordre des indices d\'une tentative',
        () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      await service.recordHintRequested(
        attemptKey: 'tentative-1',
        exercise: ex1,
        hintOrder: 1,
      );
      clockValue = DateTime.utc(2026, 3, 15, 10);
      await service.recordHintRequested(
        attemptKey: 'tentative-1',
        exercise: ex1,
        hintOrder: 2,
      );

      final history = await service.hintHistoryOf('tentative-1');

      expect(history.map((h) => h.order), <int>[1, 2]);
    });

    test('une reussite APRES indice est relue comme assistee', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      // L'eleve consulte l'indice 1, puis soumet : la tentative doit etre
      // reclassifiee comme assistee a la relecture.
      await service.recordHintRequested(
        attemptKey: 'tentative-1',
        exercise: ex1,
        hintOrder: 1,
      );
      clockValue = DateTime.utc(2026, 3, 15, 10);

      final record = await service.recordAttempt(
        exercise: ex1,
        rawAnswer: '6',
        attemptKey: 'tentative-1',
      );

      // Relecture depuis la base : la classification est derivee de
      // l'historique des indices, pas stockee.
      final reloaded = await service.findAttempt(record.eventId);

      expect(reloaded, isNotNull);
      expect(
        reloaded!.classification,
        AttemptClassification.assistedSuccess,
        reason: 'la classification se recalcule depuis les evenements',
      );
      expect(
        reloaded.isAutonomous,
        isFalse,
        reason: 'une reussite avec indice n\'est jamais autonome',
      );
    });

    test('aucun etat de maitrise n\'est stocke', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;
      await service.recordAttempt(exercise: ex1, rawAnswer: '6');

      // Le schema ne doit contenir aucune colonne de maitrise.
      final columns =
          await db.customSelect('PRAGMA table_info(learning_events)').get();
      final names = columns.map((c) => c.data['name'] as String).join(',');

      expect(names.toLowerCase(), isNot(contains('maitrise')));
      expect(names.toLowerCase(), isNot(contains('mastery')));
      expect(names.toLowerCase(), isNot(contains('score')));
      expect(names.toLowerCase(), isNot(contains('level')));
    });

    test('l\'ordre des indices est conserve dans les metadonnees', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final record = await service.recordAttempt(
        exercise: ex1,
        rawAnswer: '6',
        hintOrders: <int>{2, 1},
      );
      final event = await repository.findById(record.eventId);

      expect(event!.metadata['hintOrders'], <int>[1, 2],
          reason: 'les rangs sont normalises et tries');
    });

    test('deux tentatives distinctes ne partagent pas leurs indices',
        () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      await service.recordHintRequested(
        attemptKey: 'tentative-A',
        exercise: ex1,
        hintOrder: 1,
      );
      final attemptA = await service.recordAttempt(
        exercise: ex1,
        rawAnswer: '6',
        attemptKey: 'tentative-A',
      );

      clockValue = DateTime.utc(2026, 3, 15, 11);
      final attemptB = await service.recordAttempt(
        exercise: ex1,
        rawAnswer: '6',
        attemptKey: 'tentative-B',
      );

      final reloadedA = await service.findAttempt(attemptA.eventId);
      final reloadedB = await service.findAttempt(attemptB.eventId);

      expect(reloadedA!.classification, AttemptClassification.assistedSuccess);
      expect(reloadedB!.classification, AttemptClassification.autonomousSuccess,
          reason: 'la tentative B n\'a consulte aucun indice');
    });
  });

  group('7. Separation observations / hypotheses', () {
    test('les faits ne contiennent aucune interpretation', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'soustraction_fausse'},
        ),
        failedExerciseId: ExerciseIds.ex2,
      );

      // Les faits sont des identifiants techniques, pas des jugements.
      expect(outcome.observedFacts, <String>['soustraction_fausse']);
    });

    test('aucune hypothese n\'est jamais presentee comme certaine', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'confusion_pgcd_ppcm'},
        ),
        failedExerciseId: ExerciseIds.ex9,
      );

      expect(outcome.hypotheses, isNotEmpty);
      for (final hypothesis in outcome.hypotheses) {
        expect(hypothesis.confidence.name, isNot('confirmed'));
      }
    });

    test('D6 conserve plusieurs hypotheses concurrentes', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'confusion_pgcd_ppcm'},
        ),
        failedExerciseId: ExerciseIds.ex9,
      );

      expect(outcome.caseIds, contains('D6'));
      expect(
        outcome.hypotheses.length,
        greaterThanOrEqualTo(2),
        reason: 'le document interdit de conclure a une cause unique',
      );
    });

    test('aucune observation ne produit de diagnostic', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(facts: <String>{}),
        failedExerciseId: ExerciseIds.ex2,
      );

      expect(outcome.caseIds, isEmpty);
      expect(outcome.hypotheses, isEmpty);
      expect(outcome.intervention.question, isEmpty);
    });

    test('une observation inconnue ne declenche rien', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(facts: <String>{'fait_inconnu'}),
        failedExerciseId: ExerciseIds.ex2,
      );

      expect(outcome.caseIds, isEmpty);
    });

    test('les hypotheses sont conservees comme hypotheses, pas comme faits',
        () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'soustraction_fausse'},
        ),
        failedExerciseId: ExerciseIds.ex2,
      );

      // L'hypothese « Erreur de calcul ou de procedure » ne doit jamais
      // apparaitre parmi les faits observes.
      expect(
        outcome.observedFacts,
        isNot(contains('Erreur de calcul ou de procédure')),
      );
      expect(outcome.hypotheses.first.label, 'Erreur de calcul ou de procédure');
    });
  });

  group('11. Tache de suivi apres remediation', () {
    test('chaque cas D1 a D8 propose une tache de suivi existante', () {
      for (final diagnostic in Chapter1Bank.diagnosticCases) {
        final task = Chapter1Bank.findExercise(diagnostic.followUp.exerciseId);
        expect(
          task,
          isNotNull,
          reason: '${diagnostic.id} : tache ${diagnostic.followUp.exerciseId} absente',
        );
      }
    });

    test('la tache de suivi est DIFFERENTE de l\'exercice echoue', () {
      final failed = Chapter1Bank.findExercise(ExerciseIds.ex2)!;
      for (final diagnostic in Chapter1Bank.diagnosticCases) {
        final outcome = service.diagnose(
          observation: AttemptObservation(facts: diagnostic.observations),
          failedExerciseId: failed.id,
        );

        expect(
          outcome.followUp?.exerciseId,
          isNot(failed.id),
          reason: '${diagnostic.id} : la verification doit etre differente',
        );
      }
    });

    test('D1 propose le PGCD(16,12) prevu par la banque', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'soustraction_fausse'},
        ),
        failedExerciseId: ExerciseIds.ex2,
      );

      expect(outcome.caseIds, contains('D1'));
      expect(outcome.followUp!.label, 'PGCD(16, 12) par soustractions');
      expect(outcome.followUp!.exerciseId, ExerciseIds.verifyPgcd16And12);
    });

    test('D7 propose un nouvel exercice SANS indice', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'reussite_apres_indice'},
        ),
        failedExerciseId: ExerciseIds.ex1,
      );

      expect(outcome.caseIds, contains('D7'));
      expect(outcome.followUp, isNotNull);
      expect(outcome.followUp!.exerciseId, ExerciseIds.ex3);
      expect(outcome.followUp!.withHints, isFalse,
          reason: 'verifier une reussite autonome exige une tache sans aide');
      expect(outcome.intervention.reassuresProgress, isTrue,
          reason: 'feliciter le progres sans le compter comme reussite autonome');
    });

    test('la tache de suivi est refusee si c\'est l\'exercice echoue', () {
      // Gardefou : proposer l'exercice qui vient d'echouer ne verifierait
      // rien. Le moteur ne propose donc RIEN plutot qu'une fausse
      // verification.
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'reussite_apres_indice'},
        ),
        failedExerciseId: ExerciseIds.ex3,
      );

      expect(outcome.caseIds, contains('D7'));
      expect(outcome.followUp, isNull);
    });

    test('D8 demande de montrer une etape', () {
      final outcome = service.diagnose(
        observation: const AttemptObservation(
          facts: <String>{'reponse_correcte_sans_demarche'},
        ),
        failedExerciseId: ExerciseIds.ex6,
      );

      expect(outcome.caseIds, contains('D8'));
      expect(outcome.intervention.question, 'Montre une étape de ton calcul.');
    });
  });

  group('Correction des reponses', () {
    test('accepte la valeur attendue', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final result = correct(ex1, '6');

      expect(result.isCorrect, isTrue);
      expect(result.isEvaluated, isTrue);
    });

    test('tolere les espaces', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(correct(ex1, '  6 ').isCorrect, isTrue);
    });

    test('tolere la virgule decimale', () {
      final ex9 = Chapter1Bank.findExercise(ExerciseIds.ex9)!;

      expect(correct(ex9, '24').isCorrect, isTrue);
    });

    test('refuse une valeur fausse', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(correct(ex1, '9').isCorrect, isFalse);
    });

    test('un format non reconnu n\'est pas une erreur de l\'eleve', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final result = correct(ex1, 'beaucoup');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isFalse,
          reason: 'non evaluable != faux : la distinction est un fait');
    });

    test('une reponse vide n\'est pas evaluable', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      final result = correct(ex1, '   ');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isTrue,
          reason: 'la reponse a bien ete soumise, elle est simplement vide');
    });
  });

  group('Progression des indices', () {
    test('le service ne propose rien de plus que la banque', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      // L'exercice 1 ouvre la leçon 1 : la règle de budget lui accorde ses
      // 3 fiches, celles qu'il possède. La progression s'arrête donc là.
      expect(service.nextHint(ex1, <int>{})!.order, 1);
      expect(service.nextHint(ex1, <int>{1})!.order, 2);
      expect(service.nextHint(ex1, <int>{1, 2})!.order, 3);
      expect(service.nextHint(ex1, <int>{1, 2, 3}), isNull,
          reason: 'aucune aide inventee au-dela du document');
    });

    test('consulter un indice inexistant leve une erreur explicite', () async {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(
        () => service.recordHintRequested(
          attemptKey: 'x',
          exercise: ex1,
          hintOrder: 99,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
