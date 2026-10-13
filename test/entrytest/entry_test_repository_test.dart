/// Test d'entree — persistance, idempotence et reprise.
///
/// Verifie l'ECRITURE (idempotence, dedupplication) et la REPRISE apres
/// fermeture simulee — c'est-a-dire avec une NOUVELLE instance de depot et
/// une NOUVELLE instance de base, comme apres un redemarrage de
/// l'application.
///
/// Aucune de ces assertions ne passe par `Chapter1Service` : rien ici ne
/// doit dependre du chapitre 1.
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/entrytest/entry_test_correction.dart';
import 'package:relio/domain/entrytest/entry_test_question.dart';
import 'package:relio/domain/entrytest/entry_test_repository.dart';
import 'package:relio/domain/entrytest/entry_test_session.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LearningEventRepository events;
  late EntryTestRepository repo;

  DateTime instant(int seconds) =>
      DateTime.utc(2026, 1, 1, 9, 0, seconds);

  /// Ouvre une base SUR FICHIER : seule une base persistante survit a une
  /// fermeture, donc seule elle permet de simuler un redemarrage reel.
  Future<AppDatabase> ouvrirSurFichier(String chemin) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final AppDatabase base = AppDatabase.forTesting(NativeDatabase(File(chemin)));
    await base.migrateForTesting();
    return base;
  }

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    events = LearningEventRepository(db, clock: () => instant(0));
    repo = EntryTestRepository(events, clock: () => instant(10));
  });

  Future<void> demarrer([String sessionId = 'session-1']) =>
      repo.startSession(sessionId: sessionId, startedAt: instant(1));

  Future<bool> repondre(
    EntryTestQuestion q,
    String brut, {
    required bool correct,
    required bool evaluated,
  }) {
    return repo.recordAnswer(
      sessionId: 'session-1',
      question: q,
      rawAnswer: brut,
      correction: EntryTestCorrection(
        isCorrect: correct,
        isEvaluated: evaluated,
      ),
      normalizedAnswer: brut.trim(),
      answeredAt: instant(20),
    );
  }

  group('Ecriture et relecture', () {
    test('une reponse enregistree est relue a l\'identique', () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);

      final EntryTestSession? session = await repo.loadSession('session-1');
      expect(session, isNotNull);
      expect(session!.answeredCount, 1);

      final EntryTestAnswer? answer = session.answerFor(EntryTestBank.q1.id);
      expect(answer, isNotNull);
      expect(answer!.questionId, 'entry-q1');
      expect(answer.order, 1);
      expect(answer.rawAnswer, '7');
      expect(answer.normalizedAnswer, '7');
      expect(answer.correction.isCorrect, isTrue);
      expect(answer.correction.isEvaluated, isTrue);
    });

    test('une session jamais demarree est introuvable', () async {
      expect(await repo.loadSession('fantome'), isNull);
    });

    test('une session demarree sans reponse est vide, pas terminee', () async {
      await demarrer();
      final EntryTestSession? session = await repo.loadSession('session-1');

      expect(session, isNotNull);
      expect(session!.answeredCount, 0);
      expect(session.remainingCount, 5);
      expect(session.isCompleted, isFalse);
      expect(session.isReadyToComplete, isFalse);
    });

    test('une reponse non evaluable est conservee comme telle', () async {
      await demarrer();
      await repondre(EntryTestBank.q1, 'sept',
          correct: false, evaluated: false);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      final EntryTestAnswer answer = session.answerFor(EntryTestBank.q1.id)!;

      // Le fait « non evaluable » EST conserve : c'est une observation, pas
      // une absence.
      expect(answer.correction.isEvaluated, isFalse);
      expect(answer.correction.isIndeterminate, isTrue);
      expect(answer.rawAnswer, 'sept', reason: 'la saisie brute reste auditable');
    });
  });

  group('Idempotence', () {
    test('demarrer deux fois la meme session ne cree pas de doublon',
        () async {
      expect(await repo.startSession(
          sessionId: 'session-1', startedAt: instant(1)), isTrue);
      expect(await repo.startSession(
          sessionId: 'session-1', startedAt: instant(2)), isFalse);

      final List<dynamic> all = await events.findByType(
        EntryTestRepository.sessionStartedEventType,
      );
      expect(all.length, 1);
    });

    test('enregistrer deux fois la meme reponse ne cree pas de doublon',
        () async {
      await demarrer();
      expect(await repondre(EntryTestBank.q1, '7',
          correct: true, evaluated: true), isTrue);
      expect(await repondre(EntryTestBank.q1, '7',
          correct: true, evaluated: true), isFalse);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      expect(session.answeredCount, 1);
      expect(
        (await events.findByType(EntryTestRepository.answerEventType)).length,
        1,
      );
    });

    test('une reponse differente sur la MEME question ne l\'ecrase pas',
        () async {
      // L'historique est append-only : la premiere reponse fait foi.
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);
      await repondre(EntryTestBank.q1, '6', correct: false, evaluated: true);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      expect(session.answeredCount, 1);
      expect(session.answerFor(EntryTestBank.q1.id)!.rawAnswer, '7');
    });

    test('l\'identifiant d\'evenement est deterministe', () {
      expect(
        EntryTestRepository.eventIdFor('s1', 'answer:entry-q1'),
        'entry-test:s1:answer:entry-q1',
      );
      // Deux constructions identiques donnent le meme identifiant : c'est
      // ce qui rend la deduplication effective, un UUID par essai ne le
      // ferait pas.
      expect(
        EntryTestRepository.eventIdFor('s1', 'started'),
        EntryTestRepository.eventIdFor('s1', 'started'),
      );
    });

    test('terminer deux fois la session ne cree pas de doublon', () async {
      await demarrer();
      expect(await repo.completeSession(sessionId: 'session-1'), isTrue);
      expect(await repo.completeSession(sessionId: 'session-1'), isFalse);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      expect(session.isCompleted, isTrue);
      expect(
        (await events.findByType(
          EntryTestRepository.sessionCompletedEventType,
        ))
            .length,
        1,
      );
    });
  });

  group('Ordre de relecture', () {
    test('les reponses sont rendues dans l\'ordre des questions', () async {
      await demarrer();
      // Ecrites dans le DESORDRE volontaire.
      await repondre(EntryTestBank.q5, '5', correct: true, evaluated: true);
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);
      await repondre(EntryTestBank.q3, '2', correct: true, evaluated: true);
      await repondre(EntryTestBank.q2, '2/4', correct: true, evaluated: true);
      await repondre(EntryTestBank.q4, '7', correct: true, evaluated: true);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      final List<int> ordre = <int>[
        for (final EntryTestAnswer a in session.orderedAnswers) a.order,
      ];

      // L'ordre vient de la BANQUE, pas de l'insertion SQL.
      expect(ordre, <int>[1, 2, 3, 4, 5]);
    });

    test('l\'ordre des questions reste celui de la banque', () async {
      await demarrer();
      await repondre(EntryTestBank.q3, '2', correct: true, evaluated: true);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      expect(
        session.questions.map((EntryTestQuestion q) => q.order),
        <int>[1, 2, 3, 4, 5],
      );
    });
  });

  group('Reprise apres fermeture simulee', () {
    test('la reprise designe la premiere question sans reponse', () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);
      await repondre(EntryTestBank.q2, '2/3', correct: false, evaluated: true);

      final EntryTestSession session = (await repo.loadSession('session-1'))!;
      expect(session.nextQuestion?.id, 'entry-q3');
      expect(session.remainingCount, 3);
    });

    test('apres fermeture et relance, la session est reprise au bon endroit',
        () async {
      // Une base EN MEMOIRE perdrait ses donnees a la fermeture : elle ne
      // simulerait pas un redemarrage, elle simulerait une base neuve. Le
      // fichier rend le test faithful au cas reel.
      final Directory dossier = Directory.systemTemp.createTempSync('relio_entry');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final String chemin = '${dossier.path}/relio.sqlite';

      final AppDatabase avant = await ouvrirSurFichier(chemin);
      final EntryTestRepository depotAvant =
          EntryTestRepository(LearningEventRepository(avant));

      await depotAvant.startSession(sessionId: 'session-1', startedAt: instant(1));
      await depotAvant.recordAnswer(
        sessionId: 'session-1',
        question: EntryTestBank.q1,
        rawAnswer: '7',
        correction: const EntryTestCorrection(isCorrect: true, isEvaluated: true),
        normalizedAnswer: '7',
        answeredAt: instant(2),
      );
      await depotAvant.recordAnswer(
        sessionId: 'session-1',
        question: EntryTestBank.q2,
        rawAnswer: '2/4',
        correction: const EntryTestCorrection(isCorrect: true, isEvaluated: true),
        normalizedAnswer: '2/4',
        answeredAt: instant(3),
      );

      // Fermeture.
      await avant.close();

      // Relance : NOUVELLE base, NOUVEAU depot sur le MEME fichier, comme
      // au demarrage de l'application.
      final AppDatabase apres = await ouvrirSurFichier(chemin);
      registerTestDatabase(apres);
      final EntryTestRepository apresRelance =
          EntryTestRepository(LearningEventRepository(apres));

      final EntryTestSession? relue = await apresRelance.loadSession('session-1');
      expect(relue, isNotNull, reason: 'la session doit survivre a la fermeture');

      expect(relue!.answeredCount, 2, reason: 'les reponses sont conservees');
      expect(relue.answerFor(EntryTestBank.q1.id)!.rawAnswer, '7');
      expect(relue.answerFor(EntryTestBank.q2.id)!.rawAnswer, '2/4');
      expect(relue.nextQuestion?.id, 'entry-q3');
      expect(relue.isCompleted, isFalse);
    });

    test('une session terminee n\'est pas rouverte', () async {
      await demarrer();
      for (final EntryTestQuestion q in EntryTestBank.questions) {
        await repondre(q, q.expectedValue, correct: true, evaluated: true);
      }
      await repo.completeSession(sessionId: 'session-1', completedAt: instant(99));

      final EntryTestSession session = (await repo.loadSession('session-1'))!;

      expect(session.isCompleted, isTrue);
      expect(session.state, EntryTestSessionState.completed);
      expect(session.completedAt, instant(99));
      expect(session.isReadyToComplete, isTrue);
      // Une session terminee n'a plus de question en attente : elle ne
      // propose pas de recommencer.
      expect(session.nextQuestion, isNull);
      expect(session.remainingCount, 0);
    });

    test('la derniere session demarree est retrouvable', () async {
      expect(await repo.findLatestSessionId(), isNull);
      await demarrer('session-1');
      expect(await repo.findLatestSessionId(), 'session-1');
    });

    test('une session conservee n\'est pas remplacee par une nouvelle', () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);

      // Quelqu'un demarre une session distincte : elle ne doit pas
      // disparaitre.
      await repo.startSession(sessionId: 'session-2', startedAt: instant(5));

      expect(await repo.loadSession('session-1'), isNotNull);
      expect(await repo.loadSession('session-2'), isNotNull);
    });
  });

  group('Isolation du chapitre 1', () {
    test('aucune reponse du test d\'entree ne cree d\'ObservedError',
        () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '6', correct: false, evaluated: true);
      await repondre(EntryTestBank.q2, 'inconnu',
          correct: false, evaluated: false);

      // Une reponse fausse et une reponse non evaluable ne doivent produire
      // AUCUNE erreur pedagogique : ce serait une fausse cause d'erreur,
      // definitive dans un historique append-only.
      expect(await db.select(db.observedErrors).get(), isEmpty);
      expect(await db.select(db.exerciseAttempts).get(), isEmpty);
      expect(await db.select(db.offeredHints).get(), isEmpty);
    });

    test('aucune notion du chapitre 1 n\'est rattachee', () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);

      expect(await db.select(db.eventNotions).get(), isEmpty);
    });

    test('les evenements sont lisibles par leur seul type', () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);

      // Le type d'evenement suffit a separer le test d'entree de toute
      // tentative du chapitre 1, sans requeterir quoi que ce soit d'autre.
      expect(
        (await events.findByType(EntryTestRepository.answerEventType)).length,
        1,
      );
      expect(
        await events.findByType('exercise_attempt'),
        isEmpty,
      );
    });

    test('le contexte d\'activite est renseigne sur chaque evenement',
        () async {
      await demarrer();
      await repondre(EntryTestBank.q1, '7', correct: true, evaluated: true);

      final List<dynamic> answers =
          await events.findByType(EntryTestRepository.answerEventType);
      expect(answers.first.context?.activityId, 'session-1');
      expect(answers.first.context?.activityType,
          EntryTestRepository.activityType);
    });
  });
}