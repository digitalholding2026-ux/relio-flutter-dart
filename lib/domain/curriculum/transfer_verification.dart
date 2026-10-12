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
}