/// Traitement du résultat d'une vérification de transfert — chapitre 1.
///
/// Sépare strictement quatre choses, qui ne doivent JAMAIS être confondues :
///
///  1. ce qui est un **fait** (réponse, aide consultée, résultat) ;
///  2. ce qui est une **hypothèse** de cause ;
///  3. ce qu'on ne sait **pas** (résultat indéterminé, erreur technique) ;
///  4. ce qu'on **propose** ensuite (consolidation, nouvelle vérification).
///
/// Règle directrice : un résultat indéterminé ou une erreur technique ne
/// produit AUCUNE conclusion pédagogique. Ni « l'élève n'a pas compris »,
/// ni remédiation automatique, ni vérification de remplacement : ce serait
/// transformer une incertitude technique en difficulté pédagogique.
library;

import '../../domain/learning/exercise_attempt.dart';
import 'chapter1_service.dart';
import 'exercise.dart';
import 'observation_collector.dart';
import 'transfer_verification.dart';

/// Ce qu'il faut proposer après un échec de vérification.
enum RecoveryKind {
  /// Consolidation ciblée sur une difficulté IDENTIFIÉE.
  ///
  /// N'est proposé que si un fait l'étaye. Une « consolidation ciblée » sans
  /// fait derrière est une consolidation imaginée.
  targetedConsolidation,

  /// Reprise guidée générale, cause NON identifiée.
  ///
  /// Aucun diagnostic affirmatif ne doit accompagner ce choix : on ne sait
  /// pas où ça bloque, et le dire est plus honnête que le deviner.
  guidedReview,
}

/// Contenu pédagogique manquant, à faire valider.
///
/// Le moteur ne comble jamais un vide de contenu : il signale ce qui
/// manque, pour que la responsabilité reste pédagogique et non technique.
enum MissingContent {
  /// Aucun contenu de consolidation ne correspond à une difficulté étayée.
  consolidationActivity,

  /// Aucune tâche de vérification distincte de la tâche échouée.
  distinctVerificationTask,
}

/// Proposition de suite, après un échec évaluable.
class TransferRecovery {
  const TransferRecovery({
    required this.kind,
    this.consolidation,
    this.nextVerification,
    this.missing = const <MissingContent>[],
  });

  /// Reprise guidée générale : aucun fait n'étaye une difficulté précise.
  static const TransferRecovery guidedReview = TransferRecovery(
    kind: RecoveryKind.guidedReview,
  );

  /// Consolidation ciblée sur une difficulté étayée.
  final RecoveryKind kind;

  /// Activité de consolidation, ou `null` si la banque n'en fournit aucune
  /// qui corresponde à la difficulté.
  ///
  /// today : toujours `null`. Le chapitre 1 ne contient que des exercices et
  /// des tâches de contrôle, aucune activité de remédiation. Pointer vers un
  /// exercice existant « parce qu'il ressemble » serait inventer une
  /// association.
  final Exercise? consolidation;

  /// Tâche de vérification pour un SECOND tour, DISTINCTE de la tâche
  /// échouée, ou `null` si la banque n'en déclare aucune.
  final Exercise? nextVerification;

  /// Contenus manquants, à faire valider.
  final List<MissingContent> missing;

  /// Une reprise est-elle réellement proposable aujourd'hui ?
  bool get isActionable => consolidation != null;

  @override
  String toString() =>
      'TransferRecovery(${kind.name}, actionnable=$isActionable, '
      'missing=$missing)';
}

/// Résultat complet d'une vérification de transfert.
class TransferAssessment {
  const TransferAssessment._({
    required this.outcome,
    required this.taskId,
    required this.profile,
    this.recovery,
  });

  final TransferOutcome outcome;

  /// Tâche de vérification évaluée.
  final String taskId;

  /// Ce que l'évaluateur contrôle réellement sur cette tâche.
  final TransferCheckProfile profile;

  /// Suite proposée — uniquement en cas d'échec ÉVALUABLE.
  final TransferRecovery? recovery;

  /// Une conclusion pédagogique peut-elle être formulée ?
  bool get allowsPedagogicalConclusion =>
      outcome == TransferOutcome.success ||
      outcome == TransferOutcome.evaluableFailure;

  @override
  String toString() =>
      'TransferAssessment(${outcome.name}, $taskId, $profile)';
}

/// Traitement du résultat d'une vérification de transfert.
abstract final class TransferOutcomePolicy {
  const TransferOutcomePolicy._();

