# Rapport — Nouvelle marque Relio

Date : 2026-10-16. Branche : `main`. Sources livrées :
`docs/brand/source/logo-principal.jpg`, `docs/brand/source/icon-app.jpg`.

## Ce qui a changé

Mark organique (chapeau, fût, livre, pages, gland), mot « relio » tracé
(« o »-repère ajouré), signature « Apprendre aujourd’hui, réussir
demain », navy `#0E1821`, orange `#FE7904`. Couleurs mesurées sur aplats
JPEG (mode des pixels pleins).

## Import mécanique (règle 9, aucune retouche manuelle)

- `tool/brand_import.py` — classification navy/orange, composantes
  connexes assignées par IoU aux 7 parties, traçage vtracer, C → 2 Q,
  normalisation 100 (même math que le test), spec + aperçu.
- `tool/brand_emit.py` — fige la géométrie relue + promeut la spec.
- `tool/brand_wordmark.py`, `tool/brand_word_emit.py` — idem pour les
  6 lettres (le point du `i` rejoint sa lettre ; `r` et `e` restent
  deux parties).
- `tool/brand_launcher.py` — PNG du lanceur depuis l'icône livrée
  (recadrage mesuré 1100 px, aplats classifiés, coins r = 0,206).
- `tool/brand_preview.py` — contrôle visuel (remplissage even-odd).

## Fichiers ajoutés

- `lib/presentation/branding/relio_wordmark_geometry.dart` — 6 lettres.
- `test/branding/wordmark_spec_test.dart` — rejeu d'import du mot (7 tests).
- `tool/brand_*.py` ci-dessus.
- `assets/branding/mark/wordmark-*.svg` (générés).

## Fichiers modifiés (marque)

- `relio_mark_geometry.dart` — 7 parties, boîte (6,224 ; 0) →
  (93,776 ; 100), encre 87,552 × 100 ; point supprimé ; coins 0,206,
  retrait 0,061.
- `relio_mark.dart` — couleurs, painter sans disque,
  `RelioWordmark` peint les tracés, `RelioSignature` nouveau texte,
  ratios 0,14 / 0,153, gaps 4,5, `wordmarkPressed #0A1219` (navy × 0,75).
- `relio_lockup.dart` — rapport mark/mot 1,637, mot à hauteur pleine.
- `relio_character.dart` — mêmes 3 mouvements, cibles remappées :
  le chapeau respire, les pages pulsent décalées, le gland ondule.
- `relio_theme.dart` — `primary #0E1821`, `primaryContainer #E7E8E9`,
  `brand #FE7904` (+ contraste `#060A10` / `#D4D6D9` / `#C45D03`).
- `gen_branding.dart`, `render_branding_test.dart` (lockup vertical
  en tracés), splash + références régénérés.
- `docs/brand/README.md`, `assets/branding/README.md`, `AGENTS.md`
  (règle 9, valeurs, 710 tests), `ic_launcher.xml` (commentaire).
- Launcher Android : 25 PNG legacy/adaptatifs/mono + splash, depuis
  l'icône livrée. `splash_logo.png` vectoriel régénéré.
- Tests marque réécrits : `brand_spec`, `mark_geometry`, `character`,
  `launcher_icon` (fonds orange, navy + blanc, mono noir).

## Décision structurante : lanceur depuis le JPG

Le mark vectoriel ne porte pas les pages blanches (sur le logo, les
intervalles sont le fond). Les PNG du lanceur viennent donc de l'icône
livrée ; le vectoriel sert l'in-app, le splash et les références.
`launcher_icon_test.dart` mesure les PNG produits.

## Vérifications exécutées

- `flutter analyze` : **No issues found!**
- `flutter test` : **710 tests, tous verts**, dont 88 marque
  (rejeux d'import mark + mot inclus).
- APK `app-release.apk` (22,4 Mo) publié sur `apk-build`.

## Découvertes hors périmètre

- Swoosh orange sous la signature : non repris en-app (même précédent
  que l'ancienne marque, qui ne le rendait pas).
- Signature composée en Inter (le visuel livre une autre fonte, non
  embarquée) ; wordmark en revanche intégralement tracé.
- Hexadécimaux mesurés au pixel JPEG (±1) : `#0E1821`, `#FE7904`.
- Coins de l'icône en supercercle (~0,206 retenu, écart-type 13 px).
- vtracer émet un `<path>` par forme : l'import les concatène
  (le point du `i` n'en avait qu'un sur deux au premier passage).
- `docs/RAPPORT_*.md` historiques non réécrits (décrivent d'anciens états).
