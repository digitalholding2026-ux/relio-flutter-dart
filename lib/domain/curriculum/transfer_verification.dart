/// Vérification de transfert — règle d'affichage, S4.
///
/// L'écran S4 (« Vérifier ma maîtrise ») est FERMÉ en V1. Ce fichier ne
/// l'ouvre pas : il fixe la règle qui devra s'appliquer le jour où il
/// s'ouvrira, et il explique, en code, pourquoi il reste fermé.
///
/// Deux raisons, distinctes, de ne pas l'ouvrir aujourd'hui :
///
///  1. **Aucune association n'existe dans les données.** La banque déclare
///     un `followUpTask` sur trois exercices (ex2, ex7, ex9), mais ces
///     cibles sont des EXERCICES, pas des tâches de vérification. Les six
///     tâches de vérification ne sont rattachées qu'aux cas de diagnostic
///     D1 à D6, et ces cas ne se déclenchent qu'avec des observations que
///     l'interface ne produit pas. Relier un exercice à une tâche « parce
///     qu'ils sont du même chapitre » serait inventer une décision
///     pédagogique, pas appliquer une règle.
///
///  2. **Le bouton ne doit jamais mentir.** Même avec une association, il
///     n'apparaît qu'après une réussite AUTONOME. Une réussite obtenue avec
///     un indice ne doit jamais être présentée comme autonome, et une seule
///     réussite n'autorise aucune conclusion générale sur un chapitre.
library;

import '../../domain/learning/exercise_attempt.dart';
import 'answer_normalization.dart';
import 'chapter1_bank.dart';
import 'chapter1_service.dart';
import 'exercise.dart';

/// Pourquoi la vérification n'est pas proposée.
enum TransferUnavailable {
  /// Aucune tâche de vérification n'est associée à cet exercice.
  noLinkedTask,

  /// La réussite n'a pas été autonome : au moins un indice a été consulté.
  notAutonomous,

  /// La tentative n'a pas réussi.
  notSuccessful,
}

/// Décision de la règle de transfert, avec sa raison.
class TransferDecision {
  const TransferDecision._(this.available, this.reason, this.task);

  /// La vérification peut-elle être proposée ?
  final bool available;

  /// Raison du refus, ou `null` si la vérification est disponible.
  final TransferUnavailable? reason;

  /// Tâche de vérification proposée, ou `null`.
  final Exercise? task;

  static const TransferDecision yes = TransferDecision._(
    true,
    null,
    null,
  );

  @override
  String toString() =>
      'TransferDecision(available: $available, reason: ${reason?.name})';
}

/// Ce que l'évaluateur contrôle RÉELLEMENT sur une tâche de vérification.
///
/// Point central de ce fichier. Une tâche de vérification peut être
/// (« 16, 12 » et « PGCD = 4 ») alors que l'évaluateur ne compare que la
/// VALEUR FINALE. Confondre les deux reviendrait à annoncer qu'une méthode a
/// été vérifiée : c'est exactement l'affirmation que la mission interdit.
enum TransferEvidence {
  /// Seule la valeur finale est comparée à la réponse attendue.
  ///
  /// Un élève peut répondre « 4 » sans jamais avoir fait de soustraction.
  finalValueOnly,

  /// La valeur finale OU une formule équivalente est acceptée.
  ///
  /// La formule est ACCEPTÉE, jamais EXIGÉE : répondre « 30 » seul reste
  /// accepté. La relation peut donc être utilisée, elle n'est pas vérifiée.
  finalValueOrEquivalentFormula,

  /// L'écriture doit DÉMONTRER l'application de la relation.
  ///
  /// La valeur seule n'est plus acceptée : seul un calcul écrit
  /// comportant la division est évalué, et il doit donner le résultat
  /// attendu. C'est le seul niveau qui autorise à dire que la relation a été
  /// appliquée.
  relationApplied,
}

/// La méthode de résolution est-elle contrôlable ?
///
/// Réponse constante, et assumée : **NON**, pour toutes les tâches de la
/// banque.
///
/// Le modèle contient bien [Exercise.expectedSteps], mais ce sont des étapes
/// ATTENDUES, pas des étapes RECUEILLIES. L'élève ne saisit qu'un résultat
/// final : aucune capture de raisonnement n'existe dans le parcours nominal.
///
/// Raison de fond : `PGCD(35, 20) = 5` est vrai, que l'élève ait utilisé
/// Euclide, énuméré les diviseurs, ou deviné. Conclure « la méthode est
/// vérifiée » attribuerait au moteur une capacité qu'il n'a pas — et
/// affirming une procédure jamais observée.
const bool kTransferMethodIsEvaluable = false;

/// Ce que la vérification d'une tâche prouve, exactement.
class TransferCheckProfile {
  const TransferCheckProfile({
    required this.scope,
    required this.methodIsEvaluable,
  });

  /// Nature de ce qui est effectivement comparé.
  final TransferEvidence scope;

  /// La méthode de résolution est-elle contrôlée ?
  final bool methodIsEvaluable;

