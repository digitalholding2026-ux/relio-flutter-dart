/// Accès en écriture et en lecture aux NOTIONS du catalogue.
///
/// Le catalogue est un contenu de référence : il est modifiable, contrairement
/// aux événements d'apprentissage qui sont immuables.
library;

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../data/db/app_database.dart';
import '../../data/db/converters.dart';
import '../notion/notion.dart';

class NotionRepository {
  NotionRepository(AppDatabase db, {Clock clock = systemClockUtc})
      : _db = db,
        // ignore: prefer_initializing_formals
        _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// Insère ou met à jour une notion et ses prérequis, en une transaction.
  ///
  /// L'écriture est idempotente sur [Notion.id] : ré-enregistrer la même
  /// notion MET À JOUR la ligne au lieu d'en créer une seconde.
  Future<void> upsert(Notion notion) async {
    final now = _clock();
    await _db.transaction(() async {
      await _db
          .into(_db.notions)
          .insertOnConflictUpdate(notionToCompanion(notion, now: now));

      // Les prérequis sont remplacés intégralement : la row est un ensemble
      // déclaratif, pas un historique. On évite ainsi les liens fantômes.
      await (_db.delete(_db.notionPrerequisites)
            ..where((tbl) => tbl.notionId.equals(notion.id)))
          .go();
      for (final prerequisiteId in notion.prerequisiteIds) {
        await _db.into(_db.notionPrerequisites).insert(
              NotionPrerequisitesCompanion.insert(
                notionId: notion.id,
                prerequisiteId: prerequisiteId,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  /// Insère plusieurs notions en une seule transaction.
  Future<void> upsertAll(Iterable<Notion> notions) async {
    await _db.transaction(() async {
      for (final notion in notions) {
        await upsert(notion);
      }
    });
  }

  /// Lit une notion par son identifiant, ou `null` si absente.
  Future<Notion?> findById(String id) async {
    final row = await (_db.select(_db.notions)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _withPrerequisites(row);
  }

  /// Liste toutes les notions, triées par label.
  Future<List<Notion>> findAll() async {
    final rows = await (_db.select(_db.notions)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.label)]))
        .get();
    return [for (final row in rows) await _withPrerequisites(row)];
  }

  /// Liste les notions publiées, seules visibles des activités.
  Future<List<Notion>> findPublished() async {
    final rows = await (_db.select(_db.notions)
          ..where((tbl) => tbl.lifecycle.equals('published'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.label)]))
        .get();
    return [for (final row in rows) await _withPrerequisites(row)];
  }

  /// Supprime une notion ET ses prérequis.
  ///
  /// ⚠️ Opération réservée à la maintenance du catalogue. La suppression est
  /// refusée si des événements d'apprentissage la référencent, afin de ne
  /// jamais laisser d'historique orphelin. Pour retirer une notion du
  /// parcours, préférer `lifecycle: archived`.
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      final used = await (_db.selectOnly(_db.eventNotions)
            ..addColumns([_db.eventNotions.eventId])
            ..where(_db.eventNotions.notionId.equals(id))
            ..limit(1))
          .get();
      if (used.isNotEmpty) {
        throw StateError(
          'Impossible de supprimer la notion "$id" : elle est référencée par '
          'des événements d\'apprentissage. Archivez-la plutôt.',
        );
      }
      await (_db.delete(_db.notionPrerequisites)
            ..where((tbl) => tbl.notionId.equals(id)))
          .go();
      await (_db.delete(_db.notionPrerequisites)
            ..where((tbl) => tbl.prerequisiteId.equals(id)))
          .go();
      await (_db.delete(_db.notions)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// Recharge une notion avec ses prérequis.
  ///
  /// Deux requêtes par notion : suffisant à cette échelle, et le lot de
  /// prérequis sera mis en cache si le catalogue grandit.
  Future<Notion> _withPrerequisites(NotionRow row) async {
    final prereqs = await (_db.select(_db.notionPrerequisites)
          ..where((tbl) => tbl.notionId.equals(row.id)))
        .get();
    return row.toDomain(
      prerequisiteIds: prereqs.map((p) => p.prerequisiteId).toSet(),
    );
  }
}
