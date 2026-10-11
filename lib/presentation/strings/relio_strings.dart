/// Tous les textes de l'interface, regroupes au meme endroit.
///
/// Centralisation imposee par la specification, afin que l'adaptation a la
/// voix ou a une traduction ne touche aucun ecran.
///
/// Regle : aucun texte ne doit etre ecrit directement dans un widget. Tout
/// passe par cette classe.
library;

/// Libelles de l'interface du parcours eleve — chapitre 1.
abstract final class RelioStrings {
  const RelioStrings._();

  // ---------------------------------------------------------------------
  // S1 — Acces au chapitre
  // ---------------------------------------------------------------------

  static const String chapterCaption = 'Chapitre 1';
  static const String chapterTitle = 'Arithmétique';
  static const String chapterIntro =
      'Trois leçons pour travailler les entiers naturels.';

  // ---------------------------------------------------------------------
  // S2 — Exercice
  // ---------------------------------------------------------------------

  static const String answerFieldLabel = 'Ta réponse';
  static const String askHint = 'Demander un indice';
  static const String validate = 'Valider';
  static const String retry = 'Réessayer';
  static const String nextExercise = 'Exercice suivant';
  static const String continueLabel = 'Continuer';
  static const String back = 'Retour';

  /// Prefixe d'un indice : « Indice 1 », « Indice 2 »…
  static String hintLabel(int order) => 'Indice $order';

  // ---------------------------------------------------------------------
  // S2 — Etats techniques
  // ---------------------------------------------------------------------

  static const String emptyAnswerInline = 'Écris ta réponse avant de valider.';
  static const String loadErrorTitle = 'Impossible de charger l’exercice.';
  static const String submitErrorBanner =
      'Impossible d’envoyer la réponse. Vérifie ta connexion.';

  /// Message affiche quand la saisie n'est pas evaluable.
  static const String notRecognised =
      'Je n’ai pas reconnu ta réponse. Vérifie qu’elle est bien écrite.';

  /// Message affiche quand l'evaluation n'est pas concluante (exercice 11).
  ///
  /// REGLE PROVISOIRE : a retirer des que le moteur saura reconnaitre les
  /// formulations alternatives.
  static const String inconclusive =
      'Je ne peux pas encore vérifier cette formulation avec certitude. '
      'Relis ta réponse, ou essaie une autre formulation.';

  // ---------------------------------------------------------------------
  // S2 — Panneaux de retour
  // ---------------------------------------------------------------------

  /// Panneau A — reussite autonome.
  static const String successTitle = 'Bonne réponse.';
  static const String successAutonomous = 'Tu as réussi cet exercice sans aide.';

  /// Panneau B — reussite assistee.
  static const String successAssisted =
      'Tu as réussi cet exercice avec de l’aide.';

  /// Panneau E — erreur sans information exploitable.
  ///
  /// Formulation volontairement humilee : elle n'affirme aucune cause.
  static const String noInformation =
      'Pas encore. Je n’arrive pas à voir où ça bloque. '
      'Essaie encore, je regarde.';

  // ---------------------------------------------------------------------
  // Transparence — uniquement sur les exercices 3, 7 et 11
  // ---------------------------------------------------------------------

  /// Exercice 3 : une justification est demandee mais non notee.
  static const String transparencyJustification =
      'La réponse finale est vérifiée automatiquement ; '
      'la justification n’est pas encore évaluée.';

  /// Exercice 7 : une comparaison est demandee mais non notee.
  static const String transparencyComparison =
      'La réponse finale est vérifiée automatiquement ; '
      'la comparaison n’est pas encore évaluée.';

  /// Exercice 11 : la redaction n'est pas evaluee de facon fiable.
  static const String transparencyRedaction =
      'L’évaluation de la rédaction n’est pas encore complète.';
}
