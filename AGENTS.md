# AGENTS.md — Règles de travail sur Relio

Ce fichier s'applique à tout agent (ou personne) travaillant sur ce dépôt.
Il décrit les **règles obligatoires** à respecter.

---

## Règle 1 — Toujours livrer un APK installable

> **Après toute modification du code, produire un build APK et en
> communiquer le chemin exact.**

L'utilisateur ne dispose pas d'émulateur ni d'appareil connecté à
l'environnement de développement : **la seule façon pour lui de voir le
résultat est d'installer un APK sur son téléphone Android.**

### Ce qu'il faut faire

1. Vérifier que rien n'est cassé :

   ```bash
   flutter analyze          # doit finir par "No issues found!"
   flutter test             # doit finir par "All tests passed!"
   ```

2. Produire l'APK :

   ```bash
   flutter build apk --release --target-platform android-arm64
   ```

3. **Communiquer le chemin absolu et la taille du fichier**, par exemple :

   ```
   C:\Users\Docker\Desktop\Relio\build\app\outputs\flutter-apk\app-release.apk  (20,3 Mo)
   ```

4. Rappeler les conditions d'installation :
   - Android 7.0 (API 24) minimum ;
   - autoriser « sources inconnues » pour l'installation manuelle ;
   - le fichier est signé avec la clé de **debug** (acceptable pour un
     test local, à remplacer avant toute publication).

### Pourquoi cette règle existe

Une modification qui n'est pas compilée n'est pas vérifiable par
l'utilisateur. Livrer du code non buildé, c'est livrer quelque chose dont
personne ne peut constater le bon fonctionnement.

### Variante debug

Pour un diagnostic plus rapide (compilation ~2 min au lieu de ~3 min) :

```bash
flutter build apk --debug
```

Mais le fichier debug est **volumineux** (~150 Mo). Le release, plus léger,
est préféré pour l'installation sur téléphone.

---

## Règle 2 — Publier l'APK sur `apk-build` (automatique)

> **À la fin de tout travail, publier l'APK sur la branche `apk-build`.**
>
> Cette publication est **autorisée d'office**, sans demande explicite de
> l'utilisateur, et **ne doit jamais être retardée** en attendant une
> confirmation. C'est la seule action `git push` que l'agent effectue de
> sa propre initiative.

Cette publication ne dispense pas de la règle 1 : le build reste obligatoire
avant publication. En résumé, à la fin de chaque tâche : build → tests verts →
publication sur `apk-build` → retour sur `main`.

### Répartition des rôles

| Branche | Contenu | Usage |
|---|---|---|
| `main` | Code source uniquement | Développement, tests, documentation |
| `apk-build` | Binaire(s) APK + `apk/README.md` | Distribution et téléchargement |

**`main` ne doit JAMAIS contenir de fichier `.apk` ou `.aab`.** Le code et
les binaires sont séparés pour que l'historique de `main` reste lisible et
léger.

### Ce qu'il faut faire

1. Se placer sur `apk-build` :

   ```bash
   git checkout apk-build
   ```

2. Y copier l'APK sous un nom **versionné**, dans `apk/` :

   ```bash
   Copy-Item build\app\outputs\flutter-apk\app-release.apk apk\relio-socle-v0.1.0.apk -Force
   ```

   Convention de nom : `relio-socle-v<version>.apk`, où `<version>` reprend
   la version de `pubspec.yaml`.

3. **Forcer l'ajout**, car `.gitignore` exclut `*.apk` par défaut :

   ```bash
   git add -f apk/relio-socle-v0.1.0.apk
   ```

4. Mettre à jour `apk/README.md` si nécessaire (taille, prérequis).

5. Commiter et pousser :

   ```bash
   git commit -m "APK de distribution v<version>"
   git push origin apk-build
   ```

6. Revenir sur `main` pour poursuivre le développement :

   ```bash
   git checkout main
   ```

### Pourquoi cette règle existe

L'utilisateur récupère l'application **depuis GitHub**, pas depuis la
machine de développement. Sans cette étape, le code est poussé mais
l'installable n'est pas disponible : l'utilisateur ne peut rien tester.

### À savoir

- Chaque build ajoute ~20 Mo à `apk-build`. Cette branche est une branche de
  **distribution**, pas de développement : ne jamais y coder.
