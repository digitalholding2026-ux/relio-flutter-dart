# Rapport d'audit — Préparation du test d'entrée de Relio

**Objet** : déterminer ce que le cœur métier permet, et ce qu'il ne permet pas,
pour un test d'entrée de cinq questions présenté après la saisie du prénom.

**Nature** : audit en lecture seule. Aucun fichier du code n'a été modifié, aucun
modèle créé, aucune migration écrite, aucune dépendance ajoutée, aucune
implémentation commencée.

**Date de l'audit** : sur le commit `4ce6bcc`, branche `main`.

---

## 1. Résumé exécutif

**État général : le cœur métier est sain pour la persistance, mais il ne sait
pas évaluer 4 des 5 questions du test d'entrée.** Les deux obstacles sont de
nature différente.

Ce qui est **réutilisable tel quel** : la persistance des événements est
générique au point de ne connaître aucun contenu pédagogique
(`learning_events.type` est une chaîne libre, `metadata_json` un JSON libre).
Le prénom est stockable. L'indicateur de premier lancement existe déjà. La
fonction de correction est pure — elle peut être appelée sans déclencher indice,
diagnostic ni transfert.

Ce qui **manque** : aucune notion de choix multiple (QCM) n'existe, et le moteur
arithmétique ne connaît ni le signe unaire, ni les variables, ni les équations.
Vérifié dans le parseur lui-même :

| Question | Moteur existant | Verdict |
|---|---|---|
| Q1 `24 ÷ 6 + 3` → `7` | `evaluateArithmetic` | ✅ Évaluable |
| Q2 fractions, choix `2/4` | — | ❌ **Aucune notion de choix** |
| Q3 `(-3) + 5` → `2` | `facteur()` | ❌ **Non évaluable** |
| Q4 `2x+1`, x=3 → `7` | `_tokeniser` | ❌ **Non évaluable** |
| Q5 `x+4=9` → `5` | `_tokeniser` | ❌ **Non évaluable** |

Le risque majeur n'est pas technique mais **pédagogique et de conception** :
`correct()` ne calcule rien. Hors du contrat PPCM/PGCD, il compare des chaînes
littérales et appelle `int.tryParse`. Une réponse juste écrite sous une forme
non transcrite serait classée « non évaluable » — jamais fausse, ce qui est
propre, mais aussi jamais juste. Le test d'entrée doit donc embarquer **ses
propres critères de correction**, pas utiliser `correct()`.

**Ce qui sauve la conception** : les questions Q3, Q4 et Q5 demandent une
**valeur** (`2`, `7`, `5`), pas une expression. Le moteur n'a donc pas besoin
de savoir calculer `(-3) + 5`, `2x + 1` ou `x + 4 = 9` — il lui suffit de
comparer la valeur saisie à la valeur attendue. Aucun élargissement de
l'évaluateur arithmétique n'est nécessaire.

---

## 2. Inventaire vérifié

