/// Service audio central de Relio.
///
/// UN SEUL POINT DE PASSAGE pour tout ce qui se dit et tout ce qui s'écoute.
///
/// Trois rôles, un seul service :
///  - le NARRATEUR lit les consignes et les messages de l'accueil ;
///  - le LECTEUR lit les énoncés, les indices et les corrections ;
///  - le CONVERSATIONALISTE dicte dans le chat du tuteur.
///
/// Deux garanties structurent le service :
///  1. **Une action chasse l'autre.** Toute nouvelle lecture commence par
///     couper la précédente : deux voix ne se superposent jamais.
///  2. **Le mode muet est absolu.** Si la voix est désactivée, aucune lecture
///     ne part — même si un écran oublie de vérifier.
///
/// Le service ne persiste rien : l'état est porté par `LearnerSettings` et
/// l'application le reflète ici via [syncEnabled]. Les widgets qui basculent
/// l'interrupteur passent par [setEnabled], qui prévient l'application par
/// [onEnabledChanged].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'listening_engine.dart';
import 'speech_text.dart';
import 'voice_engine.dart';

/// Service partagé par toute l'application.
class AudioService extends ChangeNotifier {
  /// Crée le service.
  ///
  /// Les moteurs sont injectables : les tests vérifient les décisions du
  /// service sans plateforme audio.
  AudioService({VoiceEngine? voice, ListeningEngine? listening})
    : _voice = voice ?? FlutterTtsEngine(),
      _listening = listening ?? SpeechListeningEngine();

  /// Instance utilisée par l'application.
  ///
  /// Mutable pour que les tests puissent la remplacer sans toucher au code de
  /// production.
  static AudioService instance = AudioService();

  final VoiceEngine _voice;
  final ListeningEngine _listening;

  bool _enabled = false;

  /// Préférence « Voix du tuteur ». Désactivée par défaut.
  bool get enabled => _enabled;

  /// Prévient l'application qu'il faut persister le nouveau choix.
  ///
  /// Posé par la racine de l'application, jamais par un écran : un écran ne
  /// sait pas où les préférences sont stockées.
  Future<void> Function(bool enabled)? onEnabledChanged;

  bool _listeningNow = false;

  /// Une écoute micro est-elle en cours ?
  bool get isListening => _listeningNow;

  /// Reflète une préférence chargée depuis la base, SANS la réécrire.
  ///
  /// Appelé par la racine à chaque changement de `LearnerSettings` : c'est la
  /// base qui reste la source de vérité, le service n'en est que le miroir.
  void syncEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) unawaited(stop());
    notifyListeners();
  }

  /// Bascule la voix et prévient l'application pour la persistance.
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) await stop();
    notifyListeners();
    try {
      await onEnabledChanged?.call(value);
    } on Object {
      // La préférence n'a pas pu être écrite : la voix reste utilisable pour
      // la session en cours, rien n'est bloqué.
    }
  }

  /// Inverse l'état de la voix (icône globale).
  Future<void> toggle() => setEnabled(!_enabled);

  /// Lit [text] à voix haute.
  ///
  /// Coupe d'abord toute lecture en cours : c'est la règle « une action chasse
  /// l'autre ». Ne fait rien si la voix est coupée ou si le texte ne contient
  /// rien de prononçable.
  Future<void> speak(String text) async {
    if (!_enabled) return;

    final String clean = speechText(text);
    if (clean.isEmpty) return;

    try {
      await _voice.stop();
      await _voice.speak(clean);
    } on Object {
      // Une synthèse indisponible ne doit jamais interrompre l'interface.
    }
  }

  /// Coupe la lecture en cours.
  Future<void> stop() async {
    try {
      await _voice.stop();
    } on Object {
      // Rien à couper.
    }
  }

  /// Demande la permission puis démarre une dictée.
  ///
  /// Rend `false` si le micro n'est pas disponible ou si l'élève refuse :
  /// l'appelant affiche alors le message doux prévu.
  Future<bool> startListening({
    required ValueChanged<String> onWords,
    VoidCallback? onEnd,
    ValueChanged<String>? onError,
  }) async {
    if (_listeningNow) return true;

    // Une dictée n'a pas de sens par-dessus une voix qui parle.
    await stop();

    final bool started = await _listening.start(
      onWords: onWords,
      onDone: () {
        if (!_listeningNow) return;
        _listeningNow = false;
        notifyListeners();
        onEnd?.call();
      },
      onError: (String message) {
        if (_listeningNow) {
          _listeningNow = false;
          notifyListeners();
        }
        onError?.call(message);
      },
    );

    if (started) {
      _listeningNow = true;
      notifyListeners();
    }
    return started;
  }

  /// Arrête la dictée en conservant la transcription reçue.
  Future<void> stopListening() async {
    await _listening.stop();
    if (_listeningNow) {
      _listeningNow = false;
      notifyListeners();
    }
  }

  /// Arrête la dictée et abandonne la transcription.
  Future<void> cancelListening() async {
    await _listening.cancel();
    if (_listeningNow) {
      _listeningNow = false;
      notifyListeners();
    }
  }
}