  /// La relation PPCM–PGCD est-elle RÉELLEMENT contrôlée ?
  ///
  /// Vrai uniquement pour une tâche porteuse d'un contrat
  /// [PpcmRelation] : l'évaluateur y refuse une valeur seule et exige un
  /// calcul écrit comportant la division.
  bool get provesRelation => scope == TransferEvidence.relationApplied;

  /// Le résultat de la tâche permet-il d'affirmer que la MÉTHODE a été
  /// appliquée ?
  ///
  /// today : jamais. Cette valeur est celle qu'une interface doit lire pour
  /// ne pas sur-promettre.
  bool get provesMethod => methodIsEvaluable;

  @override
  String toString() =>
      'TransferCheckProfile(${scope.name}, method=$methodIsEvaluable)';
}

/// Résultat d'une vérification de transfert.
///
/// Les quatre états sont distincts et NON interchangeables : confondre
/// « non évaluable » avec « échec » fabriquerait une difficulté qui n'existe
/// pas, et déclencherait une remédiation injustifiée.
enum TransferOutcome {
  /// L'élève a produit la réponse attendue.
  success,

  /// La réponse a pu être évaluée et n'est pas conforme.
  evaluableFailure,

  /// La réponse n'a pas pu être évaluée (format non reconnu, ou critère
  /// purement textuel sur une saisie numérique).
  ///
  /// N'est PAS un échec : aucune conclusion pédagogique n'est possible.
  indeterminate,

  /// L'évaluation n'a pas pu avoir lieu (erreur technique).
  technicalError,
}

/// Règles de la vérification de transfert.
abstract final class TransferVerification {
  const TransferVerification._();

  /// Tâche de vérification associée à [exerciseId], ou `null`.
  ///
  /// LECTURE STRICTE DE LA BANQUE, sans interprétation :
  /// le suivi déclaré doit pointer sur un élément de nature
  /// [BankElementKind.verificationTask]. S'il pointe sur un exercice, il ne
  /// s'agit pas d'une tâche de vérification et la fonction renvoie `null`.
  ///
  /// Conséquence recherchée : si le document pédagogique déclare un jour un
  /// suivi vers une tâche de contrôle, le bouton s'ouvre sans qu'aucune
  /// ligne de code ne soit écrite. Tant que ce n'est pas le cas, le bouton
  /// reste fermé — sans qu'une association ait été inventée pour le
  /// déguiser.
  static Exercise? taskFor(String exerciseId) {
    final exercise = Chapter1Bank.findExercise(exerciseId);
    final followUpId = exercise?.followUpTask;
    if (followUpId == null) return null;

    final target = Chapter1Bank.findExercise(followUpId);
    if (target == null) return null;
    if (target.kind != BankElementKind.verificationTask) return null;
    return target;
  }

  /// La vérification doit-elle être proposée après [record] ?
  ///
  /// Les conditions sont cumulatives, et la plus restrictive d'abord :
  /// réussite, autonomie, association.
  static TransferDecision decide(AttemptRecord record) {
    if (record.outcome != AnswerOutcome.correct) {
      return const TransferDecision._(
        false,
        TransferUnavailable.notSuccessful,
        null,
      );
    }

    if (!record.isAutonomous) {
      return const TransferDecision._(
        false,
        TransferUnavailable.notAutonomous,
        null,
      );
    }

    final task = taskFor(record.exerciseId);
    if (task == null) {
      return const TransferDecision._(
        false,
        TransferUnavailable.noLinkedTask,
        null,
      );
    }

    return TransferDecision._(
      true,
      null,
      task,
    );
  }

  /// Ce que la tâche [taskId] contrôle réellement.
  ///
  /// Lecture des critères, sans interprétation :
  /// si la seule expression acceptée est la valeur attendue, rien d'autre
  /// n'est comparé. Dès qu'une formule différente de la valeur est acceptée,
  /// la formule devient une voie possible — sans devenir obligatoire.
  static TransferCheckProfile profileOf(String taskId) {
    final task = Chapter1Bank.findExercise(taskId);
    if (task == null) {
      return const TransferCheckProfile(
        scope: TransferEvidence.finalValueOnly,
        methodIsEvaluable: kTransferMethodIsEvaluable,
      );
    }

    final criterion = task.correction;

    // Contrat de relation : l'évaluateur va réellement contrôler
    // l'application de la relation. C'est déduit de la donnée, pas déclaré.
    if (criterion.ppcmRelation != null) {
      return const TransferCheckProfile(
        scope: TransferEvidence.relationApplied,
        methodIsEvaluable: kTransferMethodIsEvaluable,
      );
    }

    final expectedValue = criterion.acceptedValues.isEmpty
        ? null
        : '${criterion.acceptedValues.first}';

    final accepteUneFormule = criterion.acceptedExpressions.any(
      (expression) => normalizeAnswer(expression) != expectedValue,
    );

    return TransferCheckProfile(
      scope: accepteUneFormule
          ? TransferEvidence.finalValueOrEquivalentFormula
          : TransferEvidence.finalValueOnly,
      methodIsEvaluable: kTransferMethodIsEvaluable,
    );
  }
}