| Besoin | Fichier / classe / méthode | Comportement constaté | Verdict | Justification |
|---|---|---|---|---|
| Banque de questions hors chapitre 1 | **N'existe pas** | `Chapter1Bank` (`chapter1_bank.dart:8`) est `static`, contenu PGCD/PPCM exclusivement | **Absent** | Aucune abstraction `Bank`. `Chapter1Service._notionsFor` (`:510`) dérive la notion de `exercise.lesson.id` |
| Ordre fixe de présentation | `Chapter1Bank.exercises` = `static const List<Exercise>` dans l'ordre du document | Ordre naturel, **hors service** | **Adaptable** | `V1ScreenRules.positionOf/nextAfter` (`v1_screen_rules.dart`) existe mais est lié au chapitre 1 |
| Définition avec choix de réponse | `AnswerType` (`exercise.dart:236`) = `{integer, text}` — **2 valeurs** | Aucun champ `options` / `choices` | **Absent** | Le seul `answer_field.dart:101` est un `TextField`. Aucun widget de liste de choix dans le dépôt |
| Critères de correction | `CorrectionCriterion` (`exercise.dart:187`) : `acceptedValues`, `acceptedExpressions`, `ppcmRelation` | Correction **par comparaison littérale** | **Adaptable** | Convient si l'on énumère les formes acceptées. Ne calcule rien |
| Évaluation sans effets de bord | `correct(Exercise, String)` → `CorrectionResult` (`chapter1_service.dart:113`) | **Fonction pure**, de niveau supérieur. N'écrit rien, ne consomme aucun indice, ne déclenche aucun diagnostic | **Réutilisable tel quel** | Confirmé : ne touche ni `_repository`, ni `_clock`, ni `_engine` |
| Distinction correct / incorrect / non évaluable | `CorrectionResult.isCorrect` + `.isEvaluated` (deux booléens orthogonaux) → `AnswerOutcome` (`exercise_attempt.dart:17`) : `correct`, `incorrect`, `notEvaluated`, `abandoned` | Distinction **au niveau du type**, pas déduite | **Réutilisable tel quel** | `chapter1_service.dart:355-357` : `notEvaluated` ⇔ `isCorrect=false, isEvaluated=false` |
| Erreur technique (évaluation) | `TransferOutcome.technicalError` (`transfer_verification.dart:159`) | Existe **uniquement dans le module de transfert**, alimenté par un booléen fourni par l'appelant | **Absent au niveau réponse** | `correct()` ne connaît pas ce concept |
| Distinction non évaluable | `TransferOutcome.indeterminate` (`:156`) | Modélisé explicitement, mais pas produit par `correct()` | **Adaptable** | L'intention est déjà formalisée et commentée dans le dépôt |
| Réponse vide | `correct()` renvoie `(false, true)` si `raw.isEmpty` (`:115-121`) | Vide classé **évalué et faux** | **Adaptable** | `HintTrajectory.classify` (`:109`) le reclassifie en `incomplete`. Le type de test d'entrée n'a pas cette reclassification |
| Événements d'apprentissage | `LearningEventRepository.record(LearningEvent)` (`learning_event_repository.dart:47`) | **Transactionnel**, append-only, dédupliqué par `id` | **Réutilisable tel quel** | `type` est une chaîne libre, `metadata` un JSON libre. N'a aucune notion de chapitre |
| Distinguer le contexte d'activité | `ActivityContext` (`activity_context.dart`) : `activityId`, `activityType`, `source`, `locale`, tous `String?` | **Champ mort** : jamais renseigné par le code de production | **Réutilisable tel quel, mais inutilisé** | Seul `encodeContext` / `decodeContext` (`converters.dart:21-41`) le touchent. `chapter1_service.dart:384` écrit `context: null` |
| Identifiant stable de session | **N'existe pas** | Aucun `sessionId`, aucune table de session | **Absent** | `metadata['attemptKey']` est la convention de fait (`chapter1_service.dart:305, 397`), mais non typée |
| Identifiants uniques | `newId({generator})` (`core/id.dart:19`) → UUID v4 | Aléatoire, injectable par paramètre d'appel | **Réutilisable tel quel** | Pas de service injecté ; `Chapter1Service` le reçoit par constructeur (`:237`) |
| Stockage du prénom | `SettingsRepository.setName()` (`learner_settings.dart:155`) → clé `learner.name` | Écrit dans `app_settings`, `trim()` appliqué, `insertOnConflictUpdate` | **Réutilisable tel quel** | Aucune migration nécessaire |
| Indicateur de premier lancement | `hasCompletedFirstLaunch()` / `markFirstLaunchCompleted()` (`learner_settings.dart:125, 135`) → clé `app.first_launch_completed` | **Existe déjà** | **Réutilisable tel quel** | Décision d'affichage dans `app.dart:97-105` |
| Persistance des réponses au fil du test | `ExerciseAttempt` (`exercise_attempt.dart`) lié à `eventId` | Chaque réponse = **un événement** | **Adaptable** | Suffisant pour un test, mais voir §5 sur la position dans le test |
| Reprise après interruption | `findByType(type, {limit})` (`learning_event_repository.dart:189`) | Lecture possible par type | **Partiellement** | Aucun index, aucun ordre garanti, aucune position de question |
| API clé/valeur générique | `SettingsRepository` | **N'existe pas** (`_write` privé, `:170`) | **Absent** | Une nouvelle clé exige une nouvelle méthode sur le dépôt |

