/// Événement d'apprentissage : unité factuelle et immuable de l'historique.
///
/// C'est le SEUL élément que la persistance conserve. Chaque événement
/// enregistre ce qui s'est produit, quand, sur quelles notions, avec
/// quelle réponse, quel résultat observable, quelles erreurs constatées
/// et quels indices proposés.
///
/// Principes structurants :
///  1. APPEND-ONLY : un événement enregistré n'est jamais modifié ni
///     supprimé par l'application. Toute correction passe par un
///     événement ultérieur.
///  2. IDEMPOTENT : [id] est un UUID produit par le client AVANT écriture.
///     Ré-enregistrer le même événement ne crée pas de doublon, ce qui
///     protège contre les rejeux hors ligne.
///  3. SANS INTERPRÉTATION : aucune notion de maîtrise, de difficulté ou
///     de niveau d'élève n'est présente. Ces règles seront définies dans
///     une mission ultérieure, à partir de ces faits bruts.
library;

import 'activity_context.dart';
import 'exercise_attempt.dart';

class LearningEvent {
  const LearningEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.notionIds = const <String>[],
    this.attempt,
    this.context,
    this.metadata = const <String, Object?>{},
  });

  /// Identifiant stable, unique. Clé primaire et garde-fou anti-doublon.
  final String id;

  /// Type d'événement, ex. « exercise_attempt », « hint_offered »,
  /// « session_started ». Extension possible sans migration de table.
  final String type;

  /// Date de survenue (UTC).
  final DateTime occurredAt;

  /// Ids des notions concernées par l'événement.
  ///
  /// ⚠️ Renseigne QUOI a été travaillé, pas COMBIEN l'élève le maîtrise.
  final List<String> notionIds;

  /// Détail d'une tentative, si l'événement en est une.
  final ExerciseAttempt? attempt;

  /// Contexte de l'activité.
  final ActivityContext? context;

  /// Données supplémentaires libres, propres au type d'événement.
  ///
  /// Permet d'enrichir le modèle SANS migration de schéma à chaque
  /// nouvelle observation. Les clés sont des faits, pas des interprétations.
  final Map<String, Object?> metadata;

  /// Copie défensive : un LearningEvent est immuable de bout en bout.
  LearningEvent copyWith({
    String? type,
    DateTime? occurredAt,
    List<String>? notionIds,
    ExerciseAttempt? attempt,
    ActivityContext? context,
    Map<String, Object?>? metadata,
  }) {
    return LearningEvent(
      id: id,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      notionIds: List.unmodifiable(notionIds ?? this.notionIds),
      attempt: attempt ?? this.attempt,
      context: context ?? this.context,
      metadata: Map.unmodifiable(metadata ?? this.metadata),
    );
  }

  @override
  String toString() =>
      'LearningEvent($id, $type, ${occurredAt.toIso8601String()}, notions=$notionIds)';
}
