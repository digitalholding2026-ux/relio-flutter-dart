/// Appel du modèle : requête, en-têtes, lecture de la réponse, pannes.
///
/// Aucun test ne touche le réseau : `MockClient` intercepte chaque requête.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:relio/domain/tutor/openai_tutor_client.dart';
import 'package:relio/domain/tutor/tutor_client.dart';
import 'package:relio/domain/tutor/tutor_config.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';
import 'package:relio/domain/tutor/tutor_message.dart';

const TutorExerciseContext _exercise = TutorExerciseContext(
  statement: 'Calcule le PGCD de 18 et 12.',
  expectedAnswer: 'Valeurs acceptées : 6. Le PGCD de 18 et 12 est 6.',
);

TutorConfig _config({
  String apiKey = 'sk-test',
  int maxHistory = 12,
  Duration timeout = const Duration(seconds: 5),
}) {
  return TutorConfig(
    baseUrl: 'https://api.example.test/v1/',
    apiKey: apiKey,
    model: 'modele-de-test',
    timeout: timeout,
    maxHistory: maxHistory,
    maxTokens: 180,
    temperature: 0.4,
  );
}

/// Réponse de conversation valide.
http.Response _chatResponse(String content) {
  return http.Response.bytes(
    utf8.encode(
      jsonEncode(<String, Object>{
        'choices': <Object>[
          <String, Object>{
            'message': <String, Object>{
              'role': 'assistant',
              'content': content,
            },
          },
        ],
      }),
    ),
    200,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

void main() {
  group('OpenAiTutorClient — requête', () {
    test('envoie le prompt officiel, l’exercice et l’historique', () async {
      late http.Request captured;
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient((http.Request request) async {
          captured = request;
          return _chatResponse('Que cherches-tu exactement ?');
        }),
      );

      await client.reply(
        exercise: _exercise,
        history: const <TutorMessage>[
          TutorMessage(text: 'Je bloque.', fromRelio: false),
          TutorMessage(text: 'Où en es-tu ?', fromRelio: true),
          TutorMessage(text: 'Au PGCD.', fromRelio: false),
        ],
      );

      expect(captured.method, 'POST');
      expect(
        captured.url.toString(),
        'https://api.example.test/v1/chat/completions',
      );
      expect(captured.headers['Authorization'], 'Bearer sk-test');
      expect(captured.headers['Content-Type'], contains('application/json'));

      final body = jsonDecode(captured.body) as Map<String, Object?>;
      expect(body['model'], 'modele-de-test');
      expect(body['temperature'], 0.4);
      expect(body['max_tokens'], 180);

      final messages = body['messages']! as List<Object?>;
      final system = messages.first! as Map<String, Object?>;
      expect(system['role'], 'system');
      expect(system['content'], contains('tuteur personnel de mathématiques'));
      expect(system['content'], contains('Calcule le PGCD de 18 et 12.'));
      expect(
        system['content'],
        contains('Valeurs acceptées : 6. Le PGCD de 18 et 12 est 6.'),
      );

      expect(messages[1], <String, Object?>{
        'role': 'user',
        'content': 'Je bloque.',
      });
      expect(messages[2], <String, Object?>{
        'role': 'assistant',
        'content': 'Où en es-tu ?',
      });
      expect(messages[3], <String, Object?>{
        'role': 'user',
        'content': 'Au PGCD.',
      });
    });

    test('ne garde que les derniers messages', () async {
      late List<Object?> messages;
      final client = OpenAiTutorClient(
        config: _config(maxHistory: 2),
        httpClient: MockClient((http.Request request) async {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          messages = body['messages']! as List<Object?>;
          return _chatResponse('Continue.');
        }),
      );

      await client.reply(
        exercise: _exercise,
        history: const <TutorMessage>[
          TutorMessage(text: 'un', fromRelio: false),
          TutorMessage(text: 'deux', fromRelio: true),
          TutorMessage(text: 'trois', fromRelio: false),
          TutorMessage(text: 'quatre', fromRelio: true),
        ],
      );

      // System + les deux derniers messages.
      expect(messages.length, 3);
      expect(messages[1], <String, Object?>{
        'role': 'user',
        'content': 'trois',
      });
      expect(messages[2], <String, Object?>{
        'role': 'assistant',
        'content': 'quatre',
      });
    });
  });

  group('OpenAiTutorClient — réponse', () {
    test('lit le contenu et supprime les espaces de bord', () async {
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient(
          (http.Request request) async => _chatResponse('  Et ensuite ?  '),
        ),
      );

      final reply = await client.reply(
        exercise: _exercise,
        history: const <TutorMessage>[],
      );

      expect(reply, 'Et ensuite ?');
    });

    test('tronque une réponse démesurée', () async {
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient(
          (http.Request request) async => _chatResponse('a' * 5000),
        ),
      );

      final reply = await client.reply(
        exercise: _exercise,
        history: const <TutorMessage>[],
      );

      expect(reply.length, 1200);
    });
  });

  group('OpenAiTutorClient — pannes', () {
    test('sans clé, n’émet aucune requête', () async {
      var called = false;
      final client = OpenAiTutorClient(
        config: _config(apiKey: '   '),
        httpClient: MockClient((http.Request request) async {
          called = true;
          return _chatResponse('inattendu');
        }),
      );

      await expectLater(
        client.reply(exercise: _exercise, history: const <TutorMessage>[]),
        throwsA(
          isA<TutorException>().having(
            (TutorException e) => e.failure,
            'failure',
            TutorFailure.notConfigured,
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('un statut non 200 est signalé avec son code', () async {
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient(
          (http.Request request) async => http.Response('refusé', 401),
        ),
      );

      await expectLater(
        client.reply(exercise: _exercise, history: const <TutorMessage>[]),
        throwsA(
          isA<TutorException>()
              .having(
                (TutorException e) => e.failure,
                'failure',
                TutorFailure.http,
              )
              .having((TutorException e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('un corps illisible est signalé', () async {
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient(
          (http.Request request) async => http.Response('pas du JSON', 200),
        ),
      );

      await expectLater(
        client.reply(exercise: _exercise, history: const <TutorMessage>[]),
        throwsA(
          isA<TutorException>().having(
            (TutorException e) => e.failure,
            'failure',
            TutorFailure.malformed,
          ),
        ),
      );
    });

    test('une réponse sans contenu est signalée', () async {
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient(
          (http.Request request) async => http.Response(
            jsonEncode(<String, Object>{'choices': <Object>[]}),
            200,
          ),
        ),
      );

      await expectLater(
        client.reply(exercise: _exercise, history: const <TutorMessage>[]),
        throwsA(
          isA<TutorException>().having(
            (TutorException e) => e.failure,
            'failure',
            TutorFailure.malformed,
          ),
        ),
      );
    });

    test('une coupure réseau est signalée', () async {
      final client = OpenAiTutorClient(
        config: _config(),
        httpClient: MockClient(
          (http.Request request) async =>
              throw http.ClientException('hors ligne'),
        ),
      );

      await expectLater(
        client.reply(exercise: _exercise, history: const <TutorMessage>[]),
        throwsA(
          isA<TutorException>().having(
            (TutorException e) => e.failure,
            'failure',
            TutorFailure.network,
          ),
        ),
      );
    });

    test('un délai dépassé est signalé', () async {
      final client = OpenAiTutorClient(
        config: _config(timeout: const Duration(milliseconds: 20)),
        httpClient: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return _chatResponse('trop tard');
        }),
      );

      await expectLater(
        client.reply(exercise: _exercise, history: const <TutorMessage>[]),
        throwsA(
          isA<TutorException>().having(
            (TutorException e) => e.failure,
            'failure',
            TutorFailure.network,
          ),
        ),
      );
    });
  });
}
