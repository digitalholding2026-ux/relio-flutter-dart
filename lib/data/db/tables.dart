/// Définition des tables Drift (SQLite).
///
/// Le schéma est centré sur le STOCKAGE des faits, et non sur ce que
/// l'application sait faire : il ne contient AUCUNE colonne de maîtrise,
/// de score ou de niveau d'élève. Il ne conserve que des FAITS observables,
/// ce qui laisse les règles pédagogiques futures s'appuyer sur un historique
/// brut et immuable.
library;

import 'package:drift/drift.dart';

import '../../domain/learning/exercise_attempt.dart';
import '../../domain/notion/notion_status.dart';

/// Convertit une chaîne en [DateTime] UTC, et réciproquement.
class DateTimeUtcConverter extends TypeConverter<DateTime, String> {
  const DateTimeUtcConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toUtc();

  @override
  String toSql(DateTime value) => value.toUtc().toIso8601String();
}

/// Convertit le cycle de vie éditorial d'une notion.
class NotionLifecycleConverter extends TypeConverter<NotionLifecycle, String> {
  const NotionLifecycleConverter();

  @override
  NotionLifecycle fromSql(String fromDb) =>
      NotionLifecycle.values.firstWhere((e) => e.name == fromDb);

  @override
  String toSql(NotionLifecycle value) => value.name;
}

/// Convertit le résultat observable d'une réponse.
class AnswerOutcomeConverter extends TypeConverter<AnswerOutcome, String> {
  const AnswerOutcomeConverter();

  @override
  AnswerOutcome fromSql(String fromDb) =>
      AnswerOutcome.values.firstWhere((e) => e.name == fromDb);

  @override
  String toSql(AnswerOutcome value) => value.name;
}

/// Table des notions mathématiques du catalogue.
@DataClassName('NotionRow')
class Notions extends Table {
  /// Identifiant stable, choisi par le domaine. Jamais régénéré.
  TextColumn get id => text()();

  TextColumn get label => text()();

  TextColumn get description => text().nullable()();

  TextColumn get domainId => text().nullable()();

  TextColumn get levelId => text().nullable()();

  /// État éditorial (draft / published / archived) — jamais la maîtrise.
  TextColumn get lifecycle =>
      text().map(const NotionLifecycleConverter()).withDefault(Constant('draft'))();

  TextColumn get createdAt => text().map(const DateTimeUtcConverter())();

