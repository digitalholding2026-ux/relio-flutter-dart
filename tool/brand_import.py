"""Import mecanique de la nouvelle marque Relio (etape mark).

Lit docs/brand/source/logo-principal.jpg, classifie les aplats
(navy / orange), trace chaque partie au pixel avec vtracer, convertit
les cubiques en quadratiques (vocabulaire M/L/Q/Z de la geometrie),
normalise dans la grille 100x100 EXACTEMENT comme brand_spec_test,
et emet :
  - docs/brand/relio_app_icon.new.svg (spec candidate, a relire)
  - tool/brand_geometry_new.dart.txt (geometrie candidate, a relire)

Rien n'est ecrase sans relecture. Aucun trace n'est dessine a la main :
les deux sorties viennent du meme pipeline, et brand_spec_test
(reecrit pour les nouvelles parties) rejouera la normalisation.
"""
import os
import re
import sys
import tempfile
from collections import deque

from PIL import Image

import vtracer

SRC = "docs/brand/source/logo-principal.jpg"
# Boite d'encre du mark mesuree (inventaire) + marge.
CROP = (270, 160, 716, 666)

NAVY_HEX = "#0E1821"
ORANGE_HEX = "#FE7904"

# Parties attendues : id, role, boite mesuree (coords logo), aire min.
EXPECTED = [
    ("cap", "base", (296, 167, 614, 284), 1500),
    ("stem", "base", (278, 276, 356, 590), 1500),
    ("body", "base", (374, 260, 567, 488), 1500),
    ("base", "base", (376, 502, 708, 658), 1500),
    ("page-upper", "accent", (374, 389, 625, 513), 800),
    ("page-lower", "accent", (388, 460, 674, 560), 800),
    ("tassel", "accent", (593, 226, 626, 352), 800),
]


def classify(px):
    r, g, b = px
    if r < 120 and g < 120 and b < 140 and (r + g + b) < 360:
        return 0  # navy (seuil doux : capte les franges anti-aliasées)
    if r > 150 and g < 200 and (r - b) > 80:
        return 1  # orange (idem)
    return -1


