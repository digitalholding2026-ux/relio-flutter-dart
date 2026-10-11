/// Contexte de l'activité dans lequel un événement s'est produit.
///
/// Reste purement FACTUEL : où l'élève se trouvait, avec quelle séance.
/// Aucune inférence pédagogique ici.
library;

class ActivityContext {
  const ActivityContext({
    this.activityId,
    this.activityType,
    this.source,
    this.locale,
  });

  /// Identifiant de l'activité / de l'exercice proposé.
  final String? activityId;

  /// Type d'activité, ex. « exercice », « leçon », « evaluation ».
  final String? activityType;

  /// Origine de l'événement, ex. « app_android ».
  final String? source;

  /// Langue de l'interface au moment de l'événement, ex. « fr ».
  final String? locale;
}
