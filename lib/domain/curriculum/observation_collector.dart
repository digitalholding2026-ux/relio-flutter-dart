/// Collecte des OBSERVATIONS à partir d'une tentative réelle.
///
/// Règle Fondamentale de ce fichier : une observation est un **FAIT**. Elle
/// est dérivée de ce que l'élève a fait, jamais de ce qu'on suppose qu'il a
/// compris.
///
/// Corollaire, non négociable : **une observation absente vaut mieux
/// qu'une observation devinée**. Le moteur de diagnostic (D1 à D8) ne produit
/// que des hypothèses à partir de faits ; un fait fabriqué produirait une
/// cause affirmée à tort, et cette cause serait écrite définitivement dans
/// un historique immuable.
///
/// Ce que l'interface peut réellement lire :
///  - une réussite après indice (trajectoire des indices) ;
///  - un PPCM faux alors que le PGCD était DONNÉ par l'énoncé ;
///  - une réponse égale au PGCD donné (confusion observable) ;
///  - un arrêt sur un reste intermédiaire non nul (valeur lue dans les étapes
///    validées de l'exercice) ;
///  - le zéro produit par une soustraction de plus après l'égalité ;
///  - un PGCD négatif, signe d'une soustraction faite à l'envers.
///
/// Tout le reste reste HORS DE PORTÉE : un résultat final ne dit pas quelle
/// soustraction a été fausse, ni quel couple a été repris.
library;

import '../../domain/learning/exercise_attempt.dart';
import 'answer_normalization.dart';
import 'chapter1_service.dart';
import 'exercise.dart';

/// Faits observables, codés sous forme d'identifiants stables.
///
/// Les identifiants correspondent exactement à ceux attendus par
/// [Chapter1Bank.diagnosticCases]. Aucun autre n'est produit.
abstract final class ObservedFacts {
  /// Une soustraction a été faite à l'envers (PGCD négatif).
  ///
  /// Un PGCD est positif par définition. Une valeur négative prouve donc une
  /// opération inversée, sans dire laquelle.
  static const String soustractionFausse = 'soustraction_fausse';

  /// L'élève a poursuivi après deux valeurs égales : la soustraction
  /// supplémentaire donne zéro.
  static const String poursuitApresValeursEgales =
      'poursuit_apres_valeurs_egales';

  /// Un mauvais couple a été repris dans l'algorithme d'Euclide.
  ///
  /// Non produit par l'interface : un résultat final ne permet pas de savoir
  /// quel couple l'élève a réutilisé.
  static const String mauvaisCoupleRepris = 'mauvais_couple_repris';

  /// L'élève s'est arrêté sur un reste intermédiaire non nul.
  static const String arretAvecResteNonNul = 'arret_avec_reste_non_nul';

  /// Le PGCD était donné et correct, mais le PPCM calculé est faux.
  static const String pgcdCorrectPpcmFaux = 'pgcd_correct_ppcm_faux';

  /// La réponse est exactement le PGCD fourni par l'énoncé, alors que la
  /// question demandait le PPCM.
  static const String confusionPgcdPpcm = 'confusion_pgcd_ppcm';

  /// L'élève a réussi APRÈS avoir consulté au moins un indice.
  static const String reussiteApresIndice = 'reussite_apres_indice';

  /// L'élève a réussi sans jamais montrer sa démarche.
  ///
  /// VOLONTAIREMENT NON PRODUIT. L'interface ne capture aucune démarche :
  /// dans les données, un élève qui écrit la bonne réponse sans rien écrire
  /// de plus ne se distingue pas d'un élève qui a raisonné correctement, ou
  /// qui a deviné. Émettre ce fait en permanence accuserait de « stratégie
  /// inconnue » tout élève qui réussit — une affirmation infondée.
  static const String reponseCorrecteSansDemarche =
      'reponse_correcte_sans_demarche';
}

/// Les faits qu'un tuteur peut signaler au moteur depuis la conversation.
///
/// Ce sont les seuls faits d'ERREUR de la banque. Les faits de réussite
/// (D7, D8) ne sont pas des erreurs et ne déclenchent pas une intervention.
const Set<String> kTutorReportableFacts = <String>{
  ObservedFacts.soustractionFausse,
  ObservedFacts.poursuitApresValeursEgales,
  ObservedFacts.mauvaisCoupleRepris,
  ObservedFacts.arretAvecResteNonNul,
  ObservedFacts.pgcdCorrectPpcmFaux,
  ObservedFacts.confusionPgcdPpcm,
};

