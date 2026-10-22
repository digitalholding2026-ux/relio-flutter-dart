/// Modèle des cas de diagnostic D1 à D8.
///
/// Séparation STRICTE, imposée par la mission et le document source :
///
///  - une [DiagnosticObservation] est un **FAIT** : ce qui a été constaté
///    dans la réponse de l'élève. Elle est vérifiable, reproductible ;
///  - une [DiagnosticHypothesis] est une **HYPOTHÈSE** : une cause
///    possible. Elle n'est jamais présentée comme établie.
///
/// Plusieurs hypothèses peuvent coexister pour une même observation : le
/// document source impose de « garder le diagnostic ouvert » plutôt que
/// d'imposer une cause unique.
library;

/// Niveau de certitude d'une hypothèse.
///
/// Aucune hypothèse n'est jamais « confirmée » : seul un second
/// exercice de contrôle peut cela, et cette mission ne l'implémente pas.
enum HypothesisConfidence {
  /// Cause simplement envisageable, plusieurs autres restent possibles.
  possible,

  /// L'observation oriente fortement, sans preuve suffisante.
  likely,

  /// Cause identifiée par une observation dédiée et non ambiguë.
  indicated,
}

/// Une hypothèse de diagnostic — PAS un fait.
class DiagnosticHypothesis {
  const DiagnosticHypothesis({
    required this.label,
    required this.confidence,
    this.evidence = const <String>{},
  });

  /// Cause envisagée, en langage pédagogique.
  ///
  /// Transcrite du document source ; aucune cause n'est inventée.
  final String label;

  /// Degré de confiance, jamais « certain ».
  final HypothesisConfidence confidence;

  /// Observation(s) ayant motivé l'hypothèse.
  ///
  /// Ce sont des faits, pas la preuve d'une cause.
  final Set<String> evidence;

  /// Une hypothèse n'est-elle qu'une possibilité parmi d'autres ?
  bool get isUncertain => confidence != HypothesisConfidence.indicated;

  @override
  String toString() => 'DiagnosticHypothesis($label, ${confidence.name})';
}

/// Une intervention pédagogique courte.
class Intervention {
  const Intervention({
    required this.question,
    this.reassuresProgress = false,
  });

  /// Question courte posée à l'élève, transcrite du document source.
  ///
  /// Volontairement brève : ces questions sont destinées à l'oral.
  final String question;

  /// Vrai si l'intervention valorise un progrès sans le compter comme une
  /// réussite autonome (cas D7).
  final bool reassuresProgress;

  @override
  String toString() => 'Intervention($question)';
}

/// Une tâche de vérification du transfert.
///
/// Toujours une tâche DIFFÉRENTE de celle qui a échoué : c'est une règle
/// explicite du document source (« Après une remédiation, proposer une
/// tâche différente »).
class FollowUpTask {
  const FollowUpTask({
    required this.label,
    required this.exerciseId,
    this.withHints = false,
  });

  /// Description de la tâche, transcrite du document source.
  final String label;

  /// Identifiant de l'exercice de la banque servant de vérification.
  final String exerciseId;

  /// La tâche doit-elle être proposée sans indice ?
  ///
  /// Vrai par défaut pour vérifier une réussite autonome.
  final bool withHints;

  @override
  String toString() => 'FollowUpTask($exerciseId)';
}

/// Un cas de diagnostic du prototype (D1 à D8).
class DiagnosticCase {
  const DiagnosticCase({
    required this.id,
    required this.title,
    required this.observations,
    required this.hypothesis,
    required this.intervention,
    required this.followUp,
    this.chapterNumber = 1,
    this.priorityTest = false,
    this.clarificationQuestion,
  });

  /// Identifiant stable du cas (« D1 » … « D8 »).
  ///
  /// Les identifiants ne sont uniques qu'À L'INTÉRIEUR d'un chapitre : le
  /// chapitre 2 réutilise D1/D2/D3 pour ses propres erreurs. Le moteur doit
  /// donc filtrer par [chapterNumber] avant de résoudre un code.
  final String id;

  /// Chapitre auquel ce cas appartient.
  ///
  /// Ajouté pour que deux chapitres puissent employer les mêmes codes sans se
  /// confondre : un « D1 » d'arithmétique ne doit jamais ouvrir l'intervention
  /// d'un « D1 » de Thalès. Les cas existants restent au chapitre 1.
  final int chapterNumber;

  /// Titre court du cas.
  final String title;

  /// Observations (FAITS) correspondant au scénario.
  final Set<String> observations;

  /// Hypothèses possibles : jamais uniques par construction.
  final List<DiagnosticHypothesis> hypothesis;
  /// Intervention prévue par la banque.
  final Intervention intervention;

  /// Tâche de vérification du transfert.
  final FollowUpTask followUp;

  /// Cas prioritaire pour les tests (D5 et D6 dans cette mission).
  final bool priorityTest;

  /// Question de clarification supplémentaire lorsque le diagnostic reste
  /// incertain — évite une succession indéfinie de mini-questions.
  final String? clarificationQuestion;

  /// Le cas correspond-il à l'observation [observation] ?
  bool matches(String observation) => observations.contains(observation);

  @override
  String toString() => 'DiagnosticCase($id)';
}

/// Résultat d'un diagnostic effectué sur une observation.
class DiagnosisOutcome {
  const DiagnosisOutcome({
    required this.observedFacts,
    required this.caseIds,
    required this.hypotheses,
    required this.intervention,
    this.followUp,
    this.staysOpen = false,
    this.clarificationQuestion,
  });

  /// Liste vide : aucune observation ne correspond.
  const DiagnosisOutcome.none()
      : observedFacts = const <String>[],
        caseIds = const <String>[],
        hypotheses = const <DiagnosticHypothesis>[],
        intervention = const Intervention(question: ''),
        followUp = null,
        staysOpen = false,
        clarificationQuestion = null;

  /// FAITS observés ayant motivé le diagnostic.
  final List<String> observedFacts;

  /// Cas de diagnostic mobilisés (D1…D8).
  final List<String> caseIds;

  /// HYPOTHÈSES possibles, éventuellement multiples.
  final List<DiagnosticHypothesis> hypotheses;

  /// Intervention courte à proposer.
  final Intervention intervention;

  /// Tâche de vérification du transfert.
  final FollowUpTask? followUp;

  /// Vrai si le diagnostic reste INCERTAIN et doit être clarifié.
  ///
  /// Dans ce cas, une seule question de clarification est posée, plutôt
  /// qu'une succession de mini-questions.
  final bool staysOpen;

  /// Question de clarification à poser si le diagnostic reste ouvert.
  final String? clarificationQuestion;

  /// Aucune hypothèse n'est-elle en attente de confirmation ?
  bool get isUnresolved =>
      hypotheses.isEmpty || hypotheses.every((h) => h.isUncertain);

  @override
  String toString() =>
      'DiagnosisOutcome(cases=$caseIds, open=$staysOpen)';
}
