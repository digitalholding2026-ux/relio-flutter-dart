/// Tentative d'exercice et son résultat OBSERVABLE.
///
/// Distingue explicitement :
///  - ce que l'ÉLÈVE a répondu [answer] ;
///  - ce que le SYSTÈME a constaté comme résultat [outcome].
///
/// Le résultat est un fait calculé mécaniquement (correct / incorrect /
/// non évalué). Aucun jugement de niveau, de difficulté ressentie ou de
/// maîtrise n'est stocké ici : cela relèvera des missions pédagogiques.
library;

import 'activity_context.dart';
import 'observed_error.dart';
import 'offered_hint.dart';

/// Résultat observable d'une réponse.
enum AnswerOutcome {
  /// La réponse correspond à la réponse attendue.
  correct,

  /// La réponse a été soumise et ne correspond pas à la réponse attendue.
  incorrect,

  /// La réponse a été soumise mais n'a pas pu être évaluée
  /// (ex. format non reconnu). Fait distinct de « incorrect ».
  notEvaluated,

  /// L'élève a abandonné avant de soumettre.
  abandoned,
}

/// Réponse d'élève, conservée telle que saisie.
class StudentAnswer {
  const StudentAnswer({
    required this.answerId,
    this.rawText,
    this.normalizedValue,
    this.isEmpty = false,
  });

  /// Référence de la réponse dans le système de notation.
  final String? answerId;

  /// Saisie brute de l'élève, conservée telle quelle pour l'audit.
  final String? rawText;

  /// Valeur normalisée servant à la comparaison automatique.
  final String? normalizedValue;

  /// L'élève a-t-il Explicitement laissé la réponse vide ?
  final bool isEmpty;
}

/// Une tentative d'exercice.
class ExerciseAttempt {
  const ExerciseAttempt({
    required this.exerciseId,
    required this.startedAt,
    required this.outcome,
    this.submittedAt,
    this.answer,
    this.durationMs,
    this.error,
    this.hint,
    this.context,
  });

  /// Identifiant de l'exercice tenté.
  final String exerciseId;

  /// Début de la tentative.
  final DateTime startedAt;

  /// Fin de la tentative (NULL si en cours ou abandonnée sans horodatage).
  final DateTime? submittedAt;

  /// Résultat observable.
  final AnswerOutcome outcome;

  /// Réponse de l'élève.
  final StudentAnswer? answer;

  /// Durée en millisecondes, si mesurable hors ligne.
  final int? durationMs;

  /// Erreur constatée, si elle a pu être identifiée.
  final ObservedError? error;

  /// Indice / aide proposé pendant la tentative, s'il y en a eu un.
  final OfferedHint? hint;

  /// Contexte de l'activité.
  final ActivityContext? context;
}
