/// Selection du panneau de retour apres soumission.
///
/// Regle centrale : le panneau est deduit des FAITS renvoyes par le moteur,
/// jamais d'une intention pedagogique.
///
/// En V1, seuls quatre panneaux sont declenchables :
///   A — reussite autonome
///   B — reussite assistee
///   E — erreur sans information exploitable
///   non evaluable — format non reconnu
///   plus le cas special « evaluation non concluante » de l'exercice 11.
///
/// Les panneaux C et D sont VOLONTAIREMENT NON DECLENCHABLES : le moteur ne
/// produit ni observation, ni traitement de clarification. Leur invocation
/// est interdite en V1.
library;

import '../../domain/curriculum/chapter1_service.dart';
import '../../domain/curriculum/hint_trajectory.dart';
import '../../domain/learning/exercise_attempt.dart';
import '../strings/relio_strings.dart';
import '../rules/v1_screen_rules.dart';

const String _successTitle = RelioStrings.successTitle;
const String _successAutonomous = RelioStrings.successAutonomous;
const String _successAssisted = RelioStrings.successAssisted;
const String _noInformation = RelioStrings.noInformation;
const String _notRecognised = RelioStrings.notRecognised;
const String _inconclusive = RelioStrings.inconclusive;

/// Panneau de retour affichable en V1.
enum FeedbackPanel {
  /// A — reussite sans aide.
  successAutonomous,

  /// B — reussite apres au moins un indice.
  successAssisted,

  /// E — echec sans information exploitable.
  noInformation,

  /// Reponse non evaluable : format non reconnu.
  notRecognised,

  /// Cas special de l'exercice 11 : la redaction ne peut pas etre evaluee
  /// avec certitude.
  inconclusive,
}

/// Description complete du panneau a afficher.
class FeedbackSelection {
  const FeedbackSelection({
    required this.panel,
    required this.title,
    required this.message,
    this.showRetry = false,
    this.showNext = false,
    this.showContinue = false,
  });

  /// Panneau retenu.
  final FeedbackPanel panel;

  /// Titre affiche.
  final String title;

  /// Message affiche sous le titre.
  final String message;

  /// Afficher le bouton « Réessayer ».
  final bool showRetry;

  /// Afficher le bouton « Exercice suivant ».
  final bool showNext;

  /// Afficher le bouton « Continuer ».
  final bool showContinue;

  @override
  String toString() => 'FeedbackSelection(${panel.name})';
}

/// Choisit le panneau a partir des faits renvoyes par le moteur.
///
/// Parametres :
///  - [record] : tentative enregistree par le moteur ;
///  - [exerciseId] : exercice tente ;
///  - [rawAnswer] : saisie non vide au moment de la validation.
FeedbackSelection selectFeedback({
  required AttemptRecord record,
  required String exerciseId,
  required String rawAnswer,
}) {
  // Une saisie vide ne produit aucun panneau : le message inline suffit.
  if (rawAnswer.trim().isEmpty) {
    return const FeedbackSelection(
      panel: FeedbackPanel.noInformation,
      title: '',
      message: '',
    );
  }

  final isCorrect = record.outcome == AnswerOutcome.correct;

  // --- Reussite : A ou B selon l'usage d'indices -----------------------
  if (isCorrect) {
    final assisted = record.classification !=
        AttemptClassification.autonomousSuccess;
    return FeedbackSelection(
      panel: assisted
          ? FeedbackPanel.successAssisted
          : FeedbackPanel.successAutonomous,
      title: _successTitle,
      message: assisted ? _successAssisted : _successAutonomous,
      showNext: true,
    );
  }

  // --- Cas special de l'exercice 11 -------------------------------------
  //
  // L'evaluation par comparaison litterale ne peut pas conclure : la
  // reponse ne doit JAMAIS etre presentee comme fausse.
  if (V1ScreenRules.expectsUnconclusiveHandling(exerciseId)) {
    return const FeedbackSelection(
      panel: FeedbackPanel.inconclusive,
      title: '',
      message: _inconclusive,
      showRetry: true,
      showContinue: true,
    );
  }

  // --- Reponse non evaluable : format non reconnu ----------------------
  //
  // Distinct du cas suivant : ici le systeme n'a pas su evaluer, alors
  // qu'il a su evaluer et trouvé faux.
  if (record.outcome == AnswerOutcome.notEvaluated) {
    return const FeedbackSelection(
      panel: FeedbackPanel.notRecognised,
      title: '',
      message: _notRecognised,
      showRetry: true,
    );
  }

  // --- Cas E : echec sans information exploitable ----------------------
  //
  // Cas par defaut : aucun diagnostic n'est produit en conditions
  // reelles, faute d'observations.
  return const FeedbackSelection(
    panel: FeedbackPanel.noInformation,
    title: '',
    message: _noInformation,
    showRetry: true,
  );
}
