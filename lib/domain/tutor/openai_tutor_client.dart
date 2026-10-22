/// Appel du modèle par une API compatible OpenAI.
///
/// Le corps envoyé respecte le format `/chat/completions` :
/// `model`, `messages`, `temperature`, `max_tokens`. Le même code fonctionne
/// donc avec OpenAI, OpenRouter, Groq ou un serveur local (vLLM, Ollama en
/// mode compatible) — seule l'adresse de base change.
///
/// Par défaut, l'application vise OpenRouter avec `openrouter/auto` (voir
/// [TutorConfig]) : le fournisseur choisit le modèle disponible, ce qui évite
/// de maintenir une liste de secours côté client.
///
/// Rien n'est journalisé : ni la conversation, ni la clé. Une panne se traduit
/// par une [TutorException] que l'interface convertit en phrase de repli.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'tutor_client.dart';
import 'tutor_config.dart';
import 'tutor_exercise_context.dart';
import 'tutor_message.dart';

/// Tuteur branché sur un modèle de langage.
class OpenAiTutorClient implements TutorClient {
  /// Crée le client.
  ///
  /// [httpClient] permet d'injecter un faux transport dans les tests ; quand
  /// il est fourni, il n'est pas fermé par [close].
  OpenAiTutorClient({required this.config, http.Client? httpClient})
    : _http = httpClient ?? http.Client(),
      _ownsHttp = httpClient == null;

  /// Paramètres de l'appel (adresse, clé, modèle).
  final TutorConfig config;

  final http.Client _http;
  final bool _ownsHttp;

  /// Garde-fou : une réponse de chat ne doit pas dépasser quelques phrases.
  static const int _maxReplyCharacters = 1200;

  /// Origine déclarée à OpenRouter (en-tête d'attribution, facultatif).
  static const String _appUrl = 'https://github.com/digitalholding2026-ux/relio-flutter-dart';

  /// Nom déclaré à OpenRouter (en-tête d'attribution, facultatif).
  static const String _appTitle = 'Relio';

  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) async {
    if (!config.isConfigured) {
      throw const TutorException(TutorFailure.notConfigured);
    }

    final messages = <Map<String, String>>[
      <String, String>{'role': 'system', 'content': systemPromptFor(exercise)},
      for (final message in _recent(history))
        <String, String>{'role': message.role, 'content': message.text},
    ];

    final http.Response response;
    try {
      response = await _http
          .post(
            config.chatCompletionsUri,
            headers: <String, String>{
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              // En-têtes d'attribution lus par OpenRouter (ignorés par les
              // autres fournisseurs compatibles OpenAI).
              'HTTP-Referer': _appUrl,
              'X-Title': _appTitle,
            },
            body: jsonEncode(<String, Object>{
              'model': config.model,
              'messages': messages,
              'temperature': config.temperature,
              'max_tokens': config.maxTokens,
            }),
          )
          .timeout(config.timeout);
    } on TimeoutException {
      throw const TutorException(TutorFailure.network);
    } on http.ClientException {
      throw const TutorException(TutorFailure.network);
    } on Exception catch (error) {
      throw TutorException(TutorFailure.network, message: '$error');
    }

    if (response.statusCode != 200) {
      throw TutorException(TutorFailure.http, statusCode: response.statusCode);
    }

    return _contentOf(response);
  }

  /// Les derniers messages, dans l'ordre : l'historique complet coûterait
  /// des jetons sans améliorer le guidage.
  List<TutorMessage> _recent(List<TutorMessage> history) {
    if (history.length <= config.maxHistory) return history;
    return history.sublist(history.length - config.maxHistory);
  }

  /// Extrait le texte de la réponse, ou signale qu'elle est illisible.
  String _contentOf(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const TutorException(TutorFailure.malformed);
    }

    if (decoded is! Map<String, Object?>) {
      throw const TutorException(TutorFailure.malformed);
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const TutorException(TutorFailure.malformed);
    }

    final first = choices.first;
    if (first is! Map) {
      throw const TutorException(TutorFailure.malformed);
    }

    final message = first['message'];
    if (message is! Map) {
      throw const TutorException(TutorFailure.malformed);
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const TutorException(TutorFailure.malformed);
    }

    final trimmed = content.trim();
    return trimmed.length > _maxReplyCharacters
        ? trimmed.substring(0, _maxReplyCharacters)
        : trimmed;
  }

  @override
  void close() {
    if (_ownsHttp) _http.close();
  }
}
