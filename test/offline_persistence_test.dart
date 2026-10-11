/// Tests de PERSISTANCE LOCALE et de FONCTIONNEMENT HORS LIGNE.
///
/// Ces tests utilisent une base SQLite RÉELLE sur disque (et non en
/// mémoire), afin de valider ce qui compte pour un appareil Android :
///  - les données d'apprentissage survivent à la fermeture du processus ;
///  - elles sont lisibles par une nouvelle connexion ;
///  - le rejeu hors ligne (scénario de reconnexion) ne duplique rien ;
///  - le stockage résiste à un usage volumineux.
///
/// Aucun accès réseau n'intervient : c'est le comportement attendu en
/// fonctionnement hors ligne.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/catalog/notion_catalog.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learning_event.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/notion/notion.dart';

import 'helpers/event_factory.dart';

void main() {
  late Directory tempDir;
  final openConnections = <AppDatabase>[];

  setUp(() {
    openConnections.clear();
    tempDir = Directory.systemTemp.createTempSync('relio_offline_test');
  });

  tearDown(() async {
    for (final db in openConnections) {
      await db.close();
    }
    openConnections.clear();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File dbFile() => File(p.join(tempDir.path, 'relio.sqlite'));

  AppDatabase open() {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile()));
    openConnections.add(db);
    return db;
  }

  group('Conservation sur disque', () {
    test('un evenement ecrit puis relu apres fermeture', () async {
      final first = open();
      final repo = LearningEventRepository(first);
      await repo.count();
      await repo.record(
        attemptEvent(
          id: 'e-1',
          notionIds: <String>['n-fractions'],
          attempt: sampleAttempt(
            outcome: AnswerOutcome.incorrect,
            error: sampleError(errorType: 'division_by_zero'),
            hint: sampleHint(),
          ),
        ),
      );

      // Fermeture complète, comme si le processus était tué.
      openConnections.remove(first);
      await first.close();

      final second = open();
      final reopened = LearningEventRepository(second);
      final found = await reopened.findById('e-1');

      expect(found, isNotNull, reason: 'la donnee survit hors ligne');
      expect(found!.occurredAt, kTestInstant);
      expect(found.notionIds, <String>['n-fractions']);
      expect(found.attempt!.outcome, AnswerOutcome.incorrect);
      expect(found.attempt!.error!.errorType, 'division_by_zero');
      expect(found.attempt!.hint!.hintId, 'h-1');
    });

    test('le catalogue de notions survit aussi', () async {
      final first = open();
      await NotionRepository(first).upsert(
        const Notion(id: 'n-1', label: 'Fractions'),
      );
      openConnections.remove(first);
      await first.close();

      final second = open();
      final notions = await NotionRepository(second).findAll();

      expect(notions, hasLength(1));
      expect(notions.single.label, 'Fractions');
    });
  });

  group('Rejeu hors ligne (reconnexion)', () {
    test('rejouer un lot hors ligne puis synchronise ne duplique rien',
        () async {
      // Scénario : l'élève travaille sans réseau, l'application enregistre
      // des événements, puis un rejeu du même lot survient.
      final db = open();
      final repo = LearningEventRepository(db);
      await repo.count();

      final batch = <LearningEvent>[
        for (var i = 0; i < 20; i++)
          attemptEvent(
            id: 'offline-$i',
            notionIds: <String>['n-fractions'],
            occurredAt: kTestInstant.add(Duration(minutes: i)),
          ),
      ];

      final firstPass = await repo.recordAll(batch);
      // Rejeu exact du même lot, comme après une reprise sur incident.
      final secondPass = await repo.recordAll(batch);
      final thirdPass = await repo.recordAll(batch);

      expect(firstPass, 20);
      expect(secondPass, 0, reason: 'aucun nouvel evenement au rejeu');
      expect(thirdPass, 0);
      expect(await repo.count(), 20, reason: 'pas de duplication');
    });

    test('le rejeu ne duplique pas les lignes filles', () async {
      final db = open();
      final repo = LearningEventRepository(db);
      await repo.count();

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

      expect((await db.select(db.eventNotions).get()), hasLength(2));
      expect((await db.select(db.exerciseAttempts).get()), hasLength(1));
      expect((await db.select(db.observedErrors).get()), hasLength(1));
      expect((await db.select(db.offeredHints).get()), hasLength(1));
    });
  });

  group('Stabilite du stockage', () {
    test('supporte un volume important d evenements', () async {
      final db = open();
      final repo = LearningEventRepository(db);
      await repo.count();

      final inserted = await repo.recordAll(<LearningEvent>[
        for (var i = 0; i < 500; i++)
          attemptEvent(
            id: 'bulk-$i',
            notionIds: <String>['n-${i % 5}'],
            occurredAt: kTestInstant.add(Duration(seconds: i)),
          ),
      ]);

      expect(inserted, 500);
      expect(await repo.count(), 500);
    });

    test('les lectures restent exactes apres un volume important', () async {
      final db = open();
      final repo = LearningEventRepository(db);
      await repo.count();
      await repo.recordAll(<LearningEvent>[
        for (var i = 0; i < 100; i++)
          attemptEvent(
            id: 'e-$i',
            notionIds: <String>['n-1'],
            occurredAt: kTestInstant.add(Duration(seconds: i)),
          ),
      ]);

      expect(await repo.findByNotion('n-1'), hasLength(100));
      expect(await repo.findByNotion('n-2'), isEmpty);
    });

    test('les bornes de resultat restent justes sur echantillon', () async {
      final db = open();
      final repo = LearningEventRepository(db);
      await repo.count();

      await repo.recordAll(<LearningEvent>[
        attemptEvent(
          id: 'correct-1',
          attempt: sampleAttempt(outcome: AnswerOutcome.correct),
        ),
        attemptEvent(
          id: 'incorrect-1',
          attempt: sampleAttempt(outcome: AnswerOutcome.incorrect),
        ),
        attemptEvent(
          id: 'not-evaluated-1',
          attempt: sampleAttempt(outcome: AnswerOutcome.notEvaluated),
        ),
        attemptEvent(
          id: 'abandoned-1',
          attempt: sampleAttempt(outcome: AnswerOutcome.abandoned),
        ),
      ]);

      final outcomes = (await repo.findAll())
          .map((e) => e.attempt?.outcome)
          .whereType<AnswerOutcome>()
          .toSet();

      expect(outcomes, contains(AnswerOutcome.correct));
      expect(outcomes, contains(AnswerOutcome.incorrect));
      expect(outcomes, contains(AnswerOutcome.notEvaluated));
      expect(outcomes, contains(AnswerOutcome.abandoned));
    });
  });
}
