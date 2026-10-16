"""Rendu de controle de la spec candidate (regle 9, verification visuelle).

Lit docs/brand/relio_app_icon.new.svg, aplati les Q en segments,
remplit les parties et sauve un cote-a-cote avec le crop d'origine :
tool/brand_preview.png (ne pas committer : simple controle).
"""
import re
import sys

from PIL import Image, ImageDraw

SPEC = "docs/brand/relio_app_icon.new.svg"
SRC = "docs/brand/source/logo-principal.jpg"
CROP = (270, 160, 716, 666)


def flatten(d, steps=24):
    pts = []
    holes = []
    cur = []
    pen = None
    toks = re.findall(r"([MLQZ])([^MLQZ]*)", d)
    for cmd, rest in toks:
        nums = [float(s) for s in rest.split()] if rest.strip() else []
        if cmd == "M":
            if cur:
                pts.append(cur)
            cur = [(nums[0], nums[1])]
            pen = cur[0]
        elif cmd == "L":
            for i in range(0, len(nums) - 1, 2):
                cur.append((nums[i], nums[i + 1]))
                pen = cur[-1]
        elif cmd == "Q":
            for i in range(0, len(nums) - 3, 4):
                cx, cy, x, y = nums[i:i + 4]
                for k in range(1, steps + 1):
                    t = k / steps
                    mt = 1 - t
                    px = mt * mt * pen[0] + 2 * mt * t * cx + t * t * x
                    py = mt * mt * pen[1] + 2 * mt * t * cy + t * t * y
                    cur.append((px, py))
                pen = (x, y)
        elif cmd == "Z":
            if cur:
                pts.append(cur)
                cur = []
    if cur:
        pts.append(cur)
    return pts


def main():
    svg = open(SPEC, encoding="utf-8").read()
    paths = re.findall(r'<path id="([^"]+)" d="([^"]+)" fill="([^"]+)"', svg)
    S = 3
    ren = Image.new("RGB", (100 * S, 100 * S), (238, 242, 250))
    dr = ImageDraw.Draw(ren)
    for pid, d, fill in paths:
        for poly in flatten(d):
            dr.polygon([(x * S, y * S) for x, y in poly], fill=fill)
    x0, y0, x1, y1 = CROP
    img = Image.open(SRC).convert("RGB").crop(CROP)
    w, h = img.size
    r = 300 / max(w, h)
    img = img.resize((int(w * r), int(h * r)))
    side = Image.new("RGB", (300 + 100 * S + 30, max(300, 100 * S) + 20),
                     (255, 255, 255))
    side.paste(img, (10, 10))
    side.paste(ren, (320, 10))
    side.save("tool/brand_preview.png")
    print(f"OK : {len(paths)} parties, tool/brand_preview.png")


if __name__ == "__main__":
    sys.exit(main())
