/// Dimensions et chronologie du parcours d'entrée — un seul endroit.
///
/// Les valeurs viennent de la spécification des écrans (Ouverture, Bienvenue,
/// Introduction au questionnaire, Prénom, Test, Clôture). Elles sont
/// regroupées ici pour qu'un ajustement ne se fasse pas à six endroits
/// différents, et pour que les tests puissent les citer sans les recopier.
library;

import '../../theme/relio_theme.dart';

/// Tailles et durées du parcours d'entrée.
///
/// Les tailles de marque vivent dans `entry_kit.dart` ([EntryBrand]) : un
/// niveau de présence par écran (ouverture 160, bienvenue 100, explication
/// 80, prénom 64, test 24, clôture 120). Il ne reste ici que les durées et
/// les dimensions de composants.
abstract final class OnboardingMetrics {
  // -------------------------------------------------------------------
  // Transition entre écrans — fondu croisé, 250–300 ms.
  //
  // Aucun glissement, aucune mise à l'échelle d'écran. Interruptible par
  // construction : un nouvel écran relance le fondu.
  // -------------------------------------------------------------------

  /// Durée du fondu croisé entre deux écrans du parcours.
  static const int entryTransitionMs = 275;

  /// En deçà de cette largeur, les variantes compactes s'appliquent.
  ///
  /// Conservée pour les mesures de la marque, qui restent testées
  /// directement. Les écrans du parcours utilisent des tailles fixes
  /// ([EntryBrand]), sans variante compacte.
  static const double compactWidthThreshold = 360;

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

  /// Hauteur d'une carte de choix : 56 dp, rayon 12, écart 12.
  static const double choiceHeight = 56;

  /// Écart entre deux cartes de choix.
  static const double choiceGap = 12;

  // -------------------------------------------------------------------
  // Le test d'entrée — position et sortie des questions.
  // -------------------------------------------------------------------

  /// Fondu de sortie des éléments d'une question : 250 ms, dans la plage
  /// des transitions du parcours (250–300 ms).
  static const int questionFadeOutMs = 250;

  // -------------------------------------------------------------------
  // Chronologie — en millisecondes
  //
  // Ces durées sont des VALEURS DE DESIGN : durée d'un mouvement, jamais
  // délai d'attente. Aucune d'elles ne retient l'élève, et l'abandon de
  // l'écran n'est jamais conditionné à leur écoulement.
  // -------------------------------------------------------------------

  /// Fondu d'entrée des éléments d'une question.
  static const int questionFadeInMs = 200;

  /// Pause avant l'apparition du texte de clôture.
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
  /// Court : le logo doit se poser avant que l'écran change. Révélation
  /// 1600 ms + sortie 200 ms : l'écran dure 1,8 s, puis un tap à tout moment
  /// le fait sauter à l'étape suivante.
  static const int openingExitMs = 200;

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