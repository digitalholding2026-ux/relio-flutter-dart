"""Fige la geometrie candidate du wordmark relue.

Ecrit lib/presentation/branding/relio_wordmark_geometry.dart et promeut
docs/brand/relio_logo_principal.new.svg en specification.

Vocabulaire partage avec le mark (M/L/Q/Z) : le generateur et le painter
lisent la meme definition.
"""
import os
import re
import sys

TXT = "tool/brand_wordmark_new.dart.txt"
SPEC_NEW = "docs/brand/relio_logo_principal.new.svg"
SPEC = "docs/brand/relio_logo_principal.svg"
GEO = "lib/presentation/branding/relio_wordmark_geometry.dart"

DOCS = {
    "word-r": "Le « r », en navy.",
    "word-e": "Le « e » (chasse jointe au r), en navy.",
    "word-l": "Le « l », en navy.",
    "word-i": "Le « i » et son point, en navy.",
    "word-o": "Le « o »-repère, anneau orange ajouré.",
    "word-odot": "Le point central du « o », en orange.",
}

ORDER = ["word-r", "word-e", "word-l", "word-i", "word-o", "word-odot"]


def field(pid):
    return "".join(p if i == 0 else p.capitalize()
                   for i, p in enumerate(pid.split("-")))


def nx(v):
    q = round(float(v) * 1000) / 1000
    return f"{q:.1f}" if q == round(q) else str(q)


def main():
    parts = {}
    box_of = {}
    cur = None
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

    with open(GEO, "w", encoding="utf-8", newline="") as f:
        f.write('''/// Geometrie pure du wordmark « relio » — SOURCE DE VERITE.
///
/// Meme vocabulaire que le mark (M/L/Q/Z, grille 100x100) : le generateur
/// SVG et le painter Flutter lisent la meme definition. Les lettres sont
/// tracees, pas composees en fonte : le « o »-repère n'existe dans aucune
/// fonte embarquee.
///
/// Origine des valeurs : specification `docs/brand/relio_logo_principal.svg`,
/// livree et validee (import mecanique tool/brand_wordmark.py).
/// La grille est PROPRE au wordmark : mark et mot se dimensionnent l'un
/// par l'autre via le rapport mesure `kMarkToWordmarkRatio`.
library;

import 'relio_mark_geometry.dart';

/// Geometrie du wordmark « relio ».
abstract final class RelioWordmarkGeometry {
  // --- Grille -------------------------------------------------------------

  /// Cote de la grille de reference, en unites.
  static const double grid = 100;

''')
        for pid in ORDER:
            p = parts[pid]
            left, top = box_of[pid][0].split(",")
            right, bottom = box_of[pid][1].split(",")
            f.write(f"  // --- Lettre : {pid} "
                    "---------------------------------------------\n\n")
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

  /// Les lettres du mot, dans l'ordre de lecture.
  static const List<RelioMarkPart> parts = <RelioMarkPart>[
""")
        for pid in ORDER:
            f.write(f"    {field(pid)},\n")
        f.write("  ];\n\n")
        f.write("  // --- Boite englobante -----------------------------------"
                "----------------\n\n")
        f.write("  /// Boite englobante du mot entier, en coordonnees de grille.\n")
        f.write("  static const ({double left, double top, double right, "
                "double bottom})\n  wordBox = (\n")
        f.write(f"    left: {nx(bl)},\n")
        f.write(f"    top: {nx(bt)},\n")
        f.write(f"    right: {nx(br)},\n")
        f.write(f"    bottom: {nx(bb)},\n")
        f.write("  );\n\n")
        f.write("""  /// Largeur REELLEMENT encree du mot, en unites de grille.
  static double get inkWidth => wordBox.right - wordBox.left;

  /// Hauteur REELLEMENT encree du mot, en unites de grille.
  static double get inkHeight => wordBox.bottom - wordBox.top;
}
""")
    os.replace(SPEC_NEW, SPEC)
    print(f"OK : {GEO} + {SPEC}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
