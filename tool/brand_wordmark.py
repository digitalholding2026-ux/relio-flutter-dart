"""Import mecanique du wordmark « relio » (tracage + normalisation).

Lit docs/brand/source/logo-principal.jpg (zone x 700-1620, y 190-530),
trace chaque lettre au pixel avec vtracer, convertit en Q, normalise
dans une grille 100 propre au wordmark, et emet :
  - docs/brand/relio_logo_principal.new.svg (spec candidate)
  - tool/brand_wordmark_new.dart.txt (geometrie candidate)
  - tool/brand_wordmark_preview.png (controle visuel)

Les lettres r et e sont jointives mais separees : deux parties.
Le point du i rejoint sa lettre en second contour (comme l'ancien
contre du R). L'anneau du o porte son trou en second contour.
"""
import os
import re
import sys
import tempfile
from collections import deque

from PIL import Image, ImageDraw

import vtracer

SRC = "docs/brand/source/logo-principal.jpg"
X0, Y0, X1, Y1 = 700, 190, 1620, 530

# id, role, boite mesuree (coords logo).
EXPECTED = [
    ("word-r", "base", (730, 301, 868, 508)),
    ("word-e", "base", (866, 297, 1080, 512)),
    ("word-l", "base", (1093, 223, 1180, 512)),
    ("word-i", "base", (1189, 217, 1259, 508)),
    ("word-o", "accent", (1274, 294, 1501, 517)),
    ("word-odot", "accent", (1363, 380, 1412, 429)),
]

EXTRA = {
    # Le point du i rejoint sa lettre (second contour).
    "word-i": [(1189, 217, 1259, 287)],
}


def classify(px):
    r, g, b = px
    if r < 120 and g < 120 and b < 140 and (r + g + b) < 360:
        return 0
    if r > 150 and g < 200 and (r - b) > 80:
        return 1
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
                          "box": (min(xs) + X0, min(ys) + Y0,
                                  max(xs) + X0, max(ys) + Y0)})
    comps.sort(key=lambda c: -len(c["cells"]))
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


