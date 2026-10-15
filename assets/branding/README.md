# Marque Relio — livrables

Logo de l'application. Ce dossier contient les fichiers **generes** : aucune
valeur n'y est ecrite a la main.

## Source de verite

| Fichier | Role |
|---|---|
| `lib/presentation/branding/relio_mark_geometry.dart` | Traces du mark, en Dart seul |
| `lib/presentation/branding/relio_mark.dart` | Couleurs, `RelioMarkPainter`, `RelioWordmark`, `RelioSignature` |
| `lib/presentation/branding/relio_lockup.dart` | Dispositions horizontale et verticale |

La geometrie est decrite comme une suite de **traces remplies** (`M`, `L`,
`Q`, `Z`) et un disque — le vocabulaire du SVG. Le generateur restitue ces
commandes telles quelles, et le painter Flutter les traduit en `Path`. Le SVG
et le rendu a l'ecran lisent donc **la meme definition**, et non deux
reconstitutions d'une meme intention.

## Origine des valeurs

Les traces viennent de la specification livree, versionnee dans
[`docs/brand/`](../docs/brand/README.md). `test/branding/brand_spec_test.dart`
rejoue l'import depuis ces fichiers et **echoue des que les constantes ont
derive**. Une retouche manuelle de la geometrie ne peut pas passer.

## Regenerer

```bash
dart run tool/gen_branding.dart               # les SVG
flutter test tool/render_branding_test.dart   # les PNG (launcher, splash)
```

## Geometrie

Grille de reference 100 x 100, mark centre, axe y vers le bas. Encre de
91,194 x 100 unites.

| Partie | Role | Boite englobante |
|---|---|---|
| `glyph` — le « R » | base | (9,748 ; 0) → (83,019 ; 96,541) |
| `zigzag-accent` | accent | (4,403 ; 60,692) → (59,748 ; 100) |
| `zigzag-secondary` | base | (48,428 ; 33,019) → (95,597 ; 69,497) |
| `dot` — disque | accent | centre (89,308 ; 8,805), r = 6,289 |

Le « R » est **ajoure** : son contre est un second contour, pas un trou
booleen. Tous les remplissages sont donc en `evenOdd`.

Il n'y a **plus de trait ni de variante compacte** : le mark est plein, donc
rien ne s'efface quand la taille diminue. Une seule geometrie sert du splash
a l'icone de 24 px.

## Declinaisons chromatiques

Le mark porte deux couleurs. La declinaison depend du fond, pas du mark seul.

| Variante | Base | Accent | Usage |
|---|---|---|---|
| `onLight` | indigo | orange | splash, en-tete, ecrans clairs |
| `onIndigo` | blanc | orange | icone applicative |
| `monoBlack` | noir | noir | impression sur fond clair |
| `monoWhite` | blanc | blanc | impression sur fond sombre |

## Wordmark et signature

Le mot **« Relio »** et la signature **« Les maths, c'est ton terrain ! »**
sont poses par l'application en Inter SemiBold 600. Les glyphes ne sont pas
embarques dans les SVG : la police l'est deja.

| Rapport | Valeur | Origine |
|---|---|---|
| Hauteur du mark / hauteur de capitale du mot | 1,93 | logo de reference |
| Hauteur de capitale de la signature / celle du mot | 31/176 | corps 176 et 31 |
| Ecartement mot ↔ signature | 0,37 | ligne de base du mot a y = 218 |

## Launcher Android

Grille adaptative 108 dp, zone sure 66 dp. Le mark occupe **55 % de la zone
sure**, soit 36,3 dp de large et 39,8 dp de haut : il n'est pas carre, et le
traiter comme tel le ferait deborder en hauteur.

| Couche | Contenu |
|---|---|
| `ic_launcher.png` / `_round` | icone legacy : fond indigo, mark en declinaison claire |
| `ic_launcher_background` | aplat **indigo** plein |
| `ic_launcher_foreground` | mark blanc et orange, sur transparent |
| `ic_launcher_monochrome` | mark noir, pour les icones themees Android 13+ |

Le fond est l'**indigo** de la marque, pas l'orange de l'accent : un fond de
la couleur d'une des parties du mark la rendrait illisible. La couche
monochrome ne porte que le mark, en noir : c'est la seule forme qui survit a
une teinte appliquee par le systeme.

### Icone applicative

`icon/relio-app-icon.svg` est **genere** lui aussi : fond a coins arrondis
(r = 112/512) en retrait de 12/512, mark centre. Le fond ne se peint pas a la
main, sinon il deriverait du mark.

## Contenu

```
mark/       mark-primary, mark-inverse, et variantes mono noir/blanc
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
| Accent (zigzag, point) | `#F56207` |
| Base (« R », second zigzag, mot, signature) | `#1F3A6E` |
| Fond d'icone et de splash sombre | `#1F3A6E` |
| Mono noir | `#000000` |
| Mono blanc | `#FFFFFF` |

Aucune couleur n'est un degrade, une ombre ou une transparence. Les SVG
referencent la valeur hexadecimale exacte, jamais un nom.

`#F56207` et `#1F3A6E` sont deja les jetons `brand` et `primary` de
`RelioPalette` : la marque n'introduit aucune couleur nouvelle dans le theme.

## Verification

| Test | Ce qu'il verrouille |
|---|---|
| `mark_geometry_test.dart` | structure, boites, declinaisons, SVG, coherence generateur / couche Flutter |
| `brand_spec_test.dart` | la geometrie n'a pas derive de la specification livree |
| `launcher_icon_test.dart` | pixels reels des PNG du lanceur, mesures |
| `relio_character_test.dart` | les trois mouvements, et leur nombre |