# Relio — Mission 1 : Fondations

Socle technique de Relio, tuteur personnel de mathématiques destiné notamment
aux élèves francophones du Cameroun.

Ce document décrit les **structures de données**, les **choix techniques** et
les **points restant à arbitrer**. Il ne décrit aucune règle pédagogique :
celles-ci relèvent des missions suivantes.

---

## 1. Choix techniques

### 1.1 Framework : Flutter (Dart)

| Critère | Flutter | Alternative écartée |
|---|---|---|
| Mise en place | Déjà installé, SDK Android 36 présent | Kotlin/Compose : Gradle + Android Studio à installer |
| Cible Android | Natif via le canal Android | idem |
| Coût d'une dépendance | Nul si le package existe | idem |

**Conséquence principale :** le socle ne dépend d'aucun service réseau. Le
choix reste ouvert si une contrainte forte (intégration Vo2T, moteur natif
spécifique, politique de store) apparaît plus tard, mais cela vaudrait une
migration applicative, pas une refonte du modèle de données — le modèle est
entièrement Dart et ne dépend ni de Flutter ni d'Android.

### 1.2 Persistance locale : Drift / SQLite

C'est le point le plus structurant du socle.

**Options évaluées**

| Solution | Avantages | Limites | Verdict |
|---|---|---|---|
| **Drift (SQLite)** | SQL réel ; migrations versionnées **déclaratives et testables** ; requêtes d'agrégation (ex. historique par notion) ; schéma explicite relu par l'analyseur | Boilerplate de mapping Dart ; schéma maintenu à la main | **Retenu** |
| `sqflite` brut | Très léger, SQL direct | Pas de vérification de types du schéma ; mappings manuels fragiles ; pas de migration déclarative | Écarté |
| Hive / Isar | API simple | Hive n'est plus activement maintenu et réagit mal aux évolutions de schéma ; Isar ajoute du natif compilé | Écarté |
| SharedPreferences / JSON | Adapté à des réglages | Inadapté à un historique croissant ; pas de requêtes ; performances dégradantes | Écarté |

**Pourquoi ce choix est structurant**

Les futures règles de maîtrise devront répondre à des questions du type
« combien de tentatives cette notion a-t-elle recvues, sur quelle période ? ».
Cela suppose des **agrégations en base**, pas une relecture de tout le
historique en mémoire. SQLite les offre nativement.

**Coût assumé**

- Chaque évolution du schéma demande une migration explicite **et un test**.
- Le mapping objet ↔ SQL est explicite (`lib/data/db/converters.dart`), donc
  un peu répétitif.
- Drift ajoute `drift` + `sqlite3_flutter_libs` au `pubspec` (2 dépendances).

**Bénéfice décisif :** le modèle de domaine ne connaît pas SQL. Une décision
de moteur pédagogique future ne touche pas la persistance.

---

## 2. Modèle des données

Diagramme logique :

```
Notion ──┬── (préréquis) ──> Notion
         ├── domainId ──> MathDomain
         └── levelId  ──> NotionLevel

LearningEvent ──┬── (many-to-many) ──> Notion      [EventNotions]
                ├── 0..1 ExerciseAttempt            [exercise_attempts]
                │        ├── 0..1 ObservedError      [observed_errors]
                │        └── 0..1 OfferedHint        [offered_hints]
                └── ActivityContext (JSON)
```

### 2.1 Notions mathématiques (`lib/domain/notion/notion.dart`)

| Champ | Rôle |
|---|---|
| `id` | Identifiant **stable**, clé primaire. Jamais régénéré. |
| `label` | Intitulé court, en français. |
| `description` | Facultatif. **Vide par défaut** : aucun contenu pédagogique n'est inventé. |
| `domainId` / `levelId` | Rattachement déclaratif. |
| `lifecycle` | `draft` / `published` / `archived` — état **éditorial**. |
| `prerequisiteIds` | Dépendances **de catalogue**. |

`NotionLifecycle` porte un état éditorial, **pas une évaluation de l'élève**.
Une notion archivée reste en base : la supprimer casserait l'historique.

### 2.2 Événements d'apprentissage (`lib/domain/learning/`)

`LearningEvent` est l'unité factuelle et immuable de l'historique.

