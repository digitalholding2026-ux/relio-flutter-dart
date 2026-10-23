/// Moteur d'écoute vocale (micro → texte), derrière une interface étroite.
///
/// Comme [VoiceEngine], l'interface isole le service audio du plugin : les
/// tests fournissent un moteur factice et vérifient le comportement de
/// l'interface sans micro ni permission système.
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Ce que le service audio attend d'un moteur d'écoute.
abstract interface class ListeningEngine {
  /// Demande la permission, puis démarre une écoute.
  ///
  /// Rend `true` si l'écoute a réellement commencé. [onWords] reçoit la
  /// transcription (partielle puis finale), [onDone] la fin de l'écoute et
  /// [onError] un incident non bloquant.
  Future<bool> start({
    required ValueChanged<String> onWords,
    required VoidCallback onDone,
    required ValueChanged<String> onError,
  });

  /// Arrête l'écoute en conservant la transcription déjà reçue.
  Future<void> stop();

  /// Arrête l'écoute et abandonne la transcription en cours.
  Future<void> cancel();
}

/// Implémentation réelle, adossée à `speech_to_text` et `permission_handler`.
class SpeechListeningEngine implements ListeningEngine {
  /// Crée le moteur ; [speech] permet d'injecter une instance dans les tests.
  SpeechListeningEngine({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  bool _initialized = false;

  ValueChanged<String>? _onWords;
  VoidCallback? _onDone;
  ValueChanged<String>? _onError;
  bool _doneSent = false;

  Future<bool> _ensureReady() async {
    try {
      final PermissionStatus status = await Permission.microphone.status;
      if (!status.isGranted) {
        final PermissionStatus requested = await Permission.microphone.request();
        if (!requested.isGranted) return false;
      }

      if (!_initialized) {
        _initialized = await _speech.initialize(
          onStatus: (String status) {
            if (status == 'done' || status == 'notListening') _finish();
          },
          onError: (SpeechRecognitionError error) {
            _fail(error.errorMsg);
          },
        );
      }
      return _initialized;
    } on Object {
      // Permission refusée, service absent, plateforme sans micro : l'appelant
      // affiche le message doux prévu par l'interface.
      return false;
    }
  }

  @override
  Future<bool> start({
    required ValueChanged<String> onWords,
    required VoidCallback onDone,
    required ValueChanged<String> onError,
  }) async {
    _onWords = onWords;
    _onDone = onDone;
    _onError = onError;
    _doneSent = false;

    if (!await _ensureReady()) {
      _clear();
      return false;
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.recognizedWords.isNotEmpty) {
            _onWords?.call(result.recognizedWords);
          }
          if (result.finalResult) _finish();
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: 'fr_FR',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      return true;
    } on Object {
      _fail('listen');
      _clear();
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Object {
      // Aucune écoute en cours.
    }
    _finish();
  }

  @override
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } on Object {
      // Aucune écoute en cours.
    }
    _clear();
  }

  void _finish() {
    if (_doneSent) return;
    _doneSent = true;
    final VoidCallback? done = _onDone;
    _clear();
    done?.call();
  }

  void _fail(String message) {
    final ValueChanged<String>? error = _onError;
    _clear();
    error?.call(message);
  }

  void _clear() {
    _onWords = null;
    _onDone = null;
    _onError = null;
  }
}
