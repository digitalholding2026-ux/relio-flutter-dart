/// Tests du cœur de la vérification de transfert — chapitre 1.
///
/// Chaque groupe correspond à un point des critères d'acceptation de la
/// mission. Les tests portent sur le MOTEUR, jamais sur l'interface.
///
/// Determinisme : horloge et generateur d'identifiants injectes, base en
/// memoire. Aucun acces reseau, aucun fichier reel.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/diagnostic_engine.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/hint_trajectory.dart';
import 'package:relio/domain/curriculum/observation_collector.dart';
import 'package:relio/domain/curriculum/transfer_outcome.dart';
import 'package:relio/domain/curriculum/transfer_verification.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import '../helpers/test_database.dart';

late AppDatabase db;
var _id = 0;

Future<Chapter1Service> serviceFrais() async {
  db = await openTestDatabase();
  registerTestDatabase(db);
  _id = 0;
  return Chapter1Service(
    LearningEventRepository(db),
    clock: () => DateTime.utc(2026, 3, 1),
    idGenerator: () => 'id-${_id++}',
  );
}

Exercise ex(String id) => Chapter1Bank.findExercise(id)!;

void main() {
  // =====================================================================
  group('1. Une réussite AUTONOME avec tâche associée déclenche la vérification',
      () {
    test('exercice 1 réussi sans aide → vérification proposée', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: ex(ExerciseIds.ex1),
        rawAnswer: '6',
      );

      final decision = TransferVerification.decide(record);

      expect(decision.available, isTrue);
      expect(decision.reason, isNull);
      expect(decision.task!.id, ExerciseIds.verifyPgcd16And12);
    });

    test('la tâche proposée est bien une tâche de vérification', () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: '6');

      final tache = TransferVerification.decide(record).task!;
      expect(tache.kind, BankElementKind.verificationTask);
    });

    test('la tâche porte sur un couple DIFFÉRENT de l\'exercice initial',
        () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: '6');

      final tache = TransferVerification.decide(record).task!;
      expect(tache.statement, contains('16'));
      expect(tache.statement, contains('12'));
      expect(tache.statement, isNot(contains('18')),
          reason: 'refaire le même couple ne vérifierait aucun transfert');
    });
  });

  // =====================================================================
  group('2. Une réussite AVEC aide ne déclenche PAS la vérification', () {
    test('un indice consulté suffit à bloquer', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: ex(ExerciseIds.ex1),
        rawAnswer: '6',
        hintOrders: <int>{1},
      );

      final decision = TransferVerification.decide(record);

      expect(decision.available, isFalse);
      expect(decision.reason, TransferUnavailable.notAutonomous);
    });

    test('plusieurs indices : le blocage tient', () async {
      final s = await serviceFrais();
      final record = await s.recordAttempt(
        exercise: ex(ExerciseIds.ex1),
        rawAnswer: '6',
        hintOrders: <int>{1, 2},
      );

      expect(TransferVerification.decide(record).reason,
          TransferUnavailable.notAutonomous);
    });

    test('la classification reste « assistée » après rechargement SQLite',
        () async {
      final s = await serviceFrais();
      // Flux réel : l'indice est d'abord consigné comme événement, puis la
      // soumission référence la même clé de tentative.
      await s.recordHintRequested(
        attemptKey: 'tentative-a',
        exercise: ex(ExerciseIds.ex1),
        hintOrder: 1,
      );
      final record = await s.recordAttempt(
        exercise: ex(ExerciseIds.ex1),
        rawAnswer: '6',
        attemptKey: 'tentative-a',
        hintOrders: <int>{1},
      );

      // Reconstruit depuis les evenements persistes, pas depuis l'objet en
      // memoire : c'est le comportement reel apres redemarrage.
      final relu = await s.findAttempt(record.eventId);

      expect(relu, isNotNull);
      expect(relu!.classification, AttemptClassification.assistedSuccess);
      expect(relu.isAutonomous, isFalse);
      expect(TransferVerification.decide(relu).available, isFalse);
    });

    test('la réussite autonome reste autonome après rechargement', () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: '6');

      final relu = await s.findAttempt(record.eventId);

      expect(relu!.classification, AttemptClassification.autonomousSuccess);
      expect(relu.isAutonomous, isTrue);
      expect(TransferVerification.decide(relu).available, isTrue);
    });

    test('un indice consigné AVANT la soumission est bien retrouvé', () async {
      final s = await serviceFrais();
      // Scénario réel : indice demandé, puis soumission, les deux événements
      // partageant la même clé de tentative.
      await s.recordHintRequested(
        attemptKey: 'tentative-x',
        exercise: ex(ExerciseIds.ex1),
        hintOrder: 1,
      );
      final record = await s.recordAttempt(
        exercise: ex(ExerciseIds.ex1),
        rawAnswer: '6',
        attemptKey: 'tentative-x',
        hintOrders: <int>{1},
      );

      final relu = await s.findAttempt(record.eventId);

      expect(relu!.trajectory.consumedOrders, <int>{1});
      expect(relu.isAutonomous, isFalse);
    });
  });

  // =====================================================================
  group('3. Un exercice ÉCHOUÉ ne déclenche PAS la vérification', () {
    test('une réponse fausse bloque', () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: '9');

      final decision = TransferVerification.decide(record);

      expect(record.outcome, AnswerOutcome.incorrect);
      expect(decision.available, isFalse);
      expect(decision.reason, TransferUnavailable.notSuccessful);
    });

    test('une réponse NON ÉVALUABLE bloque aussi, sans être traitée comme échec',
        () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: 'beaucoup');

      expect(record.outcome, AnswerOutcome.notEvaluated);
      expect(TransferVerification.decide(record).available, isFalse);
      expect(TransferVerification.decide(record).reason,
          TransferUnavailable.notSuccessful);
    });
  });

  // =====================================================================
  group('4. Une association absente ou invalide ne déclenche rien', () {
    test('exercice sans tâche déclarée → noLinkedTask', () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex2), rawAnswer: '5');

      expect(TransferVerification.decide(record).reason,
          TransferUnavailable.noLinkedTask);
    });

    test('un identifiant d\'exercice inconnu ne renvoie aucune tâche', () {
      expect(TransferVerification.taskFor('exercice-inexistant'), isNull);
    });

    test('un suivi pointant hors banque ne renvoie aucune tâche', () {
      // Garde-fou : taskFor relit la banque, il n'invente pas de cible.
      expect(Chapter1Bank.findExercise('ch1-verify-inexistante'), isNull);
    });

    test('les 10 autres exercices n\'ont aucune association', () {
      final avecTache = Chapter1Bank.exercises
          .where((e) => TransferVerification.taskFor(e.id) != null)
          .map((e) => e.id)
          .toSet();
      expect(avecTache, <String>{ExerciseIds.ex1});
    });
  });

  // =====================================================================
  group('5. Les trois associations candidates face au contenu réel', () {
    test('A — exercice 1 → PGCD(16, 12) : contenu conforme', () {
      final tache = TransferVerification.taskFor(ExerciseIds.ex1)!;
      final exercice = ex(ExerciseIds.ex1);

      // La tâche évalue bien le CALCUL du PGCD.
      expect(tache.correction.acceptedValues, contains(4));
      // La méthode attendue est celle de l'exercice (soustractions).
      expect(tache.statement.toLowerCase(), contains('soustraction'));
      expect(exercice.statement.toLowerCase(), contains('soustraction'));
      // Même leçon : le transfert porte sur la même compétence.
      expect(tache.lesson.id, exercice.lesson.id);
      // Elle ne dépend d'aucun diagnostic du parcours nominal : c'est une
      // tâche autonome, utilisable même si aucun cas D n'a été produit.
      expect(tache.diagnosticCaseIds, isEmpty);
    });

    test('B — exercice 5 → PGCD(35, 20) : association NON activée', () {
      final tache = ex(ExerciseIds.verifyPgcd35And20);

      // L'énoncé ne demande PAS l'algorithme d'Euclide : il ne dit que
      // « PGCD(35, 20) ». Répondre 5 ne prouve aucune méthode.
      expect(tache.statement.toLowerCase(), isNot(contains('euclide')));
      // Aucune étape attendue n'est enregistrée : rien ne contrôle la
      // division euclidienne.
      expect(tache.expectedSteps, isEmpty);
      // Et surtout : la tâche est liée à D4, dont le fait déclencheur est un
      // critère d'arrêt, pas un transfert de méthode.
      final casD4 = Chapter1Bank.findCase('D4')!;
      expect(casD4.followUp.exerciseId, ExerciseIds.verifyPgcd35And20);
      expect(casD4.observations, contains('arret_avec_reste_non_nul'));

      // Conclusion : association laissée inactive.
      expect(ex(ExerciseIds.ex5).followUpTask, isNull);
      expect(TransferVerification.taskFor(ExerciseIds.ex5), isNull);
    });

    test('C — exercice 8 → PPCM de 10 et 15 : la relation est MAINTENANT contrôlée',
        () {
      final tache = ex(ExerciseIds.verifyPpcm10And15);
      final exercice = ex(ExerciseIds.ex8);

      // L'évaluation contrôle RÉELLEMENT la relation : la valeur seule n'est
      // plus acceptée, une division écrite est exigée.
      final relation = tache.correction.ppcmRelation;
      expect(relation, isNotNull);
      expect(relation!.isCoherent, isTrue);
      expect(relation.result, 30);
      expect(tache.correction.acceptedValues, isEmpty,
          reason: 'aucune valeur nue ne doit être acceptée');

      // Le profil le confirme.
      final profile = TransferVerification.profileOf(tache.id);
      expect(profile.scope, TransferEvidence.relationApplied);
      expect(profile.provesRelation, isTrue);

      // La tâche reste liée à D5, dont le fait est une division inversée.
      final casD5 = Chapter1Bank.findCase('D5')!;
      expect(casD5.followUp.exerciseId, ExerciseIds.verifyPpcm10And15);
      expect(casD5.observations, contains('pgcd_correct_ppcm_faux'));

      // L'ASSOCIATION reste inactive : la condition technique est remplie,
      // mais son activation est une décision pédagogique du fondateur.
      expect(exercice.followUpTask, isNull);
      expect(TransferVerification.taskFor(ExerciseIds.ex8), isNull);
    });

    test('l\'exercice 5 reste sans vérification alors que l\'exercice 1 en a',
        () {
      expect(TransferVerification.taskFor(ExerciseIds.ex1), isNotNull);
      expect(TransferVerification.taskFor(ExerciseIds.ex5), isNull);
    });
  });

  // =====================================================================
  group('6. La méthode n\'est PAS vérifiée par l\'évaluateur', () {
    test('la tâche active ne contrôle que la valeur finale', () {
      final profile = TransferVerification.profileOf(
        ExerciseIds.verifyPgcd16And12,
      );

      expect(profile.scope, TransferEvidence.finalValueOnly);
      expect(profile.provesMethod, isFalse,
          reason: 'répondre 4 ne prouve pas l\'usage des soustractions');
    });

    test('kTransferMethodIsEvaluable vaut false pour TOUTE la banque', () {
      expect(kTransferMethodIsEvaluable, isFalse);
      for (final element in <Exercise>[
        ...Chapter1Bank.exercises,
        ...Chapter1Bank.verificationTasks,
      ]) {
        expect(TransferVerification.profileOf(element.id).methodIsEvaluable,
            isFalse,
            reason: element.id);
      }
    });

    test('une bonne réponse sur un autre couple ne prouve pas la méthode', () {
      // La valeur est correcte, l'affirmation de méthode ne l'est pas.
      final resultat =
          correct(ex(ExerciseIds.verifyPgcd16And12), '4');

      expect(resultat.isCorrect, isTrue);
      expect(resultat.isEvaluated, isTrue);
      // Le moteur ne renvoie aucune information de méthode : il n'y a rien à
      // quoi s'accrocher pour l'affirmer.
      expect(TransferVerification.profileOf(ExerciseIds.verifyPgcd16And12)
          .provesMethod, isFalse);
    });

    test('un couple différent qui échoue ne prouve pas non plus la méthode',
        () {
      final resultat =
          correct(ex(ExerciseIds.verifyPgcd16And12), '7');

      expect(resultat.isCorrect, isFalse);
      expect(TransferVerification.profileOf(ExerciseIds.verifyPgcd16And12)
          .provesMethod, isFalse);
    });
  });

  // =====================================================================
  group('7. La tâche PPCM ne prétend vérifier la relation que si elle le fait',
      () {
    test('le profil PPCM est « relation appliquée », et le contrat le mérite', () {
      final profile =
          TransferVerification.profileOf(ExerciseIds.verifyPpcm10And15);

      expect(profile.scope, TransferEvidence.relationApplied);
      expect(profile.provesRelation, isTrue);

      // Le profil ne SUR-PROMET PAS : dire que la relation ne signifie pas que
      // la méthode de raisonnement a été observée.
      expect(profile.provesMethod, isFalse);
      expect(profile.methodIsEvaluable, isFalse);

      // Une démonstration est acceptée, une valeur seule ne l'est pas.
      expect(correct(ex(ExerciseIds.verifyPpcm10And15), '150/5').isCorrect, isTrue);
      expect(correct(ex(ExerciseIds.verifyPpcm10And15), '30').isCorrect, isFalse);
      expect(correct(ex(ExerciseIds.verifyPpcm10And15), '30').isEvaluated, isFalse);
    });

    test('la tâche D6, elle, exige de nommer les deux notions', () {
      final profile =
          TransferVerification.profileOf(ExerciseIds.verifyPpcm6And8);

      // La formulation textuelle est acceptée : l'élève doit distinguer.
      expect(profile.scope, TransferEvidence.finalValueOrEquivalentFormula);
      expect(correct(ex(ExerciseIds.verifyPpcm6And8), 'ppcm=24;pgcd=2').isCorrect,
          isTrue);
    });

    test('une tâche purement textuelle n\'est pas du ressort de ce profil', () {
      // L'exercice 11 n'est pas une tâche de vérification : il ne doit pas
      // être analysé comme tel.
      expect(TransferVerification.profileOf(ExerciseIds.ex11).scope,
          isNotNull);
    });
  });

  // =====================================================================
  group('8. Un échec ne Consolidation que si la difficulté est ÉTAYÉE', () {
    test('échec sur la tâche active → reprise guidée, pas de consolidation',
        () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(
        exercise: tache,
        rawAnswer: '7',
      );

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );

      expect(assessment.outcome, TransferOutcome.evaluableFailure);
      // Aucune observation n'identifie une difficulté : consolidation ciblée
      // impossible.
      expect(assessment.recovery!.kind, RecoveryKind.guidedReview);
      expect(assessment.recovery!.consolidation, isNull);
      expect(assessment.recovery!.isActionable, isFalse);
    });

    test('la consolidation ciblée est inatteignable faute de fait', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);

      // Même en échec APRÈS indice, le seul fait disponible est
      // « réussite après indice » — qui ne décrit PAS une difficulté de
      // calcul. Aucun fait ne soutient une consolidation ciblée.
      final record = await s.recordAttempt(
        exercise: tache,
        rawAnswer: '7',
        hintOrders: <int>{1},
      );

      final report = collectObservations(record: record, exercise: tache);
      // Un échec, même après indice, ne produit AUCUN fait : le seul fait
      // observable (`reussite_apres_indice`) suppose une RÉUSSITE.
      expect(report.facts, isEmpty);

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );
      expect(assessment.recovery!.kind, RecoveryKind.guidedReview);
    });

    test('un contenu de consolidation manquant est SIGNALÉ', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '7');

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );

      expect(assessment.recovery!.missing,
          contains(MissingContent.consolidationActivity));
    });
  });

  // =====================================================================
  group('9. Difficulté inconnue → reprise guidée SANS diagnostic affirmatif',
      () {
    test('la reprise guidée n\'accole aucune cause', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '7');

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );

      // Aucune hypothèse n'est produite : le moteur ne sait pas où ça bloque.
      expect(assessment.recovery!.kind, RecoveryKind.guidedReview);
      expect(assessment.recovery!.consolidation, isNull);
    });

    test('un échec ne produit aucun cas de diagnostic D1-D8', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '7');

      final report = collectObservations(record: record, exercise: tache);
      final diagnostic = s.diagnose(
        observation: AttemptObservation(facts: report.facts),
        failedExerciseId: tache.id,
      );

      expect(diagnostic.caseIds, isEmpty,
          reason: 'une valeur fausse ne désigne aucun des faits D1-D8');
    });

    test('aucune clarification successive n\'est enchaînée', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);

      for (var dejaPosees = 0; dejaPosees < 5; dejaPosees++) {
        final diagnostic = s.diagnose(
          observation: const AttemptObservation(facts: <String>{}),
          failedExerciseId: tache.id,
          clarificationAlreadyAsked: dejaPosees,
        );
        expect(diagnostic.clarificationQuestion, isNull,
            reason: 'aucun fait → aucune question, quelle que soit la série');
      }
    });
  });

  // =====================================================================
  group('10. Résultat indéterminé ou erreur technique : AUCUNE conclusion',
      () {
    test('réponse non évaluable → indéterminé, sans remédiation', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record =
          await s.recordAttempt(exercise: tache, rawAnswer: 'beaucoup');

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );

      expect(record.outcome, AnswerOutcome.notEvaluated);
      expect(assessment.outcome, TransferOutcome.indeterminate);
      expect(assessment.allowsPedagogicalConclusion, isFalse);
      expect(assessment.recovery, isNull,
          reason: 'ne pas transformer l\'incertitude en remédiation');
    });

    test('erreur technique → aucune conclusion, aucun verdict', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '7');

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: true,
      );

      expect(assessment.outcome, TransferOutcome.technicalError);
      expect(assessment.allowsPedagogicalConclusion, isFalse);
      expect(assessment.recovery, isNull);
    });

    test('l\'erreur technique prime même sur une réponse correcte', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '4');

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: true,
      );

      expect(assessment.outcome, TransferOutcome.technicalError);
    });

    test('soumission vide : ce que le moteur fait RÉELLEMENT', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '   ');

      // Fait documenté : `recordAttempt` ne produit JAMAIS
      // `AnswerOutcome.abandoned`. Une soumission vide est évaluée, donc
      // classée incorrect. Seule l'interface l'empêche d'arriver ici.
      expect(record.outcome, AnswerOutcome.incorrect);
      expect(record.outcome, isNot(AnswerOutcome.abandoned));

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );
      expect(assessment.outcome, TransferOutcome.evaluableFailure);
    });

    test('les quatre issues sont distinctes', () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);

      final succes = await s.recordAttempt(exercise: tache, rawAnswer: '4');
      final echec = await s.recordAttempt(exercise: tache, rawAnswer: '7');
      final indetermine =
          await s.recordAttempt(exercise: tache, rawAnswer: 'zzz');

      final issues = <TransferOutcome>{
        TransferOutcomePolicy.assess(
            task: tache, record: succes, technicalError: false).outcome,
        TransferOutcomePolicy.assess(
            task: tache, record: echec, technicalError: false).outcome,
        TransferOutcomePolicy.assess(
            task: tache, record: indetermine, technicalError: false).outcome,
        TransferOutcomePolicy.assess(
            task: tache, record: echec, technicalError: true).outcome,
      };

      expect(issues, hasLength(4),
          reason: 'aucune des quatre issues ne doit se confondre');
    });
  });

  // =====================================================================
  group('11. Une nouvelle vérification est DISTINCTE de la tâche initiale', () {
    test('aucune revalidation ne reprend la tâche qui vient d\'échouer',
        () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '7');

      final assessment = TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );
      final suivante = assessment.recovery!.nextVerification;

      expect(suivante, isNull,
          reason: 'aucune tâche distincte n\'est déclarée : mieux vaut rien '
              'que rejouer la même tâche');
      expect(assessment.recovery!.missing,
          contains(MissingContent.distinctVerificationTask));
    });

    test('les tâches de contrôle existantes sont bien des couples distincts',
        () {
      // Contrôle arithmétique : les six tâches portent sur des couples
      // différents entre eux, ce qui les rend réutilisables comme revalidation.
      final couples = <String>{};
      for (final task in Chapter1Bank.verificationTasks) {
        final nombre = task.statement;
        expect(couples.add(nombre), isTrue,
            reason: 'énoncé dupliqué : $nombre');
      }
      expect(couples, hasLength(6));
    });

    test('PGCD(16,12) et PGCD(14,7) ne sont pas la même tâche', () {
      expect(ex(ExerciseIds.verifyPgcd16And12).statement,
          isNot(ex(ExerciseIds.verifyPgcd14And7).statement));
      expect(ex(ExerciseIds.verifyPgcd16And12).correction.acceptedValues,
          isNot(ex(ExerciseIds.verifyPgcd14And7).correction.acceptedValues));
    });
  });

  // =====================================================================
  group('12 et 13. Non-régression : classification et absence de doublon', () {
    test('les cinq classes de tentative restent correctement attribuées',
        () async {
      final s = await serviceFrais();

      final autonome = await s.recordAttempt(
          exercise: ex(ExerciseIds.ex1), rawAnswer: '6');
      final assiste = await s.recordAttempt(
          exercise: ex(ExerciseIds.ex1),
          rawAnswer: '6',
          hintOrders: <int>{1});
      final faux = await s.recordAttempt(
          exercise: ex(ExerciseIds.ex1), rawAnswer: '9');
      final fauxAssiste = await s.recordAttempt(
          exercise: ex(ExerciseIds.ex1),
          rawAnswer: '9',
          hintOrders: <int>{1});
      final nonEvaluable = await s.recordAttempt(
          exercise: ex(ExerciseIds.ex1), rawAnswer: 'zzz');

      expect(autonome.classification, AttemptClassification.autonomousSuccess);
      expect(assiste.classification, AttemptClassification.assistedSuccess);
      expect(faux.classification, AttemptClassification.incorrect);
      expect(fauxAssiste.classification, AttemptClassification.assistedIncorrect);
      expect(nonEvaluable.classification, AttemptClassification.incomplete);
    });

    test('l\'évaluation d\'une vérification n\'ajoute pas d\'événement',
        () async {
      final s = await serviceFrais();
      final tache = ex(ExerciseIds.verifyPgcd16And12);
      final record = await s.recordAttempt(exercise: tache, rawAnswer: '7');

      final avant =
          await LearningEventRepository(db).findByType(kAttemptEventType);

      TransferOutcomePolicy.assess(
        task: tache,
        record: record,
        technicalError: false,
      );

      final apres =
          await LearningEventRepository(db).findByType(kAttemptEventType);
      expect(apres, hasLength(avant.length));
    });

    test('la décision de transfert n\'écrit rien non plus', () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: '6');

      final avant =
          await LearningEventRepository(db).findByType(kAttemptEventType);

      TransferVerification.decide(record);

      final apres =
          await LearningEventRepository(db).findByType(kAttemptEventType);
      expect(apres, hasLength(avant.length),
          reason: 'décider est une lecture, pas une écriture');
    });

    test('rejouer le même enregistrement ne crée pas de doublon', () async {
      final s = await serviceFrais();
      final record =
          await s.recordAttempt(exercise: ex(ExerciseIds.ex1), rawAnswer: '6');

      final events = await LearningEventRepository(db)
          .findByType(kAttemptEventType);

      // Les identifiants sont générés une seule fois : une relecture ne peut
      // pas dupliquer.
      expect(events.map((e) => e.id), hasLength(events.length));
      expect(events.map((e) => e.id).toSet(), hasLength(events.length));
      expect(record.eventId, isNotEmpty);
    });

    test('le contenu mathématique de la banque n\'a pas bougé', () {
      expect(Chapter1Bank.exercises, hasLength(11));
      expect(Chapter1Bank.verificationTasks, hasLength(6));
      expect(ex(ExerciseIds.ex1).statement,
          'Calcule le PGCD de 18 et 12 avec des soustractions successives.');
      expect(ex(ExerciseIds.verifyPgcd16And12).statement,
          'PGCD(16, 12) par soustractions successives.');
      // « PGDC » conservé tel quel.
      expect(ex(ExerciseIds.ex5).lesson.title, '« PGDC » : algorithme d’Euclide');
    });
  });
}