| Champ | Rôle |
|---|---|
| `id` | UUID produit **par le client avant écriture**. |
| `type` | Ex. `exercise_attempt`. Extensible sans migration. |
| `occurredAt` | Date UTC de survenue. |
| `notionIds` | Notions concernées — **quoi**, pas *combien* de maîtrise. |
| `attempt` | Tentative détaillée (voir ci-dessous). |
| `context` | Activité, type, source, langue. |
| `metadata` | JSON libre, propre au type d'événement. |

`ExerciseAttempt` porte `exerciseId`, `startedAt`, `submittedAt`,
`outcome`, `answer`, `durationMs`, `error`, `hint`, `context`.

`AnswerOutcome` distingue quatre faits, dont deux qu'il serait tentant de
confondre :

- `correct` / `incorrect` — la réponse a été soumise et évaluée ;
- `notEvaluated` — soumise mais **non évaluable** (format non reconnu).
  Ce n'est **pas** un échec, et la valeur par défaut en base est
  `notEvaluated` : en cas de valeur absente, on ne suppose jamais qu'une
  réponse était fausse ;
- `abandoned` — l'élève a quitté avant de soumettre.

`ObservedError.errorType` est `NULL` tant que l'erreur n'est pas identifiée :
aucune cause n'est devinée. `description` conserve le constat brut.

### 2.3 Séparation des faits et des interprétations

C'est une exigence structurante de la mission.

**Fait** — ce qui est stocké : dates, réponses, résultat observable, erreurs
constatées, indices proposés, notions, contexte.

**Interprétation** — ce qui ne l'est **pas** : maîtrise, niveau, difficulté,
progression, conseil pédagogique.

Aucun champ `maitrise = true/false` n'existe. Aucun score. Aucune moyenne.
Les requêtes d'agrégation sont déjà disponibles (`findByNotion`,
`count`, `findByType`) pour que les règles futures s'appuient sur des faits,
sans avoir à modifier le schéma.

### 2.4 Projection d'affichage (`LearnerProgress`)

L'interface ne lit jamais un état stocké : elle relit les événements et en
déduit des décomptes, à chaque affichage
(`lib/domain/learning/learner_progress.dart`).

| Affichage | Fait qui le produit |
|---|---|
| Leçon commencée | au moins une tentative soumise sur la leçon |
| Exercice terminé | au moins une réponse correcte sur l'exercice |
| Leçon maîtrisée | tous ses exercices officiels terminés |

Ces règles sont mécaniques et ne portent aucun jugement pédagogique. Un nouvel
élève voit donc `0 Exercice terminé`, `0 Notion maîtrisée`, trois leçons
« À commencer » et une barre de chapitre vide — jamais une progression
inventée. Rien n'est persisté : la projection est recalculée, jamais écrite.

### 2.5 Tuteur Relio — conversation branchée

S2 propose « Demander à Relio », sous les indices. Le panneau occupe 75 % de
la hauteur et affiche un fil de discussion.

Le tuteur appelle un modèle **compatible OpenAI** (`POST /chat/completions`)
avec le prompt système officiel (`docs/TUTEUR_LLM.md`), l'énoncé et la
réponse attendue de l'exercice ouvert. Le prompt interdit de révéler la
réponse ; les réponses tiennent en 2 à 3 phrases.

Sans clé `TUTOR_API_KEY` — ou en cas d'échec réseau, HTTP ou de réponse
illisible — l'élève reçoit la phrase de repli
(`RelioStrings.tutorUnavailableReply`). La conversation n'est pas persistée et
aucun fait d'apprentissage n'est transmis.

---

## 3. Persistence, hors ligne et migrations

### 3.1 Fonctionnement hors ligne

- Base SQLite dans le répertoire privé de l'application (`getApplicationDocumentsDirectory`).
- Aucune dépendance réseau n'est initialisée au démarrage, volontairement.
- `journal_mode = WAL`, clés étrangères activées à chaque ouverture.
- Aucun stockage ne quitte l'appareil à ce stade.

**Ce qui n'est PAS encore traité** (à arbitrer plus tard) : chiffrement au
repos, sauvegarde/récupération utilisateur, migration entre appareils.

### 3.2 Versionnage

`kSchemaVersion` vit dans `lib/data/db/app_database.dart`.

| Version | Contenu |
|---|---|
| v1 | Schéma initial réduit : notions, événements, tentatives, erreurs observées. Ni `metadata_json`, ni table `offered_hints`. |
| v2 | Ajoute `learning_events.metadata_json`, la table `offered_hints`, et la clé étrangère sur `observed_errors`. |

