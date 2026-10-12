"""Génère les poids d'Inter en sous-ensemble latin + latin étendu.

Sources : Inter variable romain et italique (SIL OFL 1.1).
Sorties : quatre poids droits + un italique, `wght` épinglé.

Pourquoi l'italique est un fichier séparé : les fichiers Google Fonts
d'Inter portent les axes `opsz` et `wght` seulement — il n'existe PAS d'axe
`ital`. L'italique est une famille à part, aux contours déjà inclinés. Le
produire comme fichier distinct garantit un VRAI italique : sans lui, les
variables seraient rendues en oblique SIMULÉ par le moteur de rendu.

Sous-ensemble : latin de base (U+0000-007F) + latin étendu. Ni cyrillique,
ni grec, ni symboles étendus.
"""

from pathlib import Path
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

# Latin de base + Latin-1 (ACCENTS FRANÇAIS : é è à ç ô î û É À Ç) +
# latin étendu A et B.
#
# Attention : les accents ne sont PAS dans U+0000-U+007F. « é » est U+00E9,
# donc dans le supplément Latin-1. Omettre cette plage revient à supprimer
# tous les accents du texte français.
UNICODES = list(range(0x0000, 0x0100))
UNICODES += list(range(0x0100, 0x0180))
UNICODES += [0x0192, 0x01CD]
UNICODES += list(range(0x01F0, 0x0200))
UNICODES += [0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D]
UNICODES += [0x2022, 0x2026, 0x2039, 0x203A, 0x00A0, 0x2212, 0x00D7, 0x00F7]

POIDS_DROITS = {
    "Regular": 400,
    "Medium": 500,
    "SemiBold": 600,
    "Bold": 700,
}


def traiter(source: Path, sortie: Path, wght: int) -> int:
    police = TTFont(str(source))

    # 1. Épingler le poids, conserver l'axe opsz.
    instancer.instantiateVariableFont(
        police,
        {"wght": wght},
        inplace=True,
        updateFontNames=True,
    )

    # 2. Correctif nécessaire : après l'épinglage, certains glyphes
    #    conservés n'ont aucune variation (espace…). Le sous-ensembleur
    #    indexe alors `gvar` sans défaut et lève une KeyError. On pré-remplit
    #    les entrées manquantes d'une variation vide — leur état réel.
    if "gvar" in police:
        variations = police["gvar"].variations
        for glyphe in police.getGlyphOrder():
            if glyphe not in variations:
                variations[glyphe] = {}

    # 3. Sous-ensemble latin + latin étendu.
    #
    # `layout_features` est RESTREINT de propos. Avec `*`, on embarque les
    # alternates contextuelles cyrilliques et toutes les tables de mise en
    # forme : le sous-ensemble pese alors plus du double du budget. Seules
    # les fonctions utiles au texte latin sont conservées.
    #
    # `glyph_names = False` supprime la table `post`, qui ne sert qu'au
    # débogage : gain important, aucun effet sur le rendu.
    options = subset.Options()
    options.layout_features = [
        "ccmp", "kern", "liga", "calt", "locl", "mark", "mkmk", "rlig",
    ]
    options.glyph_names = False
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6]
    options.notdef_outline = True
    options.recalc_bounds = True
    options.hinting = False
    options.drop_tables += ["DSIG"]

    sous = subset.Subsetter(options=options)
    sous.populate(unicodes=UNICODES)
    sous.subset(police)

    # 4. Contrôle : plus aucune table de variation ne doit subsister, les
    #    poids étant épinglés.
    if "fvar" in police:
        axes = [a.axisTag for a in police["fvar"].axes]
        if len(axes) > 1:
            print(
                f"ECHEC {sortie.name}: axes encore variables {axes}",
                file=sys.stderr,
            )
            sys.exit(1)
        axes = axes[0]
    else:
        axes = "aucun"

    police.save(str(sortie))
    taille = sortie.stat().st_size
    print(f"{sortie.name:28s} wght={wght} axe={axes} {taille/1024:6.1f} Ko")
    return taille


if __name__ == "__main__":
    destination = Path(r"C:\Users\Docker\Desktop\Relio\assets\fonts")
    total = 0

    for nom, wght in POIDS_DROITS.items():
        total += traiter(
            Path(r"C:\dev\dl\Inter.ttf"),
            destination / f"Inter-{nom}.ttf",
            wght,
        )

    total += traiter(
        Path(r"C:\dev\dl\InterItalic.ttf"),
        destination / "Inter-Italic-Regular.ttf",
        400,
    )

    print(f"{'TOTAL':28s} {total/1024:6.1f} Ko")