---

## 3. Persistance et cycle de vie

**Schéma** — `kSchemaVersion = 3` (`app_database.dart:42`), dix tables. Le test
d'entrée peut s'appuyer dessus **sans migration** : `app_settings` est une table
clé/valeur générique conçue pour cela (commentaire explicite,
`tables.dart:219-222`).

**Migrations** — `_runUpgradeSteps` (`app_database.dart:133`) couvre v1→v2
(notions, indices, `metadata_json`, recréation de `observed_errors` avec FK) et
v2→v3 (`app_settings`). Les deux sont testées dans `migration_test.dart`, y
compris la conservation des données. Il n'existe **pas** d'étape v0→v1
(`onCreate` joue ce rôle). Le test d'entrée ne requiert aucune de ces étapes.

**Déduplication** — c'est le point le plus solide. `record()`
(`learning_event_repository.dart:47`) ouvre une transaction, vérifie l'existence
de `id`, et renvoie `false` sans rien écrire si la ligne existe (`:77-86`). Le
comportement est testé (`learning_event_repository_test.dart:190-199` : trois
enregistrements du même événement → `true, false, false`).

> Une réponse de test d'entrée enregistrée deux fois **ne duplique rien**, à
> condition que l'appelant réutilise le même `id`. Or un UUID v4 régénéré à
> chaque tentative produit un `id` différent : la déduplication ne protège que si
> l'identifiant est **dérivé de la question et de la session**, pas tiré au sort
> à chaque essai.

**Cycles de vie** — `main.dart` ouvre la base avant `runApp`. `app.dart` utilise
`bool? _showIntro` : `null` = indécidé, affiché via un `_SplashGate` blanc. La
décision intro/accueil dépend de `app.first_launch_completed`. Deux réserves
factuelles :

- `_completeFirstLaunch()` (`app.dart:123-130`) absorbe l'échec d'écriture en
  silence. Si l'écriture échoue, l'accueil s'affiche quand même et **l'écran
  d'entrée sera rejoué au prochain lancement**.
- Si `hasCompletedFirstLaunch()` ne rend jamais, l'application **reste sur un
  écran blanc indéfiniment** — ni timeout, ni état d'erreur, ni écran de repli.

**Cycle de vie Android** — aucun hook d'observateur de cycle de vie n'a été
trouvé dans `lib/`. Il n'existe **aucun mécanisme** de sauvegarde à la mise en
arrière-plan ni de restauration au retour au premier plan. Le seul stockage non
persistant est `Map<String, ExerciseDraft> _drafts` (`app.dart:220`), en mémoire,
perdu à la fermeture — et le commentaire du code qualifie cette perte de
« limite ACCEPTÉE ».

**Aucun autre stockage local** que `relio.sqlite`. Pas de SharedPreferences, pas
de Hive, pas de JSON local.

---

## 4. Évaluation des réponses

**Représentation actuelle.** `correct()` renvoie `CorrectionResult` : deux
booléens orthogonaux, `isCorrect` et `isEvaluated`. La correspondance vers
`AnswerOutcome` est systématique :

```
correct      ⇔ (isCorrect: true,  isEvaluated: true)
incorrect    ⇔ (isCorrect: false, isEvaluated: true)
notEvaluated ⇔ (isCorrect: false, isEvaluated: false)
```

C'est une distinction **réelle au niveau du type**, pas une déduction. Elle
satisfait la contrainte « ne pas assimiler une réponse non évaluable à une
erreur mathématique » — **à condition de ne pas passer par
`HintTrajectory.classify`**, qui réduit `incorrect` et `notEvaluated` tous deux à
`AttemptClassification.incomplete` (`hint_trajectory.dart:109`).

