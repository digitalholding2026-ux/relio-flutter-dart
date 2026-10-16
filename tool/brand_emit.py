"""Fige la geometrie candidate relue (tool/brand_geometry_new.dart.txt).

Ecrit lib/presentation/branding/relio_mark_geometry.dart et promeut
docs/brand/relio_app_icon.new.svg en specification.

A n'executer qu'apres relecture visuelle (tool/brand_preview.png) :
c'est l'equivalent mecanique de l'import initial de la regle 9.
"""
import os
import re
import sys

TXT = "tool/brand_geometry_new.dart.txt"
SPEC_NEW = "docs/brand/relio_app_icon.new.svg"
SPEC = "docs/brand/relio_app_icon.svg"
GEO = "lib/presentation/branding/relio_mark_geometry.dart"

DOCS = {
    "cap": "La planche du chapeau de diplômé, structure principale.",
    "stem": "Le fût vertical, structure principale.",
    "body": "La courbe du livre, structure principale.",
    "base": "Le balayage inférieur du livre, structure principale.",
    "page-upper": "La page supérieure, accent.",
    "page-lower": "La page inférieure, accent.",
    "tassel": "Le gland du chapeau, accent : il ondule.",
}

ORDER = ["cap", "stem", "body", "base", "page-upper", "page-lower", "tassel"]


def field(pid):
    return "".join(p if i == 0 else p.capitalize()
                   for i, p in enumerate(pid.split("-")))


def main():
    parts = {}
    cur = None
    box_of = {}
    with open(TXT, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"### (\S+) \((\w+)\) box=\(([^)]+)\)-\(([^)]+)\)", line)
            if m:
                cur = {"id": m.group(1), "role": m.group(2), "nodes": []}
                box_of[cur["id"]] = (m.group(3), m.group(4))
                parts[cur["id"]] = cur
                continue
            line = line.strip()
            if cur is not None and line.startswith("RelioMark"):
                cur["nodes"].append("      " + line)
    if [p for p in parts] != ORDER:
        print(f"ORDRE INATTENDU : {list(parts)}")
        return 1

    bl = min(float(box_of[p][0].split(",")[0]) for p in ORDER)
    bt = min(float(box_of[p][0].split(",")[1]) for p in ORDER)
    br = max(float(box_of[p][1].split(",")[0]) for p in ORDER)
    bb = max(float(box_of[p][1].split(",")[1]) for p in ORDER)

    def nx(v):
        q = round(float(v) * 1000) / 1000
        return f"{q:.1f}" if q == round(q) else str(q)

    with open(GEO, "w", encoding="utf-8", newline="") as f:
        f.write('''/// Geometrie pure du mark Relio — SOURCE DE VERITE.
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
/// library;

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

''')
        for pid in ORDER:
            p = parts[pid]
            left, top = box_of[pid][0].split(",")
            right, bottom = box_of[pid][1].split(",")
            f.write(f"  // --- Partie : {pid} "
                    "-------------------------------------------\n\n")
            f.write(f"  /// {DOCS[pid]}\n")
            f.write(f"  static const RelioMarkPart {field(pid)} =\n"
                    "      RelioMarkPart(\n"
                    f"    id: '{pid}',\n"
                    f"    role: RelioMarkRole.{p['role']},\n"
                    "    nodes: <RelioMarkNode>[\n")
            for n in p["nodes"]:
                f.write(n + "\n")
            f.write("    ],\n"
                    f"    box: (left: {nx(left)}, top: {nx(top)}, "
                    f"right: {nx(right)}, bottom: {nx(bottom)}),\n  );\n\n")
        f.write("""  // --- Assemblage ----------------------------------------------------------

  /// Les traces du mark, dans l'ordre de dessin.
  static const List<RelioMarkPart> parts = <RelioMarkPart>[
""")
        for pid in ORDER:
            f.write(f"    {field(pid)},\n")
        f.write("""  ];

  // --- Boite englobante ---------------------------------------------------

  /// Boite englobante du mark entier, en coordonnees de grille.
  ///
  /// Le mark est remplit de traces pleines : il n'y a plus de trait dont le
  /// debord devrait etre ajoute. La boite se lit directement sur les boites
  /// des parties.
  static const ({double left, double top, double right, double bottom})
  boundingBox = (
    left: %s,
    top: %s,
    right: %s,
    bottom: %s,
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
  /// Mesure sur l'icone livree ; re-evalue avec elle si elle change.
  static const double iconCornerRadiusRatio = 112 / 512;

  /// Marge du fond de l'icone, en fraction du cote.
  static const double iconBackgroundInsetRatio = 12 / 512;
}
""")
    # Boite englobante : valeurs injectees hors du gabarit (un % dans le
    # texte entrerait en conflit avec l'operateur de formatage).
    with open(GEO, encoding="utf-8") as f:
        content = f.read()
    content = content.replace("left: %s,", f"left: {nx(bl)},")
    content = content.replace("top: %s,", f"top: {nx(bt)},")
    content = content.replace("right: %s,", f"right: {nx(br)},")
    content = content.replace("bottom: %s,", f"bottom: {nx(bb)},")
    with open(GEO, "w", encoding="utf-8", newline="") as f:
        f.write(content)
    os.replace(SPEC_NEW, SPEC)
    print(f"OK : {GEO} + {SPEC}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
