/// Préférences locales de l'élève et de l'affichage.
///
/// PÉRIMÈTRE STRICT, V1.
///
/// Ces préférences décrivent le CONFORT D'USAGE, rien de plus :
///  - le prénom saisi sur l'écran Profil ;
///  - l'échelle de texte (normal / grand / très grand) ;
///  - le contraste renforcé ;
///  - la réduction des animations.
///
/// ⚠️ AUCUNE de ces valeurs n'est un fait d'apprentissage. Ni score, ni
/// niveau, ni progression, ni maîtrise : la règle 5 d'`AGENTS.md` interdit
/// d'introduire un tel champ dans le modèle ET dans le schéma. Un réglage
/// d'affichage est une preference de confort, pas une observation de l'élève.
///
/// PERSISTANCE : locale uniquement, dans la table `app_settings`.
/// Aucune synchronisation distante n'existe en V1 ; la perte des préférences
/// à la désinstallation est ACCEPTÉE et assumée.
library;

import 'package:drift/drift.dart';

import '../../data/db/app_database.dart';

/// Échelle de texte choisie par l'élève.
///
/// Les trois valeurs correspondent EXACTEMENT aux multiplicateurs prescrits
/// (1.0, 1.15, 1.3). Aucune quatrième valeur n'est exposée en V1.
enum TextScalePreference {
  normal(1.0, 'Normal'),
  grand(1.15, 'Grand'),
  tresGrand(1.3, 'Très grand');

  const TextScalePreference(this.factor, this.label);

  /// Multiplicateur appliqué à l'échelle de texte de l'application.
  final double factor;

  /// Libellé affiché dans l'écran Profil.
  final String label;
}

/// Toutes les préférences persistées, regroupées.
///
/// Objet immuable : chaque modification produit une nouvelle instance, ce qui
/// rend la reconstruction du thème déterministe et testable.
class LearnerSettings {
  const LearnerSettings({
    this.name = '',
    this.textScale = TextScalePreference.normal,
    this.highContrast = false,
    this.reduceAnimations = false,
  });

  /// Prénom renseigné. Vide si l'élève ne l'a pas saisi.
  final String name;

  /// Échelle de texte choisie.
  final TextScalePreference textScale;

  /// Contraste renforcé des bordures et du texte secondaire.
  final bool highContrast;

  /// Désactivation des animations non essentielles.
  final bool reduceAnimations;

  /// Les valeurs par défaut, appliquées à une installation neuve.
  static const LearnerSettings defaults = LearnerSettings();

  LearnerSettings copyWith({
    String? name,
    TextScalePreference? textScale,
    bool? highContrast,
    bool? reduceAnimations,
  }) {
    return LearnerSettings(
      name: name ?? this.name,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    );
  }

  @override
  String toString() =>
      'LearnerSettings(name: "$name", textScale: ${textScale.name}, '
      'highContrast: $highContrast, reduceAnimations: $reduceAnimations)';
}

/// Clés de stockage, en un seul endroit.
abstract final class _Keys {
  static const String name = 'learner.name';
  static const String textScale = 'display.text_scale';
  static const String highContrast = 'display.high_contrast';
  static const String reduceAnimations = 'a11y.reduce_animations';

  /// Drapeau « l'écran d'entrée a déjà été vu ».
  ///
  /// Volontairement hors de [LearnerSettings] : c'est un état de
  /// l'application, pas un réglage de confort de l'élève.
  static const String firstLaunchCompleted = 'app.first_launch_completed';

  /// Identifiant de la session de test d'entrée en cours.
  ///
  /// Rappel local du passage non terminé, pour le retrouver après une
  /// fermeture de l'application. La V1 ne lance qu'une passation : cette clé
  /// n'est donc écrite qu'une fois, à la création de la session.
  static const String entryTestSessionId = 'entry_test.session_id';
}

/// Lecture et écriture des préférences.
///
/// Les écritures sont IMMÉDIATES : la sauvegarde est automatique et ne
/// dépend d'aucune action de l'élève (aucun bouton « Enregistrer »).
///
/// Une valeur illisible ou hors enum retombe sur le défaut : une préférence
/// corrompue ne doit jamais empêcher l'application de démarrer.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// L'écran d'entrée a-t-il déjà été vu ?
  ///
  /// Drapeau d'ÉTAT DE L'APPLICATION, pas une préférence de confort : il vit
  /// ici — dans la même table clé/valeur — mais délibérément HORS de
  /// [LearnerSettings], qui ne décrit que le confort de l'élève (règle 5).
  ///
  /// Sa lecture n'échoue jamais : une valeur absente ou illisible vaut
  /// « première ouverture », donc l'écran d'entrée s'affiche plutôt que de
  /// bloquer l'application sur une donnée corrompue.
  Future<bool> hasCompletedFirstLaunch() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(_Keys.firstLaunchCompleted)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  /// Marque l'écran d'entrée comme vu : il ne sera plus rejoué.
  ///
  /// Appelé par le bouton « Commencer » ET par le bouton retour Android.
  Future<void> markFirstLaunchCompleted() =>
      _write(_Keys.firstLaunchCompleted, 'true');

  /// Charge toutes les préférences, en appliquant les défauts manquantes.
  Future<LearnerSettings> load() async {
    final rows = await (_db.select(_db.appSettings)).get();
    final values = <String, String>{
      for (final row in rows)
        if (row.value != null) row.key: row.value!,
    };

    return LearnerSettings(
      name: values[_Keys.name] ?? '',
      textScale: _parseScale(values[_Keys.textScale]),
      highContrast: values[_Keys.highContrast] == 'true',
      reduceAnimations: values[_Keys.reduceAnimations] == 'true',
    );
  }

  /// Enregistre [name]. La sauvegarde est automatique.
  Future<void> setName(String name) =>
      _write(_Keys.name, name.trim());

  /// Enregistre l'échelle de texte choisie.
  Future<void> setTextScale(TextScalePreference scale) =>
      _write(_Keys.textScale, scale.name);

  /// Enregistre la préférence de contraste renforcé.
  Future<void> setHighContrast(bool value) =>
      _write(_Keys.highContrast, value ? 'true' : 'false');

  /// Enregistre la préférence de réduction des animations.
  Future<void> setReduceAnimations(bool value) =>
      _write(_Keys.reduceAnimations, value ? 'true' : 'false');

  /// Identifiant de la session de test d'entrée, `null` s'il n'y en a pas.
  ///
  /// Une valeur absente ou illisible vaut « aucune session » : le test
  /// d'entrée reprendra alors par une session neuve, ce qui vaut mieux
  /// qu'une session de référence illisible qui bloquerait l'application.
  Future<String?> entryTestSessionId() async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(_Keys.entryTestSessionId)))
        .getSingleOrNull();
    final String? value = row?.value;
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Mémorise la session de test d'entrée à reprendre.
  Future<void> saveEntryTestSessionId(String sessionId) =>
      _write(_Keys.entryTestSessionId, sessionId);

  Future<void> _write(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: Value(value)),
        );
  }

  /// Convertit une valeur stockée en [TextScalePreference].
  ///
  /// Un nom inconnu — base corrompue, version antérieure — retombe sur
  /// [TextScalePreference.normal] plutôt que de lever.
  static TextScalePreference _parseScale(String? raw) {
    for (final candidate in TextScalePreference.values) {
      if (candidate.name == raw) return candidate;
    }
    return TextScalePreference.normal;
  }
}