def label_components(cls, w, h):
    seen = bytearray(w * h)
    comps = []
    for y in range(h):
        for x in range(w):
            i = y * w + x
            if cls[i] < 0 or seen[i]:
                continue
            kind = cls[i]
            q = deque([i])
            seen[i] = 1
            cells = []
            while q:
                j = q.popleft()
                cells.append(j)
                jx = j % w
                jy = j // w
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = jx + dx, jy + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        k = ny * w + nx
                        if cls[k] == kind and not seen[k]:
                            seen[k] = 1
                            q.append(k)
            xs = [c % w for c in cells]
            ys = [c // w for c in cells]
            comps.append({"kind": kind, "cells": cells,
                          "box": (min(xs), min(ys), max(xs), max(ys))})
    return comps


def iou(a, b):
    l = max(a[0], b[0])
    t = max(a[1], b[1])
    r = min(a[2], b[2])
    b_ = min(a[3], b[3])
    if r <= l or b_ <= t:
        return 0.0
    inter = (r - l) * (b_ - t)
    union = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter
    return inter / union if union > 0 else 0.0


def trace_component(comp, w, h, tmp):
    mask = Image.new("L", (w, h), 255)
    mp = mask.load()
    for c in comp["cells"]:
        mp[c % w, c // w] = 0
    src = os.path.join(tmp, "mask.png")
    out = os.path.join(tmp, "trace.svg")
    mask.save(src)
    vtracer.convert_image_to_svg_py(
        src, out, colormode="binary", mode="spline",
        filter_speckle=4, corner_threshold=60,
        length_threshold=4.0, splice_threshold=45,
        path_precision=5,
    )
    with open(out, encoding="utf-8") as f:
        svg = f.read()
    m = re.search(r'<path d="([^"]+)"', svg)
    if not m:
        raise RuntimeError("aucun chemin trace")
    t = re.search(r'transform="translate\(([^,)]+),([^)]+)\)"', svg)
    tx, ty = (float(t.group(1)), float(t.group(2))) if t else (0.0, 0.0)
    return m.group(1), tx, ty


def parse_d(d):
    """-> liste de sous-chemins, chacun = liste de segments."""
    segs = []
    cur = []
    for m in re.finditer(r"([MLCQZ])([^MLCQZ]*)", d):
        cmd, rest = m.group(1), m.group(2).strip()
        nums = [float(s) for s in rest.split()] if rest else []
        if cmd == "M":
            if cur:
                segs.append(cur)
            cur = [("M", nums[0], nums[1])]
        elif cmd == "L":
            for i in range(0, len(nums) - 1, 2):
                cur.append(("L", nums[i], nums[i + 1]))
        elif cmd == "C":
            for i in range(0, len(nums) - 5, 6):
                cur.append(("C",) + tuple(nums[i:i + 6]))
        elif cmd == "Q":
            for i in range(0, len(nums) - 3, 4):
                cur.append(("Q",) + tuple(nums[i:i + 4]))
        elif cmd == "Z":
            cur.append(("Z",))
    if cur:
        segs.append(cur)
    return segs


def cubic_to_quad(p0, p1, p2, p3):
    """Un C -> 2 Q (de Casteljau a t=0.5 + reduction exacte au point milieu)."""
    mx = lambda a, b: ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    p01, p12, p23 = mx(p0, p1), mx(p1, p2), mx(p2, p3)
    p012, p123 = mx(p01, p12), mx(p12, p23)
    m = mx(p012, p123)

    def red(a, b, c, d):
        qx = (-a[0] + 3 * b[0] + 3 * c[0] - d[0]) / 4
        qy = (-a[1] + 3 * b[1] + 3 * c[1] - d[1]) / 4
        return (qx, qy)

    return [(p0, red(p0, p01, p012, m), m),
            (m, red(m, p123, p23, p3), p3)]


def to_nodes(subpaths):
    """Sous-chemins -> noeuds M/L/Q/Z (coords pixels du crop)."""
    nodes = []
    for sub in subpaths:
        pen = None
        for s in sub:
            if s[0] == "M":
                nodes.append(("M", s[1], s[2]))
                pen = (s[1], s[2])
            elif s[0] == "L":
                nodes.append(("L", s[1], s[2]))
                pen = (s[1], s[2])
            elif s[0] == "Q":
                nodes.append(("Q", s[1], s[2], s[3], s[4]))
                pen = (s[3], s[4])
            elif s[0] == "C":
                for a, q, b in cubic_to_quad(
                        pen, (s[1], s[2]), (s[3], s[4]), (s[5], s[6])):
                    nodes.append(("Q", q[0], q[1], b[0], b[1]))
                pen = (s[5], s[6])
            elif s[0] == "Z":
                nodes.append(("Z",))
    return nodes


def node_points(nodes):
    pts = []
    for n in nodes:
        if n[0] == "M":
            pts.append((n[1], n[2]))
        elif n[0] == "L":
            pts.append((n[1], n[2]))
        elif n[0] == "Q":
            pts.append((n[1], n[2]))
            pts.append((n[3], n[4]))
    return pts


def fx(v):
    return round(v * 1000) / 1000


def nx(v):
    q = fx(v)
    return f"{q:.1f}" if q == round(q) else str(q)


def main():
    img = Image.open(SRC).convert("RGB")
    x0, y0, x1, y1 = CROP
    w, h = x1 - x0, y1 - y0
    cls = [-1] * (w * h)
    for y in range(h):
        for x in range(w):
            cls[y * w + x] = classify(img.getpixel((x0 + x, y0 + y)))
    comps = label_components(cls, w, h)
    print(f"crop {w}x{h}, {len(comps)} composantes")

    # Assigne chaque composante >= seuil a une partie attendue (IoU).
    assigned = {}
    leftovers = []
    for comp in comps:
        l, t, r, b = comp["box"]
        glob = (l + x0, t + y0, r + x0, b + y0)
        area = len(comp["cells"])
        best, best_iou = None, 0.0
        for pid, role, ebox, amin in EXPECTED:
            v = iou(glob, ebox)
            if v > best_iou:
                best, best_iou = pid, v
        if best is not None and best_iou > 0.35 and area >= 300:
            assigned.setdefault(best, []).append(comp)
            tag = f"{best}({best_iou:.2f})"
        else:
            tag = "IGNORÉE" if area < 800 else "NON ASSIGNÉE"
            if area >= 800:
                leftovers.append((area, glob))
        print(f"  area={area} box={glob} -> {tag}")

    missing = [pid for pid, _, _, _ in EXPECTED if pid not in assigned]
    if missing or leftovers:
        print(f"ÉCHEC : manquantes={missing} restes={leftovers}")
        return 1
    for pid, lst in assigned.items():
        if len(lst) > 1:
            print(f"ÉCHEC : partie {pid} en {len(lst)} morceaux")
            return 1

    tmp = tempfile.mkdtemp(prefix="brand")
    parts = []
    for pid, role, _, _ in EXPECTED:
        comp = assigned[pid][0]
        d, tx, ty = trace_component(comp, w, h, tmp)
        nodes = to_nodes(parse_d(d))
        # Le traceur exprime ses coords dans son propre repere : on revient
        # aux pixels du crop avant toute autre operation.
        shifted = []
        for n in nodes:
            if n[0] == "M":
                shifted.append(("M", n[1] + tx, n[2] + ty))
            elif n[0] == "L":
                shifted.append(("L", n[1] + tx, n[2] + ty))
            elif n[0] == "Q":
                shifted.append(("Q", n[1] + tx, n[2] + ty,
                                n[3] + tx, n[4] + ty))
            else:
                shifted.append(("Z",))
        nodes = shifted
        n_c = sum(1 for n in nodes if n[0] == "Q")
        print(f"  {pid}: {len(nodes)} noeuds dont {n_c} Q")
        parts.append((pid, role, nodes))

    # Normalisation commune (meme math que brand_spec_test._importer).
    allpts = [p for _, _, n in parts for p in node_points(n)]
    l = min(p[0] for p in allpts)
    t = min(p[1] for p in allpts)
    r = max(p[0] for p in allpts)
    b = max(p[1] for p in allpts)
    W, H = r - l, b - t
    s = 100 / max(W, H)
    ox, oy = (100 - W * s) / 2, (100 - H * s) / 2
    print(f"bbox px: ({l:.1f},{t:.1f})-({r:.1f},{b:.1f}) s={s:.5f}")

    normed = []
    for pid, role, nodes in parts:
        out = []
        for n in nodes:
            if n[0] == "M":
                a = fx(ox + (n[1] - l) * s)
                ay = fx(oy + (n[2] - t) * s)
                out.append(("M", a, ay))
            elif n[0] == "L":
                a = fx(ox + (n[1] - l) * s)
                ay = fx(oy + (n[2] - t) * s)
                out.append(("L", a, ay))
            elif n[0] == "Q":
                a = fx(ox + (n[1] - l) * s)
                ay = fx(oy + (n[2] - t) * s)
                b_ = fx(ox + (n[3] - l) * s)
                by = fx(oy + (n[4] - t) * s)
                out.append(("Q", a, ay, b_, by))
            else:
                out.append(("Z",))
        normed.append((pid, role, out))

    # Spec SVG candidate (coords normalisees = grille 100).
    with open("docs/brand/relio_app_icon.new.svg", "w", encoding="utf-8") as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" '
                'width="512" height="512" viewBox="0 0 100 100">\n')
        f.write('  <title>Relio — icône d’application (nouvelle marque, '
                'générée par tool/brand_import.py)</title>\n')
        for pid, role, nodes in normed:
            f.write(f'  <path id="{pid}" d="')
            for n in nodes:
                if n[0] == "M":
                    f.write(f'M{n[1]} {n[2]}')
                elif n[0] == "L":
                    f.write(f'L{n[1]} {n[2]}')
                elif n[0] == "Q":
                    f.write(f'Q{n[1]} {n[2]} {n[3]} {n[4]}')
                else:
                    f.write('Z')
            fill = NAVY_HEX if role == "base" else ORANGE_HEX
            f.write(f'" fill="{fill}" fill-rule="evenodd"/>\n')
        f.write('</svg>\n')

    # Geometrie Dart candidate.
    with open("tool/brand_geometry_new.dart.txt", "w", encoding="utf-8") as f:
        for pid, role, nodes in normed:
            pts = []
            for n in nodes:
                if n[0] == "M":
                    pts.append((n[1], n[2]))
                elif n[0] == "L":
                    pts.append((n[1], n[2]))
                elif n[0] == "Q":
                    pts += [(n[1], n[2]), (n[3], n[4])]
            bl = min(p[0] for p in pts)
            bt = min(p[1] for p in pts)
            br = max(p[0] for p in pts)
            bb = max(p[1] for p in pts)
            f.write(f"### {pid} ({role}) box=({nx(bl)},{nx(bt)})-"
                    f"({nx(br)},{nx(bb)}) noeuds={len(nodes)}\n")
            for n in nodes:
                if n[0] == "M":
                    f.write(f"  RelioMarkMoveTo({nx(n[1])}, {nx(n[2])}),\n")
                elif n[0] == "L":
                    f.write(f"  RelioMarkLineTo({nx(n[1])}, {nx(n[2])}),\n")
                elif n[0] == "Q":
                    f.write(f"  RelioMarkQuadTo({nx(n[1])}, {nx(n[2])}, "
                            f"{nx(n[3])}, {nx(n[4])}),\n")
                else:
                    f.write("  RelioMarkClose(),\n")
    print("OK : docs/brand/relio_app_icon.new.svg + "
          "tool/brand_geometry_new.dart.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
