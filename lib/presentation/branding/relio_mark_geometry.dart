/// Geometrie pure du mark Relio — SOURCE DE VERITE.
///
/// Ce fichier n'importe QUE `dart:math`. Il ne depend ni de Flutter ni de
/// `dart:ui`, afin de pouvoir etre consomme aussi bien par le generateur de
/// SVG (Dart standalone) que par le rendu a l'ecran et les tests.
///
/// Toutes les valeurs sont exprimees dans la grille de reference de
/// 100 x 100 unites, le mark etant centre dedans. L'axe y descend, comme en
/// SVG : la ligne des centres est a y = 50, donc a mi-hauteur de la grille.
///
/// Origine du repere : en haut a gauche.
///
/// Origine des valeurs : specification de marque. Ces ratios sont(figes. Si un
/// d'eux ne rend pas correctement a l'ecran, on remonte le constat au lieu
/// d'ajuster en silence — meme posture que la regle 8 pour les contenus
/// pedagogiques.
library;

/// Geometrie du mark Relio, en coordonnees de grille.
///
/// Les elements accessibles ici sont des nombres bruts ; `RelioMark` (couche
/// Flutter) les expose sous forme d'`Offset`, de `Rect` et de `Color`.
abstract final class RelioMarkGeometry {
  // --- Grille -------------------------------------------------------------

  /// Cote de la grille de reference, en unites.
  static const double grid = 100;

  /// Position du centre du mark dans la grille, sur chaque axe.
  ///
  /// Le mark est centre : son axe de symetrie vertical est a x = 50.
  static const double gridCenterX = 50;

  // --- Cercles ------------------------------------------------------------

  /// Diametre du cercle droit.
  static const double diameterRight = 28;

  /// Diametre du cercle gauche : 55 % du cercle droit.
  static const double diameterLeft = 15.4;

  /// Rayon du cercle droit.
  static const double radiusRight = diameterRight / 2; // 14

  /// Rayon du cercle gauche.
  static const double radiusLeft = diameterLeft / 2; // 7.7

  /// Centre du cercle droit.
  static const double centerRightX = 66;
  static const double centerRightY = 50;

  /// Centre du cercle gauche.
  static const double centerLeftX = 24;
  static const double centerLeftY = 50;

  /// Distance horizontale entre les deux centres : 42 unites.
  static const double centerSpacing = centerRightX - centerLeftX;

  // --- Courbe -------------------------------------------------------------

  /// Ligne des centres, en y.
  ///
  /// Sert de reference aux deux cercles et aux extremites de la courbe.
  static const double centerLineY = 50;

  /// Point bas de la courbe : 6 unites sous la ligne des centres.
  ///
  /// La profondeur a ete ramenee de 16 a 6 unites. A 16, la courbe devenait
  /// le sujet du mark ; a 6, les deux cercles restent les points dominants et
  /// la courbe ne fait que les relier. Rapport profondeur/portee :
  /// 6 / 20.3 = 0.296, conforme au 0.30 de la specification.
  static const double curveLowY = 56;

  /// Abcisse du bord droit du cercle gauche : 24 + 7.7.
  static const double curveStartX = centerLeftX + radiusLeft; // 31.7

  /// Abcisse du bord gauche du cercle droit : 66 - 14.
  static const double curveEndX = centerRightX - radiusRight; // 52

  /// Portee horizontale de la courbe : 20.3 unites.
  static const double curveSpan = curveEndX - curveStartX;

  /// Profondeur de la courbe sous la ligne des centres : 6 unites.
  static const double curveDepth = curveLowY - centerLineY;

  /// Abcisse du point bas : milieu exact entre les deux extremites.
  static const double curveLowX = (curveStartX + curveEndX) / 2; // 41.85

  /// Decalage vertical des points de controle d'une cubique symetrique.
  ///
  /// Pour une cubique dont les quatre points de controle sont a la meme
  /// ordonnee aux extremites et a `centerLineY + decalage` au centre,
  /// l'ordonnee au parametre `t = 0.5` vaut `centerLineY + 0.75 * decalage`.
  /// Imposer `curveLowY` donne donc `6 / 0.75 = 8`.
  static const double curveControlOffset = 8;

  /// Recul horizontal des points de controle, en fraction de la portee.
  ///
  /// Plus la valeur est grande, plus le minimum est large et « presque plat ».
  /// 0.31 donne un creux doux qui tient dans 6 unites de profondeur sans
  /// paraitre tendu, conformement a la specification.
  static const double curveControlReach = 0.31;

