# Marque Relio — livrables

Logo de l'application. Ce dossier contient les fichiers **generes** : aucune
valeur n'y est ecrite a la main.

## Source de verite

| Fichier | Role |
|---|---|
| `lib/presentation/branding/relio_mark_geometry.dart` | Traces du mark, en Dart seul |
| `lib/presentation/branding/relio_wordmark_geometry.dart` | Lettres tracees du mot, en Dart seul |
| `lib/presentation/branding/relio_mark.dart` | Couleurs, painters, `RelioSignature` |
| `lib/presentation/branding/relio_lockup.dart` | Dispositions horizontale et verticale |

La geometrie est decrite comme une suite de **traces remplies** (`M`, `L`,
`Q`, `Z`) — le vocabulaire du SVG. Le generateur restitue ces
commandes telles quelles, et les painters Flutter les traduisent en `Path`.
Le SVG et le rendu a l'ecran lisent donc **la meme definition**, et non deux
reconstitutions d'une meme intention.

## Origine des valeurs

Les traces viennent des visuels livres, versionnes dans
[`docs/brand/`](../docs/brand/README.md), via l'import mecanique
(`tool/brand_import.py`, `tool/brand_wordmark.py`). `test/branding/brand_spec_test.dart`
et `test/branding/wordmark_spec_test.dart` rejouent l'import depuis ces
fichiers et **echouent des que les constantes ont derive**. Une retouche
manuelle de la geometrie ne peut pas passer.

## Regenerer

```bash
dart run tool/gen_branding.dart               # les SVG
python tool/brand_launcher.py                 # les PNG du lanceur (icone livree)
flutter test tool/render_branding_test.dart   # les PNG (references, splash)
```

## Geometrie

Grille de reference 100 x 100, mark centre, axe y vers le bas. Encre de
87,552 x 100 unites.

| Partie | Role | Boite englobante |
|---|---|---|
| `cap` — planche du chapeau | base | (9,985 ; 0) → (74,643 ; 24,142) |
| `stem` — fût | base | (6,224 ; 22,1) → (22,443 ; 86,057) |
| `body` — courbe du livre | base | (25,795 ; 18,948) → (65,425 ; 65,382) |
| `base` — balayage | base | (26,2 ; 67,936) → (93,776 ; 100) |
| `page-upper` | accent | (25,795 ; 44,983) → (76,832 ; 70,45) |
| `page-lower` | accent | (28,632 ; 59,219) → (86,804 ; 79,976) |
| `tassel` — gland | accent | (70,156 ; 12,062) → (77,107 ; 37,861) |

Le mot « relio » est trace lui aussi, dans sa propre grille 100 x 100
(100 x 39,036 utiles) : `word-r`, `word-e`, `word-l`, `word-i` (+ son
point), `word-o` (anneau ajoure), `word-odot`.

Il n'y a **ni trait ni variante compacte** : le mark est plein, donc
rien ne s'efface quand la taille diminue. Une seule geometrie sert du splash
a l'icone de 24 px.

## Declinaisons chromatiques

Le mark porte deux couleurs. La declinaison depend du fond, pas du mark seul.

| Variante | Base | Accent | Usage |
|---|---|---|---|
| `onLight` | navy | orange | splash, en-tete, ecrans clairs |
| `onIndigo` | blanc | orange | fonds navy |
| `monoBlack` | noir | noir | impression sur fond clair |
| `monoWhite` | blanc | blanc | impression sur fond sombre |

## Wordmark et signature

Le mot **« relio »** est trace (lettres ci-dessus) : le « o »-repère
n'existe dans aucune fonte. La signature **« Apprendre aujourd’hui,
réussir demain »** est posee par l'application en Inter SemiBold 600.

| Rapport | Valeur | Origine |
|---|---|---|
| Hauteur du mark / hauteur du mot | 1,637 | mark 491 px, mot 300 px (logo livre) |
| Hauteur de la signature / hauteur du mot | 0,14 | capitale du « A » : 42 px |
| Ecartement mot ↔ signature | 0,153 | 46 px pour un mot de 300 px |
| Ecartement mark ↔ mot | 4,5 | 22 px pour un mark de 491 px |

## Launcher Android

L'icone livree est un carre orange a coins arrondis portant le mark
complet (navy + pages blanches). Les PNG du lanceur viennent d'elle,
via `tool/brand_launcher.py` : recadrage mesure (carre 1100 px sur 1254,
coins r = 0,206), aplats classifies au pixel, aucune retouche.

| Couche | Contenu |
|---|---|
| `ic_launcher.png` / `_round` | icone legacy : carre orange, mark navy + pages blanches |
| `ic_launcher_background` | aplat **orange** plein |
| `ic_launcher_foreground` | structure navy + pages blanches, sur transparent |
| `ic_launcher_monochrome` | mark noir, pour les icones themees Android 13+ |

Le fond est l'**orange** de la marque. La couche monochrome ne porte que le
mark, en noir : c'est la seule forme qui survit a une teinte appliquee par
le systeme.

### Icone applicative

`icon/relio-app-icon.svg` est **genere** lui aussi : fond orange a coins
arrondis (r = 0,206) en retrait de 0,061, structure navy centree. Les
parties orange s'y confondent avec le fond, comme sur l'icone livree. Le
fond ne se peint pas a la main, sinon il deriverait du mark.

## Contenu

```
mark/       mark-primary, mark-inverse, et variantes mono noir/blanc ;
            wordmark-primary, wordmark-inverse, et variantes mono
icon/       relio-app-icon.svg, apercu plat de l'icone applicative
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
- **Ecran d'entree** : personnage anime (`RelioCharacter`), mark sur fond clair.
- **Splash Android** : `drawable/launch_background.xml` et sa variante `v21`,
  qui centrent `splash_logo.png` sur fond blanc.

Duree du splash : celle du chargement reel. **Aucun delai artificiel** —
Android retire la fenetre des que Flutter dessine sa premiere frame.

## Couleurs

| Role | Valeur |
|---|---|
| Accent (pages, gland, repère) | `#FE7904` |
| Base (chapeau, fût, courbe, balayage, mot, signature) | `#0E1821` |
| Fond d'icone | `#FE7904` |
| Mono noir | `#000000` |
| Mono blanc | `#FFFFFF` |

Aucune couleur n'est un degrade, une ombre ou une transparence. Les SVG
referencent la valeur hexadecimale exacte, jamais un nom.

`#FE7904` et `#0E1821` sont deja les jetons `brand` et `primary` de
`RelioPalette` : la marque n'introduit aucune couleur nouvelle dans le theme.

## Verification

| Test | Ce qu'il verrouille |
|---|---|
| `mark_geometry_test.dart` | structure, boites, declinaisons, SVG, coherence generateur / couche Flutter |
| `brand_spec_test.dart` | la geometrie du mark n'a pas derive de la specification livree |
| `wordmark_spec_test.dart` | la geometrie du mot n'a pas derive de la specification livree |
| `launcher_icon_test.dart` | pixels reels des PNG du lanceur, mesures |
| `relio_character_test.dart` | les trois mouvements, et leur nombre |