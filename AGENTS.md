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

## Règle 2 — Publier l'APK sur la branche `apk-build`

> **Après tout build réussi, versionner l'APK sur la branche `apk-build`,
> séparément de `main`.**

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

L'utilisateur contrôle le code : **ne jamais commiter ni pousser le code
source sur `main` sans demande claire.**

En revanche, la **règle 2 prime** : après tout build réussi, l'APK doit être
versionné et poussé sur `apk-build`. C'est le seul cas où un `git push` est
effectué sans demande explicite, précisément parce que l'utilisateur a demandé
que ce soit automatique.

Résumé :

| Action | Autorisation |
|---|---|
| Commit de code sur `main` | ⛔ Sur demande explicite uniquement |
| Commit + push de l'APK sur `apk-build` | ✅ Automatique après tout build (règle 2) |
| Suppression d'un APK déjà publié | ⛔ Sur demande explicite |

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

## État du dépôt

| Élément | Valeur |
|---|---|
| Application ID | `com.relio.relio` |
| minSdk | 24 (Android 7.0) |
| Flutter | 3.47.7 |
| NDK requis | 28.2.13676358 |
| Persistance | Drift / SQLite, schéma v2 |
| Tests | 317 (50 socle + 87 moteur ch.1 + 46 interface S1/S2 + 134 fiabilisation, verrouillage, vérification) |

### Branches

| Branche | Rôle | Poussée |
|---|---|---|
| `main` | Code source, tests, documentation | Sur demande explicite |
| `apk-build` | APK de distribution dans `apk/` | Automatique après build (règle 2) |

### Récupérer l'APK depuis GitHub

<https://github.com/digitalholding2026-ux/relio-flutter-dart/tree/apk-build/apk>

Détail complet dans `docs/ARCHITECTURE.md` et `docs/BUILD.md`.
