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

## Règle 2 — Publier l'APK en GitHub Release (automatique)

> **À la fin de tout travail, publier l'APK dans une GitHub Release.**
>
> Cette publication est **obligatoire et automatique**, sans demande explicite
> de l'utilisateur, et **ne doit jamais être retardée** en attendant une
> confirmation. Elle fait partie de la séquence de fin de travail décrite
> dans la **règle 7** (commit → push → Release).

Cette publication ne dispense pas de la règle 1 : le build reste obligatoire
avant publication. En résumé, à la fin de chaque tâche : tests verts →
commit → push → Release → retour sur `main`.

### Pourquoi une Release et non une branche

> **Un binaire ne doit JAMAIS entrer dans l'historique git.**

`apk-build` a porté les APK jusqu'à 23 fichiers, soit **plus de 500 Mo**
d'historique git : chaque `git clone` les retélécharge, chaque commit de
binaire est définitif. C'est le défaut classique du stockage de binaires dans
un dépôt de code.

Une **GitHub Release** résout le problème : le binaire est téléchargeable par
son URL, versionné par un tag, et **n'entre dans aucun historique**. Le dépôt
reste léger et rapide à cloner.

**La branche `apk-build` n'est donc plus un lieu de stockage de binaires.**
Elle ne conserve que `apk/README.md`, qui pointe vers les Releases.

### Ce qu'il faut faire

1. Vérifier la version dans `pubspec.yaml`, puis **incrémenter le
   `versionCode`** (règle 7) :

   ```yaml
   version: 0.4.2+18   # -> 0.4.2+19 au prochain build
   ```