**Ce que `correct()` fait réellement.** Six issues, dans cet ordre
(`chapter1_service.dart:113`) :

1. saisie vide → `(false, true)` — évaluée mais fausse
2. `ppcmRelation != null` → `_correcterParRelation` (seul chemin qui **calcule**)
3. `acceptsExpression(raw)` → comparaison **textuelle** après normalisation
4. `parseInteger(raw) == null` → `(false, false)` non évaluable
5. `isTextOnly` → `(false, false)` non évaluable
6. sinon → comparaison de l'entier parsé

**Conséquence majeure.** Hors `ppcmRelation`, le moteur **n'évalue aucune
arithmétique**. Il ne sait ni calculer ni comparer numériquement une expression.
Une réponse juste écrite sous une forme non listée dans `acceptedExpressions` est
classée non évaluable.

**Vérification du vocabulaire arithmétique** (`arithmetic_expression.dart`) :

- `_tokeniser` (`:118-155`) accepte : chiffres, `+`, `-`, `*`, `/`, `×`, `÷`,
  `(`, `)`. **Tout autre caractère provoque `return null`** (`:152`).
- `facteur()` (`:225-245`) n'accepte que `(`, ou une suite de chiffres `[0-9]+`.
  Le `-` n'y est **pas** traité : il n'existe **aucun signe unaire** dans tout le
  moteur.
- Conséquences, vérifiées par lecture du parseur :
  - `(-3)+5` → `facteur()` voit `-`, ni `(` ni chiffre → `null`
  - `2x+1` → le caractère `x` n'est dans aucune branche du tokeniseur → `null`
  - `x+4=9` → idem
  - `24÷6+3` → évalue correctement à 7

**Sans effets de bord — réponse au point C de la mission.** Oui, l'évaluation est
découplable. Sont purs : `correct()`, `evaluateArithmetic()`,
`normalizeAnswer()`, `parseInteger()`, `DiagnosticEngine.diagnose()`,
`collectObservations()`, `TransferVerification.decide()`,
`HintTrajectory.classify()`. Seuls `recordHintRequested()` et `recordAttempt()`
écrivent. Un test d'entrée peut donc évaluer sans rien enregistrer.

**Réserve critique.** `recordAttempt()` écrit systématiquement un
`ObservedError` avec `description: 'Réponse non conforme à la réponse attendue.'`
dès que `!isCorrect` (`chapter1_service.dart:366-373`). Passer par
`recordAttempt` pour le test d'entrée **polluerait l'historique append-only avec
de fausses erreurs**. C'est l'argument décisif pour ne pas réutiliser
`Chapter1Service` tel quel.

**Le contenu de la banque est verrouillé par les tests.**
`correction_test.dart:276-283` boucle sur `Chapter1Bank.exercises` avec une règle
positionnelle (`positionOf(id) <= 9` → `integer`).
`ppcm_relation_contract_test.dart:262-264` exige `ppcmRelation == null` sur les
11 exercices. **Ajouter une question à la banque du chapitre 1 casserait la
suite de tests** — et violerait de toute façon la consigne « ne pas modifier la
banque du chapitre 1 ».

---

## 5. Écarts pour le test d'entrée

### P0 — Risque de perte ou d'incohérence des données

| Écart | Constat |
|---|---|
| **Duplication de réponse si l'`id` est tiré au sort** | `newId()` produit un UUID v4 à chaque appel. La déduplication de `record()` ne protège que si l'`id` est **dérivé** de (session, question). À défaut, un double enregistrement persiste deux événements. *Adaptation : identifiant déterministe par couple session + question.* |
| **Reprise de position non gérée** | Aucun stockage de « question en cours ». Après une fermeture, on peut reconstituer les réponses par `findByType`, mais **rien ne dit où l'élève s'était arrêté**. Risque de refaire une question ou de sauter la suivante. |
| **Écriture de session non atomique** | Si l'on écrit la réponse puis, séparément, la position, un arrêt entre les deux laisse un état incohérent. Les deux doivent être dans **une seule transaction**. |
| **Réponses non évaluables converties en erreurs** | `recordAttempt` crée un `ObservedError` dès que `!isCorrect`. L'historique append-only contiendrait alors une « erreur » pour une réponse simplement non évaluable. |

