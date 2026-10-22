/// Moteur de diagnostic du chapitre 1.
///
/// Responsabilités :
///  - détecter les observations correspondant aux cas D1 à D8 ;
///  - produire des HYPOTHÈSES (jamais des faits) ;
///  - proposer l'intervention prévue par la banque ;
///  - proposer une tâche de vérification du transfert.
///
/// Règles du document source respectées :
///
///  1. Une observation ne justifie JAMAIS une cause unique : le moteur
///     conserve plusieurs hypothèses quand plusieurs explications sont
///     possibles.
///  2. Après une remédiation, la tâche proposée est DIFFÉRENTE de celle qui
///     a échoué.
///  3. Lorsque le diagnostic reste incertain, on pose UNE question de
///     clarification — jamais une succession indéfinie de mini-questions.
///  4. D5 et D6 sont prioritaires : ils doivent rester distinguables.
library;

import 'chapter1_bank.dart';
import 'diagnostic_case.dart';
import 'exercise.dart';

/// Observation constatée sur une tentative.
///
/// Les observations sont des FAITS déduits de la réponse et de la
/// démarche de l'élève. Aucune n'est une interprétation.
class AttemptObservation {
  const AttemptObservation({required this.facts});

  /// Faits observés, codés sous forme d'identifiants stables
  /// (`soustraction_fausse`, `reussite_apres_indice`, …).
  final Set<String> facts;

  /// Vrai si [fact] a été observé.
  bool has(String fact) => facts.contains(fact);

  @override
  String toString() => 'AttemptObservation($facts)';
}

/// Contexte d'une tentative, nécessaire au diagnostic.
///
/// Réutilise les modèles du socle plutôt que d'en créer de parallèles.
class DiagnosticContext {
  const DiagnosticContext({
    required this.observation,
    required this.failedExerciseId,
    this.succeededExerciseId,
    this.clarificationAlreadyAsked = 0,
  });

  /// Faits observés sur la tentative.
  final AttemptObservation observation;

  /// Exercice sur lequel l'élève a échoué, s'il y a lieu.
  final String? failedExerciseId;

  /// Exercice réussi, lorsqu'une remédiation doit être vérifiée.
  final String? succeededExerciseId;

  /// Nombre de questions de clarification déjà posées.
  ///
  /// Au-delà d'un seuil, le moteur cesse de poser des questions : le
  /// document source interdit la succession indéfinie de mini-questions.
  final int clarificationAlreadyAsked;

  /// Seuil au-delà duquel on cesse de clarifier et on passe à l'action.
  static const int maxClarifications = 2;

  /// Faut-il encore poser une question de clarification ?
  bool get canClarify => clarificationAlreadyAsked < maxClarifications;
}

/// Moteur de diagnostic de la banque pilote.
class DiagnosticEngine {
  const DiagnosticEngine({
    List<DiagnosticCase> cases = Chapter1Bank.diagnosticCases,
  }) : _cases = cases; // ignore: prefer_initializing_formals

  final List<DiagnosticCase> _cases;

  /// Les cas pris en charge.
  List<DiagnosticCase> get cases => List.unmodifiable(_cases);

  /// Exécute un diagnostic sur [context].
  ///
  /// Retourne un [DiagnosisOutcome] dont :
  ///  - [DiagnosisOutcome.observedFacts] ne contient QUE des faits ;
  ///  - [DiagnosisOutcome.hypotheses] contient une ou plusieurs causes
  ///    POSSIBLES ;
  ///  - [DiagnosisOutcome.staysOpen] signale une incertitude non résolue.
  DiagnosisOutcome diagnose(DiagnosticContext context) {
    final facts = context.observation.facts;

    // Aucun fait exploitable : on ne fabrique pas de diagnostic.
    if (facts.isEmpty) return const DiagnosisOutcome.none();

    final matched = <DiagnosticCase>[];
    for (final diagnostic in _cases) {
      if (facts.any(diagnostic.matches)) matched.add(diagnostic);
    }

    if (matched.isEmpty) return const DiagnosisOutcome.none();

    // D5 et D6 doivent rester DISTINGUABLES. Si les deux sont présents,
    // c'est précisément le cas où le diagnostic doit rester ouvert : les
    // deux causes (isolement algébrique vs confusion conceptuelle)
    // exigent des vérifications différentes.
    final ambiguous = _hasAmbiguousMatch(matched, facts);

    final hypotheses = <DiagnosticHypothesis>[
      for (final diagnostic in matched) ...diagnostic.hypothesis,
    ];

    // Une seule intervention est proposée : la plus prioritaire.
    final primary = _primaryCase(matched);

    // La tâche de vérification est DIFFÉRENTE de l'exercice échoué.
    final followUp = _resolveFollowUp(primary, context);

    final staysOpen = ambiguous || !context.canClarify;
    final clarification = ambiguous && context.canClarify
        ? primary.clarificationQuestion
        : null;

    return DiagnosisOutcome(
      observedFacts: List<String>.of(facts),
      caseIds: matched.map((c) => c.id).toList(),
      hypotheses: hypotheses,
      intervention: primary.intervention,
      followUp: followUp,
      staysOpen: staysOpen,
      clarificationQuestion: clarification,
    );
  }

