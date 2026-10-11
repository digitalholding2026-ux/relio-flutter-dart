/// Dépôt et consultation des ÉVÉNEMENTS D'APPRENTISSAGE.
///
/// Invariants garantis par ce dépôt :
///
///  1. **APPEND-ONLY** — aucune méthode de modification ou de suppression
///     n'est exposée. Un événement enregistré est immuable.
///
///  2. **IDEMPOTENCE** — [record] utilise `insertOrIgnore` sur la clé
///     primaire `id`. Réjouer le même événement (reconnexion, double
///     appel, reprise après redémarrage) ne crée PAS de doublon.
///
///  3. **ATOMICITÉ** — un événement et ses enfants (notions, tentative,
///     erreur, indice) sont écrits dans UNE transaction. Soit tout est
///     enregistré, soit rien ne l'est : pas d'événement partiel.
///
///  4. **HORODATAGE UTC** — toutes les dates sont normalisées en UTC à
///     l'écriture, pour que l'ordre chronologique survive au changement
///     de fuseau de l'appareil.
library;

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../data/db/app_database.dart';
import '../../data/db/converters.dart';
import 'exercise_attempt.dart';
import 'learning_event.dart';

class LearningEventRepository {
  LearningEventRepository(AppDatabase db, {Clock clock = systemClockUtc})
      : _db = db,
        // ignore: prefer_initializing_formals
        _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// Enregistre un événement d'apprentissage et toutes ses données liées.
  ///
  /// Retourne `true` si l'événement a réellement été inséré, `false` s'il
  /// existait déjà (rejeu). Ce retour permet à l'appelant de détecter un
  /// doublon sans avoir à le/deviner.
  ///
  /// Si le même `id` est présenté avec un contenu DIFFÉRENT, l'événement
  /// existant est conservé tel quel (append-only) et `false` est retourné :
  /// on ne réécrit jamais l'historique.
  Future<bool> record(LearningEvent event) async {
    var inserted = false;
    await _db.transaction(() async {
      inserted = await _insertEvent(event);
    });
    return inserted;
  }

  /// Enregistre un lot d'événements dans une transaction unique.
  ///
  /// Retourne le nombre d'événements RÉELLEMENT insérés (les doublons ne
  /// sont pas comptés).
  Future<int> recordAll(Iterable<LearningEvent> events) async {
    var inserted = 0;
    await _db.transaction(() async {
      for (final event in events) {
        if (await _insertEvent(event)) inserted++;
      }
    });
    return inserted;
  }

