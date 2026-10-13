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

  // ---------------------------------------------------------------------
  // Navigation globale — barre basse à trois onglets
  // ---------------------------------------------------------------------

  /// Libellé de l'onglet 1.
  static const String tabHome = 'Accueil';

  /// Libellé de l'onglet 2.
  static const String tabLearn = 'Apprendre';

  /// Libellé de l'onglet 3.
  static const String tabProfile = 'Profil';

  // ---------------------------------------------------------------------
  // Accueil
  // ---------------------------------------------------------------------

  /// En-tête d'accueil. Le prénom est ajouté séparément s'il est renseigné.
  static const String greeting = 'Bonjour';

  /// Titre de la carte principale.
  static const String startHereTitle = 'Commence ici';

  /// Sous-titre de la carte principale.
  static const String startHereSubtitle = 'Chapitre 1 — Arithmétique';

  /// Titre de la carte secondaire.
  static const String programTitle = 'Programme de 3e';

  /// Sous-titre de la carte secondaire.
  static const String programSubtitle = 'Voir les chapitres';

  // ---------------------------------------------------------------------
  // Apprendre
  // ---------------------------------------------------------------------

  /// Titre d'écran.
  static const String learnTitle = 'Programme de 3e';

  /// Sous-titre d'un chapitre actif.
  static const String chapterArithmetic = 'Arithmétique';

  /// Sous-titre d'un chapitre non encore disponible.
  static const String chapterComingSoon = 'Bientôt disponible';

  // ---------------------------------------------------------------------
  // Profil
  // ---------------------------------------------------------------------

  static const String profileTitle = 'Profil';

  static const String sectionIdentity = 'Identité';
  static const String sectionDisplay = 'Affichage';
  static const String sectionAccessibility = 'Accessibilité';

  static const String nameLabel = 'Nom';
  static const String nameHint = 'Ajoute ton prénom';
  static const String classLabel = 'Classe';
  static const String classValue = '3e';

  static const String textSizeLabel = 'Taille du texte';
  static const String highContrastLabel = 'Contraste renforcé';
  static const String reduceAnimationsLabel = 'Réduire les animations';

  // ---------------------------------------------------------------------
  // Onboarding — parcours d'entrée
  //
  // Aucun de ces libellés ne mentionne de score, de niveau ni de résultat :
  // le test d'entrée enregistre des FAITS, et l'interface ne restitue aucun
  // de ces faits à l'élève pendant le parcours.
  // ---------------------------------------------------------------------

  /// Étape Prénom — titre de l'écran.
  static const String nameTitle = 'Comment tu t’appelles ?';

  /// Étape Prénom — placeholder du champ.
  static const String namePlaceholder = 'Ton prénom';

  /// Étape Prénom — bouton de validation.
  static const String nameContinue = 'Continuer';

  /// Test d'entrée — progression : « N sur 5 ».
  ///
  /// SEULE information de progression visible pendant le test. Aucun score,
  /// aucun pourcentage, aucun indice.
  static String entryProgress(int current, int total) => '$current sur $total';

  /// Test d'entrée — libellé du bouton, identique pour les cinq questions.
  static const String entryContinue = 'Continuer';

  /// Test d'entrée — échec d'enregistrement, bannière neutre.
  ///
  /// Volontairement NEUTRE : elle ne dit rien de la réponse, ni juste ni
  /// fausse. L'élève doit pouvoir réessayer sans se sentir jugé.
  static const String entrySaveError =
      'Impossible d’enregistrer pour le moment. Réessaie.';

  /// Test d'entrée — bouton de réessai après échec.
  static const String entryRetry = 'Réessayer';

  /// Test d'entrée — aucune question disponible (cas théorique).
  static const String entryNoQuestion =
      'Je n’ai pas de question à te proposer pour le moment.';

  /// Clôture — texte d'accueil, prénom inséré au début.
  static String closingMessage(String name) =>
      'Merci $name. Je commence à te connaître.';

  /// Clôture — bouton de sortie du parcours.
  static const String closingDiscover = 'Découvrir Relio';
}
