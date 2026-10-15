/// Dimensions et chronologie du parcours d'entrée — un seul endroit.
///
/// Les valeurs viennent de la spécification des écrans (Ouverture, Bienvenue,
/// Introduction au questionnaire, Prénom, Test, Clôture). Elles sont
/// regroupées ici pour qu'un ajustement ne se fasse pas à six endroits
/// différents, et pour que les tests puissent les citer sans les recopier.
library;

import '../../theme/relio_theme.dart';

/// Tailles et durées du parcours d'entrée.
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
  // La présentation d'introduction au questionnaire
  // -------------------------------------------------------------------

  /// Diamètre d'une pastille.
  static const double introChipSize = 10;

  /// Écart entre deux pastilles.
  static const double introChipGap = 8;

  /// Hauteur de la zone de pastilles.
  static double get introChipHeight => introChipSize;

  /// Nombre de pastilles : une par question du test d'entrée.
  ///
  /// Ce n'est PAS une progression — elle est vide au départ. C'est une
  /// promesse de durée courte, lisible avant même de commencer.
  static const int introChipCount = 5;

  // -------------------------------------------------------------------
  // Le test d'entrée
  // -------------------------------------------------------------------

  /// Hauteur d'une carte de choix.
  static const double choiceHeight = 60;

  /// Écart entre deux cartes de choix.
  static const double choiceGap = 12;

  /// Distance du personnage au haut de l'écran, en FRACTION DE LA HAUTEUR
  /// DISPONIBLE.
  ///
  /// La spécification dit « ancré à ~15 % depuis le haut » : c'est une
  /// position dans l'écran, pas dans le personnage. Appliquer ce ratio à la
  /// TAILLE du personnage donnerait 12 px au lieu de ~15 % de l'écran — le
  /// personnage serait collé en haut au lieu d'être posé dans le tiers
  /// supérieur.
  static const double characterTopRatio = 0.15;

  // -------------------------------------------------------------------
  // Chronologie — en millisecondes
  //
  // Ces durées sont des VALEURS DE DESIGN : durée d'un mouvement, jamais
  // délai d'attente. Aucune d'elles ne retient l'élève, et l'abandon de
  // l'écran n'est jamais conditionné à leur écoulement.
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

  /// Décalage entre deux blocs qui arrivent l'un après l'autre.
  static const int staggerMs = 110;

  // -------------------------------------------------------------------
  // Ouverture — révélation de la marque
  //
  // L'ouverture ne RACONTE rien : elle montre le logo, puis s'efface. Il n'y a
  // donc pas de chronologie narrative, seulement la durée d'une révélation.
  // Aucune de ces valeurs n'est un délai d'attente : chacune est la durée
  // d'un mouvement, et l'écran enchaîne dès que le mouvement est terminé.
  // -------------------------------------------------------------------

  /// Durée totale de la révélation, avant passage à l'étape Bienvenue.
  ///
  /// C'est le plafond de l'écran : passé ce point, la suite est affichée quoi
  /// qu'il arrive. Aucune animation ne peut retenir l'élève.
  static const int openingTotalMs = 1600;

  /// Fondu d'apparition du logo.
  static const int openingFadeMs = 320;

  /// Mise à l'échelle du logo, de `openingScaleFrom` à 1.
  static const int openingScaleMs = 460;

  /// Décalage avant le début du mouvement d'échelle.
  ///
  /// Le logo apparaît d'abord, il se met ensuite à sa place : sans ce
  /// décalage, fondu et échelle se superposent et l'ensemble parait flou.
  static const int openingScaleDelayMs = 80;

  /// Échelle initiale du logo.
  static const double openingScaleFrom = 0.94;

  /// Durée du glissement vertical du logo, en dp.
  ///
  /// Le logo descend de 10 dp vers sa place : c'est le « mouvement graphique
  /// subtil » de l'ouverture. Il n'a lieu qu'une fois, à l'arrivée.
  static const double openingRise = 10;

  /// Delai avant la sortie, une fois le logo en place.
  ///
  /// court : le logo doit se poser avant que l'écran change. Il ne s'agit pas
  /// de faire attendre, mais de ne pas faire disparaître une marque pendant
  /// qu'elle bouge encore.
  static const int openingExitMs = 420;

  /// Durée du fondu de sortie vers l'étape Bienvenue.
  static const int openingExitFadeMs = 260;

  // -------------------------------------------------------------------
  // Étape Bienvenue
  // -------------------------------------------------------------------

  /// Durée d'une apparition décalée (texte, puis bouton).
  static const int welcomeRevealMs = 360;

  /// Taille du lockup sur l'écran d'accueil, en hauteur de capitale du mot.
  static const double welcomeLockupCapHeight = 30;

  /// Taille du lockup sur écran compact.
  static const double welcomeLockupCapHeightCompact = 22;
}