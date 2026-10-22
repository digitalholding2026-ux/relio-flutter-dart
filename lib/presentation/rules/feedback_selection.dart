/// Selection du panneau de retour apres soumission.
///
/// Regle centrale : le panneau est deduit des FAITS renvoyes par le moteur,
/// jamais d'une intention pedagogique.
///
/// Panneaux declenchables :
///   A — reussite autonome
///   B — reussite assistee
///   C — intervention : le moteur a une hypothese, il pose une question
///   D — clarification : le moteur doit distinguer deux hypotheses
///   E — erreur sans information exploitable
///   non evaluable — format non reconnu
///   plus le cas special « evaluation non concluante » de l'exercice 11.
///
/// C et D ne s'affichent que si le moteur a reellement produit des
/// hypotheses. Aucun code D1…D8 n'est transmis a la vue : seuls les textes
/// valides de la banque le sont.
library;

import '../../domain/curriculum/chapter1_service.dart';
import '../../domain/curriculum/diagnostic_case.dart';
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

/// Panneau de retour affichable.
enum FeedbackPanel {
  /// A — reussite sans aide.
  successAutonomous,

  /// B — reussite apres au moins un indice.
  successAssisted,

  /// C — intervention pedagogique, avec une question du moteur.
  intervention,

  /// D — question de clarification, avec des options a choisir.
  clarification,

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
    this.clarificationOptions = const <String>[],
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

  /// Options proposees pour une clarification (panneau D).
  ///
  /// Vide hors clarification. Les options sont des libelles d'interface,
  /// pas du contenu pedagogique.
  final List<String> clarificationOptions;

  @override
  String toString() => 'FeedbackSelection(${panel.name})';
}

/// Choisit le panneau a partir des faits renvoyes par le moteur.
///
/// Parametres :
///  - [record] : tentative enregistree par le moteur ;
///  - [exerciseId] : exercice tente ;
///  - [rawAnswer] : saisie non vide au moment de la validation ;
///  - [diagnosis] : hypothese eventuellement produite par le moteur.
FeedbackSelection selectFeedback({
  required AttemptRecord record,
  required String exerciseId,
  required String rawAnswer,
  DiagnosisOutcome? diagnosis,
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
    final assisted =
        record.classification != AttemptClassification.autonomousSuccess;
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

  // --- C ou D : le moteur a produit une hypothese ----------------------
  //
  // On ne remplace le panneau E que si le moteur a effectivement quelque
  // chose a dire. Une liste d'hypotheses vide ne doit jamais fabriquer une
  // intervention.
  if (diagnosis != null && diagnosis.hypotheses.isNotEmpty) {
    return selectDiagnosisFeedback(diagnosis);
  }

  // --- Cas E : echec sans information exploitable ----------------------
  //
  // Cas par defaut : aucune observation n'a pu etre derivee de la tentative.
  return const FeedbackSelection(
    panel: FeedbackPanel.noInformation,
    title: '',
    message: _noInformation,
    showRetry: true,
  );
}

/// Construit le panneau C ou D a partir d'un resultat de diagnostic.
///
/// Utilise aussi par le tuteur : une erreur signalee dans la conversation
/// suit exactement la meme regle qu'une erreur detectee a la soumission.
FeedbackSelection selectDiagnosisFeedback(DiagnosisOutcome diagnosis) {
  final question = diagnosis.clarificationQuestion?.trim() ?? '';
  if (question.isNotEmpty) {
    return FeedbackSelection(
      panel: FeedbackPanel.clarification,
      title: RelioStrings.clarificationTitle,
      message: question,
      clarificationOptions: RelioStrings.clarificationOptions,
    );
  }

  final intervention = diagnosis.intervention.question.trim();
  if (intervention.isNotEmpty) {
    return FeedbackSelection(
      panel: FeedbackPanel.intervention,
      title: '',
      message: intervention,
      showRetry: true,
    );
  }

  // Le moteur n'a pas de texte affichable : on retombe sur E plutot que
  // d'inventer une intervention.
  return const FeedbackSelection(
    panel: FeedbackPanel.noInformation,
    title: '',
    message: _noInformation,
    showRetry: true,
  );
}