  /// Évalue le résultat d'une tentative de vérification.
  ///
  /// Les quatre issues sont disjointes et jamais déduites l'une de l'autre :
  ///
  ///  - [TransferOutcome.technicalError] : aucune évaluation possible ;
  ///  - [TransferOutcome.indeterminate] : réponse non évaluable, donc
  ///    aucune conclusion — surtout pas un échec ;
  ///  - [TransferOutcome.success] : réponse conforme ;
  ///  - [TransferOutcome.evaluableFailure] : réponse évaluée et non conforme.
  static TransferAssessment assess({
    required Exercise task,
    required AttemptRecord record,
    required bool technicalError,
  }) {
    final profile = TransferVerification.profileOf(task.id);

    if (technicalError) {
      // Aucune conclusion, aucune remédiation : l'incertitude n'est pas
      // une difficulté.
      return TransferAssessment._(
        outcome: TransferOutcome.technicalError,
        taskId: task.id,
        profile: profile,
      );
    }

    switch (record.outcome) {
      case AnswerOutcome.correct:
        return TransferAssessment._(
          outcome: TransferOutcome.success,
          taskId: task.id,
          profile: profile,
        );

      case AnswerOutcome.notEvaluated:
        return TransferAssessment._(
          outcome: TransferOutcome.indeterminate,
          taskId: task.id,
          profile: profile,
        );

      case AnswerOutcome.abandoned:
        // L'élève n'a pas répondu : ce n'est ni une réussite, ni un échec.
        return TransferAssessment._(
          outcome: TransferOutcome.indeterminate,
          taskId: task.id,
          profile: profile,
        );

      case AnswerOutcome.incorrect:
        return TransferAssessment._(
          outcome: TransferOutcome.evaluableFailure,
          taskId: task.id,
          profile: profile,
          recovery: recoveryAfterFailure(
            task: task,
            record: record,
          ),
        );
    }
  }

  /// Suite à proposer après un échec évaluable.
  ///
  /// Deux branches, et une seule condition de bascule :
  ///
  ///  - si au moins un FAIT identifie une difficulté ET que la banque
  ///    declare une consolidation correspondante → consolidation ciblée ;
  ///  - sinon → reprise guidée générale, SANS diagnostic affirmatif.
  ///
  /// today, aucune observation du parcours nominal n'identifie une
  /// difficulté (voir `kFactsRequiringStepByStep`). La branche ciblée est
  /// donc inatteignable : elle est écrite pour être correcte le jour où une
  /// source de données réelle existera, pas pour être activée aujourd'hui.
  static TransferRecovery recoveryAfterFailure({
    required Exercise task,
    required AttemptRecord record,
  }) {
    final report = collectObservations(
      record: record,
      exercise: task,
    );

    // Consolidation ciblée : uniquement si un fait la soutient ET que la
    // banque en fournit une. Aucune des deux conditions n'est remplie
    // aujourd'hui, et l'absence est ASSUMÉE, pas contournée.
    if (report.facts.isNotEmpty) {
      final consolidation = _consolidationFor(task, report.facts);
      if (consolidation != null) {
        final suivante = _nextVerificationFor(task, consolidation);
        return TransferRecovery(
          kind: RecoveryKind.targetedConsolidation,
          consolidation: consolidation,
          nextVerification: suivante,
          missing: suivante == null
              ? const <MissingContent>[MissingContent.distinctVerificationTask]
              : const <MissingContent>[],
        );
      }
    }

    return const TransferRecovery(
      kind: RecoveryKind.guidedReview,
      missing: <MissingContent>[
        MissingContent.consolidationActivity,
        MissingContent.distinctVerificationTask,
      ],
    );
  }

  /// Activité de consolidation correspondant aux faits [facts], ou `null`.
  ///
  /// AUCUNE association n'est déclarée dans la banque pour l'instant : la
  /// fonction renvoie donc toujours `null`. Elle est écrite avec la forme
  /// finale pour que l'ajout d'un contenu validé soit une ligne de donnée,
  /// pas une refonte.
  static Exercise? _consolidationFor(Exercise task, Set<String> facts) {
    return null;
  }

  /// Tâche de vérification distincte de [failedTask], ou `null`.
  ///
  /// Garde-fou : la nouvelle tâche ne doit JAMAIS être la tâche qui vient
  /// d'échouer. Refaire la même tâche n'est pas une seconde vérification.
  static Exercise? _nextVerificationFor(
    Exercise failedTask,
    Exercise consolidation,
  ) {
    return null;
  }
}