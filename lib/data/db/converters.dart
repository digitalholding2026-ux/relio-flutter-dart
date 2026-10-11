/// Conversion entre le domaine (objets Dart) et la persistance (rows Drift).
///
/// Isoler le mapping ici permet de faire évoluer le modèle métier sans
/// exposer le schéma SQL au reste de l'application, et de tester la
/// conversion indépendamment de SQLite.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/learning/activity_context.dart';
import '../../domain/learning/exercise_attempt.dart';
import '../../domain/learning/learning_event.dart';
import '../../domain/learning/observed_error.dart';
import '../../domain/learning/offered_hint.dart';
import '../../domain/notion/notion.dart';
import 'app_database.dart';

/// Sérialise le contexte d'activité en JSON déterministe.
String? encodeContext(ActivityContext? context) {
  if (context == null) return null;
  return jsonEncode(<String, Object?>{
    'activityId': context.activityId,
    'activityType': context.activityType,
    'source': context.source,
    'locale': context.locale,
  });
}

/// Reconstruit un contexte depuis le JSON stocké.
ActivityContext? decodeContext(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final map = jsonDecode(raw) as Map<String, Object?>;
  return ActivityContext(
    activityId: map['activityId'] as String?,
    activityType: map['activityType'] as String?,
    source: map['source'] as String?,
    locale: map['locale'] as String?,
  );
}

/// Sérialise les métadonnées libres d'un événement.
String encodeMetadata(Map<String, Object?> metadata) => jsonEncode(metadata);

/// Reconstruit les métadonnées libres depuis le JSON stocké.
Map<String, Object?> decodeMetadata(String? raw) {
  if (raw == null || raw.isEmpty) return const <String, Object?>{};
  return Map<String, Object?>.from(jsonDecode(raw) as Map<String, Object?>);
}

extension NotionRowMapper on NotionRow {
  Notion toDomain({Set<String> prerequisiteIds = const <String>{}}) => Notion(
        id: id,
        label: label,
        description: description,
        domainId: domainId,
        levelId: levelId,
        lifecycle: lifecycle,
        prerequisiteIds: prerequisiteIds,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Construit la row d'une notion, préréquis non inclus (table séparée).
NotionsCompanion notionToCompanion(
  Notion notion, {
  required DateTime now,
}) {
  return NotionsCompanion(
    id: Value(notion.id),
    label: Value(notion.label),
    description: Value(notion.description),
    domainId: Value(notion.domainId),
    levelId: Value(notion.levelId),
    lifecycle: Value(notion.lifecycle),
    createdAt: Value(notion.createdAt ?? now),
    updatedAt: Value(notion.updatedAt ?? now),
  );
}

extension LearningEventRowMapper on LearningEventRow {
  /// Reconstitue les parties stockées directement sur l'événement.
  LearningEvent toDomain({
    Set<String> notionIds = const <String>{},
    ExerciseAttempt? attempt,
  }) {
    return LearningEvent(
      id: id,
      type: type,
      occurredAt: occurredAt,
      notionIds: List<String>.of(notionIds),
      attempt: attempt,
      context: decodeContext(contextJson),
      metadata: decodeMetadata(metadataJson),
    );
  }
}

extension ExerciseAttemptRowMapper on ExerciseAttemptRow {
  ExerciseAttempt toDomain({
    ObservedError? error,
    OfferedHint? hint,
    ActivityContext? activityContext,
  }) {
    final hasAnswer =
        answerId != null ||
            answerRaw != null ||
            answerNormalized != null ||
            answerEmpty;
    return ExerciseAttempt(
      exerciseId: exerciseId,
      startedAt: startedAt,
      submittedAt: submittedAt,
      outcome: outcome,
      answer: hasAnswer
          ? StudentAnswer(
              answerId: answerId,
              rawText: answerRaw,
              normalizedValue: answerNormalized,
              isEmpty: answerEmpty,
            )
          : null,
      durationMs: durationMs,
      error: error,
      hint: hint,
      context: activityContext,
    );
  }
}

extension ObservedErrorRowMapper on ObservedErrorRow {
  ObservedError toDomain() => ObservedError(
        id: id,
        occurredAt: occurredAt,
        errorType: errorType,
        description: description,
        locatedAt: locatedAt,
      );
}

extension OfferedHintRowMapper on OfferedHintRow {
  OfferedHint toDomain() => OfferedHint(
        id: id,
        offeredAt: offeredAt,
        hintId: hintId,
        kind: kind,
        content: content,
      );
}

/// Construit la row d'un événement d'apprentissage.
///
/// [contextOverride] permet d'écrire le contexte résolu (celui de
/// l'événement, ou à défaut celui de sa tentative) plutôt que de le
/// perdre silencieusement.
LearningEventsCompanion learningEventToCompanion(
  LearningEvent event, {
  required DateTime recordedAt,
  ActivityContext? contextOverride,
}) {
  return LearningEventsCompanion(
    id: Value(event.id),
    type: Value(event.type),
    occurredAt: Value(event.occurredAt),
    contextJson: Value(encodeContext(contextOverride ?? event.context)),
    metadataJson: Value(encodeMetadata(event.metadata)),
    recordedAt: Value(recordedAt),
  );
}
