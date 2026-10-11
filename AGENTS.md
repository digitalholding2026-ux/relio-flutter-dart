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

## Règle 2 — Android est la seule cible

Relio est une application **Android**. Le web n'est pas supporté et n'a pas
été conservé.

La visualisation se fait **uniquement via un APK installé sur le téléphone**
(voir règle 1). Ne pas proposer de solution web, et ne pas réintroduire de
dossier `web/` ou de dépendance WebAssembly : cela a été tenté puis abandonné
car la persistance SQLite via `WasmDatabase` n'aboutit pas à un rendu
fonctionnel dans cet environnement.

---

## Règle 3 — Le socle pédagogique reste vide

Aucune notion, aucun exercice, aucune règle de maîtrise ne doit être
inventé sans validation explicite. Les champs descriptionnels restent vides
par défaut.

Ce qui est **autorisé** : structure, stockage, migrations, tests, interface
technique.

---

## Règle 4 — Pas de champ de maîtrise

Le stockage contient uniquement des **faits observables** (dates, réponses,
résultats, erreurs constatées, indices, contexte).

Interdits dans le modèle et le schéma :
`maitrise`, `score`, `niveau`, `progression`, `moyenne`, ou tout champ
équivalent. Ces règles relèvent d'une mission dédiée.

---

## Règle 5 — Toute évolution de schéma est testée

1. Incrémenter `kSchemaVersion` dans `lib/data/db/app_database.dart`.
2. Ajouter l'étape de migration explicite dans `_runUpgradeSteps`.
3. Ajouter un test dans `test/migration_test.dart` qui vérifie la
   **préservation des données**.

Interdit : supprimer ou réécrire un événement d'apprentissage lors d'une
migration.

---

## Règle 6 — Pas de commit sans demande explicite

L'utilisateur contrôle les commits et les pushes. Ne pas faire
`git commit` ni `git push` sans demande claire.

---

## État du dépôt

| Élément | Valeur |
|---|---|
| Application ID | `com.relio.relio` |
| minSdk | 24 (Android 7.0) |
| Flutter | 3.47.7 |
| NDK requis | 28.2.13676358 |
| Persistance | Drift / SQLite, schéma v2 |
| Tests | 50 |

Détail complet dans `docs/ARCHITECTURE.md` et `docs/BUILD.md`.