  /// Abscisse du premier point de controle.
  static const double curveControl1X = curveStartX + curveSpan * curveControlReach;

  /// Abscisse du second point de controle.
  static const double curveControl2X = curveEndX - curveSpan * curveControlReach;

  /// Ordonnee des deux points de controle.
  static const double curveControlY = centerLineY + curveControlOffset;

  // --- Trait --------------------------------------------------------------

  /// Epaisseur du trait, variante principale : rendue a partir de 48 dp.
  static const double strokePrimary = 4;

  /// Epaisseur du trait, variante compacte : rendue sous 48 dp.
  ///
  /// A 24 dp, le trait de 4 unites ne fait que 0.96 px et disparait. Ce n'est
  /// pas un probleme de courbe mais un probleme de trait : on epaissit pour
  /// compenser la perte de definition optique. Proportions des cercles et de
  /// la courbe inchangees — seul le trait differe.
  static const double strokeCompact = 6.2;

  /// Taille en dp en dessous de laquelle la variante compacte s'applique.
  static const double compactThresholdDp = 48;

  /// Epaisseur de trait adaptee a une largeur logique donnee.
  static double strokeForSize(double logicalWidth) =>
      logicalWidth < compactThresholdDp ? strokeCompact : strokePrimary;

  // --- Launcher icon ------------------------------------------------------

  /// Grille de l'icon adaptatif Android.
  static const double androidGridDp = 108;

  /// Zone sure Android : seule cette zone survit aux masques constructeur.
  static const double androidSafeZoneDp = 66;

  /// Part de la zone safe occupee par le mark : 55 %.
  static const double androidMarkFill = 0.55;

  /// Cote du mark dans la grille de 108 dp : 66 * 0.55 = 36.3 dp.
  ///
  /// Le mark n'est donc pas centre bord a bord dans la zone sure : il laisse
  /// de la respiration. Exception ASSUMEE a la regle des 14 unites, imposee
  /// par les contraintes Android.
  static const double androidMarkSizeDp = androidSafeZoneDp * androidMarkFill;

  // --- Boite englobante ---------------------------------------------------

  /// Moitie du trait : c'est de combien le trait deborde de chaque cote.
  static double strokeCap(double stroke) => stroke / 2;

  /// Boite englobante du mark, trait compris.
  ///
  /// Les extremites arrondies ajoutent la meme moitie d'epaisseur que le
  /// debord du trait : la boite est donc legerement plus large que la seule
  /// somme des diametres.
  static ({double left, double top, double right, double bottom}) boundingBox(
    double stroke,
  ) {
    final double cap = strokeCap(stroke);
    return (
      left: centerLeftX - radiusLeft - cap,
      top: centerLineY - radiusRight - cap,
      right: centerRightX + radiusRight + cap,
      bottom: curveLowY + cap,
    );
  }

  /// Largeur de la boite englobante, trait compris.
  static double boundingWidth(double stroke) =>
      boundingBox(stroke).right - boundingBox(stroke).left;

  /// Hauteur de la boite englobante, trait compris.
  static double boundingHeight(double stroke) =>
      boundingBox(stroke).bottom - boundingBox(stroke).top;

  // --- Evaluation de la cubique ------------------------------------------

  /// Ordonnee de la courbe au parametre [t] de Bezier.
  ///
  /// Expose pour les tests : la valeur 56 au point bas doit etre CONFIRMEE par
  /// l'evaluation, pas reconduite depuis la specification.
  static double curveY(double t) {
    final double mt = 1 - t;
    return mt * mt * mt * centerLineY +
        3 * mt * mt * t * curveControlY +
        3 * mt * t * t * curveControlY +
        t * t * t * centerLineY;
  }

  /// Abscisse de la courbe au parametre [t] de Bezier.
  static double curveX(double t) {
    final double mt = 1 - t;
    return mt * mt * mt * curveStartX +
        3 * mt * mt * t * curveControl1X +
        3 * mt * t * t * curveControl2X +
        t * t * t * curveEndX;
  }

  /// Profondeur maximale reellement atteinte par la courbe, mesuree par
  /// echantillonnage.
  ///
  /// Sert de garde-fou : la profondeur doit rester inferieure au double de la
  /// profondeur voulue, faute de quoi le mark se transformerait en Smile.
  static double measuredDepth({int samples = 2000}) {
    double maxY = centerLineY;
    for (int i = 0; i <= samples; i++) {
      final double y = curveY(i / samples);
      if (y > maxY) maxY = y;
    }
    return maxY - centerLineY;
  }
}