### P1 — Indispensable à une évaluation pédagogique fiable

| Écart | Constat |
|---|---|
| **Le moteur ne peut pas évaluer Q2, Q3, Q4, Q5** | Ni choix multiple, ni signe unaire, ni variables, ni équations. **4 questions sur 5 hors vocabulaire.** Ni `correct()` ni les critères de correction ne savent calculer. *Atténuation : seul le contenu des réponses est à comparer, voir §1 et §6.* |
| **Aucune notion de choix multiple** | `AnswerType` = `{integer, text}`. La question 2 impose 3 options. Aucun champ, aucun type, aucun widget. |
| **Aucun type « erreur technique » au niveau d'une réponse** | `TransferOutcome.technicalError` existe mais est propre au transfert. Le scénario 7 (erreur à l'enregistrement) n'a pas de représentation dédiée. |
| **Aucun identifiant de session stable** | `ActivityContext` existe mais est **mort** — jamais renseigné. Sans `activityId`, impossible de regrouper les 5 réponses d'une même passation. |

### P2 — Nécessaire à l'intégration fonctionnelle

| Écart | Constat |
|---|---|
| **Prénom saisi après l'écran d'entrée, pas avant** | Aujourd'hui : intro → accueil → onglet Profil pour saisir le prénom (`ProfilePage`). Le test d'entrée est voulu **après** le prénom. L'enchaînement des écrans n'existe pas. *Constat, pas proposition : la mission interdit de toucher à l'interface.* |
| **Aucune API clé/valeur générique** | `_write` est privé (`learner_settings.dart:170`). Stocker l'identifiant de session ou l'état du test impose d'ajouter des méthodes sur `SettingsRepository` — sans migration. |
| **Ordinalité non garantie à la relecture** | `findByType` renvoie des lignes sans ordre explicite. L'ordre des questions doit être porté par le contenu, pas par l'ordre d'insertion. |
| **Aucun index** | `findByType` fait un balayage séquentiel. Sans gravité à cinq éléments, mais le commentaire « Indexé pour les filtres » de `tables.dart:119` est **inexact**. |

### P3 — Améliorations non bloquantes

| Écart | Constat |
|---|---|
| **En-tête de `app_database.dart` obsolète** | Le commentaire annonce « VERSION DE SCHÉMA = 2 » alors que la valeur est 3. |
| **`AnswerOutcome.abandoned` n'est jamais émis** | Aucun code ne le produit. À clarifier si le test d'entrée veut distinguer abandon et non-réponse. |
| **`deleteAll()` ne purge pas `app_settings`** | Affecte uniquement les tests. |
| **Écart documentaire** | `AGENTS.md` annonce 534 tests ; la suite en compte 536. |

---

## 6. Proposition d'architecture minimale

Quatre abstractions. Chacune est justifiée par un écart identifié ; aucune n'est
redondante. Aucun code n'est écrit ici.

### 1. `EntryTestQuestion` — définition des questions

- **Responsabilité** : porter l'énoncé, le type de réponse et les critères de
  correction, sans dépendre de `Exercise`.
- **Données minimales** : `id` stable, `order` (1..5), `statement`, `kind`
  (`numeric` | `choice`), `expectedValue`, `choices` (liste vide si non
  applicable), `accepts(String)`.
- **Réutilisation** : **aucune**. `Exercise` est inutilisable ici — pas de choix
  possible, et `AnswerType` ne couvre pas le cas « équation » du tout.
- **Justification** : P1. Le vocabulaire arithmétique existant ne couvre pas 4
  questions sur 5 ; l'étendre risquerait de casser le contrat PPCM/PGCD. **Le
  contenu est déjà validé** (section 4 du mandat) : la transcription est
  possible sans interprétation.

