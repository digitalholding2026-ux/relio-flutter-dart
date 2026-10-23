/// Décisions du service audio central.
///
/// Les moteurs sont remplacés par des doublures : ce sont les RÈGLES du
/// service qui sont vérifiées — mode muet, une lecture chasse l'autre, arrêt
/// sur désactivation — et non la plateforme TTS.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/services/audio/audio_service.dart';
import 'package:relio/services/audio/listening_engine.dart';
import 'package:relio/services/audio/voice_engine.dart';

class _FakeVoice implements VoiceEngine {
  final List<String> log = <String>[];
  final List<String> said = <String>[];

  @override
  Future<void> speak(String text) async {
    log.add('speak:$text');
    said.add(text);
  }

  @override
  Future<void> stop() async {
    log.add('stop');
  }
}

class _FakeListening implements ListeningEngine {
  _FakeListening({this.starts = true});

  final bool starts;
  int startCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;

  ValueChanged<String>? onWords;
  VoidCallback? onDone;
  ValueChanged<String>? onError;

  @override
  Future<bool> start({
    required ValueChanged<String> onWords,
    required VoidCallback onDone,
    required ValueChanged<String> onError,
  }) async {
    startCalls++;
    this.onWords = onWords;
    this.onDone = onDone;
    this.onError = onError;
    return starts;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

void main() {
  late _FakeVoice voice;
  late _FakeListening listening;
  late AudioService service;

  setUp(() {
    voice = _FakeVoice();
    listening = _FakeListening();
    service = AudioService(voice: voice, listening: listening);
  });

  group('mode muet', () {
    test('la voix est désactivée par défaut', () {
      expect(service.enabled, isFalse);
    });

    test('aucune lecture ne part quand la voix est coupée', () async {
      await service.speak('Bonjour');
      expect(voice.said, isEmpty);
    });

    test('syncEnabled reflète la préférence sans la persister', () async {
      var persisted = 0;
      service.onEnabledChanged = (_) async => persisted++;

      service.syncEnabled(true);

      expect(service.enabled, isTrue);
      expect(persisted, 0);
    });
  });

  group('lecture', () {
    test('le texte est nettoyé avant la synthèse', () async {
      service.syncEnabled(true);

      await service.speak('AM/AB = 2');

      expect(voice.said.single, 'A M sur A B égal à 2');
    });

    test('une nouvelle lecture coupe la précédente', () async {
      service.syncEnabled(true);

      await service.speak('Premier');
      await service.speak('Deuxième');

      expect(voice.log, <String>[
        'stop',
        'speak:Premier',
        'stop',
        'speak:Deuxième',
      ]);
    });

    test('un texte vide n’appelle pas le moteur', () async {
      service.syncEnabled(true);

      await service.speak('   ');

      expect(voice.log, isEmpty);
    });

    test('couper la voix arrête immédiatement la lecture', () async {
      service.syncEnabled(true);
      await service.speak('Bonjour');
      voice.log.clear();

      await service.setEnabled(false);

      expect(voice.log, contains('stop'));
      expect(service.enabled, isFalse);
    });
  });

  group('persistance', () {
    test('setEnabled prévient l’application', () async {
      final List<bool> written = <bool>[];
      service.onEnabledChanged = (bool value) async => written.add(value);

      await service.setEnabled(true);
      await service.setEnabled(false);

      expect(written, <bool>[true, false]);
    });

    test('toggle inverse l’état courant', () async {
      await service.toggle();
      expect(service.enabled, isTrue);

      await service.toggle();
      expect(service.enabled, isFalse);
    });
  });

  group('dictée', () {
    test('un moteur indisponible rend false, sans lever', () async {
      listening = _FakeListening(starts: false);
      service = AudioService(voice: voice, listening: listening);

      final bool started = await service.startListening(
        onWords: (_) {},
        onEnd: () {},
        onError: (_) {},
      );

      expect(started, isFalse);
      expect(service.isListening, isFalse);
    });

    test('la transcription est transmise et la fin notifiée', () async {
      String? heard;
      var ended = 0;

      final bool started = await service.startListening(
        onWords: (String words) => heard = words,
        onEnd: () => ended++,
      );

      expect(started, isTrue);
      expect(service.isListening, isTrue);

      listening.onWords?.call('bonjour');
      listening.onDone?.call();

      expect(heard, 'bonjour');
      expect(ended, 1);
      expect(service.isListening, isFalse);
    });

    test('une erreur du moteur rend la main sans bloquer', () async {
      String? error;
      final bool started = await service.startListening(
        onWords: (_) {},
        onError: (String message) => error = message,
      );

      expect(started, isTrue);
      listening.onError?.call('micro');

      expect(error, 'micro');
      expect(service.isListening, isFalse);
    });

    test('annuler la dictée ne notifie pas la fin', () async {
      var ended = 0;
      await service.startListening(
        onWords: (_) {},
        onEnd: () => ended++,
      );

      await service.cancelListening();

      expect(ended, 0);
      expect(service.isListening, isFalse);
      expect(listening.cancelCalls, 1);
    });

    test('une dictée coupe la lecture en cours', () async {
      service.syncEnabled(true);
      await service.speak('Bonjour');
      voice.log.clear();

      await service.startListening(onWords: (_) {});

      expect(voice.log, contains('stop'));
    });
  });
}
