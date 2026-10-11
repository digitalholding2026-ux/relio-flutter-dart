/// Cycle de vie d'une notion.
///
/// Décrit un état EDITORIAL et factuel de la notion dans le catalogue
/// (est-elle publiée, archivée), et rien de plus.
///
/// ⚠️ Ce type ne porte volontairement aucune notion de maîtrise.
/// La maîtrise d'un élève est une INTERPRÉTATION pédagogique, qui sera
/// derivée plus tard des événements d'apprentissage. Aucun champ
/// `maitrise = true/false` n'existe dans ce socle.
enum NotionLifecycle {
  /// Structurée mais non encore validée pour l'affichage aux élèves.
  draft,

  /// Publiée dans le catalogue, utilisable par les activités.
  published,

  /// Retirée du catalogue. Conservée pour ne jamais casser
  /// l'historique d'apprentissage qui la référence.
  archived,
}
