/// Indice ou aide proposé à l'élève.
///
/// Enregistre CE QUI A ÉTÉ PROPOSÉ, pas l'effet produit sur l'élève
/// (l'effet serait une interprétation pédagogique).
library;

class OfferedHint {
  const OfferedHint({
    required this.id,
    required this.offeredAt,
    this.hintId,
    this.kind,
    this.content,
  });

  final String id;
  final DateTime offeredAt;

  /// Identifiant de l'indice dans le contenu pédagogique (s'il existe).
  final String? hintId;

  /// Nature de l'aide, ex. « exemple », « methode », « relance ».
  final String? kind;

  /// Texte effectivement présenté à l'élève.
  final String? content;
}