def trace_cells(cells, w, h, tmp, tag):
    mask = Image.new("L", (w, h), 255)
    mp = mask.load()
    for c in cells:
        mp[c % w, c // w] = 0
    src = os.path.join(tmp, f"{tag}.png")
    out = os.path.join(tmp, f"{tag}.svg")
    mask.save(src)
    vtracer.convert_image_to_svg_py(
        src, out, colormode="binary", mode="spline",
        filter_speckle=4, corner_threshold=60,
        length_threshold=4.0, splice_threshold=45,
        path_precision=5,
    )
    svg = open(out, encoding="utf-8").read()
    # vtracer emet un <path> par forme disjointe : on les prend tous,
    # chacun avec sa translation propre.
    out_d = []
    total_tx, total_ty = 0.0, 0.0
    for m in re.finditer(r'<path d="([^"]+)"[^>]*>', svg):
        tag = m.group(0)
        t = re.search(r'transform="translate\(([^,)]+),([^)]+)\)"', tag)
        tx, ty = (float(t.group(1)), float(t.group(2))) if t else (0.0, 0.0)
        out_d.append((m.group(1), tx, ty))
    if not out_d:
        raise RuntimeError(f"aucun chemin : {tag}")
    return out_d


def parse_d(d):
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
    mx = lambda a, b: ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    p01, p12, p23 = mx(p0, p1), mx(p1, p2), mx(p2, p3)
    p012, p123 = mx(p01, p12), mx(p12, p23)
    m = mx(p012, p123)

    def red(a, b, c, d):
        return ((-a[0] + 3 * b[0] + 3 * c[0] - d[0]) / 4,
                (-a[1] + 3 * b[1] + 3 * c[1] - d[1]) / 4)

    return [(p0, red(p0, p01, p012, m), m),
            (m, red(m, p123, p23, p3), p3)]


def to_nodes(subpaths):
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
    w, h = X1 - X0, Y1 - Y0
    cls = [-1] * (w * h)
    px = img.load()
    for y in range(h):
        for x in range(w):
            cls[y * w + x] = classify(px[X0 + x, Y0 + y])
    comps = label_components(cls, w, h)
    print(f"zone {w}x{h}, {len(comps)} composantes")

    assigned = {}
    for comp in comps:
        area = len(comp["cells"])
        if area < 800:
            continue
        best, best_iou = None, 0.0
        for pid, role, ebox in EXPECTED:
            v = iou(comp["box"], ebox)
            if v > best_iou:
                best, best_iou = pid, v
        print(f"  area={area} box={comp['box']} -> {best}({best_iou:.2f})")
        if best is not None and best_iou > 0.35:
            assigned.setdefault(best, []).append(comp)

    missing = [pid for pid, _, _ in EXPECTED if pid not in assigned]
    if missing:
        print(f"ÉCHEC : manquantes={missing}")
        return 1

    tmp = tempfile.mkdtemp(prefix="word")
    parts = []
    for pid, role, _ in EXPECTED:
        comp = max(assigned[pid], key=lambda c: len(c["cells"]))
        # Contours supplementaires (point du i) : meme trace, ajoutes.
        cells = list(comp["cells"])
        for (l, t, r, b) in EXTRA.get(pid, []):
            for y in range(t - Y0, b - Y0 + 1):
                for x in range(l - X0, r - X0 + 1):
                    i = y * w + x
                    if cls[i] == comp["kind"]:
                        cells.append(i)
        # Re-étiquette locale pour tracer l'union.
        subpaths = []
        for d, tx, ty in trace_cells(cells, w, h, tmp, pid.replace("-", "")):
            for s in parse_d(d):
                moved = []
                for seg in s:
                    if seg[0] == "M":
                        moved.append(("M", seg[1] + tx, seg[2] + ty))
                    elif seg[0] == "L":
                        moved.append(("L", seg[1] + tx, seg[2] + ty))
                    elif seg[0] == "Q":
                        moved.append(("Q", seg[1] + tx, seg[2] + ty,
                                      seg[3] + tx, seg[4] + ty))
                    elif seg[0] == "C":
                        moved.append(("C", seg[1] + tx, seg[2] + ty,
                                      seg[3] + tx, seg[4] + ty,
                                      seg[5] + tx, seg[6] + ty))
                    else:
                        moved.append(("Z",))
                subpaths.append(moved)
        nodes = to_nodes(subpaths)
        # Les translations vtracer sont deja appliquees ; on revient aux
        # coords logo en ajoutant l'origine de zone.
        nodes = [("M", n[1] + X0, n[2] + Y0) if n[0] == "M"
                 else ("L", n[1] + X0, n[2] + Y0) if n[0] == "L"
                 else ("Q", n[1] + X0, n[2] + Y0, n[3] + X0, n[4] + Y0)
                 if n[0] == "Q" else ("Z",) for n in nodes]
        n_c = sum(1 for n in nodes if n[0] == "Q")
        print(f"  {pid}: {len(nodes)} noeuds dont {n_c} Q")
        parts.append((pid, role, nodes))

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
                out.append(("M", fx(ox + (n[1] - l) * s),
                            fx(oy + (n[2] - t) * s)))
            elif n[0] == "L":
                out.append(("L", fx(ox + (n[1] - l) * s),
                            fx(oy + (n[2] - t) * s)))
            elif n[0] == "Q":
                out.append(("Q", fx(ox + (n[1] - l) * s),
                            fx(oy + (n[2] - t) * s),
                            fx(ox + (n[3] - l) * s),
                            fx(oy + (n[4] - t) * s)))
            else:
                out.append(("Z",))
        normed.append((pid, role, out))

    with open("docs/brand/relio_logo_principal.new.svg", "w",
              encoding="utf-8") as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" '
                'width="1200" height="360" viewBox="0 0 100 100">\n')
        f.write('  <title>Relio — logo principal (nouvelle marque, '
                'généré par tool/brand_wordmark.py)</title>\n')
        for pid, role, nodes in normed:
            fill = "#0E1821" if role == "base" else "#FE7904"
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
            f.write(f'" fill="{fill}" fill-rule="evenodd"/>\n')
        f.write('</svg>\n')

    with open("tool/brand_wordmark_new.dart.txt", "w",
              encoding="utf-8") as f:
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
            n_m = sum(1 for n in nodes if n[0] == "M")
            f.write(f"### {pid} ({role}) box=({nx(bl)},{nx(bt)})-"
                    f"({nx(br)},{nx(bb)}) contours={n_m} "
                    f"noeuds={len(nodes)}\n")
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

    # Controle visuel (remplissage even-odd : un contour contenu dans un
    # nombre impair d'autres contours est un trou).
    def dans_poly(pt, poly):
        x, y = pt
        dedans = False
        n = len(poly)
        for i in range(n):
            x1, y1 = poly[i]
            x2, y2 = poly[(i + 1) % n]
            if (y1 > y) != (y2 > y):
                xin = (x2 - x1) * (y - y1) / (y2 - y1) + x1
                if x < xin:
                    dedans = not dedans
        return dedans

    S = 2
    ren = Image.new("RGB", (100 * S, 100 * S), (254, 247, 229))
    dr = ImageDraw.Draw(ren)
    svg = open("docs/brand/relio_logo_principal.new.svg",
               encoding="utf-8").read()
    import re as _re
    for m in _re.finditer(r'<path id="[^"]+" d="([^"]+)" fill="([^"]+)"', svg):
        d, fill = m.group(1), m.group(2)
        polys, cur, pen = [], [], None
        for tm in _re.finditer(r"([MLQZ])([^MLQZ]*)", d):
            cmd, rest = tm.group(1), tm.group(2).strip()
            nums = [float(x) for x in rest.split()] if rest else []
            if cmd == "M":
                if cur:
                    polys.append(cur)
                cur = [(nums[0], nums[1])]
                pen = cur[0]
            elif cmd == "L":
                for i in range(0, len(nums) - 1, 2):
                    cur.append((nums[i], nums[i + 1]))
                    pen = cur[-1]
            elif cmd == "Q":
                for i in range(0, len(nums) - 3, 4):
                    cx, cy, x, y = nums[i:i + 4]
                    for k in range(1, 17):
                        tt = k / 16
                        mt = 1 - tt
                        cur.append((mt * mt * pen[0] + 2 * mt * tt * cx
                                    + tt * tt * x,
                                    mt * mt * pen[1] + 2 * mt * tt * cy
                                    + tt * tt * y))
                    pen = (x, y)
            elif cmd == "Z":
                if cur:
                    polys.append(cur)
                    cur = []
        if cur:
            polys.append(cur)
        for k, poly in enumerate(polys):
            profondeur = sum(1 for j, autre in enumerate(polys)
                             if j != k and dans_poly(poly[0], autre))
            couleur = fill if profondeur % 2 == 0 else (254, 247, 229)
            dr.polygon([(x * S, y * S) for x, y in poly], fill=couleur)
    ren.save("tool/brand_wordmark_preview.png")
    print("OK : spec + txt + preview wordmark")
    return 0


if __name__ == "__main__":
    sys.exit(main())