**Règle de contribution :** toute évolution du schéma incrémente
`kSchemaVersion` **et** fournit une étape explicite dans `_runUpgradeSteps`,
accompagnée d'un test dans `test/migration_test.dart`.

**Contrainte absolue :** une migration peut ajouter ou compléter, **jamais
supprimer ni réécrire** un événement d'apprentissage.

La migration v1 → v2 illustre les trois gestes légitimes :

1. `ALTER TABLE ... ADD COLUMN metadata_json ... DEFAULT '{}'` — les lignes
   existantes sont conservées, la colonne prend une valeur neutre.
2. `CREATE TABLE IF NOT EXISTS offered_hints` — `IF NOT EXISTS` rend l'étape
   rejouable.
3. Recréation de `observed_errors` via une table temporaire, copie des lignes,
   suppression, renommage — ajoute la clé étrangère **sans perte**.

### 3.3 Perte et duplication

**Anti-duplication — trois barrières combinées :**

1. `id` (UUID client) en clé primaire de `learning_events` ;
2. contrôle d'existence explicite **dans la transaction**, avant écriture.
   `insertOrIgnore` seul ne suffit pas : Drift renvoie le dernier `rowid`,
   non nul même lorsque la ligne est ignorée ;
3. clés primaires sur `exercise_attempts`, `observed_errors`,
   `offered_hints`, `event_notions`.

Un rejeu hors ligne est donc sans effet. Le dépôt retourne `true` si l'événement
a réellement été inséré, `false` s'il s'agissait d'un doublon : l'appelant
détecte le rejeu au lieu de le deviner.

Un rejeu avec un contenu **différent** est refusé : l'historique n'est jamais
réécrit.

**Atomicité :** un événement et ses lignes filles sont écrits dans une seule
transaction. Les lignes filles sont insérées **strictement** (pas
`insertOrIgnore`) : un doublon ici signalerait une incohérence réelle qui doit
faire échouer la transaction plutôt que d'être masquée.

**Suppression protégée :** `NotionRepository.delete` refuse de supprimer une
notion référencée par un événement et renvoie une `StateError`. Utiliser
`archived` pour retirer une notion du parcours.

---

## 4. Tests

`flutter test` — **50 tests, tous verts.**

| Fichier | Couverture |
|---|---|
| `notion_catalog_test.dart` | Création, lecture, mise à jour, prérequis, unicité des ids, filtres, tri, suppression protégée |
| `learning_event_repository_test.dart` | Conservation, atomicité/rollback, anti-duplication, rejeu, requêtes, UTC |
| `migration_test.dart` | Schéma v2, tables et clés primaires réelles, migration v1 → v2 **avec données préexistantes**, idempotence, contraintes après migration, persistance après réouverture |
| `offline_persistence_test.dart` | Base **sur disque**, survie à la fermeture, rejeu hors ligne ×3, volume (500 événements), bornes de résultat |
| `widget_test.dart` | Écran d'accueil contre une vraie base : compteurs, chargement, absence de données |

Deux défauts réels ont été trouvés par ces tests pendant l'écriture :

- `exercise_attempts`, `observed_errors` et `offered_hints` n'avaient **aucune
  clé primaire** dans le schéma Drift. SQLite les créait sans contrainte
  d'unicité, et les doublons passaient silencieusement. Corrigé, et un test
  vérifie désormais la présence effective des `PRIMARY KEY` dans `sqlite_master`.
- Le contexte d'activité porté par une **tentative** (et non par l'événement)
  était perdu à l'écriture. Corrigé par résolution de contexte à l'insertion.

---

## 5. Points restant à arbitrer

Aucun de ces points n'a été tranché d'autorité.

### Bloquant avant toute mission pédagogique

1. **Contenu des notions.** Le catalogue est vide par conception. Quelles
   notions, quel découpage, quelles définitions ? Source, validation,
   granularity ?
2. **Règles de maîtrise.** Combien de tentatives, sur quelle fenêtre, avec
   quelles conditions ? C'est l'objet d'une mission dédiée ; le socle ne
   pré-engage rien.
3. **Modèle d'exercice.** `exerciseId` est une chaîne libre aujourd'hui. Il
   faudra décider si les exercices sont stockés en base, générés, ou
   empaquetés — impacte la table `exercise_attempts`.

