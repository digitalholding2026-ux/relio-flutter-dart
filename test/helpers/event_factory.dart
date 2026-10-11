/// Constructeurs d'événements d'apprentissage pour les tests.
///
/// Centralisés pour que les tests portent sur le COMPORTEMENT attendu
/// plutôt que sur la construction manuelle des objets.
library;

import 'package:relio/domain/learning/activity_context.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learning_event.dart';
import 'package:relio/domain/learning/observed_error.dart';
import 'package:relio/domain/learning/offered_hint.dart';

final DateTime kTestInstant = DateTime.utc(2026, 3, 15, 9, 30);

/// Construit un événement simple, sans détail de tentative.
LearningEvent sampleEvent({
  String id = 'e-1',
  String type = 'exercise_attempt',
  DateTime? occurredAt,
  List<String> notionIds = const <String>[],
  Map<String, Object?> metadata = const <String, Object?>{},
}) {
  return LearningEvent(
    id: id,
    type: type,
    occurredAt: occurredAt ?? kTestInstant,
    notionIds: notionIds,
    metadata: metadata,
  );
}

/// Construit une tentative d'exercice complète.
ExerciseAttempt sampleAttempt({
  String exerciseId = 'ex-1',
  AnswerOutcome outcome = AnswerOutcome.correct,
  DateTime? startedAt,
  DateTime? submittedAt,
  String? rawText = '3/4',
  String? normalized = '0.75',
  bool answerEmpty = false,
  int? durationMs = 4200,
  ObservedError? error,
  OfferedHint? hint,
}) {
  return ExerciseAttempt(
    exerciseId: exerciseId,
    startedAt: startedAt ?? kTestInstant,
    submittedAt: submittedAt ??
        kTestInstant.add(const Duration(minutes: 1)),
    outcome: outcome,
    answer: StudentAnswer(
      answerId: 'a-1',
      rawText: rawText,
      normalizedValue: normalized,
      isEmpty: answerEmpty,
    ),
    durationMs: durationMs,
    error: error,
    hint: hint,
    context: const ActivityContext(
      activityId: 'act-1',
      activityType: 'exercice',
      source: 'app_android',
      locale: 'fr',
    ),
  );
}

/// Construit un événement portant une tentative complète.
LearningEvent attemptEvent({
  required String id,
  ExerciseAttempt? attempt,
  List<String> notionIds = const <String>[],
  DateTime? occurredAt,
}) {
  return LearningEvent(
    id: id,
    type: 'exercise_attempt',
    occurredAt: occurredAt ?? kTestInstant,
    notionIds: notionIds,
    attempt: attempt ?? sampleAttempt(),
  );
}

/// Erreur observée minimale.
ObservedError sampleError({
  String id = 'err-1',
  String? errorType,
  String? description = 'Saisie illisible',
}) {
  return ObservedError(
    id: id,
    occurredAt: kTestInstant,
    errorType: errorType,
    description: description,
  );
}

/// Indice proposé minimal.
OfferedHint sampleHint({
  String id = 'hint-1',
  String? hintId = 'h-1',
  String content = 'Pense au dénominateur commun.',
}) {
  return OfferedHint(
    id: id,
    offeredAt: kTestInstant,
    hintId: hintId,
    kind: 'methode',
    content: content,
  );
}
