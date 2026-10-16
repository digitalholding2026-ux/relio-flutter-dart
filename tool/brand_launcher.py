"""Pipeline de l'icone de lanceur depuis l'icone livree.

Lit docs/brand/source/icon-app.jpg (carre orange a coins arrondis,
contenu navy + pages blanches) et produit :
  - android/app/src/main/res/mipmap-*/ic_launcher.png (+_round)
  - android/.../mipmap-*/ic_launcher_{foreground,background,monochrome}.png
  - assets/branding/launcher/adaptive-{foreground,background,monochrome}-*.png

Regle 9 : aucune retouche. Le carre est recadre sur sa boite mesuree,
les calques sont des aplats classifies au pixel (navy / blanc / orange),
les coins arrondis viennent d'un masque geometrique. Les blancs sont les
pages du livre ; l'orange du mark se confond avec le fond, comme sur
l'icone livree.

launcher_icon_test.dart mesure les PNG produits.
"""
import os
import sys

from PIL import Image, ImageDraw

SRC = "docs/brand/source/icon-app.jpg"
RES = "android/app/src/main/res"
LAUNCHER = "assets/branding/launcher"

# Carre mesure sur l'icone livree (1254 px).
BOX = (77, 77, 1177, 1177)
SIDE = BOX[2] - BOX[0]

NAVY = (14, 24, 33)  # #0E1821
ORANGE = (254, 121, 4)  # #FE7904
WHITE = (255, 255, 255)

DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0,
             "xxhdpi": 3.0, "xxxhdpi": 4.0}


def classify(px):
    r, g, b = px
    if r < 120 and g < 120 and b < 140 and (r + g + b) < 360:
        return 0  # navy
    if r > 200 and g > 200 and b > 150 and (r - b) < 80:
        return 1  # blanc (pages ; l'orange est exclu par R-B)
    return -1  # orange / fond : transparent dans le premier plan


def rounded_mask(size, radius_ratio):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1],
                        radius=int(size * radius_ratio), fill=255)
    return m


def main():
    img = Image.open(SRC).convert("RGB")
    crop = img.crop(BOX)

    # Calque de contenu : aplats navy + blanc sur transparent, pleine
    # resolution, puis reechantillonne par densite (les bords restent doux).
    rgba = Image.new("RGBA", (SIDE, SIDE), (0, 0, 0, 0))
    src = crop.load()
    dst = rgba.load()
    for y in range(SIDE):
        for x in range(SIDE):
            c = classify(src[x, y])
            if c == 0:
                dst[x, y] = NAVY + (255,)
            elif c == 1:
                dst[x, y] = WHITE + (255,)

    # Masque du carre arrondi mesure (r = 0,206).
    square_mask = rounded_mask(SIDE, 0.206)

    for name, f in DENSITIES.items():
        # --- legacy 48 dp ------------------------------------------------
        leg = int(48 * f)
        base = crop.resize((leg, leg), Image.LANCZOS)
        base.putalpha(square_mask.resize((leg, leg), Image.LANCZOS))
        out = os.path.join(RES, f"mipmap-{name}", "ic_launcher.png")
        base.save(out)
        circ = Image.new("L", (leg, leg), 0)
        ImageDraw.Draw(circ).ellipse([0, 0, leg - 1, leg - 1], fill=255)
        rnd = crop.resize((leg, leg), Image.LANCZOS)
        rnd.putalpha(circ)
        rnd.save(os.path.join(RES, f"mipmap-{name}", "ic_launcher_round.png"))

        # --- adaptatif 108 dp -------------------------------------------
        grid = int(108 * f)
        fg = rgba.resize((grid, grid), Image.BILINEAR)
        # Les coins du premier plan sont transparents : le carre arrondi
        # laisse passer le fond, et les masques constructeur agissent.
        fg.putalpha(_min_alpha(
            fg.getchannel("A"),
            square_mask.resize((grid, grid), Image.BILINEAR)))
        fg.save(os.path.join(RES, f"mipmap-{name}",
                             "ic_launcher_foreground.png"))
        bg = Image.new("RGBA", (grid, grid), ORANGE + (255,))
        bg.save(os.path.join(RES, f"mipmap-{name}",
                             "ic_launcher_background.png"))
        mono = Image.new("RGBA", (grid, grid), (0, 0, 0, 0))
        mp = mono.load()
        fp = fg.load()
        for y in range(grid):
            for x in range(grid):
                if fp[x, y][3] > 128 and _is_navy_flat(fp[x, y]):
                    mp[x, y] = (0, 0, 0, 255)
        mono.save(os.path.join(RES, f"mipmap-{name}",
                               "ic_launcher_monochrome.png"))

        fg.save(os.path.join(LAUNCHER, f"adaptive-foreground-{name}.png"))
        bg.save(os.path.join(LAUNCHER, f"adaptive-background-{name}.png"))
        mono.save(os.path.join(LAUNCHER, f"adaptive-monochrome-{name}.png"))
        print(f"  {name}: legacy {leg}px, adaptatif {grid}px")
    print("OK : calques ecrits")
    return 0


def _min_alpha(a, b):
    out = Image.new("L", a.size, 0)
    pa, pb, po = a.load(), b.load(), out.load()
    for y in range(a.size[1]):
        for x in range(a.size[0]):
            v = pa[x, y]
            w = pb[x, y]
            po[x, y] = v if v < w else w
    return out


def _is_navy_flat(p):
    r, g, b, _ = p
    return r < 100 and g < 100 and b < 120 and (r + g + b) > 20


if __name__ == "__main__":
    sys.exit(main())