  TextColumn get updatedAt => text().map(const DateTimeUtcConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des branches mathématiques (ex. « algèbre »).
@DataClassName('MathDomainRow')
class MathDomains extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des niveaux de progression déclarés dans le catalogue.
@DataClassName('NotionLevelRow')
class NotionLevels extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des prérequis structurels entre notions.
///
/// Décrit une dépendance de CATALOGUE. N'exprime en aucun cas une
/// maîtrise acquise par un élève.
@DataClassName('NotionPrerequisiteRow')
class NotionPrerequisites extends Table {
  TextColumn get prerequisiteId => text()();
  TextColumn get notionId => text()();

  @override
  Set<Column> get primaryKey => {prerequisiteId, notionId};
}

/// Événements d'apprentissage — table principale, APPEND-ONLY.
///
/// [id] est une clé primaire textuelle générée par le client : c'est la
/// garantie structurelle contre la duplication lors des rejeux hors ligne.
@DataClassName('LearningEventRow')
class LearningEvents extends Table {
  TextColumn get id => text()();

  /// Type d'événement (ex. « exercise_attempt »). Indexé pour les filtres.
  TextColumn get type => text()();

  TextColumn get occurredAt => text().map(const DateTimeUtcConverter())();

  /// Contexte de l'activité, sérialisé en JSON.
  TextColumn get contextJson => text().nullable()();

  /// Métadonnées libres propres au type d'événement, sérialisées en JSON.
  ///
  /// Permet d'ajouter des faits sans migration de table.
  TextColumn get metadataJson => text().withDefault(Constant('{}'))();

  /// Date d'enregistrement en base (pour l'audit et le tri).
  TextColumn get recordedAt => text().map(const DateTimeUtcConverter())();

  @override
  Set<Column> get primaryKey => {id};
  // Aucune contrainte `uniqueKeys` supplémentaire : la clé primaire `id`
  // garantit DÉJÀ l'unicité, et c'est elle qui rend l'écriture idempotente.
}

/// Table de liaison entre un événement et les notions concernées.
///
/// Modèle many-to-many explicite plutôt qu'une colonne JSON, pour permettre
/// des requêtes d'agrégation (historique par notion) — dont les futures
/// règles pédagogiques auront besoin.
@DataClassName('EventNotionRow')
class EventNotions extends Table {
  TextColumn get eventId =>
      text().references(LearningEvents, #id, onDelete: KeyAction.cascade)();
  TextColumn get notionId => text()();

  @override
  Set<Column> get primaryKey => {eventId, notionId};
}

/// Détail d'une tentative d'exercice, rattaché à son événement parent.
///
/// Séparé de [LearningEvents] pour que le schéma reste normalisé :
/// les événements non-exercice ne créent aucune ligne ici.
@DataClassName('ExerciseAttemptRow')
class ExerciseAttempts extends Table {
  TextColumn get eventId =>
      text().references(LearningEvents, #id, onDelete: KeyAction.cascade)();

  TextColumn get exerciseId => text()();
  TextColumn get startedAt => text().map(const DateTimeUtcConverter())();
  TextColumn get submittedAt => text().map(const DateTimeUtcConverter()).nullable()();

  /// Résultat OBSERVABLE : correct / incorrect / notEvaluated / abandoned.
  /// Aucune valeur de maîtrise ici.
  ///
  /// La valeur par défaut est `notEvaluated` : en cas de valeur absente ou
  /// illisible, on ne suppose JAMAIS qu'une réponse était fausse.
  TextColumn get outcome => text()
      .withDefault(Constant('notEvaluated'))
      .map(const AnswerOutcomeConverter())();

  TextColumn get answerId => text().nullable()();
  TextColumn get answerRaw => text().nullable()();
  TextColumn get answerNormalized => text().nullable()();
  BoolColumn get answerEmpty => boolean().withDefault(const Constant(false))();

  IntColumn get durationMs => integer().nullable()();

  /// Clé primaire = un (et un seul) essai par événement.
  @override
  Set<Column> get primaryKey => {eventId};
}

/// Erreurs constatées, NULL-conservantes : une tentative peut n'avoir
/// aucune erreur, et une erreur non identifiée reste NULL plutôt que devinée.
@DataClassName('ObservedErrorRow')
class ObservedErrors extends Table {
  TextColumn get id => text()();
  TextColumn get eventId =>
      text().references(LearningEvents, #id, onDelete: KeyAction.cascade)();

  TextColumn get occurredAt => text().map(const DateTimeUtcConverter())();

  /// Marqueur technique ; NULL tant que l'erreur n'est pas identifiée.
  TextColumn get errorType => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get locatedAt => text().nullable()();

  /// Clé primaire : un identifiant d'observation d'erreur est unique dans
  /// le stockage, ce qui empêche toute duplication silencieuse.
  @override
  Set<Column> get primaryKey => {id};
}

/// Aides et indices proposés à l'élève, tels qu'ils ont été affichés.
/// Préférences d'affichage et identité de l'élève.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  /// Clé du réglage. Une seule ligne par clé.
  TextColumn get key => text()();

  /// Valeur, stockée en texte brut.
  ///
  /// Choix VOLONTAIRE : ces réglages sont un petit nombre de chaînes
  /// courtes et hétérogènes (un prénom, un booléen, un indice d'échelle).
  /// Un stockage clé/valeur évite d'ajouter une colonne — donc une
  /// migration — à chaque nouveau réglage.
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Aides et indices proposés à l'élève, tels qu'ils ont été affichés.
@DataClassName('OfferedHintRow')
class OfferedHints extends Table {
  TextColumn get id => text()();
  TextColumn get eventId =>
      text().references(LearningEvents, #id, onDelete: KeyAction.cascade)();

  TextColumn get offeredAt => text().map(const DateTimeUtcConverter())();
  TextColumn get hintId => text().nullable()();
  TextColumn get kind => text().nullable()();
  TextColumn get content => text().nullable()();

  /// Clé primaire : un indice proposé est identifié de façon unique.
  @override
  Set<Column> get primaryKey => {id};
}
