/// Construction du tuteur : un seul point de décision, testable.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/tutor/openai_tutor_client.dart';
import 'package:relio/domain/tutor/tutor_client.dart';
import 'package:relio/domain/tutor/tutor_client_factory.dart';
import 'package:relio/domain/tutor/tutor_config.dart';

void main() {
  group('buildTutorClient', () {
    test('sans clé, renvoie le client indisponible', () {
      final client = buildTutorClient(
        config: const TutorConfig(
          baseUrl: 'https://api.example.test/v1',
          apiKey: '',
          model: 'm',
        ),
      );

      expect(client, isA<UnavailableTutorClient>());
    });

    test('avec une clé, renvoie le client du modèle', () {
      final client = buildTutorClient(
        config: const TutorConfig(
          baseUrl: 'https://api.example.test/v1',
          apiKey: 'sk-test',
          model: 'm',
        ),
      );
      addTearDown(client.close);

      expect(client, isA<OpenAiTutorClient>());
    });
  });
}
