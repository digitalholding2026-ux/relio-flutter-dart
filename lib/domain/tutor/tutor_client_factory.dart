/// Construction du tuteur selon la configuration compilée.
///
/// Un seul point de décision :
///  - clé compilée → [OpenAiTutorClient], branché sur OpenRouter ;
///  - pas de clé → [MockTutorClient], **mode simulé**, sans appel réseau.
///
/// Dans les deux cas l'interface se comporte de la même façon : message de
/// l'élève, attente, puis réponse. Une panne réelle (réseau, HTTP, réponse
/// illisible) reste traitée par l'interface, qui propose de réessayer.
library;

import 'mock_tutor_client.dart';
import 'openai_tutor_client.dart';
import 'tutor_client.dart';
import 'tutor_config.dart';

/// Crée le client du tuteur.
///
/// [config] est destiné aux tests ; par défaut, la configuration vient des
/// `dart-define` (voir `docs/TUTEUR_LLM.md`).
TutorClient buildTutorClient({TutorConfig? config}) {
  final resolved = config ?? TutorConfig.fromEnvironment();
  if (!resolved.isConfigured) return const MockTutorClient();
  return OpenAiTutorClient(config: resolved);
}
