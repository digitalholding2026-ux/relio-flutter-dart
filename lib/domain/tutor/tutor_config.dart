/// Configuration du tuteur, lue à la compilation.
///
/// Aucun secret n'est écrit dans le dépôt : la clé vient d'un `dart-define`
/// (voir `docs/TUTEUR_LLM.md`). Sans clé, le tuteur répond en mode repli.
library;

import 'package:flutter/foundation.dart';

/// Paramètres de l'appel au modèle.
@immutable
class TutorConfig {
  /// Crée une configuration.
  const TutorConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.timeout = const Duration(seconds: 20),
    this.maxHistory = 12,
    this.maxTokens = 180,
    this.temperature = 0.4,
  });

  /// Racine de l'API compatible OpenAI.
  static const String _envBaseUrl = String.fromEnvironment(
    'TUTOR_API_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );

  /// Clé du fournisseur. Vide par défaut : aucune clé dans le dépôt.
  static const String _envApiKey = String.fromEnvironment('TUTOR_API_KEY');

  /// Identifiant du modèle.
  static const String _envModel = String.fromEnvironment(
    'TUTOR_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  /// Lit la configuration compilée dans l'application.
  factory TutorConfig.fromEnvironment() {
    return const TutorConfig(
      baseUrl: _envBaseUrl,
      apiKey: _envApiKey,
      model: _envModel,
    );
  }

  /// Racine de l'API, par exemple `https://api.openai.com/v1`.
  final String baseUrl;

  /// Clé d'authentification.
  final String apiKey;

  /// Modèle à interroger.
  final String model;

  /// Délai maximal avant repli.
  final Duration timeout;

  /// Nombre maximal de messages d'historique envoyés.
  final int maxHistory;

  /// Plafond de génération : 2 à 3 phrases.
  final int maxTokens;

  /// Créativité du modèle : guidage stable, sans rigidité.
  final double temperature;

  /// La clé est-elle renseignée ?
  bool get isConfigured => apiKey.trim().isNotEmpty;

  /// Adresse de l'appel de conversation.
  ///
  /// Un ou plusieurs `/` finals sont tolérés : `…/v1/` et `…/v1` produisent
  /// la même adresse.
  Uri get chatCompletionsUri {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$normalized/chat/completions');
  }
}
