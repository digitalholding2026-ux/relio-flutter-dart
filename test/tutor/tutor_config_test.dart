/// Configuration du tuteur : rien n'est codé en dur hors des valeurs par
/// défaut, et une base URL avec ou sans `/` final produit la même adresse.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/tutor/tutor_config.dart';

void main() {
  group('TutorConfig', () {
    test('sans clé compilée, le tuteur n’est pas configuré', () {
      final config = TutorConfig.fromEnvironment();

      expect(config.isConfigured, isFalse);
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.model, 'gpt-4o-mini');
    });

    test('une clé, même entourée d’espaces, active le tuteur', () {
      const config = TutorConfig(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: '  sk-test  ',
        model: 'gpt-4o-mini',
      );

      expect(config.isConfigured, isTrue);
    });

    test('l’adresse de conversation tolère le slash final', () {
      const withSlash = TutorConfig(
        baseUrl: 'https://openrouter.ai/api/v1/',
        apiKey: 'k',
        model: 'm',
      );
      const withoutSlash = TutorConfig(
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: 'k',
        model: 'm',
      );

      expect(
        withSlash.chatCompletionsUri.toString(),
        'https://openrouter.ai/api/v1/chat/completions',
      );
      expect(
        withoutSlash.chatCompletionsUri.toString(),
        withSlash.chatCompletionsUri.toString(),
      );
    });

    test('les valeurs de génération restent bornées', () {
      const config = TutorConfig(
        baseUrl: 'https://example.test/v1',
        apiKey: 'k',
        model: 'm',
      );

      expect(config.timeout, const Duration(seconds: 20));
      expect(config.maxHistory, 12);
      expect(config.maxTokens, 180);
      expect(config.temperature, 0.4);
    });
  });
}
