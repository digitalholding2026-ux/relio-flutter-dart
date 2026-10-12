# Marque Relio — livrables

Logo de l'application. Ce dossier contient les fichiers **generes** : aucune
valeur n'y est ecrite a la main.

## Source de verite

| Fichier | Role |
|---|---|
| `lib/presentation/branding/relio_mark_geometry.dart` | Geometrie pure, en Dart seul |
| `lib/presentation/branding/relio_mark.dart` | Couleurs, `RelioMarkPainter`, `RelioWordmark` |
| `lib/presentation/branding/relio_lockup.dart` | Dispositions horizontale et verticale |

Le SVG et le rendu a l'ecran lisent **les memes constantes**. Les modifier a la
main dans un SVG serait les desynchroniser silencieusement : c'est
interdit.

## Regenerer

```bash
dart run tool/gen_branding.dart               # les SVG
flutter test tool/render_branding_test.dart   # les PNG (launcher, splash)
```

## Geometrie

Grille de reference 100 x 100, mark centre, axe y vers le bas.

| Element | Valeur |
|---|---|
| Cercle droit | O 28, centre (66, 50) |
| Cercle gauche | O 15,4, centre (24, 50) |
| Espacement des centres | 42 |
| Courbe — depart | (31,7, 50), bord droit du cercle gauche |
| Courbe — arrivee | (52, 50), bord gauche du cercle droit |
| Courbe — point bas | (41,85, 56) |
| Courbe — profondeur | 6 sous la ligne des centres |
| Courbe — portee | 20,3 (rapport 0,296 ~= 0,30) |
| Extremites | arrondies (`stroke-linecap: round`) |

La courbe est une cubique de Bezier unique, symetrique par construction. Les
points de controle sont derives : decalage vertical `6 / 0.75 = 8`, recul
horizontal `0.31` de la portee.

**Profondeur 6, et non 16.** A 16, la courbe devenait le sujet du mark ;
a 6, les deux cercles restent les points dominants et la courbe ne fait que
les relier. `test/branding/mark_geometry_test.dart` verrouille ce choix et
refuse un depassement de y = 58.

## Variante compacte

| Variante | Trait | Usage |
|---|---|---|
| Principale | 4 u | splash, en-tete, ecrans >= 48 dp |
| Compacte | 6,2 u | launcher, favicon, tout rendu <= 48 dp |

A 24 dp, le trait de 4 u ne fait que **0,96 px** et disparait. Ce n'est pas un
probleme de courbe mais un probleme de trait : on epaissit pour compenser la
perte de definition optique. Cercles et courbe sont **inchanges** — seul le
trait differe, ce que le test verifie explicitement.

Seuil de bascule : 48 dp.

## Launcher Android

Grille adaptative 108 dp, zone sure 66 dp.

Le mark occupe **55 % de la zone sure**, soit 36,3 dp. Il n'est donc pas centre
bord a bord dans la zone sure : il laisse de la respiration. C'est une
exception assumee a la regle des 14 unites, imposee par les masques de forme
des constructeurs. La regle des 14 unites reste valable partout ailleurs
(splash, en-tete, impression).

Quatre couches sont fournies par densite :

| Couche | Contenu |
|---|---|
| `ic_launcher.png` / `_round` | icone legacy, mark orange sur blanc |
| `ic_launcher_background` | aplat **blanc** plein |
| `ic_launcher_foreground` | mark orange seul, sur transparent |
| `ic_launcher_monochrome` | mark noir, pour les icones themees Android 13+ |

La couche monochrome ne porte **que** le mark : c'est la seule forme qui
survit a une teinte appliquee par le systeme.

La couche **background est blanche**, jamais orange. Un fond de la couleur du
mark le rend illisible, et le lanceur n'affiche qu'un carre orange uni — c'est
exactement le defaut que ce reglage corrige.

### Deux pieges de dimensionnement

L'icone est le seul rendu ou ces deux subtilites apparaissent. Elles sont
codees dans `RelioMarkGeometry` et verifiees par
`test/branding/launcher_icon_test.dart`.

**La boite englobante surestime l'encre de 8 %.** Les extremites gauche et
droite du mark ne sont *pas* definies par le debord du trait : elles le sont
par les **cercles pleins**. La capacite arrondie ne deborde qu'aux extremites
de la courbe, tres a l'interieur. Dimensionne sur la boite, l'icone sort trop
petite.

**L'encre n'est pas centree dans la boite.** En haut, le trait deborde au-dessus
du cercle ; en bas, la courbe descend seule. Le centre optique est donc 2,45 u
au-dessus du centre geometrique. Centre sur la boite, le mark parait descendu
dans le masque du lanceur.

## Contenu

```
mark/       mark-primary, -compact, et variantes mono noir/blanc
wordmark/   (la police est embarquee ; le mot est pose par l'application)
lockup/     lockup-horizontal, -vertical, et variantes mono
launcher/   presence-<taille>.png, sobre-<taille>.png, mark-<taille>.png,
            ios-1024.png, splash-<taille>.png, adaptive-*.png
render/     rendus de reference, pour comparaison
```

Tailles exportees : 1024, 512, 192, 96, 48, 24.

L'icone iOS fait 1024 px, sans transparence ni coins arrondis : l'OS les
applique lui-meme.

## Integration dans l'application

- **En-tete Accueil** : lockup horizontal (`RelioLockupHorizontal`).
- **Splash Android** : `drawable/launch_background.xml` et sa variante `v21`,
  qui centrent `splash_logo.png` sur fond blanc.

Duree du splash : celle du chargement reel. **Aucun delai artificiel** —
Android retire la fenetre des que Flutter dessine sa premiere frame.

## Couleurs

| Role | Valeur |
|---|---|
| Mark | `#F56207` |
| Wordmark | `#1F3A6E` |
| Mono noir | `#000000` |
| Mono blanc | `#FFFFFF` |

Le mark n'a **qu'une seule couleur** : ni degrade, ni ombre, ni contour, ni
transparence. Les SVG referencent la valeur hexadecimale exacte, jamais un nom.

`#F56207` et `#1F3A6E` sont deja les jetons `brand` et `primary` de
`RelioPalette` : la marque n'introduit aucune couleur nouvelle dans le theme.

## Verification

`test/branding/mark_geometry_test.dart` verrouille les valeurs de la
specification, relit les SVG generes et compare la geometrie au rendu Flutter.
Une derive entre le SVG et l'ecran fait echouer la suite.
