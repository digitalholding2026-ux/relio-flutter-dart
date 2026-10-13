/// Dimensions et chronologie de l'onboarding — un seul endroit.
///
/// Les valeurs viennent de la spécification des trois écrans (Prénom, Test,
/// Clôture). Elles sont regroupées ici pour qu'un ajustement ne se fasse pas à
/// trois endroits différents, et pour que les tests puissent les citer sans
/// les recopier.
library;

import '../../theme/relio_theme.dart';

/// tailles et durées du parcours d'entrée.
abstract final class OnboardingMetrics {
  // -------------------------------------------------------------------
  // Le personnage
  //
  // Le personnage EST le mark : seule sa taille change d'un écran à
  // l'autre. Il n'a jamais de visage ni de membre, et ne réagit à rien.
  // -------------------------------------------------------------------

  /// Grand écran — étapes Prénom et Clôture.
  static const double characterLarge = 140;

  /// Petit écran (≤ 360 dp de large) — étapes Prénom et Clôture.
  static const double characterLargeCompact = 120;

  /// Test d'entrée, écran standard.
  static const double characterSmall = 80;

  /// Test d'entrée, petit écran.
  static const double characterSmallCompact = 70;

  /// En deçà de cette largeur, les tailles réduites s'appliquent.
  static const double compactWidthThreshold = 360;

  /// Taille du personnage pour [width], et l'étape concernée.
  static double characterSize({required double width, required bool large}) {
    final bool compact = width <= compactWidthThreshold;
    if (large) return compact ? characterLargeCompact : characterLarge;
    return compact ? characterSmallCompact : characterSmall;
  }

  // -------------------------------------------------------------------
  // Le champ Prénom
  // -------------------------------------------------------------------

  /// Longueur maximale du prénom.
  ///
  /// Une borne de saisie, pas une règle de forme : un prénom de trois
  /// lettres comme un prénom de vingt-quatre passent tous les deux.
  static const int nameMaxLength = 24;

  /// Hauteur du champ Prénom.
  static double get nameFieldHeight => RelioSizes.fieldHeight;

  // -------------------------------------------------------------------
  // Le test d'entrée
  // -------------------------------------------------------------------

  /// Hauteur d'une carte de choix.
  static const double choiceHeight = 60;

  /// Écart entre deux cartes de choix.
  static const double choiceGap = 12;

  /// Distance du personnage au haut de l'écran, en fraction de la hauteur.
  static const double characterTopRatio = 0.15;

  // -------------------------------------------------------------------
  // Chronologie — en millisecondes
  //
  // Ces durées sont des VALEURS DE DESIGN, pas des instants narratifs : ce ne
  // sont pas celles de l'écran d'entrée, dont la séquence de 5,3 s reste
  // figée par sa propre spécification.
  // -------------------------------------------------------------------

  /// Fondu de sortie de l'étape Prénom (titre, champ, bouton).
  static const int nameFadeOutMs = 250;

  /// Réduction du personnage 140 → 80 à la validation du prénom.
  static const int nameShrinkMs = 400;

  /// Fondu de sortie des éléments d'une question.
  static const int questionFadeOutMs = 200;

  /// Fondu d'entrée des éléments d'une question.
  static const int questionFadeInMs = 200;

  /// Transition de taille du personnage 80 → 140 à la clôture.
  static const int closingGrowMs = 400;

  /// Pause après la transition de taille, avant l'apparition du texte.
  ///
  /// Le personnage se redresse AVANT que Relio ne parle : sans cette pause,
  /// le texte et l'animation de taille se chevaucheraient.
  static const int closingTextDelayMs = 1500;

  /// Fondu du bouton « Découvrir Relio », après l'apparition du texte.
  static const int closingButtonDelayMs = 300;

  /// Fondu d'un élément suivi d'un glissement vertical.
  static const int slideFadeMs = 300;

  /// Glissement vertical des apparitions.
  static const double slideOffset = 8;
}