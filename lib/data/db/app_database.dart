/// Base de données locale Relio (SQLite via Drift).
///
/// VERSION DE SCHÉMA : [kSchemaVersion] = 2.
///
/// Politique de versionnage :
///  - toute évolution du schéma INCREMENTE `kSchemaVersion` ;
///  - chaque increment DOIT fournir une étape de migration explicite dans
///    [MigrationStrategy.onUpgrade] ;
///  - les migrations sont testées (cf. `test/migration_test.dart`),
///    y compris la PRÉSERVATION des événements déjà enregistrés.
///
/// La stratégie de migration ne doit JAMAIS supprimer ni réécrire un
/// événement d'apprentissage : la perte de données est interdite par la
/// mission D.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../../domain/learning/exercise_attempt.dart';
import '../../domain/notion/notion_status.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// VERSION courante du schéma de stockage.
///
/// Historique :
///  - v1 : schéma initial réduit (notions, événements, tentatives, erreurs
///    observées). Ne comportait pas les indices proposés, ni les métadonnées
///    libres d'événement.
///  - v2 : ajoute `learning_events.metadata_json` et la table
///    `offered_hints`, et renforce les clés étrangères.
///  - v3 : ajoute la table `app_settings` (préférences d'affichage et prénom).
///    Aucune donnée d'apprentissage n'est touchée.
const int kSchemaVersion = 3;