### Important

4. **Sauvegarde et restauration.** Si l'élève change d'appareil ou désinstalle,
   son historique est perdu. Sauvegarde locale, export manuel, ou compte
   distant ? Impacte fortement le schéma (identifiant élève).
5. **Multi-élèves / profils.** Le modèle suppose implicitement un seul élève.
   Pour une utilisation familiale (plusieurs enfants, un téléphone), il faudra
   introduire un identifiant d'élève et le porter sur les événements.
6. **Signature de publication.** La configuration release utilise la clé de
   debug. À remplacer avant toute diffusion.
7. **Confidentialité.** Aucun chiffrement au repos pour l'instant. Arbitrage
   selon la sensibilité des données d'un enfant.
8. **Version Flutter et NDK.** L'environnement de build a nécessité un NDK que
   le dépôt du SDK ne proposait pas ; voir `docs/BUILD.md`.

### Différé

9. **Langue et devise.** Interface et contenu en français ; format des dates
   et séparateurs décimaux à trancher (Cameroun : francophone mais usage
   numérique variable).
10. **Accessibilité et appareils modestes.** Écran en Material 3 ; aucun
    travail d'accessibilité ni de calibration sur Terminaux d'entrée de gamme
    n'a encore été fait.

---

## 6. Organisation du code

```
lib/
  main.dart                     Point d'entrée : ouvre la base locale
  app.dart                      Configuration Material, injection
  core/
    id.dart                     Génération d'identifiants
    clock.dart                  Horloge injectable (tests déterministes)
  domain/                       Règles métier, AUCUNE dépendance à Drift
    notion/                     Notions, cycle de vie
    learning/                   Événements, tentatives, erreurs, indices
    catalog/notion_catalog.dart Dépôt du catalogue
    learning/learning_event_repository.dart  Dépôt des événements
  data/db/                      Persistance
    tables.dart                 Schéma Drift + convertisseurs
    app_database.dart           Connexion, version, migrations
    converters.dart             Mapping domaine ↔ SQL
  presentation/
    home_page.dart              Écran d'accueil technique
  services/audio/
    audio_service.dart          Point de passage unique de la voix
    speech_text.dart            Nettoyage du texte avant synthèse
    voice_engine.dart           Synthèse (flutter_tts), derrière une interface
    listening_engine.dart       Dictée (speech_to_text), derrière une interface
```

### 6.1 Voix — narrateur, lecteur, conversationaliste

La voix traverse l'application, mais elle n'a **qu'un seul point de passage** :
`AudioService`. Trois rôles s'y appuient :

| Rôle | Ce qu'il lit | Où il est déclenché |
|---|---|---|
| Narrateur | Le message d'accueil | Ouverture de l'écran Accueil, si la voix est active |
| Lecteur | Énoncés, fiches d'indice, corrections, réponses du tuteur | Boutons « Écouter », haut-parleur des bulles, validation d'un exercice |
| Conversationaliste | La dictée de l'élève | Bouton micro du chat du tuteur |

Deux règles structurent le service :

1. **Une action chasse l'autre.** Toute lecture commence par couper la
   précédente ; deux voix ne se superposent jamais.
2. **Le mode muet est absolu.** `AudioService.speak` ne fait rien tant que la
   préférence est désactivée, même si un écran oublie de vérifier.

La préférence vit dans `app_settings`, sous la clé `voice.enabled` — aucune
migration de schéma n'est nécessaire. `LearnerSettings` en est la source de
vérité ; `AudioService.syncEnabled` n'en est que le miroir. L'icône globale
(haut-parleur) et l'interrupteur du Profil écrivent tous deux la même
préférence, l'une par le service, l'autre par `SettingsController`.

Les moteurs (`VoiceEngine`, `ListeningEngine`) sont injectables : les tests
vérifient les décisions du service sans plateforme audio. Les appels réels sont
toujours non bloquants pour l'interface — un moteur absent ou lent ne fige
jamais un écran.

Le texte affiché n'est **jamais** modifié : `speechText` ne fabrique que la
chaîne donnée au moteur (`AM/AB` → « A M sur A B », `−` → « moins », etc.).

La règle de dépendance est stricte : `domain` ne connaît pas `data`, et
`data` ne connaît que le modèle de domaine. Aucune dépendance réseau n'existe
à ce stade.
