/// Geometrie pure du mark Relio — SOURCE DE VERITE.
///
/// Ce fichier n'importe QUE `dart:math`. Il ne depend ni de Flutter ni de
/// `dart:ui`, afin de pouvoir etre consomme aussi bien par le generateur de
/// SVG (Dart standalone) que par le rendu a l'ecran et les tests.
///
/// Toutes les valeurs sont exprimees dans la grille de reference de
/// 100 x 100 unites, le mark etant centre dedans. L'axe y descend, comme en
/// SVG.
///
/// Le mark n'est plus paramétrique : il est decrit comme une suite de
/// TRACES REMPLIES, exactement comme il a ete valide. C'est ce qui permet au
/// generateur SVG et au painter Flutter de lire la meme definition au lieu de
/// reconstituer deux formes qui divergeraient.
///
/// Origine des valeurs : specification de marque `docs/brand/`, livree et
/// validee. `test/branding/brand_spec_test.dart` rejoue la normalisation depuis
/// ces fichiers et echoue des que les constantes ci-dessous divergent.
library;

/// Role chromatique d'une partie du mark.
///
/// Le mark n'est plus monochrome : il porte une couleur de base et un accent.
/// Les declinaisons monochrome ecraseent les deux roles sur une seule couleur.
enum RelioMarkRole {
  /// Structure principale : le « R » et le second zigzag.
  base,

  /// Accent : le zigzag orange et le point.
  accent,
}

/// Un noeud de trace, dans la grille de reference.
///
/// Les variantes[M] et [L] sont des positions ; [Q] amene un point de
/// controle puis une arrivee. Ce vocabulaire est celui du SVG : le generateur
/// le restitue tel quel et le painter le traduit en `Path`.
sealed class RelioMarkNode {
  const RelioMarkNode();
}

/// Deplacement, sans tracé.
final class RelioMarkMoveTo extends RelioMarkNode {
  const RelioMarkMoveTo(this.x, this.y);
  final double x;
  final double y;
}

/// Segment droit.
final class RelioMarkLineTo extends RelioMarkNode {
  const RelioMarkLineTo(this.x, this.y);
  final double x;
  final double y;
}

/// Courbe quadratique : point de controle puis arrivee.
final class RelioMarkQuadTo extends RelioMarkNode {
  const RelioMarkQuadTo(this.cx, this.cy, this.x, this.y);
  final double cx;
  final double cy;
  final double x;
  final double y;
}

/// Fermeture du contour courant.
final class RelioMarkClose extends RelioMarkNode {
  const RelioMarkClose();
}

/// Une partie du mark : une trace remplie, avec son role chromatique.
class RelioMarkPart {
  const RelioMarkPart({
    required this.id,
    required this.role,
    required this.nodes,
    required this.box,
  });

  /// Identifiant stable, utilise par le generateur et les tests.
  final String id;

  /// Role chromatique de la partie.
  final RelioMarkRole role;

  /// Trace, en coordonnees de grille.
  final List<RelioMarkNode> nodes;

  /// Boite englobante de la seule partie, en coordonnees de grille.
  final ({double left, double top, double right, double bottom}) box;

  /// Centre de la boite englobante : point de pivot des animations.
  double get centerX => (box.left + box.right) / 2;

  /// Centre de la boite englobante : point de pivot des animations.
  double get centerY => (box.top + box.bottom) / 2;
}

/// Le point du mark : un disque, pas une trace.
///
/// Traite a part parce que le generateur SVG et le painter l'emetent
/// respectivement en `<circle>` et en `drawCircle`.
class RelioMarkDot {
  const RelioMarkDot({
    required this.id,
    required this.role,
    required this.centerX,
    required this.centerY,
    required this.radius,
  });

  final String id;
  final RelioMarkRole role;
  final double centerX;
  final double centerY;
  final double radius;
}

abstract final class RelioMarkGeometry {
  // --- Grille -------------------------------------------------------------

  /// Cote de la grille de reference, en unites.
  static const double grid = 100;

  // --- Partie : le « R » ---------------------------------------------------

