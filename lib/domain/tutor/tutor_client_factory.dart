/// Construction du tuteur selon la configuration compilée.
///
/// Un seul point de décision : sans clé, aucun appel réseau n'est possible et
/// l'application reçoit un [UnavailableTutorClient]. L'interface se comporte
/// alors exactement comme sur une panne réseau — phrase de repli, pas d'erreur
/// technique.
library;

import 'openai_tutor_client.dart';
import 'tutor_client.dart';
import 'tutor_config.dart';

/// Crée le client du tuteur.
///
/// [config] est destiné aux tests ; par défaut, la configuration vient des
/// `dart-define` (voir `docs/TUTEUR_LLM.md`).
TutorClient buildTutorClient({TutorConfig? config}) {
  final resolved = config ?? TutorConfig.fromEnvironment();
  if (!resolved.isConfigured) return const UnavailableTutorClient();
  return OpenAiTutorClient(config: resolved);
}
