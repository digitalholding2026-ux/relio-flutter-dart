/// Structure des notions mathématiques.
///
/// Modèle volontairement MINIMAL et ENRICHIissable : il décrit ce qu'est
/// une notion mathématique et comment elle se rattache aux autres, sans
/// figer de contenu pédagogique.
///
/// Aucun contenu de notion n'est fourni ici : les notions réelles seront
/// saisies ou importées après validation pédagogique (cf. Mission 2).
library;

import 'notion_status.dart';

/// Domaine (branche) des mathématiques, ex. « algèbre », « géométrie ».
class MathDomain {
  const MathDomain({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) => other is MathDomain && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MathDomain($id)';
}

/// Niveau de progressión, utilisé pour ordonnancer une progression.
///
/// C'est un fait déclaratif du catalogue, pas une évaluation de l'élève.
class NotionLevel {
  const NotionLevel({required this.id, required this.label, required this.order});

  final String id;
  final String label;

  /// Ordre croissant : sert au tri, jamais à une décision pédagogique
  /// automatique (une telle décision relèvera d'une mission ultérieure).
  final int order;

  @override
  bool operator ==(Object other) => other is NotionLevel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NotionLevel($id, order=$order)';
}

/// Une notion mathématique du catalogue.
///
/// Invariants :
///  - [id] est stable et sert de clé primaire (jamais régénéré) ;
///  - [prerequisiteIds] déclare les dépendances structurelles du CATALOGUE,
///    ce qui n'implique AUCUNE maîtrise acquise par l'élève.
class Notion {
  const Notion({
    required this.id,
    required this.label,
    this.description,
    this.domainId,
    this.levelId,
    this.lifecycle = NotionLifecycle.draft,
    this.prerequisiteIds = const <String>{},
    this.createdAt,
    this.updatedAt,
  });

  /// Identifiant stable et unique de la notion.
  final String id;

  /// Intitulé court, en français.
  final String label;

  /// Description facultative. Non fournie par défaut : aucun contenu
  /// pédagogique n'est inventé ici.
  final String? description;

  /// Rattachement à un domaine (ex. « geometrie »).
  final String? domainId;

  /// Rattachement à un niveau de progression.
  final String? levelId;

  /// État éditorial de la notion.
  final NotionLifecycle lifecycle;

  /// Ids des notions prérequises.
  final Set<String> prerequisiteIds;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Notion copyWith({
    String? label,
    String? description,
    String? domainId,
    String? levelId,
    NotionLifecycle? lifecycle,
    Set<String>? prerequisiteIds,
    DateTime? updatedAt,
  }) {
    return Notion(
      id: id,
      label: label ?? this.label,
      description: description ?? this.description,
      domainId: domainId ?? this.domainId,
      levelId: levelId ?? this.levelId,
      lifecycle: lifecycle ?? this.lifecycle,
      prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Notion($id, "$label", ${lifecycle.name})';
}
