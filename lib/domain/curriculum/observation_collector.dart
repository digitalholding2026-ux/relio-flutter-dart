/// Collecte des OBSERVATIONS à partir d'une tentative réelle.
///
/// Règle Fondamentale de ce fichier : une observation est un **FAIT**. Elle
/// est dérivée de ce que l'élève a fait, jamais de ce qu'on suppose qu'il a
/// compris.
///
/// Corollaire, non négociable : **une observation absente vaut mieux
/// qu'une observation devinée**. Le moteur de diagnostic（D1 à D8）ne produit
/// que des hypothèses à partir de faits ; un fait fabriqué produirait une
/// cause affirmée à tort, et cette cause serait écrite définitivement dans
/// un historique immuable.
library;

import '../../domain/learning/exercise_attempt.dart';
import 'chapter1_service.dart';
import 'exercise.dart';

/// Faits observables, codés sous forme d'identifiants stables.
///
/// Les identifiants correspondent exactement à ceux attendus par
/// [Chapter1Bank.diagnosticCases]. Aucun autre n'est produit.
abstract final class ObservedFacts {
  /// L'élève a réussi APRÈS avoir consulté au moins un indice.
  ///
  /// Fait directement lisible dans la trajectoire des indices. C'est le
  /// SEUL fait que l'interface sait produire aujourd'hui de façon fiable.
  static const String reussiteApresIndice = 'reussite_apres_indice';

  /// L'élève a réussi sans jamais montrer sa démarche.
  ///
  /// VOLONTAIREMENT NON PRODUIT. L'interface ne capture aucune démarche :
  /// dans les données, un élève qui écrit la bonne réponse sans rien écrire
  /// de plus ne se distingue pas d'un élève qui a raisonné correctement, ou
  /// qui a deviné. Émettre ce fait en permanence accuserait de « stratégie
  /// inconnue » tout élève qui réussit — une affirmation infondée.
  static const String reponseCorrecteSansDemarche = 'reponse_correcte_sans_demarche';
}

/// Résultat de la collecte : les faits établis, et ceux qui restent hors de
/// portée de l'interface.
class ObservationReport {
  const ObservationReport({
    required this.facts,
    required this.unreachableFacts,
  });

  /// FAITS établis à partir des données réellement disponibles.
  final Set<String> facts;

  /// Faits attendus par la banque mais NON.productibles en l'état.
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

/// Les observations attendues par la banque, mais qui exigent une analyse
/// du pas-à-pas que l'interface ne capture pas.
///
/// L'élève ne saisit qu'un RÉSULTAT final. Or D1 à D6 décrivent tous un
/// endroit précis d'un raisonnement : « soustraction fausse », « mauvais
/// couple repris », « arrêt avec reste non nul ». Aucun de ces faits ne peut
/// être déduit d'un résultat final seul : PGCD(18, 12) vaut 6, mais le
/// chemin qui y mène peut être juste ou faux, et les données ne le
/// distinguent pas.
const Set<String> kFactsRequiringStepByStep = <String>{
  'soustraction_fausse',
  'poursuit_apres_valeurs_egales',
  'mauvais_couple_repris',
  'arret_avec_reste_non_nul',
  'pgcd_correct_ppcm_faux',
  'confusion_pgcd_ppcm',
};

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

  return ObservationReport(
    facts: facts,
    unreachableFacts: <String>{
      ...kFactsRequiringStepByStep,
      ObservedFacts.reponseCorrecteSansDemarche,
    }.difference(facts),
  );
}