- Si le volume devient gênant, la solution propre est une **GitHub Release**
  (les binaires n'entrent alors pas dans l historic git). Elle nécessite le
  CLI GitHub (`winget install GitHub.cli`), absent de la machine actuelle.
- Ne pas supprimer les anciens APK sans demande explicite : l'utilisateur
  peut être en train d'en télécharger un.

---

## Règle 3 — Android est la seule cible

Relio est une application **Android**. Le web n'est pas supporté et n'a pas
été conservé.

La visualisation se fait **uniquement via un APK installé sur le téléphone**
(voir règle 1). Ne pas proposer de solution web, et ne pas réintroduire de
dossier `web/` ou de dépendance WebAssembly : cela a été tenté puis abandonné
car la persistance SQLite via `WasmDatabase` n'aboutit pas à un rendu
fonctionnel dans cet environnement.

---

## Règle 4 — Le socle pédagogique reste vide

Aucune notion, aucun exercice, aucune règle de maîtrise ne doit être
inventé sans validation explicite. Les champs descriptionnels restent vides
par défaut.

Ce qui est **autorisé** : structure, stockage, migrations, tests, interface
technique.

---

## Règle 5 — Pas de champ de maîtrise

Le stockage contient uniquement des **faits observables** (dates, réponses,
résultats, erreurs constatées, indices, contexte).

Interdits dans le modèle et le schéma :
`maitrise`, `score`, `niveau`, `progression`, `moyenne`, ou tout champ
équivalent. Ces règles relèvent d'une mission dédiée.

---

## Règle 6 — Toute évolution de schéma est testée

1. Incrémenter `kSchemaVersion` dans `lib/data/db/app_database.dart`.
2. Ajouter l'étape de migration explicite dans `_runUpgradeSteps`.
3. Ajouter un test dans `test/migration_test.dart` qui vérifie la
   **préservation des données**.

Interdit : supprimer ou réécrire un événement d'apprentissage lors d'une
migration.

---

## Règle 7 — Qui commite et pousse quoi

Deux périmètres nettement séparés. Ne pas les confondre.

| Action | Autorisation |
|---|---|
| Commit de **code source** sur `main` | ⛔ Sur demande explicite uniquement |
| Commit + push de l'**APK** sur `apk-build` | ✅ **Automatique, en fin de travail** (règle 2) |
| Suppression d'un APK déjà publié | ⛔ Sur demande explicite |

### Le code ne bouge pas sans demande

`main` est sous le contrôle de l'utilisateur : **ne jamais commiter ni
pousser le code source** sans qu'il l'ait demandé.

### L'APK, si, se publie tout seul

C'est l'**exception unique et permanente**. À la fin de chaque tâche, une fois
`flutter analyze` et `flutter test` verts et l'APK construit :

1. commiter et pousser l'APK sur `apk-build` **sans attendre de confirmation** ;
2. revenir sur `main`.

Ne pas demander « dois-je pousser l'APK ? ». La question est déjà tranchée.

### Versionner l'APK

`versionCode` doit **progresser à chaque build** (le `+N` de `pubspec.yaml`).
Android refuse d'installer un APK dont le `versionCode` est égal ou inférieur
à celui déjà installé : sans incrément, l'APK paraîtrait ne pas s'installer
et donnerait l'impression que la correction n'a pas été appliquée.

---

## Règle 8 — Le contenu pédagogique vient d'un document validé

> **Ne jamais inventer un énoncé, une réponse attendue, une intervention ou
> une règle de diagnostic.**

Les contenus pédagogiques sont transcrits d'un document validé par le
responsable pédagogique, présent dans le dépôt
(`relio_chapitre1_banque_exercices_diagnostic_v1.md` pour le chapitre 1).

Si ce document est absent, **demander qu'il soit ajouté** plutôt que de le
reconstituer de mémoire : un contenu inventé pollue définitivement
l'historique d'apprentissage, qui est append-only par conception.

Une valeur mathématique ajoutée (tâche de vérification, réponse attendue) doit
être **vérifiée arithmétiquement** et couverte par un test.

---

## Règle 9 — La marque est générée, pas dessinée

> **Aucun SVG, PNG ou widget de la marque ne s'édite à la main.**

La géométrie du mark vit dans **un seul fichier** :

```
lib/presentation/branding/relio_mark_geometry.dart
```

Le mark y est décrit comme une suite de **traces pleines** (`M`, `L`, `Q`,
`Z`) et un disque. C'est le vocabulaire du SVG : le générateur restitue ces
commandes telles quelles, et `RelioMarkPainter` les traduit en `Path`. Les
deux lisent donc **la même définition**, et non deux reconstitutions d'une
même intention.

### Origine : une spécification versionnée

Les traces viennent de `docs/brand/`, où sont versionnés les deux SVG livrés
et validés. `test/branding/brand_spec_test.dart` **rejoue l'import** depuis
ces fichiers et échoue dès que les constantes ont dérivé.

> Une retouche manuelle de `relio_mark_geometry.dart` fait donc échouer la
> suite. C'est ce qui rend cette règle opposable plutôt que déclarative.

Le mark n'est paramétrique en rien : ni cercle, ni courbe, ni épaisseur de
trait — il est plein, donc rien ne s'efface quand la taille diminue. Les
valeurs sont figées **tant que la spécification de `docs/brand/` ne change
pas**.

### Ce qu'il faut faire après toute retouche de la marque

1. Modifier **uniquement** `relio_mark_geometry.dart`.
2. Régénérer :

   ```bash
   dart run tool/gen_branding.dart               # SVG
   flutter test tool/render_branding_test.dart   # PNG launcher et splash
   ```

3. Vérifier :

   ```bash
   flutter analyze
   flutter test test/branding
   ```

### Pourquoi cette règle existe

Un SVG retouché à la main dérive du painter, ou l'inverse. Les deux
décrivent alors deux marques différentes : l'impression ne correspond plus à
l'écran, et rien ne le signale. `brand_spec_test.dart` échoue dès que la
géométrie s'écarte de la spécification.

### Valeurs figées

Ne pas les ajuster sans remonter le constat. Les rapports ci-dessous ont été
vérifiés un par un ; une correction doit être motivée, pas discrète.

| Élément | Valeur |
|---|---|
| Grille de référence | 100 × 100, mark centré |
| Encre du mark | 91,194 × 100 — **plus haut que large** |
| « R » | (9,748 ; 0) → (83,019 ; 96,541), ajouré, `evenOdd` |
| Zigzag d'accent | (4,403 ; 60,692) → (59,748 ; 100) |
| Second zigzag | (48,428 ; 33,019) → (95,597 ; 69,497) |
| Point | centre (89,308 ; 8,805), rayon 6,289 |
| Launcher adaptatif | grille 108 dp, zone sûre 66 dp, mark à 55 % = 36,3 dp |
| Icône applicative | coins r = 112/512, fond en retrait de 12/512 |
| Rapport mark / mot | 1,93 |
| Signature | corps 31/176 du mot, écartement 0,37 |
| Couleurs | accent `#F56207`, base `#1F3A6E` |

Le mark porte **deux couleurs** : la structure en indigo, l'accent en orange.
La déclinaison dépend du fond — sur fond indigo, la structure passe en blanc.

---

## Règle 10 — L'écran d'entrée est une spécification temporelle figée

> **La séquence dure 5,3 secondes. Jamais plus.**

La chronologie de l'écran d'entrée (première ouverture) est **figée** :

| Temps | Ce qui se passe |
|---|---|
| 0 s | Le personnage apparaît : fondu + scale 0,9 → 1,0, sur 300 ms |
| 1,5 s | « Salut. Je suis Relio. » — fondu 250 ms |
| 3 s | « Je t'accompagne en maths, à ton rythme. » |
| 5 s | « On commence ? » — le personnage se redresse |
| 5,3 s | Bouton « Commencer » — fondu + glissement de 8 dp |

### Ce qu'il ne faut PAS faire

- **Allonger la séquence** pour compenser un appareil lent. La mission 2
  l'interdit explicitement. Sur un appareil lent, la sequence doit **sauter des
  étapes** — c'est ce que fait le tap d'accélération — pas durer plus longtemps.
- **Ajouter un mouvement** au personnage. Il y en a exactement trois :
  le « R » respire, le point pulse décalé, le zigzag d'accent ondule.
  Un mouvement qui ne se décrit pas en une phrase simple est un mouvement de
  trop.
- **Donner un visage, des membres ou une couleur au personnage.** Le
  personnage *est* le mark : le « R », deux zigzags et un point, structure
  indigo et accent orange.

### Le tap n'accélère qu'avant le bouton

Un tap n'importe où saute vers le bouton **tant que la séquence n'est pas
terminée**. Une fois le bouton visible, le tap ne fait strictement rien, et le
bouton n'est **pas** dans l'arbre avant 5,3 s : il ne doit jamais être
atteignable au toucher trop tôt.

### Tests

```bash
flutter test test/presentation/intro_sequence_test.dart    # chronologie
flutter test test/presentation/intro_page_test.dart        # comportement
flutter test test/branding/relio_character_test.dart       # rétention
flutter test test/presentation/intro_accessibility_test.dart
```

La chronologie est testée **sans rendu** : `IntroSequenceState.at(durée)` est
une fonction pure. Tester la sequence via `pumpAndSettle` serait lent et
fragile — l'animation du personnage ne se stabilise jamais.

> `RelioApp` prend `showIntro: false` dans les tests d'interface. Sans ce
> drapeau, chaque test d'ecran attendrait 5,3 s et `pumpAndSettle`
> expirerait, puisque l'animation du personnage tourne en boucle.

---

## État du dépôt

| Élément | Valeur |
|---|---|
| Application ID | `com.relio.relio` |
| minSdk | 24 (Android 7.0) |
| Flutter | 3.47.7 |
| NDK requis | 28.2.13676358 |
| Persistance | Drift / SQLite, schéma v2 |
| Marque | `assets/branding/` — spécification dans `docs/brand/`, voir [règle 9](#règle-9--la-marque-est-générée-pas-dessinée) |
| Tests | 708 (622 applicatifs + 86 marque) |
| Écran d'entrée | 5,3 s, première ouverture uniquement — voir règle 10 |

### Branches

| Branche | Rôle | Poussée |
|---|---|---|
| `main` | Code source, tests, documentation | Sur demande explicite |
| `apk-build` | APK de distribution dans `apk/` | **Automatique en fin de travail** (règle 2) |

### Récupérer l'APK depuis GitHub

<https://github.com/digitalholding2026-ux/relio-flutter-dart/tree/apk-build/apk>

Détail complet dans `docs/ARCHITECTURE.md` et `docs/BUILD.md`.


