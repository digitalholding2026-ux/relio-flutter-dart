/// Moteur de synthèse vocale, derrière une interface étroite.
///
/// L'interface existe pour que le service audio ne dépende pas du plugin :
/// les tests fournissent un moteur muet et vérifient les décisions (couper la
/// lecture précédente, respecter le mode muet) sans plateforme.
library;

import 'package:flutter_tts/flutter_tts.dart';

/// Ce que le service audio attend d'un moteur de synthèse.
abstract interface class VoiceEngine {
  /// Dit [text] à voix haute.
  Future<void> speak(String text);

  /// Coupe immédiatement la lecture en cours.
  Future<void> stop();
}

/// Implémentation réelle, adossée à `flutter_tts`.
class FlutterTtsEngine implements VoiceEngine {
  /// Crée le moteur ; [tts] permet d'injecter une instance dans les tests.
  FlutterTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _ready = _configure();
  }

  final FlutterTts _tts;

  /// Configuration initiale, attendue avant la première lecture.
  ///
  /// Elle ne lève jamais : sur une plateforme sans synthèse (tests, poste sans
  /// moteur vocal), le service reste simplement muet.
  late final Future<void> _ready;

  Future<void> _configure() async {
    try {
      await _tts.setLanguage('fr-FR');
      // Débit légèrement posé : le public est scolaire, pas pressé.
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(false);
    } on Object {
      // Aucun moteur vocal disponible : rien à configurer.
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _ready;
      // Une nouvelle action coupe toujours la précédente.
      await _tts.stop();
      await _tts.speak(text);
    } on Object {
      // Un échec de synthèse ne doit jamais interrompre l'interface.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // Rien à couper.
    }
  }
}