2. Copier l'APK sous un nom **versionné**, hors du dépôt suivi :

   ```powershell
   Copy-Item build\app\outputs\flutter-apk\app-release.apk `
             $env:TEMP\relio-socle-v0.4.2-19.apk -Force
   ```

   Convention : `relio-socle-v<versionName>-v<versionCode>.apk`. **Le nom de
   fichier est obligatoire** : `gh release create` dérive le nom du fichier
   source, et `app-release.apk` écraserait le précédent.

3. Publier la Release (le tag reprend le `versionCode`) :

   ```powershell
   gh release create "apk-v0.4.2-19" $env:TEMP\relio-socle-v0.4.2-19.apk `
     --title "APK v0.4.2+19 — <titre du travail>" `
     --notes-file $env:TEMP\notes.md
   ```

4. Vérifier que l'actif est bien nommé et télégeable :

   ```powershell
   gh release view apk-v0.4.2-19 --json assets
   ```

5. Si un actif s'est mal nommé, le supprimer et le téléverser à nouveau sous
   le bon nom :

   ```powershell
   gh api repos/digitalholding2026-ux/relio-flutter-dart/releases/assets/<id> -X DELETE
   gh release upload apk-v0.4.2-19 $env:TEMP\relio-socle-v0.4.2-19.apk --clobber
   ```

6. Ne rien commiter : les binaires ne vont pas dans le dépôt.

### Pourquoi cette règle existe

L'utilisateur récupère l'application **depuis GitHub**, pas depuis la machine
de développement. Sans cette étape, le code est poussé mais l'installable
n'est pas disponible : l'utilisateur ne peut rien tester.

### À savoir

- Le CLI GitHub (`gh`, compte `digitalholding2026-ux`) doit être **installé et
  authentifié**. Si `gh auth status` échoue, tenter `gh auth login` une fois ;
  si l'authentification n'aboutit toujours pas, **le signaler** plutôt que de
  publier autrement.
- **Ne jamais commiter d'APK**, ni sur `main`, ni sur `apk-build`. Les seuls
  APK déjà dans l'historique sont ceux de `apk-build` avant la bascule ; ils
  y restent, on ne réécrit pas l'historique.
- Ne pas supprimer une Release existante sans demande explicite : l'utilisateur
  peut être en train de la télécharger.
- Le tag `apk-v<versionName>-v<versionCode>` est la référence de livraison.
  Deux builds de même `versionName` restent donc distinguables.

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

## Règle 7 — Terminer chaque travail par un commit, un push et une Release

> **Aucun travail ne reste sur la machine. À la fin de chaque tâche, le code
> est commité, poussé sur `main`, et l'APK publié en Release — sans attendre de
> confirmation.**

Cette règle remplace la règle antérieure « le code ne bouge pas sans demande ».
Elle existe parce que du travail non poussé est du travail perdu : il
n'apparaît dans aucun historique, il ne survit ni à une réinstallation ni à un
changement de machine, et personne — y compris l'utilisateur — ne peut le voir.

| Action | Autorisation |
|---|---|
| Commit du **code source** sur `main` | ✅ **Automatique, en fin de travail** |
| `git push origin main` | ✅ **Automatique, en fin de travail** |
| Publication de l'**APK** en GitHub Release | ✅ **Automatique, en fin de travail** (règle 2) |
| Commit d'un **binaire** (`.apk`, `.aab`) | ⛔ **Interdit**, sur toute branche (règle 2) |
| Suppression d'une **Release** existante | ⛔ Sur demande explicite |

### La séquence de fin de travail

À exécuter **dans cet ordre**, sans demander l'autorisation :

1. `flutter analyze` → doit finir par `No issues found!` ;
2. `flutter test` → doit finir par `All tests passed!` ;
3. incrémenter le `versionCode` dans `pubspec.yaml` (voir plus bas) ;
4. `flutter build apk --release --target-platform android-arm64` ;
5. `git add -A` puis `git commit` avec un message qui décrit le travail ;
6. `git push origin main` ;
7. publier l'APK en **Release** (règle 2) ;
8. vérifier que `git status` est propre et que `main` est à jour, puis que
   l'actif de la Release est bien nommé et téléchargeable ;
9. rendre compte à l'utilisateur : commit, branche, URL de la Release, chemin
   local de l'APK.

Si une étape échoue, ne pas s'arrêter en silence : corriger, et si le blocage
persiste, le signaler **avec** l'état exact (`git status`, message d'erreur).

### Un travail documentaire se pousse aussi

Une modification de documentation, de règle ou de configuration ne produit pas
d'APK — le dernier APK publié reste la référence de livraison. Elle se termine
tout de même par les étapes 5, 6 et 9 : **commit + push**. La règle 1 (build)
ne s'applique qu'aux modifications de code. En cas de doute, produire l'APK :
un build superflu coûte quelques minutes, un livrable manquant coûte le travail.

### Ne pas commiter n'importe quoi

- **Jamais de binaire** : ni `.apk`, ni `.aab`, ni `build/` (règle 2).
- Ne pas commiter `android/local.properties`, `.dart_tool/`, ni un fichier
  généré déjà ignoré par `.gitignore`.
- Ne pas réécrire l'historique (`git push --force`) sur `main`.

### Pourquoi le commit compte autant que la Release

La Release rend l'application installable ; le commit rend le **code**
retrouvable. Les deux sont nécessaires : une Release sans commit est un
binaire orphelin, un commit sans Release est une correction que l'utilisateur
ne peut pas tester.

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

et celle du mot trace dans son pendant :

```
lib/presentation/branding/relio_wordmark_geometry.dart
```

Le mark y est décrit comme une suite de **traces pleines** (`M`, `L`, `Q`,
`Z`). C'est le vocabulaire du SVG : le générateur restitue ces
commandes telles quelles, et `RelioMarkPainter` / `RelioWordmarkPainter` les
traduisent en `Path`. Les deux lisent donc **la même définition**, et non
deux reconstitutions d'une même intention.

### Origine : une spécification versionnée

Les traces viennent de `docs/brand/`, où sont versionnés les visuels livrés
(`source/`) et les SVG dérivés par l'import mécanique
(`tool/brand_import.py`, `tool/brand_wordmark.py`).
`test/branding/brand_spec_test.dart` et
`test/branding/wordmark_spec_test.dart` **rejouent l'import** depuis
ces fichiers et échouent dès que les constantes ont dérivé.

> Une retouche manuelle de la géométrie fait donc échouer la
> suite. C'est ce qui rend cette règle opposable plutôt que déclarative.

Le mark n'est paramétrique en rien : ni cercle, ni courbe, ni épaisseur de
trait — il est plein, donc rien ne s'efface quand la taille diminue. Les
valeurs sont figées **tant que la spécification de `docs/brand/` ne change
pas**.

### Ce qu'il faut faire après toute retouche de la marque

1. Déposer le visuel livré dans `docs/brand/source/`.
2. Importer mécaniquement (`tool/brand_import.py`, `tool/brand_wordmark.py`),
   relire les aperçus, figer (`tool/brand_emit.py`, `tool/brand_word_emit.py`).
3. Régénérer :

   ```bash
   dart run tool/gen_branding.dart               # SVG
   python tool/brand_launcher.py                 # PNG du lanceur (icône livrée)
   flutter test tool/render_branding_test.dart   # PNG références et splash
   ```

4. Vérifier :

   ```bash
   flutter analyze
   flutter test test/branding
   ```

### Pourquoi cette règle existe

Un SVG retouché à la main dérive du painter, ou l'inverse. Les deux
décrivent alors deux marques différentes : l'impression ne correspond plus à
l'écran, et rien ne le signale. Les tests de spec échouent dès que la
géométrie s'écarte de la spécification.

### Valeurs figées

Ne pas les ajuster sans remonter le constat. Les rapports ci-dessous ont été
vérifiés un par un ; une correction doit être motivée, pas discrète.

| Élément | Valeur |
|---|---|
| Grille de référence | 100 × 100, mark centré |
| Encre du mark | 87,552 × 100 — **plus haut que large** |
| Chapeau | (9,985 ; 0) → (74,643 ; 24,142) |
| Fût | (6,224 ; 22,1) → (22,443 ; 86,057) |
| Courbe du livre | (25,795 ; 18,948) → (65,425 ; 65,382) |
| Balayage | (26,2 ; 67,936) → (93,776 ; 100) |
| Page supérieure | (25,795 ; 44,983) → (76,832 ; 70,45) |
| Page inférieure | (28,632 ; 59,219) → (86,804 ; 79,976) |
| Gland | (70,156 ; 12,062) → (77,107 ; 37,861), ondule de ±2 |
| Mot « relio » | trace pleine, 100 × 39,036 utiles ; « o » ajouré, `evenOdd` |
| Launcher | icône livrée (`docs/brand/source/icon-app.jpg`), coins r = 0,206, retrait 0,061 |
| Rapport mark / mot | 1,637 |
| Signature | « Apprendre aujourd’hui, réussir demain », corps 0,14 du mot, écartement 0,153 |
| Couleurs | accent `#FE7904`, base `#0E1821` |