  /// Le « R », structure principale du mark.
  ///
  /// Contours ajoures (`evenodd`) : le contre du « R » est un deuxieme
  /// contour, pas un trou boolean.
  static const RelioMarkPart glyph = RelioMarkPart(
    id: 'glyph',
    role: RelioMarkRole.base,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(9.748, 96.541),
      RelioMarkLineTo(9.748, 9.119),
      RelioMarkQuadTo(9.748, 0.0, 19.182, 0.0),
      RelioMarkLineTo(49.371, 0.0),
      RelioMarkQuadTo(76.73, 0.0, 76.73, 26.101),
      RelioMarkQuadTo(76.73, 42.767, 62.579, 50.0),
      RelioMarkLineTo(83.019, 96.541),
      RelioMarkLineTo(60.377, 96.541),
      RelioMarkLineTo(42.453, 53.774),
      RelioMarkLineTo(29.874, 53.774),
      RelioMarkLineTo(29.874, 96.541),
      RelioMarkClose(),
      RelioMarkMoveTo(29.874, 17.925),
      RelioMarkLineTo(29.874, 36.792),
      RelioMarkLineTo(46.855, 36.792),
      RelioMarkQuadTo(55.975, 36.792, 55.975, 27.358),
      RelioMarkQuadTo(55.975, 17.925, 46.855, 17.925),
      RelioMarkClose(),
    ],
    box: (left: 9.748, top: 0.0, right: 83.019, bottom: 96.541),
  );

  // --- Partie : le zigzag d'accent ----------------------------------------

  /// Le zigzag orange : l'accent qui traverse le « R ».
  static const RelioMarkPart zigzagAccent = RelioMarkPart(
    id: 'zigzag-accent',
    role: RelioMarkRole.accent,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(4.403, 92.767),
      RelioMarkLineTo(25.157, 72.013),
      RelioMarkLineTo(32.704, 79.56),
      RelioMarkLineTo(51.572, 60.692),
      RelioMarkLineTo(59.748, 68.868),
      RelioMarkLineTo(32.704, 95.912),
      RelioMarkQuadTo(28.616, 100.0, 23.899, 96.541),
      RelioMarkClose(),
    ],
    box: (left: 4.403, top: 60.692, right: 59.748, bottom: 100.0),
  );

  // --- Partie : le second zigzag ------------------------------------------

  /// Le second zigzag, structure principale : il double le premier en montant.
  static const RelioMarkPart zigzagSecondary = RelioMarkPart(
    id: 'zigzag-secondary',
    role: RelioMarkRole.base,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(48.428, 61.006),
      RelioMarkLineTo(70.44, 38.679),
      RelioMarkLineTo(70.44, 49.371),
      RelioMarkLineTo(86.792, 33.019),
      RelioMarkLineTo(95.597, 41.824),
      RelioMarkLineTo(78.931, 58.491),
      RelioMarkLineTo(89.308, 58.491),
      RelioMarkLineTo(89.308, 69.497),
      RelioMarkLineTo(48.428, 69.497),
      RelioMarkClose(),
    ],
    box: (left: 48.428, top: 33.019, right: 95.597, bottom: 69.497),
  );

  // --- Partie : le point ---------------------------------------------------

  /// Le point orange, en haut a droite : le second accent du mark.
  static const RelioMarkDot dot = RelioMarkDot(
    id: 'dot',
    role: RelioMarkRole.accent,
    centerX: 89.308,
    centerY: 8.805,
    radius: 6.289,
  );

  // --- Assemblage ----------------------------------------------------------

  /// Les traces du mark, dans l'ordre de dessin.
  static const List<RelioMarkPart> parts = <RelioMarkPart>[
    glyph,
    zigzagAccent,
    zigzagSecondary,
  ];

  // --- Boite englobante ---------------------------------------------------

  /// Boite englobante du mark entier, en coordonnees de grille.
  ///
  /// Le mark est remplit de traces pleines : il n'y a plus de trait dont le
  /// debord devrait etre ajoute. La boite se lit directement sur les boites
  /// des parties.
  static const ({double left, double top, double right, double bottom})
  boundingBox = (
    left: 4.403,
    top: 0.0,
    right: 95.597,
    bottom: 100.0,
  );

  /// Largeur REELLEMENT encree du mark, en unites de grille.
  ///
  /// Distincte de la largeur de la boite englobante des lignes ci-dessous :
  /// celle-ci se rapporte a un carre de reference arbitraire, celle-la a
  /// l'encre. Les deux coincident ici puisque le mark n'a plus de debord de
  /// trait, mais les nommer separement evite de les confondre.
  static double get inkWidth => boundingBox.right - boundingBox.left;

  /// Hauteur REELLEMENT encree du mark, en unites de grille.
  static double get inkHeight => boundingBox.bottom - boundingBox.top;

  /// Centre vertical reellement encre, en unites de grille.
  static double get inkCenterY => (boundingBox.top + boundingBox.bottom) / 2;

  /// Centre horizontal reellement encre, en unites de grille.
  static double get inkCenterX => (boundingBox.left + boundingBox.right) / 2;

  // --- Launcher icon ------------------------------------------------------

  /// Grille de l'icon adaptatif Android.
  static const double androidGridDp = 108;

  /// Zone sure Android : seule cette zone survit aux masques constructeur.
  static const double androidSafeZoneDp = 66;

  /// Part de la zone safe occupee par le mark : 55 %.
  static const double androidMarkFill = 0.55;

  /// Cote du mark dans la grille de 108 dp : 66 * 0.55 = 36.3 dp.
  static const double androidMarkSizeDp = androidSafeZoneDp * androidMarkFill;

  /// Largeur REELLE du mark dans la grille de 108 dp, en dp.
  static double get androidMarkWidthDp => androidMarkSizeDp;

  /// Hauteur correspondante du mark, en dp, deduite de son rapport de forme.
  ///
  /// Le mark n'est pas carre : il mesure 91,194 x 100 unites. Traiter
  /// `androidMarkSizeDp` comme un cote de carre le ferait sortir de la zone
  /// sure en hauteur.
  static double get androidMarkHeightDp =>
      androidMarkWidthDp * inkHeight / inkWidth;

  // --- Icone applicative --------------------------------------------------

  /// Rayon des coins du fond de l'icone, en fraction du cote.
  ///
  /// L'icone fournie introduit un carre a coins arrondis : ce rayon est ce
  /// qui la distingue d'une pastille pleine. Exprime en fraction pour
  /// survivre a tous les densites sans etre recalcule.
  static const double iconCornerRadiusRatio = 112 / 512;

  /// Marge du fond de l'icone, en fraction du cote.
  ///
  /// Le fond ne touche pas le bord du canevas : il est en retrait, sinon les
  /// coins arrondis seraient coupes par le bord du fichier.
  static const double iconBackgroundInsetRatio = 12 / 512;
}