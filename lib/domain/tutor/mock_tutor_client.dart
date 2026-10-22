/// Tuteur simulé — le mode sans clé.
///
/// Tant qu'aucune clé n'est compilée (voir `docs/TUTEUR_LLM.md`), l'application
/// n'a pas de modèle à interroger. Plutôt que de laisser l'élève devant une
/// erreur, le mode simulé répond une phrase de guidage fixe : la conversation
/// reste utilisable, l'attente et le fil sont identiques au mode réel, et rien
/// ne prétend avoir interrogé un modèle.
///
/// Le texte est **volontairement neutre** : il ne propose aucune correction
/// mathématique. Inventer une réponse pédagogique reviendrait à écrire du
/// contenu de cours sans validation (règle 8).
library;

import 'tutor_client.dart';
import 'tutor_exercise_context.dart';
import 'tutor_message.dart';

/// Réponse du tuteur simulé, quand aucune clé n'est compilée.
const String kMockTutorReply =
    'Je ne peux pas encore te répondre, as-tu essayé de relire la règle ?';

/// Latence simulée, pour que l'attente affichée soit réelle et observable.
const Duration kMockTutorLatency = Duration(milliseconds: 400);

/// Tuteur sans réseau : renvoie [kMockTutorReply] après une courte attente.
///
/// Aucun appel n'est émis et l'exercice n'est pas transmis : ce client ne
/// quitte jamais l'appareil.
class MockTutorClient implements TutorClient {
  /// Crée le tuteur simulé.
  const MockTutorClient();

  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) async {
    await Future<void>.delayed(kMockTutorLatency);
    return kMockTutorReply;
  }

  @override
  void close() {}
}