Le mark porte **deux couleurs** : la structure en navy, l'accent en orange.
La déclinaison dépend du fond — sur fond navy, la structure passe en blanc.
Les pages blanches du lanceur viennent de l'icône livrée, pas de la
géométrie : sur le logo, les intervalles sont le fond.

---

## Règle 10 — L'ouverture montre la marque, elle n'attend pas

> **Aucun bouton sur l'ouverture. Aucune attente artificielle.**

> Cette règle remplace une contrainte antérieure qui figeait une séquence de
> 5,3 s avec un bouton « Commencer ». Elle est **abolie** : la mission
> « expérience d'entrée » a substitué à l'ouverture une **révélation du logo**
> suivie de deux écrans qui portent chacun leur propre texte et leur propre
> bouton. La règle ci-dessous décrit ce qui existe désormais.

L'ouverture est le **premier** écran, et le seul qui n'ait rien à demander :

| Temps | Ce qui se passe |
|---|---|
| 0 ms | Le logo apparaît : fondu 320 ms |
| 80 → 540 ms | Il se pose : échelle 0,94 → 1, descente de 10 dp |
| 1 600 ms | La révélation est finie |
| 1 800 ms | Passage à l'écran Bienvenue |
| à tout moment | Un tap saute à l'écran suivant |

### Ce qu'il ne faut PAS faire

- **Ajouter un bouton** sur l'ouverture. Elle rend la main seule : l'élève
  n'a rien à valider, il n'a qu'à regarder la marque.
- **Allonger la séquence** pourahlonger l'attente. Chaque durée est la durée
  d'un mouvement, pas un délai. Au-delà de `openingTotalMs`, l'écran enchaîne
  quoi qu'il arrive.
- **Faire dépendre la navigation d'une animation.** L'enchaînement passe par
  une minuterie bornée, pas par la fin d'un `AnimationController`. Une
  animation avortée, une préférence « réduire les animations » ou un retour
  au premier plan ne peuvent pas bloquer l'élève.
- **Dessiner la marque dans l'écran.** L'ouverture instancie
  `EntryMark` (le mark seul, 160 dp, sans texte). Si la marque évolue, un
  seul endroit change.
- **Ajouter un personnage, un avatar ou une mascotte.** Le sujet est suspendu.
  Le `RelioCharacter` — le mark animé — reste sur le prénom, le test et la
  clôture, où il existait déjà ; il n'est pas étendu.

### Le parcours, dans l'ordre

