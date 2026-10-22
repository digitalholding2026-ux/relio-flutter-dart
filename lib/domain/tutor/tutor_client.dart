/// Contrat du tuteur : une question, une réponse guidée.
///
/// L'interface ne connaît que ce contrat. Un client réel, un faux client de
/// test ou le mode repli sont interchangeables : la mise en page ne bouge pas.
library;

import 'tutor_exercise_context.dart';
import 'tutor_message.dart';

/// Pourquoi le tuteur n'a pas pu répondre.
enum TutorFailure {
  /// Aucune clé n'est configurée (ou le client est explicitement indisponible).
  notConfigured,

  /// Réseau indisponible, délai dépassé.
  network,

  /// Le fournisseur a répondu autre chose que 200.
  http,

  /// Réponse vide ou illisible.
  malformed,
}

/// Échec d'un appel au tuteur.
class TutorException implements Exception {
  /// Crée l'échec.
  const TutorException(this.failure, {this.statusCode, this.message});

  /// Nature de l'échec.
  final TutorFailure failure;

  /// Code HTTP, si connu.
  final int? statusCode;

  /// Détail technique, pour les journaux — jamais affiché à l'élève.
  final String? message;

  @override
  String toString() =>
      'TutorException($failure${statusCode == null ? '' : ', HTTP $statusCode'})';
}

/// Capacité à répondre à un message dans le contexte d'un exercice.
abstract interface class TutorClient {
  /// Demande une réponse au tuteur.
  ///
  /// [history] contient la conversation, dans l'ordre, message de l'élève
  /// compris. Lève [TutorException] si le tuteur ne peut pas répondre.
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  });

  /// Libère les ressources réseau.
  void close();
}

/// Tuteur sans modèle : signale l'absence de configuration.
///
/// L'interface affiche alors la phrase de repli, comme pour une panne réseau.
class UnavailableTutorClient implements TutorClient {
  /// Crée le client indisponible.
  const UnavailableTutorClient();

  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) async {
    throw const TutorException(TutorFailure.notConfigured);
  }

  @override
  void close() {}
}