  /// Diagnostic explicite à partir de la carte [Exercise.errorCases].
  ///
  /// C'est le chemin PRIORITAIRE de la correction : une réponse mappée par la
  /// banque ouvre directement l'intervention du cas (panneau C), sans passer
  /// par les observations déduites de la réponse.
  ///
  /// Retourne `null` si la réponse n'est pas mappée, ou si l'identifiant de
  /// cas est inconnu. L'appelant garde alors le chemin habituel.
  DiagnosisOutcome? diagnoseAnswer({
    required Exercise exercise,
    required String rawAnswer,
  }) {
    final caseId = exercise.errorCaseFor(rawAnswer);
    if (caseId == null) return null;

    for (final diagnostic in _cases) {
      if (diagnostic.id != caseId) continue;

      // Même garde-fou que [diagnose] : la tâche de vérification ne doit
      // jamais être l'exercice qui vient d'échouer.
      final followUp = diagnostic.followUp.exerciseId == exercise.id
          ? null
          : diagnostic.followUp;

      return DiagnosisOutcome(
        observedFacts: List<String>.of(diagnostic.observations),
        caseIds: <String>[diagnostic.id],
        hypotheses: diagnostic.hypothesis,
        intervention: diagnostic.intervention,
        followUp: followUp,
        // Une correspondance explicite ne demande pas de clarification :
        // la banque a déjà tranché le cas.
        staysOpen: false,
      );
    }

    return null;
  }

  /// Ferme la clarification après la réponse de l'élève.
  ///
  /// Aucune hypothèse n'est ajoutée ni confirmée : une réponse à une question
  /// ne prouve pas une cause. Le moteur cesse simplement de demander, comme
  /// l'exige la règle « une seule clarification, jamais une série ».
  DiagnosisOutcome submitClarification(
    DiagnosisOutcome diagnosis,
    String answer,
  ) {
    if (diagnosis.clarificationQuestion == null) return diagnosis;
    if (answer.trim().isEmpty) return diagnosis;
    return DiagnosisOutcome(
      observedFacts: diagnosis.observedFacts,
      caseIds: diagnosis.caseIds,
      hypotheses: diagnosis.hypotheses,
      intervention: diagnosis.intervention,
      followUp: diagnosis.followUp,
      staysOpen: false,
    );
  }

  /// Deux cas sont-ils en concurrence sur les mêmes faits ?
  ///
  /// C'est le cas de D5 et D6 : tous deux s'appliquent à la leçon 3, et une
  /// réponse peut déclencher l'un ou l'autre sans permettre de trancher.
  bool _hasAmbiguousMatch(List<DiagnosticCase> matched, Set<String> facts) {
    final ids = matched.map((c) => c.id).toSet();
    // D5 + D6 simultanément : la distinction est le point délicat de la
    // mission, elle ne doit JAMAIS être tranchée automatiquement.
    if (ids.contains('D5') && ids.contains('D6')) return true;

    // Deux cas pour un seul fait, sans fait discriminant : le diagnostic
    // reste ouvert plutôt que de trancher arbitrairement.
    return facts.length == 1 && matched.length > 1;
  }

  /// Cas prioritaire : D5 et D6 d'abord, puis l'ordre du document.
  DiagnosticCase _primaryCase(List<DiagnosticCase> matched) {
    for (final candidate in matched) {
      if (candidate.priorityTest) return candidate;
    }
    return matched.first;
  }

  /// Tâche de vérification, en garantissant qu'elle diffère de l'échec.
  FollowUpTask? _resolveFollowUp(
    DiagnosticCase diagnostic,
    DiagnosticContext context,
  ) {
    final task = diagnostic.followUp;
    if (task.exerciseId != context.failedExerciseId) return task;

    // Garde-fou : la banque exige une tâche DIFFÉRENTE. Si la tâche prévue
    // est l'exercice qui a échoué, on ne propose rien plutôt que de
    // proposer une vérification qui ne vérifierait rien.
    return null;
  }
}