  Future<bool> _insertEvent(LearningEvent event) async {
    // Vérification d'existence explicite AVANT écriture.
    //
    // `insertOrIgnore` ne signale pas de façon fiable l'insertion ignorée
    // (Drift renvoie le dernier rowid, non nul même en cas d'ignoré).
    // Ce contrôle est fait dans la transaction, donc atomique vis-à-vis
    // des autres écritures : c'est ce qui rend `record` réellement
    // idempotent.
    final existing = await (_db.selectOnly(_db.learningEvents)
          ..addColumns([_db.learningEvents.id])
          ..where(_db.learningEvents.id.equals(event.id))
          ..limit(1))
        .get();
    if (existing.isNotEmpty) {
      // Doublon : l'événement d'origine est conservé tel quel.
      // L'historique n'est JAMAIS réécrit.
      return false;
    }

    // Le contexte est résolu AVANT insertion.
    //
    // Il peut être porté par l'événement lui-même OU par sa tentative.
    // On privilégie celui de l'événement et l'on retombe sur celui de la
    // tentative : sans cela, le contexte d'une tentative serait
    // silencieusement perdu, puisque l'événement ne le porte pas toujours.
    final resolvedContext = event.context ?? event.attempt?.context;

    await _db.into(_db.learningEvents).insert(
          learningEventToCompanion(
            event,
            recordedAt: _clock(),
            contextOverride: resolvedContext,
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Notions concernées (table de liaison many-to-many).
    //
    // Insertion STRICTE (pas `insertOrIgnore`) : les lignes filles sont
    // ajoutées uniquement quand l'événement est neuf, donc tout doublon
    // ici traduirait une incohérence réelle qui doit remonter et faire
    // échouer la transaction, plutôt que d'être masquée.
    for (final notionId in event.notionIds.toSet()) {
      await _db.into(_db.eventNotions).insert(
            EventNotionsCompanion.insert(
              eventId: event.id,
              notionId: notionId,
            ),
          );
    }

    final attempt = event.attempt;
    if (attempt != null) {
      final answer = attempt.answer;
      await _db.into(_db.exerciseAttempts).insert(
            ExerciseAttemptsCompanion.insert(
              eventId: event.id,
              exerciseId: attempt.exerciseId,
              startedAt: attempt.startedAt,
              submittedAt: Value(attempt.submittedAt),
              outcome: Value(attempt.outcome),
              answerId: Value(answer?.answerId),
              answerRaw: Value(answer?.rawText),
              answerNormalized: Value(answer?.normalizedValue),
              answerEmpty: Value(answer?.isEmpty ?? false),
              durationMs: Value(attempt.durationMs),
            ),
          );

      final error = attempt.error;
      if (error != null) {
        await _db.into(_db.observedErrors).insert(
              ObservedErrorsCompanion.insert(
                id: error.id,
                eventId: event.id,
                occurredAt: error.occurredAt,
                errorType: Value(error.errorType),
                description: Value(error.description),
                locatedAt: Value(error.locatedAt),
              ),
            );
      }

      final hint = attempt.hint;
      if (hint != null) {
        await _db.into(_db.offeredHints).insert(
              OfferedHintsCompanion.insert(
                id: hint.id,
                eventId: event.id,
                offeredAt: hint.offeredAt,
                hintId: Value(hint.hintId),
                kind: Value(hint.kind),
                content: Value(hint.content),
              ),
            );
      }
    }

    return true;
  }

  /// Lit un événement par son identifiant, `null` si absent.
  Future<LearningEvent?> findById(String id) async {
    final row = await (_db.select(_db.learningEvents)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  /// Liste tous les événements, du plus récent au plus ancien.
  Future<List<LearningEvent>> findAll({int? limit}) async {
    final query = _db.select(_db.learningEvents)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.occurredAt)]);
    if (limit != null) query.limit(limit);
    final rows = await query.get();
    return [for (final row in rows) await _hydrate(row)];
  }

  /// Liste les événements d'un type donné.
  Future<List<LearningEvent>> findByType(
    String type, {
    int? limit,
  }) async {
    final query = _db.select(_db.learningEvents)
      ..where((tbl) => tbl.type.equals(type))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.occurredAt)]);
    if (limit != null) query.limit(limit);
    final rows = await query.get();
    return [for (final row in rows) await _hydrate(row)];
  }

  /// Liste les événements rattachés à une notion donnée.
  ///
  /// Cette requête d'agrégation par notion est précisément ce dont les
  /// futures règles pédagogiques auront besoin : elle est donc prévue dès
  /// le socle, sans en tirer aucune conclusion ici.
  Future<List<LearningEvent>> findByNotion(
    String notionId, {
    int? limit,
  }) async {
    final idsQuery = _db.selectOnly(_db.eventNotions)
      ..addColumns([_db.eventNotions.eventId])
      ..where(_db.eventNotions.notionId.equals(notionId));
    final rows = await idsQuery.get();
    final eventIds = <String>[
      for (final r in rows)
        if (r.read(_db.eventNotions.eventId) case final String id) id,
    ];
    if (eventIds.isEmpty) return <LearningEvent>[];

    final query = _db.select(_db.learningEvents)
      ..where((tbl) => tbl.id.isIn(eventIds))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.occurredAt)]);
    if (limit != null) query.limit(limit);
    final events = await query.get();
    return [for (final row in events) await _hydrate(row)];
  }

  /// Nombre total d'événements enregistrés.
  Future<int> count() async {
    final count = _db.learningEvents.id.count();
    final row = await (_db.selectOnly(_db.learningEvents)..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Recharge un événement complet (notions, tentative, erreur, indice).
  Future<LearningEvent> _hydrate(LearningEventRow row) async {
    final notionRows = await (_db.select(_db.eventNotions)
          ..where((tbl) => tbl.eventId.equals(row.id)))
        .get();

    final attemptRow = await (_db.select(_db.exerciseAttempts)
          ..where((tbl) => tbl.eventId.equals(row.id)))
        .getSingleOrNull();

    ExerciseAttempt? attempt;
    if (attemptRow != null) {
      final errorRow = await (_db.select(_db.observedErrors)
            ..where((tbl) => tbl.eventId.equals(row.id)))
          .getSingleOrNull();
      final hintRow = await (_db.select(_db.offeredHints)
            ..where((tbl) => tbl.eventId.equals(row.id)))
          .getSingleOrNull();
      attempt = attemptRow.toDomain(
        error: errorRow?.toDomain(),
        hint: hintRow?.toDomain(),
        activityContext: decodeContext(row.contextJson),
      );
    }

    return row.toDomain(
      notionIds: notionRows.map((r) => r.notionId).toSet(),
      attempt: attempt,
    );
  }
}