### 2. `EntryTestCorrection` — critères et résultat d'évaluation

- **Responsabilité** : évaluer une réponse sans effet de bord, en distinguant
  les cas.
- **Données minimales** : `correct`, `evaluable`, `value`, sur le modèle de
  `CorrectionResult` existant.
- **Réutilisation** : **réutiliser la forme de `CorrectionResult`** (deux
  booléens orthogonaux, déjà conforme à la contrainte « non évaluable ≠
  erreur »). Pour les critères :
  - Q1, Q3, Q4, Q5 → comparaison de **valeur entière** (`7`, `2`, `7`, `5`)
  - Q2 → comparaison de **chaîne normalisée** sur les choix (`2/4` vs `2/4`),
    et non par fraction
- **Justification** : **P1 résolu sans toucher au moteur**. Le point important :
  les questions Q3 à Q5 portent sur la **réponse**, pas sur l'énoncé. Q1 est
  dans le même cas, l'élève répondant `7`. C'est ce qui rend le test d'entrée
  réalisable sans étendre l'évaluateur arithmétique.

### 3. `EntryTestSession` — passation

- **Responsabilité** : regrouper les réponses d'une même passation et porter la
  position.
- **Données minimales** : `sessionId`, `startedAt`, `answers` (liste ordonnée par
  `order`), `isComplete`.
- **Réutilisation** : `newId()` (`core/id.dart`) pour l'identifiant ; `Clock`
  injectable pour l'horodatage.
- **Justification** : P0 et P2. `ActivityContext.activityId` peut porter le
  `sessionId` **sans modification du modèle** — il sérialise déjà en JSON dans
  `context_json`. Cela évite de créer une table.
- **Point d'attention** : `ActivityContext` n'est aujourd'hui jamais renseigné.
  L'utiliser pour la première fois ne le rend pas discriminant par lui-même —
  il faut **aussi** renseigner `activityType` de façon stable, sinon la
  distinction test d'entrée / chapitre 1 repose sur un champ que rien ne
  remplit.

### 4. `EntryTestRepository` — persistance

- **Responsabilité** : écrire et relire les réponses de session, en transaction,
  avec déduplication.
- **Données minimales** : un `LearningEvent` par réponse, `type` =
  `'entry_test_answer'`, `metadata` = `{sessionId, order, questionId, raw,
  normalized}`, `id` **déterministe**.
- **Réutilisation** : **`LearningEventRepository.record()` est directement
  réutilisable** — transactionnel, append-only, dédupliqué. L'écriture passerait
  par `record()` avec un `id` dérivé de `'$sessionId-$questionId'`, ce qui donne
  la déduplication P0 gratuitement. `recordAll()` permet d'écrire les cinq
  réponses en une seule transaction.
- **Justification** : c'est le levier principal. **Aucune migration, aucune table
  nouvelle, aucun modèle d'événement modifié** — conforme aux contraintes.

### Ce qu'il ne faut pas faire

Réutiliser `Chapter1Service.recordAttempt()`. Il écrit un `ObservedError` à
chaque `!isCorrect` et lie la notion à `lecon-${lesson.id}`
(`chapter1_service.dart:510`). Un test d'entrée n'a ni notion de leçon ni notion
d'erreur.

---

## 7. Tests à prévoir

**Correction** — pour chacune des 5 questions : réponse attendue → `correct:
true, evaluable: true`. Réponse fausse plausible → `correct: false, evaluable:
true` (et **non** `evaluable: false`). Saisie illisible → `correct: false,
evaluable: false`. Ces deux derniers cas doivent rester **distincts** : c'est la
garantie centrale.

**Choix multiple (Q2)** — `2/4` accepté ; `2/3` et `3/4` rejetés en `evaluable:
true` ; un choix hors liste traité comme non évaluable.

**Isolation** — évaluer une question du test ne doit produire **aucune** écriture.
Vérifiable en comparant `repository.count()` avant et après.

