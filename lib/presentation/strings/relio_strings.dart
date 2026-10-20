/// Tous les textes de l'interface, regroupes au meme endroit.
///
/// Centralisation imposee par la specification, afin que l'adaptation a la
/// voix ou a une traduction ne touche aucun ecran.
///
/// Regle : aucun texte ne doit etre ecrit directement dans un widget. Tout
/// passe par cette classe.
library;

import '../../domain/curriculum/rich_hint.dart';

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
  // S2 — Fiche d'aide riche (Bottom Sheet)
  // ---------------------------------------------------------------------

  /// Titre de la fiche d'aide.
  static const String richHintTitle = '💡 Comprendre cette étape';

  /// Bouton de fermeture de la fiche.
  static const String richHintUnderstood = 'J’ai compris';

  /// Bandeau affiche quand la fiche est ouverte sur un EXERCICE PRECEDENT.
  static String richHintReviewBanner(int exerciseNumber) =>
      'Voici les explications de l’exercice $exerciseNumber. '
      'Prends le temps de les relire.';

  /// Bouton de retour depuis la relecture d'un exercice precedent.
  static const String richHintBackToCurrent = 'Retour à l’exercice en cours';

  /// Libelle du bouton d'aide, deduit du budget.
  ///
  /// `askFirst` → premier clic ; `next` → des fiches restent ; `finalOne` →
  /// la prochaine sera la derniere ; `reviewPrevious` → budget epuise.
  static String hintCta(HintCta cta, {int? previousExerciseNumber}) {
    switch (cta) {
      case HintCta.askFirst:
        return askHint;
      case HintCta.next:
        return 'Indice suivant';
      case HintCta.finalOne:
        return 'Indice final';
      case HintCta.reviewPrevious:
        return 'Revoir l’exercice ${previousExerciseNumber ?? ''}'.trim();
      case HintCta.none:
        return askHint;
    }
  }

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
  // Accueil — tableau de bord
  //
  // L'accueil ne donne aucun résultat chiffré : il nomme ce qui est
  // disponible et laisse les statuts de leçon à l'état de présentation.
  // ---------------------------------------------------------------------

  /// En-tête d'accueil. Le prénom est ajouté séparément s'il est renseigné.
  static const String greeting = 'Bonjour';

  /// Message de Relio, dans la carte sous l'en-tête.
  static const String relioMessage = 'Prêt à avancer en maths aujourd’hui ?';

  /// Étiquette de la carte principale.
  static const String resumeLabel = 'REPRENDRE';

  /// Sous-texte de la carte principale : position dans le chapitre.
  static String resumeProgress(int current, int total) =>
      'Exercice $current sur $total';

  /// Libellé du bouton de la carte principale.
  static const String resumeContinue = 'Continuer';

  /// Action rapide — titre.
  static const String quickFiveTitle = 'J’ai 5 minutes';

  /// Action rapide — sous-titre.
  static const String quickFiveSubtitle = 'Révision éclair';

  /// Action rapide — titre.
  static const String quickWarmupTitle = 'Échauffement';

  /// Action rapide — sous-titre.
  static const String quickWarmupSubtitle = 'Question du jour';

  /// Titre de la section qui liste les leçons du chapitre.
  static const String programSectionTitle = 'Ton programme';

  /// Statut d'une leçon commencée, non terminée.
  static const String statusInProgress = 'En cours';

  /// Statut d'une leçon maîtrisée.
  static const String statusMastered = 'Maîtrisé';

  /// Statut d'une leçon à reprendre.
  static const String statusToReview = 'À revoir';

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
  // ---------------------------------------------------------------------
  // Ouverture — révélation de la marque
  //
  // L'ouverture ne parle pas : elle montre le logo. Le seul texte qu'elle
  // porte est donc la signature, qui vit dans `RelioSignature.text` et non
  // ici — une seule source pour le mot de marque.
  // ---------------------------------------------------------------------

  /// Étape Bienvenue — texte d'accueil.
  ///
  /// Texte EXACT : il ne se reformule pas, et aucune variante n'existe pour
  /// un écran plus étroit. La mise en page s'adapte, le texte non.
  ///
  /// L'écran affiche les trois parties SÉPARÉMENT (titre, sous-titre,
  /// question), avec leur propre style et leur propre espacement. Leur
  /// concaténation restitue EXACTEMENT [welcomeMessage] : aucun mot n'est
  /// ajouté, aucun n'est retiré.
  static const String welcomeMessage =
      'Salut, moi c\u2019est Relio ! On va avancer ensemble en maths, '
      'à ton rythme. Pr\u00eat à découvrir comment je peux t\u2019aider ?';

  /// Étape Bienvenue — titre, en Display.
  static const String welcomeTitle = 'Salut, moi c\u2019est Relio !';

  /// Étape Bienvenue — sous-titre, en Body secondaire.
  static const String welcomeSubtitle =
      'On va avancer ensemble en maths, à ton rythme.';

  /// Étape Bienvenue — question d'entrée dans le parcours, en Body.
  static const String welcomeQuestion =
      'Pr\u00eat à découvrir comment je peux t\u2019aider ?';

  /// Étape Bienvenue — bouton d'entrée dans le parcours.
  static const String welcomeStart = 'Commencer';

  // ---------------------------------------------------------------------
  // Introduction au questionnaire
  //
  // Explique une étape de DÉCOUVERTE. Aucun mot ne doit laisser croire à une
  // évaluation, ni à un résultat : ni « test », ni « examen », ni « note ».
  // ---------------------------------------------------------------------

  /// Introduction au questionnaire — texte.
  ///
  /// L'écran affiche les trois parties SÉPARÉMENT (titre, description,
  /// phrase de fin), avec leur propre style et leur propre espacement. Leur
  /// concaténation restitue EXACTEMENT [entryIntroMessage].
  static const String entryIntroMessage =
      'Faisons connaissance ! Je vais te proposer 5 petites questions de '
      'maths. Elles m\u2019aideront à mieux comprendre ton point de départ '
      'pour t\u2019accompagner dans la suite. Ici, on avance pas à pas.';

  /// Introduction au questionnaire — titre, en Title.
  static const String entryIntroTitle = 'Faisons connaissance !';

  /// Introduction au questionnaire — description, en Body aligné à gauche.
  static const String entryIntroBody =
      'Je vais te proposer 5 petites questions de maths. '
      'Elles m\u2019aideront à mieux comprendre ton point de départ '
      'pour t\u2019accompagner dans la suite.';

  /// Introduction au questionnaire — phrase de fin, en BodyStrong indigo.
  static const String entryIntroFinal = 'Ici, on avance pas à pas.';

  /// Introduction au questionnaire — légende sous les pastilles.
  ///
  /// Reformule la étape sans jamais parler d'évaluation : cinq questions,
  /// une par une.
  static const String entryIntroCaption = 'Cinq questions, une par une.';

  /// Introduction au questionnaire — bouton.
  static const String entryIntroStart = 'C\u2019est parti !';

  // ---------------------------------------------------------------------
  // Démarrage — échec d'initialisation
  //
  // Un écran blanc sans explication est le pire des échecs : l'élève ne sait
  // ni ce qui s'est passé, ni quoi faire. Il doit donc toujours y avoir un
  // écran d'erreur et un moyen de réessayer.
  // ---------------------------------------------------------------------

  /// Titre de l'écran d'échec au démarrage.
  static const String startupErrorTitle =
      'Relio n\'a pas pu démarrer';

  /// Message de l'écran d'échec au démarrage.
  ///
  /// Volontairement NEUTRE : ni cause affirmée, ni diagnostic. L'élève n'a
  /// rien à corriger — c'est l'application qui doit recommencer.
  static const String startupErrorMessage =
      'La préparation n\'a pas abouti. Réessaie pour continuer ton parcours.';

  /// Bouton de réessai.
  static const String startupRetry = 'Réessayer';

  // Onboarding — parcours d'entrée
  //
  // Aucun de ces libellés ne mentionne de score, de niveau ni de résultat :
  // le test d'entrée enregistre des FAITS, et l'interface ne restitue aucun
  // de ces faits à l'élève pendant le parcours.
  // ---------------------------------------------------------------------

  /// Étape Prénom — titre de l'écran.
  static const String nameTitle = 'Comment tu t’appelles ?';

  /// Étape Prénom — sous-titre, en Body secondaire.
  static const String nameSubtitle = 'Pour que je puisse te parler comme il faut.';

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
  ///
  /// AUCUN bilan : ni score, ni « tu as réussi », ni nombre de bonnes
  /// réponses. La phrase annonce la suite, pas un résultat.
  ///
  /// L'écran affiche le titre et le corps SÉPARÉMENT : [closingTitle] en
  /// Display, [closingBody] centré en dessous. Le titre reprend le prénom
  /// avec un point final, comme validé pour la refonte.
  static String closingMessage(String name) =>
      'Merci $name ! Je commence à mieux te connaître. '
      'On va continuer à avancer ensemble, étape par étape.';

  /// Clôture — titre, en Display : « Merci {prénom}. »
  static String closingTitle(String name) => 'Merci $name.';

  /// Clôture — corps centré sous le titre, en Body.
  static String closingBody() =>
      'Je commence à mieux te connaître. '
      'On va continuer à avancer ensemble, étape par étape.';

  /// Clôture — bouton de sortie du parcours.
  static const String closingDiscover = 'Découvrir Relio';
}