/// Les observations attendues par la banque, mais qui exigent une analyse
/// du pas-à-pas que l'interface ne capture pas toujours.
///
/// Certaines deviennent lisibles sur un exercice précis : c'est alors la
/// structure de l'énoncé qui le permet (PGCD donné, reste intermédiaire
/// connu), jamais une supposition sur la démarche.
const Set<String> kFactsRequiringStepByStep = <String>{
  ObservedFacts.soustractionFausse,
  ObservedFacts.poursuitApresValeursEgales,
  ObservedFacts.mauvaisCoupleRepris,
  ObservedFacts.arretAvecResteNonNul,
  ObservedFacts.pgcdCorrectPpcmFaux,
  ObservedFacts.confusionPgcdPpcm,
};

/// Résultat de la collecte : les faits établis, et ceux qui restent hors de
/// portée de l'interface.
class ObservationReport {
  const ObservationReport({
    required this.facts,
    required this.unreachableFacts,
  });

  /// FAITS établis à partir des données réellement disponibles.
  final Set<String> facts;

  /// Faits attendus par la banque mais NON productibles en l'état.
  ///
  /// Ce ne sont pas des échecs : ce sont des limites documentées. Les
  /// lister évite qu'un lecteur futur croie à un oubli.
  final Set<String> unreachableFacts;

  /// Un seul fait observable suffit-il à faire avancer le diagnostic ?
  bool get hasAnyFact => facts.isNotEmpty;

  @override
  String toString() =>
      'ObservationReport(${facts.isEmpty ? 'aucun fait' : facts.join(', ')})';
}

/// Collecte les faits d'une tentative.
///
/// Signature volontairement pauvre : elle ne reçoit que des données déjà
/// enregistrées. Si l'interface apprend un jour à capturer une démarche,
/// cette fonction sera le point d'entrée à enrichir — et les tests
/// existants continueront de garantir qu'aucun fait n'apparaît sans
/// donnée correspondante.
ObservationReport collectObservations({
  required AttemptRecord record,
  required Exercise exercise,
}) {
  final facts = <String>{};

  // Réussite assistée : le seul fait que la trajectoire établit sans
  // aucune interprétation. Le moteur en déduit D7, qui ne fait qu'inciter
  // à réessayer SANS indice.
  if (record.outcome == AnswerOutcome.correct &&
      record.trajectory.consumedOrders.isNotEmpty) {
    facts.add(ObservedFacts.reussiteApresIndice);
  }

  // Échec évalué : les faits lisibles dans la réponse et dans la structure
  // de l'exercice. Aucun n'est produit pour une réponse non évaluable.
  if (record.outcome == AnswerOutcome.incorrect) {
    facts.addAll(_observableErrorFacts(exercise, record.rawAnswer));
  }

  return ObservationReport(
    facts: facts,
    unreachableFacts: <String>{
      ...kFactsRequiringStepByStep,
      ObservedFacts.reponseCorrecteSansDemarche,
    }.difference(facts),
  );
}

/// Faits d'erreur que la réponse seule rend vérifiables.
///
/// Chaque règle s'appuie sur une donnée de l'exercice (PGCD fourni, étapes
/// validées) : aucune ne reconstitue un raisonnement.
Set<String> _observableErrorFacts(Exercise exercise, String rawAnswer) {
  final facts = <String>{};
  if (exercise.diagnosticCaseIds.isEmpty) return facts;

  final parsed = parseInteger(rawAnswer.trim());
  if (parsed == null) return facts;

  final cases = exercise.diagnosticCaseIds.toSet();

  // La question ne demande que le PPCM, et le PGCD est DONNÉ par l'énoncé.
  // Le PGCD est donc correct par construction : un PPCM faux est un fait.
  if (exercise.givenPgcd != null) {
    facts.add(ObservedFacts.pgcdCorrectPpcmFaux);
    // Répondre exactement le PGCD donné, alors qu'on demande le PPCM, est
    // une confusion observable — pas une hypothèse sur l'intention.
    if (parsed == exercise.givenPgcd) {
      facts.add(ObservedFacts.confusionPgcdPpcm);
    }
  }

  // Arrêt sur un reste intermédiaire non nul : la valeur est dans les étapes
  // validées, et elle n'est ni zéro ni le résultat final.
  if (cases.contains('D4')) {
    final expected = exercise.correction.acceptedValues.isEmpty
        ? null
        : exercise.correction.acceptedValues.first;
    for (final step in exercise.expectedSteps) {
      if (step.kind != SolutionStepKind.operation) continue;
      final value = step.value;
      if (value == null || value == 0 || value == expected) continue;
      if (parsed == value) {
        facts.add(ObservedFacts.arretAvecResteNonNul);
      }
    }
  }

  // Poursuivre une soustraction après l'égalité produit zéro : c'est
  // exactement ce que fait l'élève qui ne s'arrête pas à temps.
  if (cases.contains('D2') && parsed == 0) {
    facts.add(ObservedFacts.poursuitApresValeursEgales);
  }

  // Un PGCD négatif prouve une soustraction faite dans le mauvais ordre.
  if (cases.contains('D1') && parsed < 0) {
    facts.add(ObservedFacts.soustractionFausse);
  }

  return facts;
}