**Non-régression** — les tests existants du chapitre 1 doivent rester verts
**inchangés**, notamment `correction_test.dart:276-283` et
`ppcm_relation_contract_test.dart:262-264`, qui verrouillent le contenu de la
banque. Ce sont eux qui prouvent qu'on n'a pas touché au chapitre 1.

**Persistance** — idempotence : enregistrer deux fois la même réponse (même
`id`) ne crée qu'une ligne. C'est le test qui protège le scénario 8. Relecture
dans l'ordre des questions après fermeture simulée. Reprise après relance au bon
endroit (scénario 12).

**Cycle de vie** — le scénario 7 (erreur d'écriture) doit avoir un test :
l'erreur remonte-t-elle, ou l'application continue-t-elle silencieusement ?
Question ouverte, cf. §9.

---

## 8. État des vérifications

Commandes réellement exécutées depuis le dépôt, branche `main`, working tree
propre :

| Commande | Résultat |
|---|---|
| `flutter analyze` | **`No issues found!` (19,2 s)** |
| `flutter test` | **`All tests passed!` — 536 tests (1 min 15 s)** |

Aucun échec, donc aucune distinction à faire entre échecs préexistants et
problèmes découverts pendant l'audit.

**Aucun fichier du code n'a été modifié** : `git status --short` ne retourne
rien. Aucun fichier créé, aucune migration, aucun test ajouté, aucune
dépendance.

**Limites de l'environnement.** Aucun téléphone ni émulateur : rien n'a été
vérifié sur un appareil réel. Les affirmations de la section 4 reposent sur la
**lecture du parseur et du tokeniseur**, pas sur une exécution — elles sont
déduites de code. Un test d'exécution confirmant `evaluateArithmetic('(-3)+5')`
renvoyant `null` serait une confirmation utile lors de l'implémentation. Aucune
commande `dart` ad hoc n'a été exécutée, la mission interdisant de créer des
fichiers.

**Note** : la règle 1 d'`AGENTS.md` n'est pas applicable — aucun code n'a été
modifié, donc aucun build ni APK à produire, et rien à publier sur `apk-build`
au sens de la règle 2.

---

## 9. Décisions à réserver

Les cinq questions pédagogiques sont **validées** et ne sont pas remises en
cause. Restent quatre décisions, aucune déductible du code.

1. **Position de la saisie du prénom.** Aujourd'hui : écran d'entrée → accueil →
   onglet Profil. Le mandat situe le test **après** la saisie du prénom. Savoir
   si le prénom est saisi avant l'écran d'entrée ou sur un écran dédié détermine
   la séquence d'écrans. Décision d'interface et de parcours, hors périmètre du
   cœur métier.

2. **Traitement d'une erreur technique à l'enregistrement.** Le scénario 7 est
   prévu mais rien ne l'implémente. Trois voies : remonter l'erreur à l'élève,
   enregistrer la réponse avec un marqueur technique, ou ne rien enregistrer. La
   deuxième rejoint `TransferOutcome.technicalError`, qui existe mais n'a pas
   d'équivalent au niveau d'une réponse.

3. **Durée de validité d'une session interrompue.** Reprendre le test demain
   est-il une reprise, ou une nouvelle passation ? Cela décide si l'on cherche
   une session ouverte ou si l'on repart de zéro.

4. **Traitement de la deuxième passation.** Que se passe-t-il si l'élève déjà
   évalué relance le test d'entrée ? Le code actuel ne contient aucun élément
   permettant de trancher.

**Point d'arbitrage, non bloquant.** `ActivityContext` est le support naturel
pour distinguer le test d'entrée du chapitre 1, mais il est **mort dans le code
de production** — `chapter1_service.dart:384` écrit explicitement `context:
null`. Le faire vivre est cohérent, mais cela modifie le comportement d'écriture
du chapitre 1 et touche donc à la règle « ne pas modifier les modèles
d'événements existants ». À confirmer avant de s'en servir comme discriminant.