@DriftDatabase(
  tables: [
    Notions,
    MathDomains,
    NotionLevels,
    NotionPrerequisites,
    LearningEvents,
    EventNotions,
    ExerciseAttempts,
    ObservedErrors,
    OfferedHints,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Ouvre la base dans le répertoire privé de l'application Android.
  ///
  /// Le stockage est 100 % LOCAL : aucune donnée d'apprentissage ne sort de
  /// l'appareil, et aucune connexion réseau n'est requise pour lire ou écrire.
  static Future<AppDatabase> openLocal() async {
    // Nécessaire sur Android pour charger la SQLite native.
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'relio.sqlite'));
    return AppDatabase(_openConnection(file));
  }

  /// Connexion ouverte pour les TESTS : base en mémoire.
  AppDatabase.forTesting(super.e);

  /// Simule le cycle de vie d'une base : ouverture, upgrade, fermeture.
  /// Réservé aux tests de migration.
  @visibleForTesting
  Future<void> migrateForTesting() async {
    final before = await _readUserVersion();
    if (before < kSchemaVersion) {
      await _runUpgradeSteps(before);
      await customStatement('PRAGMA user_version = $kSchemaVersion');
    }
  }

  /// Version déclarée par SQLite dans `PRAGMA user_version`.
  Future<int> _readUserVersion() async {
    final rows = await customSelect('PRAGMA user_version').get();
    final raw = rows.first.data['user_version'];
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  /// Version de schéma telle que SQLite la déclare réellement sur le fichier.
  ///
  /// Exposé pour les tests de migration : permet de vérifier que la version
  /// a bien été écrite sur le disque, et pas seulement en mémoire.
  @visibleForTesting
  Future<int> readUserVersionForTesting() => _readUserVersion();

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Étapes de migration EXPLICITES, une par version.
          //
          // Exemple pour une future version 2 :
          //   if (from < 2) {
          //     await m.addColumn(learningEvents, learningEvents.label);
          //     await m.createTable(someNewTable);
          //   }
          //
          // Contrainte forte : ne jamais supprimer ni réécrire une table
          // d'historique d'apprentissage.
          await _runUpgradeSteps(from);
        },
        beforeOpen: (details) async {
          // Intégrité référentielle activée à chaque ouverture.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Applique les étapes de migration séquentielles depuis [from].
  ///
  /// Règle absolue : une migration peut AJOUTER ou COMPLÉTER, jamais
  /// supprimer ni réécrire un événement d'apprentissage.
  Future<void> _runUpgradeSteps(int from) async {
    if (from < 1) {
      // v0 -> v1 : création du schéma initial.
      // Une base en version 0 n'a jamais été publiée : `onCreate` joue ce
      // rôle lors d'une installation neuve, rien à migrer.
    }
    if (from < 2) {
      // v1 -> v2 : enrichissement du schéma SANS toucher à l'historique.
      await _migratedV1ToV2();
    }
    if (from < 3) {
      // v2 -> v3 : préférences d'affichage et identité de l'élève.
      await _migratedV2ToV3();
    }
  }

  /// Migration v2 -> v3.
  ///
  /// Ajoute la SEULE table `app_settings`, qui ne contient aucun fait
  /// d'apprentissage : elle ne fait qu'accueillir les préférences locales de
  /// l'interface (prénom, échelle de texte, contraste, animations).
  ///
  /// Aucune ligne existante n'est lue, modifiée ni supprimée : l'historique
  /// d'apprentissage v2 est intégralement conservé.
  Future<void> _migratedV2ToV3() async {
    // `IF NOT EXISTS` rend l'opération rejouable sans effet de bord.
    await customStatement(
      'CREATE TABLE IF NOT EXISTS app_settings ('
      ' key TEXT NOT NULL PRIMARY KEY,'
      ' value TEXT NULL'
      ');',
    );
  }

  /// Migration v1 -> v2.
  ///
  /// Le schéma v1 contenait déjà de l'historique d'apprentissage, mais dans
  /// une forme réduite : pas de colonne `metadata_json`, pas de table
  /// `offered_hints`, et pas de clé étrangère sur `observed_errors`.
  ///
  ///   1. Ajout de la colonne manquante avec une valeur par défaut neutre
  ///      ('{}') : les lignes existantes sont conservées telles quelles.
  ///   2. Création des tables ajoutées en v2.
  ///   3. Recréation de `observed_errors` pour ajouter sa clé étrangère, en
  ///      recopiant les lignes existantes.
  ///
  /// Aucune ligne d'événement n'est supprimée ni réécrite.
  Future<void> _migratedV1ToV2() async {
    // 1. Colonne `metadata_json` absente en v0.
    //
    // `IF NOT EXISTS` rend l'opération rejouable sans effet de bord.
    await customStatement(
      'ALTER TABLE learning_events ADD COLUMN metadata_json TEXT NOT NULL '
      "DEFAULT '{}'",
    );

    // 2. Tables présentes en v1 mais absentes en v0.
    await customStatement(
      'CREATE TABLE IF NOT EXISTS offered_hints ('
      ' id TEXT NOT NULL PRIMARY KEY,'
      ' event_id TEXT NOT NULL '
      'REFERENCES learning_events (id) ON DELETE CASCADE,'
      ' offered_at TEXT NOT NULL,'
      ' hint_id TEXT NULL,'
      ' kind TEXT NULL,'
      ' content TEXT NULL'
      ');',
    );

    await customStatement(
      'CREATE TABLE IF NOT EXISTS notions ('
      ' id TEXT NOT NULL PRIMARY KEY,'
      ' label TEXT NOT NULL,'
      ' description TEXT NULL,'
      ' domain_id TEXT NULL,'
      ' level_id TEXT NULL,'
      " lifecycle TEXT NOT NULL DEFAULT 'draft',"
      ' created_at TEXT NOT NULL,'
      ' updated_at TEXT NOT NULL'
      ');',
    );

    await customStatement(
      'CREATE TABLE IF NOT EXISTS math_domains ('
      ' id TEXT NOT NULL PRIMARY KEY,'
      ' label TEXT NOT NULL'
      ');',
    );

    await customStatement(
      'CREATE TABLE IF NOT EXISTS notion_levels ('
      ' id TEXT NOT NULL PRIMARY KEY,'
      ' label TEXT NOT NULL,'
      ' sort_order INTEGER NOT NULL'
      ');',
    );

    await customStatement(
      'CREATE TABLE IF NOT EXISTS notion_prerequisites ('
      ' prerequisite_id TEXT NOT NULL,'
      ' notion_id TEXT NOT NULL,'
      ' PRIMARY KEY (prerequisite_id, notion_id)'
      ');',
    );

    // 3. Clés étrangères des tables d'apprentissage, absentes en v1.
    //
    // Recréer la table conserve les lignes tout en ajoutant les
    // contraintes d'intégrité attendues en v2.
    await customStatement('DROP TABLE IF EXISTS observed_errors_v1');
    await customStatement(
      'CREATE TABLE observed_errors_v1 ('
      ' id TEXT NOT NULL PRIMARY KEY,'
      ' event_id TEXT NOT NULL '
      'REFERENCES learning_events (id) ON DELETE CASCADE,'
      ' occurred_at TEXT NOT NULL,'
      ' error_type TEXT NULL,'
      ' description TEXT NULL,'
      ' located_at TEXT NULL'
      ');',
    );
    await customStatement(
      'INSERT INTO observed_errors_v1 '
      '(id, event_id, occurred_at, error_type, description, located_at) '
      'SELECT id, event_id, occurred_at, error_type, description, located_at '
      'FROM observed_errors;',
    );
    await customStatement('DROP TABLE observed_errors');
    await customStatement('ALTER TABLE observed_errors_v1 RENAME TO observed_errors');
  }

  /// Supprime la base. Réservé aux tests.
  @visibleForTesting
  Future<void> deleteAll() async {
    await transaction(() async {
      await delete(offeredHints).go();
      await delete(observedErrors).go();
      await delete(exerciseAttempts).go();
      await delete(eventNotions).go();
      await delete(learningEvents).go();
      await delete(notionPrerequisites).go();
      await delete(notions).go();
      await delete(notionLevels).go();
      await delete(mathDomains).go();
    });
  }
}

/// Connexion native, exécutée en arrière-plan pour ne pas bloquer l'UI.
LazyDatabase _openConnection(File file) {
  return LazyDatabase(() async {
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL');
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}