| Étape | Écran | Écrit un marqueur ? |
|---|---|---|
| 1 | Ouverture — révélation du logo | non |
| 2 | Bienvenue — « Commencer » | `entryScreenSeen` |
| 3 | Introduction au questionnaire — « C'est parti ! » | non |
| 4 | Prénom — « Continuer » | `learnerFirstName` |
| 5 | Questionnaire — « Continuer » × 5 | réponses, en silence |
| 6 | Conclusion — « Découvrir Relio » | `firstLaunchCompleted` |
| 7 | Accueil | non |

`entryScreenSeen` est écrit **au seul tap sur « Commencer »**, et rien d'autre.
L abandoning de l'ouverture ne marque donc rien : l'élève la reverra.

### Tests

```bash
flutter test test/presentation/entry_screens_test.dart       # les 3 écrans
flutter test test/presentation/onboarding_entry_flow_test.dart # le flux complet
flutter test test/branding/relio_character_test.dart         # rétention
```

`RelioApp` prend `showIntro: false` dans les tests d'interface : le parcours
d'entrée n'a pas à être traversé pour tester un écran d'accueil.

> Les écrans qui portent le personnage ne peuvent pas être testés par
> `pumpAndSettle` : son animation tourne en boucle et l'état ne se stabilise
> jamais. On pompe donc un nombre fixe de fois, comme le fait
> `laisserResoudre` dans `onboarding_entry_flow_test.dart`.

## Règle 11 — Tester la visibilité, pas la présence

> **Un `find.text(...)` qui passe ne prouve pas que l'écran est visible.**

Un widget peint à `Opacity 0` reste dans l'arbre : les finders le trouvent,
et tous les tests passent — sur un écran entièrement blanc. C'est
exactement ce qui a masqué le blocage de démarrage décrit dans
[`docs/RAPPORT_DEMARRAGE_BLOQUE.md`](docs/RAPPORT_DEMARRAGE_BLOQUE.md).

### Ce qu'il faut faire

- **Tester l'opacité.** `onboarding_visibility_test.dart` vérifie que
  `min(opacity) == 1` sur chaque écran du parcours, une fois l'animation
  terminée.
- **Capturer le rendu.** `tool/capture_parcours_test.dart` écrit un PNG par
  écran à 360 × 640. Une capture d'un écran bloqué est blanche — ce que
  aucune assertion d'arbre ne peut voir.
- **Abonner un écran animé à son animation.** Lire `controller.value` dans
  `build()` est un bug **silencieux** : rien ne lève, aucun journal ne le
  mentionne.
- **Éviter `pumpAndSettle` sur un écran qui attend entre deux animations.**
  Pendant un `Future.delayed` aucune frame n'est attendue : la boucle rend
  la main avant que le contenu soit apparu.
- **Un `Stack` ne signale rien quand deux enfants se chevauchent.** Seul un
  débordement de `Flex` lève une exception ; un recouvrement passe
  inaperçu. `expect(tester.takeException(), isNull)` ne le prouve donc pas.
  C'est ainsi que le titre de l'écran du prénom en est venu à passer sur le
  personnage — 50 px de recouvrement, zéro test en échec.
- **Capturer l'écran.** C'est le seul contrôle qui voie un recouvrement, un
  décalage ou un texte hors de son cadre.

> Aucun écran du parcours ne doit être considéré vérifié tant qu'il n'a pas
> été **vu**. Un test qui passe sur un écran vide, ou sur un écran où deux
> éléments se marchent dessus, est pire qu'aucun test.

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
| Tests | 946 (`test/`), plus 5 captures dans `tool/capture_etat_vide_test.dart` |
| Diagnostics | Panneaux C (intervention) et D (clarification) actifs ; le tuteur peut signaler une erreur par un marqueur fermé |
| Écran d'entrée | 7 étapes, 1,8 s d'ouverture sans bouton, tap pour passer — voir règle 10 |

### Branches

| Branche | Rôle | Poussée |
|---|---|---|
| `main` | Code source, tests, documentation | ✅ **Automatique, en fin de travail** (règle 7) |
| `apk-build` | Historique de distribution, figé — **plus de binaires** (règle 2) |

### Récupérer l'APK

L'APK n'est plus dans le dépôt : il est publié en **Release**.

<https://github.com/digitalholding2026-ux/relio-flutter-dart/releases>

Release courante : [`apk-v0.4.4-31`](https://github.com/digitalholding2026-ux/relio-flutter-dart/releases/tag/apk-v0.4.4-31)

Détail complet dans `docs/ARCHITECTURE.md` et `docs/BUILD.md`.


