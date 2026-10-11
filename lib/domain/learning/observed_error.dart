/// Erreur constatée lors d'une réponse d'élève.
///
/// ⚠️ Ne décrit QUE ce qui a été OBSERVÉ, jamais l'intention ou la cause
/// de l'erreur (pas de diagnostic). Le champ [errorType] est un marqueur
/// technique laissé NULL tant qu'aucune classification fiable n'est
/// disponible : aucune règle d'identification n'est inventée ici.
library;

class ObservedError {
  const ObservedError({
    required this.id,
    required this.occurredAt,
    this.errorType,
    this.description,
    this.locatedAt,
  });

  /// Identifiant stable de l'observation d'erreur.
  final String id;

  /// Date de l'observation.
  final DateTime occurredAt;

  /// Marqueur technique d'erreur (ex. « division_by_zero »),
  /// NULL si l'erreur n'a pas pu être identifiée.
  final String? errorType;

  /// Description libre de ce qui a été constaté, sans interprétation.
  final String? description;

  /// Emplacement de l'erreur dans la réponse, si connu
  /// (ex. offset dans la saisie de l'élève).
  final String? locatedAt;
}
