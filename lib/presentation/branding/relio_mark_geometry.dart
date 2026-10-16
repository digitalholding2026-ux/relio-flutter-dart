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
/// Le mark est decrit comme une suite de TRACES REMPLIES, exactement comme
/// il a ete valide. C'est ce qui permet au generateur SVG et au painter
/// Flutter de lire la meme definition au lieu de reconstituer deux formes
/// qui divergeraient.
///
/// Origine des valeurs : specification de marque `docs/brand/`, livree et
/// validee (import mecanique tool/brand_import.py).
/// `test/branding/brand_spec_test.dart` rejoue la normalisation depuis
/// ces fichiers et echoue des que les constantes ci-dessous divergent.
library;

/// Role chromatique d'une partie du mark.
///
/// Le mark n'est pas monochrome : il porte une couleur de base et un accent.
/// Les declinaisons monochrome ecraseent les deux roles sur une seule couleur.
enum RelioMarkRole {
  /// Structure principale : chapeau, fût, courbe et balayage, en navy.
  base,

  /// Accent : les pages et le gland, en orange.
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

abstract final class RelioMarkGeometry {
  // --- Grille -------------------------------------------------------------

  /// Cote de la grille de reference, en unites.
  static const double grid = 100;

  // --- Partie : cap -------------------------------------------

  /// La planche du chapeau de diplômé, structure principale.
  static const RelioMarkPart cap =
      RelioMarkPart(
    id: 'cap',
    role: RelioMarkRole.base,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(44.332, 0.653),
      RelioMarkQuadTo(44.453, 0.696, 44.576, 0.74),
      RelioMarkQuadTo(44.698, 0.783, 44.823, 0.827),
      RelioMarkQuadTo(45.086, 0.921, 45.35, 1.016),
      RelioMarkQuadTo(45.613, 1.111, 45.876, 1.207),
      RelioMarkQuadTo(46.304, 1.362, 46.733, 1.516),
      RelioMarkQuadTo(47.162, 1.67, 47.592, 1.822),
      RelioMarkQuadTo(48.21, 2.042, 48.827, 2.263),
      RelioMarkQuadTo(49.445, 2.483, 50.063, 2.704),
      RelioMarkQuadTo(51.476, 3.208, 52.893, 3.701),
      RelioMarkQuadTo(54.311, 4.193, 55.729, 4.682),
      RelioMarkQuadTo(56.216, 4.85, 56.703, 5.019),
      RelioMarkQuadTo(57.189, 5.187, 57.676, 5.356),
      RelioMarkQuadTo(59.356, 5.939, 61.039, 6.516),
      RelioMarkQuadTo(62.721, 7.093, 64.406, 7.661),
      RelioMarkQuadTo(65.161, 7.915, 65.915, 8.171),
      RelioMarkQuadTo(66.67, 8.426, 67.424, 8.682),
      RelioMarkQuadTo(68.051, 8.895, 68.68, 9.106),
      RelioMarkQuadTo(69.308, 9.318, 69.937, 9.527),
      RelioMarkQuadTo(70.233, 9.626, 70.529, 9.726),
      RelioMarkQuadTo(70.825, 9.826, 71.121, 9.927),
      RelioMarkQuadTo(71.484, 10.05, 71.848, 10.172),
      RelioMarkQuadTo(72.211, 10.294, 72.576, 10.414),
      RelioMarkQuadTo(72.736, 10.469, 72.897, 10.525),
      RelioMarkQuadTo(73.059, 10.58, 73.224, 10.637),
      RelioMarkQuadTo(73.364, 10.684, 73.505, 10.731),
      RelioMarkQuadTo(73.646, 10.779, 73.79, 10.827),
      RelioMarkQuadTo(74.17, 11.022, 74.338, 11.247),
      RelioMarkQuadTo(74.507, 11.473, 74.643, 11.872),
      RelioMarkQuadTo(74.304, 12.217, 74.04, 12.308),
      RelioMarkQuadTo(73.776, 12.4, 73.302, 12.454),
      RelioMarkQuadTo(70.282, 12.954, 67.412, 13.818),
      RelioMarkQuadTo(64.542, 14.682, 61.671, 15.724),
      RelioMarkQuadTo(61.49, 15.787, 61.309, 15.851),
      RelioMarkQuadTo(61.127, 15.916, 60.941, 15.981),
      RelioMarkQuadTo(57.521, 17.201, 54.125, 18.492),
      RelioMarkQuadTo(50.73, 19.783, 47.338, 21.079),
      RelioMarkQuadTo(46.975, 21.217, 46.613, 21.355),
      RelioMarkQuadTo(46.25, 21.492, 45.887, 21.629),
      RelioMarkQuadTo(45.059, 21.942, 44.235, 22.262),
      RelioMarkQuadTo(43.411, 22.583, 42.591, 22.917),
      RelioMarkQuadTo(42.447, 22.975, 42.302, 23.033),
      RelioMarkQuadTo(42.157, 23.092, 42.009, 23.151),
      RelioMarkQuadTo(41.745, 23.258, 41.482, 23.366),
      RelioMarkQuadTo(41.219, 23.475, 40.958, 23.587),
      RelioMarkQuadTo(39.479, 24.142, 38.142, 23.882),
      RelioMarkQuadTo(36.805, 23.622, 35.354, 23.076),
      RelioMarkQuadTo(35.182, 23.018, 35.008, 22.96),
      RelioMarkQuadTo(34.834, 22.902, 34.657, 22.843),
      RelioMarkQuadTo(34.191, 22.686, 33.725, 22.529),
      RelioMarkQuadTo(33.259, 22.372, 32.794, 22.214),
      RelioMarkQuadTo(32.404, 22.082, 32.014, 21.951),
      RelioMarkQuadTo(31.624, 21.819, 31.235, 21.688),
      RelioMarkQuadTo(28.552, 20.787, 25.876, 19.865),
      RelioMarkQuadTo(23.2, 18.943, 20.53, 18.003),
      RelioMarkQuadTo(17.954, 17.1, 15.367, 16.23),
      RelioMarkQuadTo(12.781, 15.36, 10.188, 14.507),
      RelioMarkQuadTo(10.169, 14.414, 10.137, 14.255),
      RelioMarkQuadTo(10.106, 14.097, 9.985, 13.494),
      RelioMarkQuadTo(10.766, 12.933, 11.596, 12.525),
      RelioMarkQuadTo(12.426, 12.118, 13.315, 11.755),
      RelioMarkQuadTo(13.473, 11.688, 13.631, 11.621),
      RelioMarkQuadTo(13.79, 11.554, 13.953, 11.485),
      RelioMarkQuadTo(14.474, 11.265, 14.996, 11.045),
      RelioMarkQuadTo(15.518, 10.825, 16.04, 10.606),
      RelioMarkQuadTo(16.501, 10.411, 16.962, 10.216),
      RelioMarkQuadTo(17.423, 10.021, 17.884, 9.826),
      RelioMarkQuadTo(17.978, 9.786, 18.072, 9.746),
      RelioMarkQuadTo(18.166, 9.706, 18.262, 9.666),
      RelioMarkQuadTo(18.356, 9.626, 18.451, 9.586),
      RelioMarkQuadTo(18.546, 9.545, 18.643, 9.504),
      RelioMarkQuadTo(18.933, 9.382, 19.223, 9.259),
      RelioMarkQuadTo(19.514, 9.136, 19.804, 9.014),
      RelioMarkQuadTo(21.688, 8.217, 23.569, 7.411),
      RelioMarkQuadTo(25.45, 6.606, 27.329, 5.797),
      RelioMarkQuadTo(28.386, 5.343, 29.443, 4.891),
      RelioMarkQuadTo(30.5, 4.439, 31.557, 3.987),
      RelioMarkQuadTo(32.476, 3.594, 33.395, 3.199),
      RelioMarkQuadTo(34.313, 2.804, 35.23, 2.407),
      RelioMarkQuadTo(35.741, 2.187, 36.252, 1.968),
      RelioMarkQuadTo(36.764, 1.749, 37.275, 1.532),
      RelioMarkQuadTo(37.504, 1.434, 37.732, 1.335),
      RelioMarkQuadTo(37.96, 1.237, 38.188, 1.137),
      RelioMarkQuadTo(38.495, 1.003, 38.803, 0.872),
      RelioMarkQuadTo(39.11, 0.741, 39.419, 0.61),
      RelioMarkQuadTo(39.481, 0.583, 39.587, 0.538),
      RelioMarkQuadTo(39.693, 0.492, 40.097, 0.318),
      RelioMarkQuadTo(41.222, 0.0, 42.239, 0.118),
      RelioMarkQuadTo(43.256, 0.237, 44.332, 0.653),
      RelioMarkClose(),
    ],
    box: (left: 9.985, top: 0.0, right: 74.643, bottom: 24.142),
  );

