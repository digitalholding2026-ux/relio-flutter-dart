/// Construction du tuteur : un seul point de décision, testable.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/tutor/mock_tutor_client.dart';
import 'package:relio/domain/tutor/openai_tutor_client.dart';
import 'package:relio/domain/tutor/tutor_client_factory.dart';
import 'package:relio/domain/tutor/tutor_config.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';
import 'package:relio/domain/tutor/tutor_message.dart';

const TutorExerciseContext _exercise = TutorExerciseContext(
  statement: 'Calcule le PGCD de 18 et 12.',
  expectedAnswer: 'Valeurs acceptées : 6.',
);

void main() {
  group('buildTutorClient', () {
    test('sans clé, renvoie le tuteur simulé', () async {
      final client = buildTutorClient(
        config: const TutorConfig(
          baseUrl: 'https://api.example.test/v1',
          apiKey: '',
          model: 'm',
        ),
      );

      expect(client, isA<MockTutorClient>());

      // Le mode simulé répond vraiment : le fil de conversation reste
      // utilisable sans clé, sans jamais toucher le réseau.
      final reply = await client.reply(
        exercise: _exercise,
        history: const <TutorMessage>[],
      );
      expect(reply, kMockTutorReply);
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
