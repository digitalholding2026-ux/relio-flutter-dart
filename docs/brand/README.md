# Specification de marque — source

Ce dossier contient les fichiers de marque **livres et valides** (dans
`source/`) et les specifications **derivees par l'import mecanique**.
Ce ne sont pas des dessins a la main : ce sont les **entrees** du
generateur.

| Fichier | Role |
|---|---|
| `source/logo-principal.jpg` | logo principal livre : fait master du mark et du mot |
| `source/icon-app.jpg` | icone applicative livree : reference du lanceur |
| `relio_app_icon.svg` | mark seul, 7 traces — **fait master du mark**, derive par `tool/brand_import.py` |
| `relio_logo_principal.svg` | mot « relio » trace, 6 lettres — derive par `tool/brand_wordmark.py` |

## Le mark : sept parties

| Partie | Role | Contenu |
|---|---|---|
| `cap` | base | planche du chapeau de diplômé |
| `stem` | base | fût vertical |
| `body` | base | courbe du livre |
| `base` | base | balayage inférieur |
| `page-upper` | accent | page supérieure |
| `page-lower` | accent | page inférieure |
| `tassel` | accent | gland (il ondule) |

Le mot est trace lui aussi : `word-r`, `word-e`, `word-l`, `word-i`
(+ son point), `word-o` (anneau ajouré), `word-odot`.

## Couleurs

| Role | Valeur | Mesure |
|---|---|---|
| Navy (structure, mot) | `#0E1821` | aplat le plus frequent du logo livre |
| Orange (pages, gland, repère) | `#FE7904` | mode mesure sur les aplats |

## Pourquoi le lanceur vient du JPG

Le mark vectoriel ne porte pas les pages blanches du livre : sur le logo,
les intervalles entre les pages sont le fond. Sur l'icone applicative
(fond orange), ces intervalles sont des pages blanches. Les PNG du
lanceur (`android/.../mipmap-*/`) sont donc produits par
`tool/brand_launcher.py` depuis `source/icon-app.jpg` : recadrage mesure,
aplats classifies au pixel, coins arrondis geometriques. Aucune retouche.

## Ce que ces fichiers NE sont pas

Ils ne sont pas la source de verite du code. Les sources de verite sont
`lib/presentation/branding/relio_mark_geometry.dart` (le mark) et
`lib/presentation/branding/relio_wordmark_geometry.dart` (le mot) :

- les traces y sont normalisees dans des grilles de reference 100 x 100 ;
- le SVG, le PNG et le rendu a l'ecran sont generes a partir de ces fichiers ;
- la signature (« Apprendre aujourd’hui, réussir demain ») reste composee
  en Inter SemiBold 600, la police etant deja embarquee.

## Ce qui garantit la coherence

`test/branding/brand_spec_test.dart` (le mark) et
`test/branding/wordmark_spec_test.dart` (le mot) relisent les SVG,
reappliquent exactement la normalisation de l'import, et comparent le
resultat aux constantes de geometrie.

Concretement : **ajuster une coordonnee a la main dans la geometrie fait
echouer la suite.** La regle 9 devient opposable au lieu d'etre une
declaration.

Pour modifier la marque, dans l'ordre :

1. deposer le visuel livre dans `source/` ;
2. `python tool/brand_import.py` et/ou `python tool/brand_wordmark.py` ;
3. relire les apercus (`tool/brand_preview.png`, `tool/brand_wordmark_preview.png`) ;
4. `python tool/brand_emit.py` / `tool/brand_word_emit.py` ;
5. `dart run tool/gen_branding.dart` ;
6. `python tool/brand_launcher.py` (icone) ;
7. `flutter test tool/render_branding_test.dart` (splash + references) ;
8. `flutter analyze && flutter test`.