  // --- Partie : stem -------------------------------------------

  /// Le fût vertical, structure principale.
  static const RelioMarkPart stem =
      RelioMarkPart(
    id: 'stem',
    role: RelioMarkRole.base,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(9.376, 22.281),
      RelioMarkQuadTo(9.921, 22.353, 10.465, 22.432),
      RelioMarkQuadTo(11.008, 22.512, 11.552, 22.594),
      RelioMarkQuadTo(11.753, 22.624, 11.954, 22.654),
      RelioMarkQuadTo(12.155, 22.684, 12.356, 22.714),
      RelioMarkQuadTo(12.775, 22.777, 13.194, 22.84),
      RelioMarkQuadTo(13.613, 22.903, 14.031, 22.967),
      RelioMarkQuadTo(14.567, 23.048, 15.103, 23.128),
      RelioMarkQuadTo(15.638, 23.208, 16.174, 23.287),
      RelioMarkQuadTo(16.588, 23.348, 17.002, 23.411),
      RelioMarkQuadTo(17.416, 23.473, 17.83, 23.535),
      RelioMarkQuadTo(18.123, 23.579, 18.417, 23.623),
      RelioMarkQuadTo(18.71, 23.666, 19.003, 23.71),
      RelioMarkQuadTo(19.181, 23.737, 19.361, 23.765),
      RelioMarkQuadTo(19.541, 23.792, 19.725, 23.82),
      RelioMarkQuadTo(19.881, 23.844, 20.039, 23.868),
      RelioMarkQuadTo(20.196, 23.891, 20.358, 23.916),
      RelioMarkQuadTo(21.049, 24.037, 21.502, 24.248),
      RelioMarkQuadTo(21.955, 24.458, 22.349, 25.047),
      RelioMarkQuadTo(22.386, 25.323, 22.394, 25.46),
      RelioMarkQuadTo(22.402, 25.597, 22.401, 25.923),
      RelioMarkQuadTo(22.402, 26.058, 22.402, 26.194),
      RelioMarkQuadTo(22.403, 26.33, 22.404, 26.468),
      RelioMarkQuadTo(22.404, 26.617, 22.403, 26.766),
      RelioMarkQuadTo(22.402, 26.915, 22.402, 27.068),
      RelioMarkQuadTo(22.402, 27.127, 22.402, 27.226),
      RelioMarkQuadTo(22.403, 27.326, 22.404, 27.705),
      RelioMarkQuadTo(22.406, 28.235, 22.406, 28.765),
      RelioMarkQuadTo(22.405, 29.296, 22.405, 29.826),
      RelioMarkQuadTo(22.405, 30.205, 22.406, 30.585),
      RelioMarkQuadTo(22.407, 30.964, 22.408, 31.343),
      RelioMarkQuadTo(22.41, 32.268, 22.41, 33.193),
      RelioMarkQuadTo(22.411, 34.117, 22.41, 35.042),
      RelioMarkQuadTo(22.41, 35.794, 22.41, 36.545),
      RelioMarkQuadTo(22.411, 37.297, 22.411, 38.049),
      RelioMarkQuadTo(22.411, 38.155, 22.411, 38.263),
      RelioMarkQuadTo(22.411, 38.37, 22.412, 38.48),
      RelioMarkQuadTo(22.412, 38.698, 22.412, 38.915),
      RelioMarkQuadTo(22.412, 39.132, 22.412, 39.349),
      RelioMarkQuadTo(22.414, 41.386, 22.414, 43.423),
      RelioMarkQuadTo(22.414, 45.461, 22.413, 47.498),
      RelioMarkQuadTo(22.412, 49.362, 22.414, 51.227),
      RelioMarkQuadTo(22.415, 53.091, 22.418, 54.955),
      RelioMarkQuadTo(22.421, 56.869, 22.422, 58.782),
      RelioMarkQuadTo(22.423, 60.696, 22.423, 62.609),
      RelioMarkQuadTo(22.422, 63.684, 22.423, 64.758),
      RelioMarkQuadTo(22.424, 65.833, 22.426, 66.907),
      RelioMarkQuadTo(22.428, 67.918, 22.427, 68.928),
      RelioMarkQuadTo(22.427, 69.939, 22.425, 70.949),
      RelioMarkQuadTo(22.425, 71.32, 22.425, 71.692),
      RelioMarkQuadTo(22.426, 72.063, 22.427, 72.434),
      RelioMarkQuadTo(22.429, 72.94, 22.428, 73.446),
      RelioMarkQuadTo(22.427, 73.952, 22.425, 74.458),
      RelioMarkQuadTo(22.426, 74.606, 22.427, 74.754),
      RelioMarkQuadTo(22.428, 74.903, 22.429, 75.055),
      RelioMarkQuadTo(22.443, 75.788, 22.329, 76.371),
      RelioMarkQuadTo(22.214, 76.955, 21.741, 77.544),
      RelioMarkQuadTo(21.448, 77.774, 21.303, 77.872),
      RelioMarkQuadTo(21.157, 77.97, 20.811, 78.171),
      RelioMarkQuadTo(20.672, 78.254, 20.531, 78.338),
      RelioMarkQuadTo(20.39, 78.422, 20.247, 78.508),
      RelioMarkQuadTo(20.096, 78.595, 19.945, 78.683),
      RelioMarkQuadTo(19.793, 78.771, 19.638, 78.861),
      RelioMarkQuadTo(19.319, 79.051, 18.999, 79.241),
      RelioMarkQuadTo(18.68, 79.431, 18.36, 79.621),
      RelioMarkQuadTo(18.199, 79.717, 18.037, 79.813),
      RelioMarkQuadTo(17.874, 79.909, 17.708, 80.007),
      RelioMarkQuadTo(17.013, 80.421, 16.325, 80.846),
      RelioMarkQuadTo(15.637, 81.27, 14.951, 81.699),
      RelioMarkQuadTo(14.691, 81.86, 14.432, 82.02),
      RelioMarkQuadTo(14.172, 82.181, 13.912, 82.342),
      RelioMarkQuadTo(13.484, 82.607, 13.056, 82.872),
      RelioMarkQuadTo(12.628, 83.138, 12.2, 83.404),
      RelioMarkQuadTo(11.723, 83.701, 11.245, 83.996),
      RelioMarkQuadTo(10.767, 84.292, 10.289, 84.587),
      RelioMarkQuadTo(10.141, 84.68, 9.992, 84.773),
      RelioMarkQuadTo(9.843, 84.866, 9.691, 84.961),
      RelioMarkQuadTo(9.639, 84.993, 9.551, 85.047),
      RelioMarkQuadTo(9.464, 85.101, 9.13, 85.306),
      RelioMarkQuadTo(9.008, 85.382, 8.885, 85.458),
      RelioMarkQuadTo(8.762, 85.534, 8.636, 85.612),
      RelioMarkQuadTo(8.257, 85.81, 7.916, 85.921),
      RelioMarkQuadTo(7.574, 86.031, 7.147, 86.057),
      RelioMarkQuadTo(6.85, 85.898, 6.723, 85.803),
      RelioMarkQuadTo(6.597, 85.708, 6.337, 85.449),
      RelioMarkQuadTo(6.264, 85.125, 6.248, 84.962),
      RelioMarkQuadTo(6.232, 84.798, 6.235, 84.401),
      RelioMarkQuadTo(6.233, 84.238, 6.231, 84.073),
      RelioMarkQuadTo(6.23, 83.908, 6.228, 83.74),
      RelioMarkQuadTo(6.23, 83.56, 6.231, 83.378),
      RelioMarkQuadTo(6.232, 83.197, 6.234, 83.011),
      RelioMarkQuadTo(6.233, 82.82, 6.232, 82.628),
      RelioMarkQuadTo(6.231, 82.435, 6.23, 82.239),
      RelioMarkQuadTo(6.227, 81.707, 6.228, 81.175),
      RelioMarkQuadTo(6.229, 80.644, 6.231, 80.112),
      RelioMarkQuadTo(6.232, 79.539, 6.231, 78.966),
      RelioMarkQuadTo(6.229, 78.393, 6.227, 77.82),
      RelioMarkQuadTo(6.225, 76.697, 6.225, 75.575),
      RelioMarkQuadTo(6.225, 74.452, 6.227, 73.329),
      RelioMarkQuadTo(6.228, 72.416, 6.229, 71.504),
      RelioMarkQuadTo(6.229, 70.592, 6.228, 69.679),
      RelioMarkQuadTo(6.228, 69.55, 6.228, 69.419),
      RelioMarkQuadTo(6.228, 69.289, 6.228, 69.155),
      RelioMarkQuadTo(6.228, 68.892, 6.227, 68.628),
      RelioMarkQuadTo(6.227, 68.365, 6.227, 68.101),
      RelioMarkQuadTo(6.225, 65.629, 6.227, 63.156),
      RelioMarkQuadTo(6.228, 60.684, 6.232, 58.211),
      RelioMarkQuadTo(6.234, 56.088, 6.234, 53.966),
      RelioMarkQuadTo(6.234, 51.843, 6.231, 49.72),
      RelioMarkQuadTo(6.228, 47.257, 6.227, 44.794),
      RelioMarkQuadTo(6.226, 42.33, 6.227, 39.867),
      RelioMarkQuadTo(6.228, 39.605, 6.228, 39.342),
      RelioMarkQuadTo(6.228, 39.079, 6.228, 38.817),
      RelioMarkQuadTo(6.228, 38.688, 6.228, 38.558),
      RelioMarkQuadTo(6.228, 38.428, 6.228, 38.295),
      RelioMarkQuadTo(6.229, 37.383, 6.228, 36.472),
      RelioMarkQuadTo(6.228, 35.56, 6.226, 34.649),
      RelioMarkQuadTo(6.224, 33.538, 6.225, 32.428),
      RelioMarkQuadTo(6.226, 31.317, 6.229, 30.207),
      RelioMarkQuadTo(6.23, 29.64, 6.231, 29.073),
      RelioMarkQuadTo(6.231, 28.506, 6.229, 27.939),
      RelioMarkQuadTo(6.227, 27.325, 6.229, 26.711),
      RelioMarkQuadTo(6.23, 26.098, 6.234, 25.484),
      RelioMarkQuadTo(6.233, 25.416, 6.232, 25.303),
      RelioMarkQuadTo(6.231, 25.189, 6.228, 24.756),
      RelioMarkQuadTo(6.23, 24.592, 6.231, 24.427),
      RelioMarkQuadTo(6.233, 24.262, 6.235, 24.093),
      RelioMarkQuadTo(6.235, 23.952, 6.235, 23.809),
      RelioMarkQuadTo(6.235, 23.666, 6.235, 23.521),
      RelioMarkQuadTo(6.53, 22.332, 7.437, 22.216),
      RelioMarkQuadTo(8.343, 22.1, 9.376, 22.281),
      RelioMarkClose(),
    ],
    box: (left: 6.224, top: 22.1, right: 22.443, bottom: 86.057),
  );

  // --- Partie : body -------------------------------------------

  /// La courbe du livre, structure principale.
  static const RelioMarkPart body =
      RelioMarkPart(
    id: 'body',
    role: RelioMarkRole.base,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(62.482, 19.169),
      RelioMarkQuadTo(64.33, 21.736, 64.877, 25.089),
      RelioMarkQuadTo(65.425, 28.441, 65.016, 31.512),
      RelioMarkQuadTo(64.352, 34.893, 62.648, 37.504),
      RelioMarkQuadTo(60.944, 40.115, 58.091, 42.03),
      RelioMarkQuadTo(56.502, 42.989, 54.802, 43.719),
      RelioMarkQuadTo(53.103, 44.449, 51.378, 45.128),
      RelioMarkQuadTo(48.359, 46.338, 47.412, 46.766),
      RelioMarkQuadTo(46.465, 47.193, 45.316, 47.862),
      RelioMarkQuadTo(45.204, 47.926, 45.09, 47.989),
      RelioMarkQuadTo(44.977, 48.053, 44.861, 48.118),
      RelioMarkQuadTo(42.858, 49.264, 40.979, 50.594),
      RelioMarkQuadTo(39.099, 51.923, 37.348, 53.424),
      RelioMarkQuadTo(37.207, 53.537, 37.065, 53.651),
      RelioMarkQuadTo(36.923, 53.765, 36.778, 53.881),
      RelioMarkQuadTo(35.659, 54.797, 34.608, 55.778),
      RelioMarkQuadTo(33.557, 56.759, 32.534, 57.782),
      RelioMarkQuadTo(32.401, 57.913, 32.267, 58.046),
      RelioMarkQuadTo(32.134, 58.178, 31.997, 58.313),
      RelioMarkQuadTo(31.094, 59.223, 30.26, 60.178),
      RelioMarkQuadTo(29.426, 61.134, 28.632, 62.139),
      RelioMarkQuadTo(28.546, 62.247, 28.46, 62.355),
      RelioMarkQuadTo(28.373, 62.464, 28.284, 62.575),
      RelioMarkQuadTo(28.066, 62.848, 27.849, 63.123),
      RelioMarkQuadTo(27.632, 63.397, 27.416, 63.672),
      RelioMarkQuadTo(27.389, 63.706, 27.344, 63.764),
      RelioMarkQuadTo(27.298, 63.822, 27.124, 64.042),
      RelioMarkQuadTo(26.631, 64.664, 26.486, 64.874),
      RelioMarkQuadTo(26.342, 65.083, 26.2, 65.382),
      RelioMarkQuadTo(26.1, 65.382, 25.999, 65.382),
      RelioMarkQuadTo(25.898, 65.382, 25.795, 65.382),
      RelioMarkQuadTo(26.418, 60.739, 29.244, 56.605),
      RelioMarkQuadTo(32.069, 52.47, 35.071, 48.999),
      RelioMarkQuadTo(39.301, 43.963, 40.163, 42.248),
      RelioMarkQuadTo(41.026, 40.532, 40.591, 38.019),
      RelioMarkQuadTo(39.504, 34.42, 36.076, 31.857),
      RelioMarkQuadTo(32.648, 29.294, 29.595, 27.353),
      RelioMarkQuadTo(29.449, 27.25, 29.301, 27.147),
      RelioMarkQuadTo(29.154, 27.044, 29.003, 26.938),
      RelioMarkQuadTo(28.271, 26.427, 27.526, 25.952),
      RelioMarkQuadTo(26.781, 25.476, 25.997, 25.047),
      RelioMarkQuadTo(26.048, 24.847, 26.098, 24.645),
      RelioMarkQuadTo(26.149, 24.443, 26.2, 24.236),
      RelioMarkQuadTo(26.723, 24.058, 27.158, 24.09),
      RelioMarkQuadTo(27.592, 24.122, 28.122, 24.271),
      RelioMarkQuadTo(28.289, 24.314, 28.457, 24.357),
      RelioMarkQuadTo(28.625, 24.4, 28.797, 24.443),
      RelioMarkQuadTo(28.864, 24.461, 28.978, 24.491),
      RelioMarkQuadTo(29.091, 24.521, 29.523, 24.635),
      RelioMarkQuadTo(29.709, 24.682, 29.895, 24.73),
      RelioMarkQuadTo(30.082, 24.778, 30.273, 24.826),
      RelioMarkQuadTo(30.867, 24.979, 31.461, 25.132),
      RelioMarkQuadTo(32.055, 25.286, 32.648, 25.44),
      RelioMarkQuadTo(33.24, 25.594, 33.832, 25.747),
      RelioMarkQuadTo(34.424, 25.9, 35.017, 26.051),
      RelioMarkQuadTo(35.386, 26.146, 35.754, 26.241),
      RelioMarkQuadTo(36.123, 26.337, 36.491, 26.434),
      RelioMarkQuadTo(37.921, 26.817, 39.096, 26.796),
      RelioMarkQuadTo(40.272, 26.775, 41.649, 26.256),
      RelioMarkQuadTo(41.782, 26.208, 41.915, 26.16),
      RelioMarkQuadTo(42.049, 26.112, 42.186, 26.062),
      RelioMarkQuadTo(42.599, 25.912, 43.011, 25.759),
      RelioMarkQuadTo(43.423, 25.607, 43.834, 25.453),
      RelioMarkQuadTo(43.958, 25.406, 44.082, 25.36),
      RelioMarkQuadTo(44.207, 25.313, 44.334, 25.265),
      RelioMarkQuadTo(45.07, 24.989, 45.803, 24.708),
      RelioMarkQuadTo(46.537, 24.427, 47.27, 24.144),
      RelioMarkQuadTo(49.614, 23.241, 51.963, 22.352),
      RelioMarkQuadTo(54.313, 21.463, 56.669, 20.593),
      RelioMarkQuadTo(56.964, 20.483, 57.259, 20.373),
      RelioMarkQuadTo(57.554, 20.263, 57.848, 20.152),
      RelioMarkQuadTo(58.259, 19.998, 58.671, 19.845),
      RelioMarkQuadTo(59.083, 19.693, 59.495, 19.542),
      RelioMarkQuadTo(59.616, 19.496, 59.738, 19.449),
      RelioMarkQuadTo(59.86, 19.403, 59.985, 19.355),
      RelioMarkQuadTo(60.644, 19.101, 61.216, 19.025),
      RelioMarkQuadTo(61.788, 18.948, 62.482, 19.169),
      RelioMarkClose(),
    ],
    box: (left: 25.795, top: 18.948, right: 65.425, bottom: 65.382),
  );

  // --- Partie : base -------------------------------------------

  /// Le balayage inférieur du livre, structure principale.
  static const RelioMarkPart base =
      RelioMarkPart(
    id: 'base',
    role: RelioMarkRole.base,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(46.418, 67.954),
      RelioMarkQuadTo(46.545, 67.954, 46.672, 67.955),
      RelioMarkQuadTo(46.799, 67.955, 46.929, 67.955),
      RelioMarkQuadTo(48.871, 67.953, 50.772, 68.09),
      RelioMarkQuadTo(52.672, 68.227, 54.577, 68.625),
      RelioMarkQuadTo(54.723, 68.656, 54.871, 68.686),
      RelioMarkQuadTo(55.019, 68.716, 55.17, 68.747),
      RelioMarkQuadTo(63.452, 70.539, 70.32, 74.931),
      RelioMarkQuadTo(77.187, 79.322, 82.751, 85.651),
      RelioMarkQuadTo(83.01, 85.933, 83.27, 86.215),
      RelioMarkQuadTo(83.529, 86.497, 83.789, 86.779),
      RelioMarkQuadTo(84.39, 87.441, 84.964, 88.122),
      RelioMarkQuadTo(85.538, 88.803, 86.099, 89.499),
      RelioMarkQuadTo(86.545, 90.04, 87.001, 90.572),
      RelioMarkQuadTo(87.458, 91.103, 87.919, 91.631),
      RelioMarkQuadTo(88.604, 92.416, 89.275, 93.212),
      RelioMarkQuadTo(89.945, 94.008, 90.601, 94.818),
      RelioMarkQuadTo(91.082, 95.405, 91.571, 95.984),
      RelioMarkQuadTo(92.061, 96.563, 92.555, 97.139),
      RelioMarkQuadTo(93.419, 98.116, 93.597, 98.506),
      RelioMarkQuadTo(93.776, 98.897, 93.696, 99.637),
      RelioMarkQuadTo(93.353, 99.807, 93.072, 99.841),
      RelioMarkQuadTo(92.791, 99.875, 92.407, 99.868),
      RelioMarkQuadTo(92.355, 99.868, 92.267, 99.869),
      RelioMarkQuadTo(92.179, 99.87, 91.844, 99.872),
      RelioMarkQuadTo(91.691, 99.872, 91.537, 99.872),
      RelioMarkQuadTo(91.383, 99.872, 91.225, 99.872),
      RelioMarkQuadTo(91.165, 99.873, 91.063, 99.873),
      RelioMarkQuadTo(90.961, 99.874, 90.573, 99.875),
      RelioMarkQuadTo(90.037, 99.878, 89.5, 99.879),
      RelioMarkQuadTo(88.964, 99.88, 88.427, 99.881),
      RelioMarkQuadTo(88.053, 99.882, 87.679, 99.883),
      RelioMarkQuadTo(87.305, 99.883, 86.931, 99.884),
      RelioMarkQuadTo(86.144, 99.886, 85.357, 99.887),
      RelioMarkQuadTo(84.57, 99.888, 83.783, 99.888),
      RelioMarkQuadTo(82.783, 99.889, 81.782, 99.892),
      RelioMarkQuadTo(80.781, 99.896, 79.781, 99.9),
      RelioMarkQuadTo(79.006, 99.903, 78.232, 99.904),
      RelioMarkQuadTo(77.457, 99.905, 76.683, 99.905),
      RelioMarkQuadTo(76.315, 99.906, 75.946, 99.907),
      RelioMarkQuadTo(75.578, 99.908, 75.21, 99.91),
      RelioMarkQuadTo(69.025, 100.0, 63.72, 98.228),
      RelioMarkQuadTo(58.415, 96.456, 53.897, 92.12),
      RelioMarkQuadTo(53.629, 91.853, 53.362, 91.585),
      RelioMarkQuadTo(53.095, 91.317, 52.828, 91.048),
      RelioMarkQuadTo(52.695, 90.916, 52.561, 90.783),
      RelioMarkQuadTo(52.427, 90.65, 52.29, 90.514),
      RelioMarkQuadTo(51.492, 89.713, 50.749, 88.877),
      RelioMarkQuadTo(50.006, 88.041, 49.299, 87.158),
      RelioMarkQuadTo(48.954, 86.731, 48.595, 86.323),
      RelioMarkQuadTo(48.236, 85.914, 47.863, 85.512),
      RelioMarkQuadTo(47.444, 85.058, 47.031, 84.6),
      RelioMarkQuadTo(46.619, 84.143, 46.216, 83.675),
      RelioMarkQuadTo(43.52, 80.501, 40.425, 77.749),
      RelioMarkQuadTo(37.33, 74.996, 33.497, 73.287),
      RelioMarkQuadTo(33.371, 73.23, 33.244, 73.172),
      RelioMarkQuadTo(33.116, 73.114, 32.986, 73.055),
      RelioMarkQuadTo(31.451, 72.507, 29.62, 72.527),
      RelioMarkQuadTo(27.789, 72.548, 26.2, 72.882),
      RelioMarkQuadTo(26.2, 72.782, 26.2, 72.681),
      RelioMarkQuadTo(26.2, 72.58, 26.2, 72.477),
      RelioMarkQuadTo(28.816, 71.379, 31.469, 70.437),
      RelioMarkQuadTo(34.122, 69.495, 36.892, 68.866),
      RelioMarkQuadTo(37.025, 68.837, 37.158, 68.807),
      RelioMarkQuadTo(37.292, 68.777, 37.428, 68.746),
      RelioMarkQuadTo(39.663, 68.286, 41.902, 68.111),
      RelioMarkQuadTo(44.142, 67.936, 46.418, 67.954),
      RelioMarkClose(),
    ],
    box: (left: 26.2, top: 67.936, right: 93.776, bottom: 100.0),
  );

  // --- Partie : page-upper -------------------------------------------

  /// La page supérieure, accent.
  static const RelioMarkPart pageUpper =
      RelioMarkPart(
    id: 'page-upper',
    role: RelioMarkRole.accent,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(66.662, 45.025),
      RelioMarkQuadTo(66.85, 45.02, 67.039, 45.014),
      RelioMarkQuadTo(67.227, 45.009, 67.421, 45.004),
      RelioMarkQuadTo(68.662, 44.983, 69.059, 45.057),
      RelioMarkQuadTo(69.456, 45.13, 69.961, 45.476),
      RelioMarkQuadTo(70.448, 46.222, 70.903, 46.983),
      RelioMarkQuadTo(71.358, 47.744, 71.793, 48.521),
      RelioMarkQuadTo(71.943, 48.786, 72.093, 49.05),
      RelioMarkQuadTo(72.244, 49.315, 72.394, 49.58),
      RelioMarkQuadTo(72.497, 49.761, 72.6, 49.942),
      RelioMarkQuadTo(72.703, 50.124, 72.806, 50.305),
      RelioMarkQuadTo(73.432, 51.409, 74.072, 52.504),
      RelioMarkQuadTo(74.712, 53.599, 75.356, 54.692),
      RelioMarkQuadTo(75.585, 55.083, 75.812, 55.476),
      RelioMarkQuadTo(76.039, 55.868, 76.264, 56.261),
      RelioMarkQuadTo(76.302, 56.326, 76.366, 56.434),
      RelioMarkQuadTo(76.43, 56.542, 76.673, 56.955),
      RelioMarkQuadTo(76.822, 57.316, 76.827, 57.472),
      RelioMarkQuadTo(76.832, 57.629, 76.708, 57.959),
      RelioMarkQuadTo(76.648, 58.04, 76.588, 58.122),
      RelioMarkQuadTo(76.528, 58.204, 76.467, 58.288),
      RelioMarkQuadTo(76.366, 58.262, 76.263, 58.236),
      RelioMarkQuadTo(76.161, 58.21, 76.056, 58.184),
      RelioMarkQuadTo(75.739, 58.104, 75.421, 58.025),
      RelioMarkQuadTo(75.103, 57.945, 74.785, 57.867),
      RelioMarkQuadTo(74.411, 57.774, 74.037, 57.677),
      RelioMarkQuadTo(73.664, 57.581, 73.291, 57.481),
      RelioMarkQuadTo(63.369, 55.038, 53.137, 57.038),
      RelioMarkQuadTo(42.905, 59.039, 34.149, 64.11),
      RelioMarkQuadTo(29.315, 66.908, 28.073, 67.899),
      RelioMarkQuadTo(26.831, 68.89, 26.2, 70.45),
      RelioMarkQuadTo(26.1, 70.4, 25.999, 70.349),
      RelioMarkQuadTo(25.898, 70.299, 25.795, 70.247),
      RelioMarkQuadTo(27.017, 67.793, 28.688, 65.734),
      RelioMarkQuadTo(30.359, 63.675, 32.281, 61.734),
      RelioMarkQuadTo(32.394, 61.617, 32.508, 61.499),
      RelioMarkQuadTo(32.621, 61.381, 32.738, 61.26),
      RelioMarkQuadTo(34.124, 59.813, 35.566, 58.456),
      RelioMarkQuadTo(37.009, 57.098, 38.622, 55.908),
      RelioMarkQuadTo(38.898, 55.705, 39.172, 55.5),
      RelioMarkQuadTo(39.447, 55.295, 39.72, 55.088),
      RelioMarkQuadTo(44.413, 51.544, 49.637, 49.087),
      RelioMarkQuadTo(54.861, 46.63, 60.657, 45.519),
      RelioMarkQuadTo(60.844, 45.482, 61.031, 45.444),
      RelioMarkQuadTo(61.219, 45.407, 61.411, 45.368),
      RelioMarkQuadTo(62.715, 45.159, 64.029, 45.098),
      RelioMarkQuadTo(65.342, 45.038, 66.662, 45.025),
      RelioMarkClose(),
    ],
    box: (left: 25.795, top: 44.983, right: 76.832, bottom: 70.45),
  );

  // --- Partie : page-lower -------------------------------------------

  /// La page inférieure, accent.
  static const RelioMarkPart pageLower =
      RelioMarkPart(
    id: 'page-lower',
    role: RelioMarkRole.accent,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(58.32, 59.456),
      RelioMarkQuadTo(58.452, 59.455, 58.585, 59.453),
      RelioMarkQuadTo(58.718, 59.452, 58.854, 59.45),
      RelioMarkQuadTo(70.402, 59.219, 73.6, 59.829),
      RelioMarkQuadTo(76.797, 60.439, 79.321, 63.355),
      RelioMarkQuadTo(79.75, 64.033, 80.106, 64.743),
      RelioMarkQuadTo(80.463, 65.452, 80.8, 66.181),
      RelioMarkQuadTo(80.878, 66.346, 80.957, 66.513),
      RelioMarkQuadTo(81.036, 66.679, 81.117, 66.85),
      RelioMarkQuadTo(81.33, 67.3, 81.542, 67.751),
      RelioMarkQuadTo(81.754, 68.202, 81.965, 68.654),
      RelioMarkQuadTo(82.099, 68.939, 82.234, 69.224),
      RelioMarkQuadTo(82.368, 69.509, 82.503, 69.795),
      RelioMarkQuadTo(83.13, 71.12, 83.749, 72.449),
      RelioMarkQuadTo(84.369, 73.779, 84.98, 75.112),
      RelioMarkQuadTo(85.057, 75.278, 85.134, 75.446),
      RelioMarkQuadTo(85.211, 75.614, 85.289, 75.785),
      RelioMarkQuadTo(85.493, 76.233, 85.695, 76.682),
      RelioMarkQuadTo(85.896, 77.132, 86.095, 77.582),
      RelioMarkQuadTo(86.154, 77.712, 86.214, 77.844),
      RelioMarkQuadTo(86.274, 77.976, 86.336, 78.11),
      RelioMarkQuadTo(86.387, 78.229, 86.439, 78.349),
      RelioMarkQuadTo(86.491, 78.469, 86.545, 78.591),
      RelioMarkQuadTo(86.59, 78.693, 86.636, 78.796),
      RelioMarkQuadTo(86.681, 78.899, 86.728, 79.005),
      RelioMarkQuadTo(86.735, 79.038, 86.747, 79.095),
      RelioMarkQuadTo(86.759, 79.152, 86.804, 79.368),
      RelioMarkQuadTo(86.704, 79.518, 86.603, 79.67),
      RelioMarkQuadTo(86.502, 79.821, 86.399, 79.976),
      RelioMarkQuadTo(85.878, 79.79, 85.441, 79.552),
      RelioMarkQuadTo(85.004, 79.314, 84.574, 78.967),
      RelioMarkQuadTo(84.462, 78.879, 84.35, 78.789),
      RelioMarkQuadTo(84.238, 78.7, 84.123, 78.608),
      RelioMarkQuadTo(84.006, 78.514, 83.888, 78.42),
      RelioMarkQuadTo(83.77, 78.325, 83.65, 78.228),
      RelioMarkQuadTo(82.595, 77.392, 81.517, 76.614),
      RelioMarkQuadTo(80.439, 75.836, 79.305, 75.112),
      RelioMarkQuadTo(79.144, 75.005, 78.982, 74.897),
      RelioMarkQuadTo(78.82, 74.79, 78.654, 74.68),
      RelioMarkQuadTo(77.238, 73.748, 75.776, 72.903),
      RelioMarkQuadTo(74.315, 72.057, 72.819, 71.26),
      RelioMarkQuadTo(72.721, 71.207, 72.622, 71.154),
      RelioMarkQuadTo(72.523, 71.101, 72.422, 71.046),
      RelioMarkQuadTo(68.385, 68.889, 64.045, 67.481),
      RelioMarkQuadTo(59.705, 66.072, 55.185, 65.382),
      RelioMarkQuadTo(55.086, 65.367, 54.987, 65.351),
      RelioMarkQuadTo(54.888, 65.335, 54.786, 65.319),
      RelioMarkQuadTo(51.578, 64.889, 48.171, 65.006),
      RelioMarkQuadTo(44.764, 65.122, 41.605, 65.788),
      RelioMarkQuadTo(41.459, 65.818, 41.311, 65.848),
      RelioMarkQuadTo(41.164, 65.879, 41.014, 65.91),
      RelioMarkQuadTo(38.042, 66.532, 35.167, 67.454),
      RelioMarkQuadTo(32.292, 68.377, 29.534, 69.652),
      RelioMarkQuadTo(29.412, 69.699, 29.288, 69.746),
      RelioMarkQuadTo(29.164, 69.793, 29.038, 69.842),
      RelioMarkQuadTo(28.938, 69.791, 28.837, 69.741),
      RelioMarkQuadTo(28.736, 69.691, 28.632, 69.639),
      RelioMarkQuadTo(35.173, 65.102, 42.74, 62.351),
      RelioMarkQuadTo(50.306, 59.6, 58.32, 59.456),
      RelioMarkClose(),
    ],
    box: (left: 28.632, top: 59.219, right: 86.804, bottom: 79.976),
  );

  // --- Partie : tassel -------------------------------------------

  /// Le gland du chapeau, accent : il ondule.
  static const RelioMarkPart tassel =
      RelioMarkPart(
    id: 'tassel',
    role: RelioMarkRole.accent,
    nodes: <RelioMarkNode>[
      RelioMarkMoveTo(74.643, 12.075),
      RelioMarkQuadTo(74.643, 12.178, 74.643, 12.281),
      RelioMarkQuadTo(74.644, 12.384, 74.644, 12.49),
      RelioMarkQuadTo(74.647, 13.56, 74.655, 14.631),
      RelioMarkQuadTo(74.662, 15.701, 74.674, 16.771),
      RelioMarkQuadTo(74.677, 17.17, 74.68, 17.57),
      RelioMarkQuadTo(74.682, 17.969, 74.683, 18.368),
      RelioMarkQuadTo(74.684, 18.943, 74.69, 19.517),
      RelioMarkQuadTo(74.695, 20.091, 74.702, 20.666),
      RelioMarkQuadTo(74.702, 20.844, 74.701, 21.023),
      RelioMarkQuadTo(74.701, 21.202, 74.7, 21.386),
      RelioMarkQuadTo(74.704, 22.689, 74.806, 23.092),
      RelioMarkQuadTo(74.907, 23.495, 75.349, 23.966),
      RelioMarkQuadTo(75.396, 24.009, 75.476, 24.083),
      RelioMarkQuadTo(75.555, 24.157, 75.859, 24.439),
      RelioMarkQuadTo(76.068, 24.861, 76.093, 25.226),
      RelioMarkQuadTo(76.117, 25.59, 76.062, 26.061),
      RelioMarkQuadTo(75.952, 26.195, 75.842, 26.331),
      RelioMarkQuadTo(75.731, 26.467, 75.618, 26.605),
      RelioMarkQuadTo(75.352, 27.074, 75.307, 27.25),
      RelioMarkQuadTo(75.262, 27.427, 75.329, 27.737),
      RelioMarkQuadTo(75.345, 27.786, 75.372, 27.869),
      RelioMarkQuadTo(75.398, 27.952, 75.499, 28.268),
      RelioMarkQuadTo(75.782, 29.229, 75.995, 30.199),
      RelioMarkQuadTo(76.208, 31.169, 76.391, 32.154),
      RelioMarkQuadTo(76.424, 32.322, 76.457, 32.491),
      RelioMarkQuadTo(76.49, 32.661, 76.524, 32.834),
      RelioMarkQuadTo(76.671, 33.598, 76.804, 34.365),
      RelioMarkQuadTo(76.937, 35.132, 77.042, 35.903),
      RelioMarkQuadTo(77.058, 36.019, 77.074, 36.136),
      RelioMarkQuadTo(77.091, 36.253, 77.107, 36.373),
      RelioMarkQuadTo(77.075, 36.788, 76.916, 37.053),
      RelioMarkQuadTo(76.757, 37.317, 76.467, 37.614),
      RelioMarkQuadTo(75.813, 37.824, 75.127, 37.841),
      RelioMarkQuadTo(74.441, 37.859, 73.756, 37.842),
      RelioMarkQuadTo(73.645, 37.843, 73.534, 37.843),
      RelioMarkQuadTo(73.422, 37.844, 73.308, 37.844),
      RelioMarkQuadTo(71.536, 37.861, 71.048, 37.762),
      RelioMarkQuadTo(70.56, 37.662, 70.184, 37.209),
      RelioMarkQuadTo(70.156, 35.773, 70.411, 34.344),
      RelioMarkQuadTo(70.665, 32.916, 70.982, 31.521),
      RelioMarkQuadTo(71.022, 31.325, 71.063, 31.127),
      RelioMarkQuadTo(71.103, 30.93, 71.145, 30.728),
      RelioMarkQuadTo(71.428, 29.34, 71.563, 28.895),
      RelioMarkQuadTo(71.698, 28.451, 72.008, 27.885),
      RelioMarkQuadTo(71.967, 27.545, 71.868, 27.278),
      RelioMarkQuadTo(71.77, 27.011, 71.59, 26.719),
      RelioMarkQuadTo(71.382, 26.208, 71.353, 25.696),
      RelioMarkQuadTo(71.324, 25.183, 71.4, 24.642),
      RelioMarkQuadTo(71.571, 24.227, 71.666, 24.069),
      RelioMarkQuadTo(71.761, 23.91, 72.008, 23.628),
      RelioMarkQuadTo(72.083, 23.61, 72.21, 23.578),
      RelioMarkQuadTo(72.336, 23.546, 72.819, 23.426),
      RelioMarkQuadTo(72.819, 20.72, 72.819, 17.994),
      RelioMarkQuadTo(72.819, 15.268, 72.819, 12.48),
      RelioMarkQuadTo(73.978, 12.189, 74.263, 12.126),
      RelioMarkQuadTo(74.548, 12.062, 74.643, 12.075),
      RelioMarkClose(),
    ],
    box: (left: 70.156, top: 12.062, right: 77.107, bottom: 37.861),
  );

  // --- Assemblage ----------------------------------------------------------

  /// Les traces du mark, dans l'ordre de dessin.
  static const List<RelioMarkPart> parts = <RelioMarkPart>[
    cap,
    stem,
    body,
    base,
    pageUpper,
    pageLower,
    tassel,
  ];

  // --- Boite englobante ---------------------------------------------------

  /// Boite englobante du mark entier, en coordonnees de grille.
  ///
  /// Le mark est remplit de traces pleines : il n'y a plus de trait dont le
  /// debord devrait etre ajoute. La boite se lit directement sur les boites
  /// des parties.
  static const ({double left, double top, double right, double bottom})
  boundingBox = (
    left: 6.224,
    top: 0.0,
    right: 93.776,
    bottom: 100.0,
  );

  /// Largeur REELLEMENT encree du mark, en unites de grille.
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

  /// Cote du mark dans la grille de 108 dp : 66 * 0.55 = 36,3 dp.
  static const double androidMarkSizeDp = androidSafeZoneDp * androidMarkFill;

  /// Largeur REELLE du mark dans la grille de 108 dp, en dp.
  static double get androidMarkWidthDp => androidMarkSizeDp;

  /// Hauteur correspondante du mark, en dp, deduite de son rapport de forme.
  static double get androidMarkHeightDp =>
      androidMarkWidthDp * inkHeight / inkWidth;

  // --- Icone applicative --------------------------------------------------

  /// Rayon des coins du fond de l'icone, en fraction du cote.
  ///
  /// Mesure sur l'icone livree (arc ~0,206) ; re-evalue avec elle si elle
  /// change.
  static const double iconCornerRadiusRatio = 0.206;

  /// Marge du fond de l'icone, en fraction du cote.
  ///
  /// Mesuree sur l'icone livree : carre de 1100 px sur 1254.
  static const double iconBackgroundInsetRatio = 0.061;
}
