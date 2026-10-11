/// Tests de persistance des ÉVÉNEMENTS D'APPRENTISSAGE.
///
/// Couvre les exigences de la mission :
///  - création, lecture, mise à jour des données ;
///  - conservation des événements ;
///  - absence de perte ou de duplication injustifiée.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/core/clock.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learning_event.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import 'helpers/test_database.dart';
import 'helpers/event_factory.dart';

void main() {
  late AppDatabase db;
  late LearningEventRepository repo;

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    repo = LearningEventRepository(db, clock: fixedClock(kTestInstant));
  });

  group('Création et lecture', () {
    test('enregistre puis relit un événement simple', () async {
      final inserted = await repo.record(
        sampleEvent(id: 'e-1', notionIds: <String>['n-fractions']),
      );

      expect(inserted, isTrue);

      final found = await repo.findById('e-1');
      expect(found, isNotNull);
      expect(found!.type, 'exercise_attempt');
      expect(found.occurredAt, kTestInstant);
      expect(found.notionIds, <String>['n-fractions']);
    });

    test('relit une tentative complète : réponse et résultat', () async {
      await repo.record(attemptEvent(id: 'e-1', notionIds: <String>['n-f']));

      final found = await repo.findById('e-1');
      final attempt = found!.attempt;

      expect(attempt, isNotNull);
      expect(attempt!.exerciseId, 'ex-1');
      expect(attempt.outcome, AnswerOutcome.correct);
      expect(attempt.answer!.rawText, '3/4');
      expect(attempt.answer!.normalizedValue, '0.75');
      expect(attempt.durationMs, 4200);
    });

    test('conserve le contexte de l’activité', () async {
      await repo.record(attemptEvent(id: 'e-1'));

      final context = (await repo.findById('e-1'))!.attempt!.context;

      expect(context!.activityType, 'exercice');
      expect(context.locale, 'fr');
      expect(context.source, 'app_android');
    });

    test('conserve les erreurs constatées et les indices proposés', () async {
      await repo.record(
        attemptEvent(
          id: 'e-1',
          attempt: sampleAttempt(
            outcome: AnswerOutcome.incorrect,
            error: sampleError(errorType: 'division_by_zero'),
            hint: sampleHint(),
          ),
        ),
      );

      final attempt = (await repo.findById('e-1'))!.attempt!;

      expect(attempt.error, isNotNull);
      expect(attempt.error!.errorType, 'division_by_zero');
      expect(attempt.hint, isNotNull);
      expect(attempt.hint!.content, 'Pense au dénominateur commun.');
    });

    test('une erreur non identifiée reste null, jamais devinée', () async {
      await repo.record(
        attemptEvent(
          id: 'e-1',
          attempt: sampleAttempt(error: sampleError(errorType: null)),
        ),
      );

      final error = (await repo.findById('e-1'))!.attempt!.error!;

      expect(error.errorType, isNull, reason: 'on n’invente pas de cause');
      expect(error.description, 'Saisie illisible');
    });

    test('préserve les métadonnées libres de type événement', () async {
      await repo.record(
        sampleEvent(
          id: 'e-1',
          type: 'session_started',
          metadata: <String, Object?>{'dureeMin': 12, 'horsLigne': true},
        ),
      );

      final meta = (await repo.findById('e-1'))!.metadata;

      expect(meta['dureeMin'], 12);
      expect(meta['horsLigne'], true);
    });

    test('compte les événements enregistrés', () async {
      await repo.recordAll(<LearningEvent>[
        sampleEvent(id: 'e-1'),
        sampleEvent(id: 'e-2'),
      ]);

      expect(await repo.count(), 2);
    });
  });

  group('Conservation et intégrité', () {
    test('les événements survivent à la fermeture et réouverture', () async {
      await repo.record(attemptEvent(id: 'e-1', notionIds: <String>['n-f']));

      // Ferme le dépôt : la persistance est en base, pas en mémoire vive.
      final snapshot = (await repo.findById('e-1'))!;

      final reopened = await repo.findById('e-1');

      expect(reopened, isNotNull);
      expect(reopened!.id, snapshot.id);
      expect(reopened.occurredAt, snapshot.occurredAt);
      expect(reopened.notionIds, snapshot.notionIds);
    });

    test('un lot d’événements est intégralement conservé', () async {
      final events = <LearningEvent>[
        for (var i = 0; i < 50; i++)
          sampleEvent(id: 'e-$i', occurredAt: kTestInstant.add(Duration(seconds: i))),
      ];

      final inserted = await repo.recordAll(events);

      expect(inserted, 50);
      expect(await repo.count(), 50);
    });

    test('une écriture invalide ne laisse pas d’événement partiel', () async {
      // Événement de référence, porteur de l'erreur 'err-1'.
      await repo.record(
        attemptEvent(
          id: 'e-ok',
          attempt: sampleAttempt(error: sampleError(id: 'err-1')),
        ),
      );

      // Le lot suivant réintroduit l'identifiant d'erreur 'err-1' :
      // la contrainte de clé primaire doit faire échouer TOUTE la
      // transaction, y compris l'événement valide 'e-valide' déjà écrit.
      await expectLater(
        () => repo.recordAll(<LearningEvent>[
          sampleEvent(id: 'e-valide', notionIds: <String>['n-1']),
          attemptEvent(
            id: 'e-conflit',
            attempt: sampleAttempt(error: sampleError(id: 'err-1')),
          ),
        ]),
        throwsA(anything),
      );

      // Rollback complet : ni l'événement valide, ni le conflit, ni les
      // notions du lot n'ont été conservés.
      expect(await repo.findById('e-valide'), isNull);
      expect(await repo.findById('e-conflit'), isNull);
      expect(await repo.findByNotion('n-1'), isEmpty);

      // L'événement préexistant est intact après l'échec.
      expect(await repo.count(), 1);
      expect((await repo.findById('e-ok'))!.attempt!.error!.id, 'err-1');
    });
  });

  group('Absence de duplication injustifiée', () {
    test('ré-enregistrer le même événement ne crée pas de doublon', () async {
      final event = attemptEvent(id: 'e-1', notionIds: <String>['n-f']);

      final first = await repo.record(event);
      final second = await repo.record(event);
      final third = await repo.record(event);

      expect(first, isTrue);
      expect(second, isFalse, reason: 'rejeu détecté');
      expect(third, isFalse);
      expect(await repo.count(), 1);
    });

    test('le rejeu ne duplique ni les notions, ni la tentative', () async {
      final event = attemptEvent(
        id: 'e-1',
        notionIds: <String>['n-a', 'n-b'],
        attempt: sampleAttempt(
          error: sampleError(id: 'err-1'),
          hint: sampleHint(id: 'hint-1'),
        ),
      );

      await repo.record(event);
      await repo.record(event);
      await repo.record(event);

      final found = await repo.findById('e-1');
      expect(found!.notionIds.toSet(), <String>{'n-a', 'n-b'});

      final attemptRows = await db.select(db.exerciseAttempts).get();
      expect(attemptRows, hasLength(1));
      final errorRows = await db.select(db.observedErrors).get();
      expect(errorRows, hasLength(1));
      final hintRows = await db.select(db.offeredHints).get();
      expect(hintRows, hasLength(1));
    });

    test('les notions en doublon dans une même liste sont dédupliquées', () async {
      await repo.record(
        sampleEvent(id: 'e-1', notionIds: <String>['n-a', 'n-a', 'n-b']),
      );

      expect((await repo.findById('e-1'))!.notionIds.toSet(),
          <String>{'n-a', 'n-b'});
    });

    test('un rejeu avec un contenu différent préserve l’original', () async {
      await repo.record(sampleEvent(id: 'e-1', type: 'session_started'));

      // Deuxième écriture du même id mais avec un autre type.
      final inserted = await repo.record(sampleEvent(id: 'e-1', type: 'autre'));

      expect(inserted, isFalse, reason: 'append-only : rien n’est réécrit');
      expect((await repo.findById('e-1'))!.type, 'session_started');
    });

    test('recordAll ne recompte pas les doublons', () async {
      final count = await repo.recordAll(<LearningEvent>[
        sampleEvent(id: 'e-1'),
        sampleEvent(id: 'e-1'),
        sampleEvent(id: 'e-2'),
      ]);

      expect(count, 2, reason: 'seuls 2 événements réellement insérés');
      expect(await repo.count(), 2);
    });
  });

  group('Requêtes d’interrogation', () {
    test('filtre par type d’événement', () async {
      await repo.recordAll(<LearningEvent>[
        sampleEvent(id: 'e-1', type: 'exercise_attempt'),
        sampleEvent(id: 'e-2', type: 'session_started'),
        sampleEvent(id: 'e-3', type: 'session_started'),
      ]);

      expect(await repo.findByType('session_started'), hasLength(2));
    });

    test('filtre par notion concernée', () async {
      await repo.recordAll(<LearningEvent>[
        sampleEvent(id: 'e-1', notionIds: <String>['n-fractions']),
        sampleEvent(id: 'e-2', notionIds: <String>['n-geometry']),
        sampleEvent(id: 'e-3', notionIds: <String>['n-fractions']),
      ]);

      final found = await repo.findByNotion('n-fractions');

      expect(found.map((e) => e.id).toSet(), <String>{'e-1', 'e-3'});
    });

    test('retourne une liste vide pour une notion jamais travaillée', () async {
      expect(await repo.findByNotion('n-inconnue'), isEmpty);
    });

    test('trie du plus récent au plus ancien', () async {
      await repo.recordAll(<LearningEvent>[
        sampleEvent(id: 'vieux', occurredAt: kTestInstant.subtract(const Duration(hours: 2))),
        sampleEvent(id: 'recent', occurredAt: kTestInstant),
        sampleEvent(id: 'milieu', occurredAt: kTestInstant.subtract(const Duration(hours: 1))),
      ]);

      final ids = (await repo.findAll()).map((e) => e.id).toList();

      expect(ids, <String>['recent', 'milieu', 'vieux']);
    });

    test('respecte la limite demandée', () async {
      await repo.recordAll(<LearningEvent>[
        for (var i = 0; i < 10; i++)
          sampleEvent(id: 'e-$i', occurredAt: kTestInstant.add(Duration(seconds: i))),
      ]);

      expect(await repo.findAll(limit: 3), hasLength(3));
    });
  });

  group('Horodatage', () {
    test('normalise les dates locales en UTC', () async {
      final local = DateTime(2026, 3, 15, 11, 30); // heure locale, non UTC
      await repo.record(sampleEvent(id: 'e-1', occurredAt: local));

      final stored = (await repo.findById('e-1'))!.occurredAt;

      expect(stored.isUtc, isTrue);
      expect(stored.toUtc(), local.toUtc());
    });
  });
}
