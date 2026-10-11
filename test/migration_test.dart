/// Tests de VERSIONNAGE et de MIGRATION du schéma.
///
/// Objectifs (mission D) :
///  - vérifier que le schéma s'applique proprement sur une base neuve ;
///  - vérifier qu'une base ancienne est migrée vers la version courante ;
///  - vérifier que les DONNÉES D'APPRENTISSAGE sont conservées pendant et
///    après une migration ;
///  - vérifier que la migration est idempotente (rejouable sans effet de bord) ;
///  - vérifier que les contraintes d'intégrité attendues existent réellement
///    en base, et ne sont pas seulement déclarées en Dart.
library;

import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import 'helpers/event_factory.dart';

void main() {
  late Directory tempDir;
  final openConnections = <AppDatabase>[];

  setUp(() {
    openConnections.clear();
    tempDir = Directory.systemTemp.createTempSync('relio_migration_test');
  });

  tearDown(() async {
    // Toutes les bases sont fermées AVANT la suppression du dossier :
    // sous Windows, un fichier ouvert verrouille le répertoire.
    for (final db in openConnections) {
      await db.close();
    }
    openConnections.clear();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File dbFile() => File(p.join(tempDir.path, 'relio.sqlite'));

  /// Ouvre la base de fichier SANS appliquer la migration.
  ///
  /// La connexion est enregistrée afin d'être fermée en `tearDown`.
  AppDatabase openRaw() {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile()));
    openConnections.add(db);
    return db;
  }

  /// Connexion SQLite brute, pour écrire un schéma qui n'appartient à
  /// aucune version de Relio (schéma hérité).
  Future<drift.QueryExecutor> rawConnection() async {
    final raw = NativeDatabase(dbFile());
    await raw.ensureOpen(const _TestUser());
    return raw;
  }

  group('Schema et migrations', () {
    test('la version courante du schema est bien 2', () {
      final db = openRaw();
      expect(db.schemaVersion, kSchemaVersion);
      expect(kSchemaVersion, 2);
    });

    test('cree toutes les tables attendues sur une base neuve', () async {
      final db = openRaw();
      await db.migrateForTesting();

      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final tables = rows.map((r) => r.data['name'] as String).toSet();

      expect(tables, containsAll(<String>[
        'notions',
        'math_domains',
        'notion_levels',
        'notion_prerequisites',
        'learning_events',
        'event_notions',
        'exercise_attempts',
        'observed_errors',
        'offered_hints',
      ]));
    });

    test('declare les cles primaires attendues', () async {
      final db = openRaw();
      await db.migrateForTesting();

      Future<String> sqlFor(String table) async {
        final rows = await db
            .customSelect(
              "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
              variables: <drift.Variable<Object>>[
                drift.Variable<String>(table),
              ],
            )
            .get();
        return rows.first.data['sql'] as String;
      }

      // Les cles primaires sont la base de l'idempotence : sans elles,
      // rien n'empeche les doublons.
      expect(await sqlFor('learning_events'), contains('PRIMARY KEY'));
      expect(await sqlFor('event_notions'), contains('PRIMARY KEY'));
      expect(await sqlFor('exercise_attempts'), contains('PRIMARY KEY'));
      expect(await sqlFor('observed_errors'), contains('PRIMARY KEY'));
      expect(await sqlFor('offered_hints'), contains('PRIMARY KEY'));
    });
  });

  group('Migration depuis une version anterieure', () {
    /// Reproduit une base creee par Relio v1, contenant deja des evenements
    /// d'apprentissage.
    ///
    /// Le schema v1 etait plus simple : pas de colonne `metadata_json`, pas
    /// de table `offered_hints`, et pas de cle etrangere sur
    /// `observed_errors`. On verifie ensuite que la migration vers v2
    /// preserve integralement l'historique.
    Future<void> seedLegacyDatabase() async {
      final raw = await rawConnection();
      final ts = kTestInstant.toIso8601String();

      raw.runCustom(
        'CREATE TABLE learning_events ('
        ' id TEXT NOT NULL PRIMARY KEY,'
        ' type TEXT NOT NULL,'
        ' occurred_at TEXT NOT NULL,'
        ' context_json TEXT NULL,'
        ' recorded_at TEXT NOT NULL'
        ');',
      );
      raw.runCustom(
        'CREATE TABLE event_notions ('
        ' event_id TEXT NOT NULL,'
        ' notion_id TEXT NOT NULL,'
        ' PRIMARY KEY (event_id, notion_id)'
        ');',
      );
      raw.runCustom(
        'CREATE TABLE exercise_attempts ('
        ' event_id TEXT NOT NULL PRIMARY KEY,'
        ' exercise_id TEXT NOT NULL,'
        ' started_at TEXT NOT NULL,'
        ' submitted_at TEXT NULL,'
        ' outcome TEXT NOT NULL,'
        ' answer_id TEXT NULL,'
        ' answer_raw TEXT NULL,'
        ' answer_normalized TEXT NULL,'
        ' answer_empty INTEGER NOT NULL,'
        ' duration_ms INTEGER NULL'
        ');',
      );
      raw.runCustom(
        'CREATE TABLE observed_errors ('
        ' id TEXT NOT NULL PRIMARY KEY,'
        ' event_id TEXT NOT NULL,'
        ' occurred_at TEXT NOT NULL,'
        ' error_type TEXT NULL,'
        ' description TEXT NULL,'
        ' located_at TEXT NULL'
        ');',
      );

      // Donnees d'apprentissage preexistantes.
      raw.runCustom(
        "INSERT INTO learning_events "
        "(id, type, occurred_at, context_json, recorded_at) "
        "VALUES ('legacy-1', 'exercise_attempt', '$ts', NULL, '$ts');",
      );
      raw.runCustom(
        "INSERT INTO event_notions (event_id, notion_id) "
        "VALUES ('legacy-1', 'n-legacy');",
      );
      raw.runCustom(
        'INSERT INTO exercise_attempts '
        '(event_id, exercise_id, started_at, submitted_at, outcome, '
        ' answer_id, answer_raw, answer_normalized, answer_empty, duration_ms) '
        "VALUES ('legacy-1', 'ex-legacy', '$ts', NULL, 'correct', "
        "'a-1', '42', '42', 0, 1200);",
      );

      // La base heritee se declare en version 1.
      raw.runCustom('PRAGMA user_version = 1');
      await raw.close();
    }

    /// Lit `PRAGMA user_version` sur une connexion brute.
    Future<int> readRawUserVersion() async {
      final raw = await rawConnection();
      final rows = await raw.runSelect('PRAGMA user_version', <Object?>[]);
      final version = rows.first.values.first;
      await raw.close();
      return version as int;
    }

    test('la base heritee est bien en version 1', () async {
      await seedLegacyDatabase();
      expect(await readRawUserVersion(), 1);
    });

    test('migre une base heritee et conserve les evenements', () async {
      await seedLegacyDatabase();

      // L'ouverture via Drift applique la migration automatiquement.
      final db = openRaw();
      final repo = LearningEventRepository(db);
      await repo.count();

      expect(await db.readUserVersionForTesting(), kSchemaVersion);

      final migrated = await repo.findById('legacy-1');

      expect(migrated, isNotNull, reason: 'AUCUNE perte de donnees');
      expect(migrated!.type, 'exercise_attempt');
      expect(migrated.occurredAt, kTestInstant);
      expect(migrated.notionIds, <String>['n-legacy']);

      final attempt = migrated.attempt!;
      expect(attempt.exerciseId, 'ex-legacy');
      expect(attempt.answer!.rawText, '42');
      expect(attempt.durationMs, 1200);
      expect(await repo.count(), 1);
    });

    test('la migration est idempotente', () async {
      await seedLegacyDatabase();
      final db = openRaw();
      await LearningEventRepository(db).count();

      final afterFirst = await db.readUserVersionForTesting();

      // Rejouer la migration ne doit rien changer ni rien perdre.
      await db.migrateForTesting();
      await db.migrateForTesting();

      expect(await db.readUserVersionForTesting(), afterFirst);
      expect(
        await LearningEventRepository(db).count(),
        1,
        reason: 'aucun doublon cree par un rejeu de migration',
      );
    });

    test('les contraintes sont actives APRES migration', () async {
      await seedLegacyDatabase();
      final db = openRaw();
      await LearningEventRepository(db).count();

      // La cle primaire doit desormais rejeter les doublons.
      await expectLater(
        () => db.customStatement(
          "INSERT INTO learning_events (id, type, occurred_at, context_json, "
          "metadata_json, recorded_at) VALUES ('legacy-1', 'x', "
          "'2026-03-15T09:30:00.000Z', NULL, '{}', "
          "'2026-03-15T09:30:00.000Z');",
        ),
        throwsA(anything),
      );
    });

    test('les donnees restent lisibles apres fermeture et reouverture',
        () async {
      await seedLegacyDatabase();
      final first = openRaw();
      final repo = LearningEventRepository(first);
      await repo.count();
      await repo.record(sampleEvent(id: 'neuf-1', notionIds: <String>['n-x']));

      // Fermeture explicite : retiree du registre pour eviter une double
      // fermeture dans `tearDown`.
      openConnections.remove(first);
      await first.close();

      // Nouvelle connexion : les donnees sont relues depuis le fichier.
      final second = openRaw();
      final reopened = LearningEventRepository(second);

      expect(await reopened.count(), 2);
      expect(await reopened.findById('legacy-1'), isNotNull);
      expect(await reopened.findById('neuf-1'), isNotNull);
    });
  });
}

/// Utilisateur Drift minimal requis par `ensureOpen` sur une connexion brute.
///
/// `schemaVersion` vaut 1 : c'est la version de la base héritée, et Drift
/// réécrit `PRAGMA user_version` à l'ouverture en s'appuyant dessus.
class _TestUser implements drift.QueryExecutorUser {
  const _TestUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    drift.QueryExecutor e,
    drift.OpeningDetails details,
  ) async {}
}
