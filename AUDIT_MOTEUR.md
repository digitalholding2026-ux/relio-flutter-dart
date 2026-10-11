# Audit du moteur pédagogique — Relio chapitre 1

**Destinataire :** ingénieur(e) UI/UX tasked(e) de concevoir le parcours élève.
**Objet :** ce que le moteur sait faire aujourd'hui, ce qu'il ne sait pas faire,
et ce qui doit être arbitré avant de concevoir les écrans.

> Ce rapport décrit **l'état réel du code**, vérifié par lecture des sources et
> par 137 tests. Il n'a été produit ni modifié après ajout d'aucune
> fonctionnalité : il ne décrit que ce qui existe.
>
> Commit de référence : `320f559` — branche `main`.

---

## 1. En une phrase

Le moteur sait **présenter un exercice, corriger une réponse, distribuer des
indices dans l'ordre et poser un diagnostic sous forme d'hypothèses**, mais
il **ne sait pas encore produire un retour pédagogique consolidé**, ni
exposer le type de réponse attendu. Un écran construit directement dessus
manquerait de données pour S2 et S4.

---

## 2. Ce qui est disponible

### 2.1 Banque de contenu — `lib/domain/curriculum/chapter1_bank.dart`

| Élément | Accès | Détail |
|---|---|---|
| 11 exercices validés | `Chapter1Bank.exercises` | `List<Exercise>` |
| 6 tâches de vérification | `Chapter1Bank.verificationTasks` | `List<Exercise>` |
| 8 diagnostics D1–D8 | `Chapter1Bank.diagnosticCases` | `List<DiagnosticCase>` |
| Recherche par id | `Chapter1Bank.findExercise(String)` | Exercices **et** tâches |

**Les trois leçons**, avec leurs intitulés exacts :

| id | Intitulé affiché | Exercices |
|---|---|---|
| `lecon-1` | `PGCD : algorithme des soustractions` | 4 |
| `lecon-2` | `« PGDC » : algorithme d’Euclide` | 3 |
| `lecon-3` | `Relation entre le PPCM et le PGCD de deux entiers naturels` | 4 |

> **Leçon 2 :** l'intitulé contient **« PGDC »**. C'est une transcription
> fidèle de la capture source. L'enum expose
> `ArithmeticLesson.requiresEditorialConfirmation == true` pour la leçon 2.
> Le texte doit être affiché **tel quel**, sans correction.

### 2.2 Modèle d'exercice — `lib/domain/curriculum/exercise.dart`

```dart
class Exercise {
  final String id;                          // stable
  final BankElementKind kind;               // exercise | verificationTask
  final ArithmeticLesson lesson;
  final String statement;                   // énoncé, texte brut
  final CorrectionCriterion correction;
  final List<SolutionStep> expectedSteps;
  final List<ExerciseHint> hints;
  final ComprehensionQuestion? comprehension;
  final String? followUpTask;
  final List<String> diagnosticCaseIds;
}
```

Points utiles à l'écran :

- `statement` est une **`String` brute**. Aucun rendu mathématique n'existe :
  pas de notation `a=8`, pas de `÷`, pas de `_` ni de `^`. Voir §5.
- `hints` + `orderedHints` + `nextHintAfter(Set<int> consommés)` gèrent la
  **révélation progressive**.
- `comprehension` est disponible sur les exercices 1 et 5 uniquement.
- `expectedSteps` décrit la méthode attendue (utile pour un affichage
  « méthode » ou une vérification de démarche).

### 2.3 Correction d'une réponse — `chapter1_service.dart`

```dart
CorrectionResult correct(Exercise exercise, String rawInput)
```

| Champ | Signification |
|---|---|
| `isCorrect` | la réponse correspond à l'attendu |
| `isEvaluated` | la réponse a pu être évaluée |
| `matchedValue` | valeur retenue si numérique |

**Point de vigilance pour l'UX :** `isEvaluated == false` signifie « format
non reconnu », ce qui est **différent** d'une réponse fausse. Trois états
existent donc réellement : correct, faux, non évaluable. Prévoir un rendu
pour le troisième cas.

Tolérances de saisie : espaces, virgule décimale convertie en point.

### 2.4 Indices

| Besoin | API | Retour |
|---|---|---|
| Prochain indice | `service.nextHint(exercise, Set<int> consommés)` | `ExerciseHint?` |
| Rangs déjà vus | `AttemptRecord.trajectory.consumedOrders` | `Set<int>` |
| Historique ordonné | `service.hintHistoryOf(String attemptKey)` | `List<ConsumedHint>` |

`ExerciseHint` = `{ order: int, text: String, kind: String?, hintId: String }`.

> **Aucun indice n'est inventé.** Quand tous ceux de la banque sont
> consommés, `nextHint` renvoie `null` et le bouton doit disparaître.

### 2.5 Classification d'une tentative

```dart
enum AttemptClassification {
  autonomousSuccess,   // correct, aucun indice
  assistedSuccess,     // correct, APRÈS au moins un indice
  incorrect,           // faux, aucun indice
  assistedIncorrect,   // faux, après indice
  incomplete,          // vide, abandonné ou non évaluable
}
```

Déduite de la trajectoire, **jamais stockée**. Une réussite après indice ne
peut donc pas être affichée comme autonome : la garantie est structurelle.

### 2.6 Diagnostic — `diagnostic_case.dart` / `diagnostic_engine.dart`

```dart
DiagnosisOutcome service.diagnose({
  required AttemptObservation observation,  // Set<String> de FAITS
  required String failedExerciseId,
  int clarificationAlreadyAsked = 0,
});
```

`DiagnosisOutcome` contient : `observedFacts`, `caseIds`, `hypotheses`,
`intervention`, `followUp`, `staysOpen`, `clarificationQuestion`.

**Faits observables attendus en entrée** (chaînes exactes) :

| Fait | Déclenche |
|---|---|
| `soustraction_fausse` | D1 |
| `poursuit_apres_valeurs_egales` | D2 |
| `mauvais_couple_repris` | D3 |
| `arret_avec_reste_non_nul` | D4 |
| `pgcd_correct_ppcm_faux` | D5 |
| `confusion_pgcd_ppcm` | D6 |
| `reussite_apres_indice` | D7 |
| `reponse_correcte_sans_demarche` | D8 |

> **Ces faits ne sont produits par aucun code aujourd'hui.** Voir §5.1.

---

## 3. Ce qui manque — à arbitrer avant de concevoir

### 3.1 Contrat « type de réponse » — BLOQUANT pour S2

Le moteur **n'expose nulle part** si un exercice attend un entier ou un texte.
Il n'existe ni `AnswerType`, ni `inputType`, ni équivalent.

Conséquence directe : **l'interface ne peut pas choisir le clavier.** Elle ne
peut que le déduire indirectement des critères de correction
(`acceptedValues` non vide → numérique), ce qui est fragile : plusieurs
exercices acceptent à la fois une valeur et une expression.

| Exercice | `acceptedValues` | `acceptedExpressions` | Type déductible |
|---|---|---|---|
| 1 à 9 | oui | oui | **ambigu** |
| 10 | oui | oui | **ambigu** |
| 11 | non | oui | texte |

> **Décision attendue :** faut-il ajouter un champ `AnswerType` explicite au
> modèle ? C'est la correction la moins risquée : elle ne touche pas au
> contenu mathématique.

### 3.2 Contrat « retour pédagogique consolidé » — BLOQUANT pour S2

Aucun composant ne produit un objet « prêt à afficher ». Les cas A à E de la
spécification doivent être **composés par l'appelant** à partir de la
correction, de la trajectoire et du diagnostic.

C'est faisable sans modifier le moteur, mais la règle de sélection du cas
doit être décidée une fois pour toutes :

| Situation | Cas |
|---|---|
| correct, 0 indice | A |
| correct, ≥ 1 indice | B |
| faux, observations + intervention non vide | C |
| faux, diagnostic ouvert avec question | D |
| faux, aucune observation exploitable | E |

> **Point de conception à trancher :** le cas D exige un **titre de panneau**.
> La banque ne fournit que des **questions** d'intervention, jamais de titres
> de remédiation. Écrire « Reprenons cette étape. » serait inventer du contenu
> pédagogique non validé.

### 3.3 Contrat « répondre à une clarification » — ABSENT

`DiagnosisOutcome` produit une `clarificationQuestion` et
`clarificationOptions`, mais **rien ne permet d'y répondre ni de recevoir un
résultat mis à jour**. Le cas D ne peut donc pas se terminer.

> **Décision attendue :** construire un `submitClarification()` dans le moteur,
> ou assumer que le cas D reste informatif.

### 3.4 Brouillon de réponse — ABSENT

Aucun mécanisme ne sauvegarde une saisie en cours par identifiant d'exercice.
Le critère « retour puis retour en S2 restaure la saisie et les indices
consultés » n'est **pas** satisfiable en l'état.

> **Deux voies :** (a) état en mémoire dans le widget — ne survit pas à un
> changement d'écran ; (b) persistance via les événements existants —
> cohérent avec l'append-only, mais chaque brouillon entre dans
> l'historique pédagogique.

### 3.5 Rendu mathématique — ABSENT

`statement` est du texte brut contenant `a = 8`, `b = 12`, `÷`, `×`.
Aucun composant de rendu n'existe et la dépendance MathJax/KaTeX n'est pas
installée.

> **Décision attendue :**anitizeur minimal dans l'écran (remplacer `÷`, `×`,
> mettre `a = 8` en variables) ou introduction d'une vraie bibliothèque de
> rendu ? La seconde ajoute une dépendance et un temps de chargement.

### 3.6 Chaîne de progression S1 → S2

Rien ne relie une leçon à son premier exercice, ni un exercice à son suivant.
L'ordre existe dans la liste, mais il faut le parcourir explicitement.

---

## 4. Ce que le moteur ne fera pas — à ne pas contourner

| Interdit | Raison |
|---|---|
| Afficher `D1`…`D8` | codes internes, jamais destinés à l'élève |
| Afficher « confusion PGCD/PPCM » comme une certitude | ce sont des **hypothèses**, jamais des faits |
| Afficher un compteur de progression ou de maîtrise | **aucune donnée fiable** n'existe ; le schéma l'interdit explicitement |
| Proposer un indice supplémentaire | la banque n'en contient pas d'autre |
| Afficher « Tu maîtrises ce point » | interdit par la règle de séparation ; à reformuler par l'UX |
| Vérifier une réussite assistée | contredit la règle de progression de la banque |

`HypothesisConfidence` s'arrête à `indicated` : **aucune hypothèse n'est
confirmée**, et `DiagnosisOutcome.isUnresolved` indique si le diagnostic reste
ouvert.

---

## 5. Points techniques à connaître

### 5.1 Le moteur ne produit aucune observation

C'est la limite la plus importante. `AttemptObservation` est une classe
porteuse d'un `Set<String>`. **Aucun code ne construit ce `Set`** à partir
d'une réponse réelle : l'analyse du pas-à-pas (détecter une soustraction
fausse, un mauvais couple, un arrêt au mauvais moment) n'est pas implémentée.

**Conséquence pour l'UX :** tant que ce n'est pas fait, un échec produit
systématiquement le cas E (« pas d'information exploitable »). Les cas C et D
ne se produiront pas en conditions réelles.

### 5.2 Injection de dépendances

`Chapter1Service(LearningEventRepository, {Clock, DiagnosticEngine, idGenerator})`
— horloge et générateur d'ids injectables, donc **tests déterministes**. À
réutiliser pour les chapitres suivants.

### 5.3 Séquence d'appels d'une tentative

```dart
// 1. Identifier la tentative en cours
const attemptKey = 'tentative-1';

// 2. À chaque indice demandé (avant soumission)
await service.recordHintRequested(
  attemptKey: attemptKey, exercise: exercise, hintOrder: 1);

// 3. À la soumission
final record = await service.recordAttempt(
  exercise: exercise, rawAnswer: '6', attemptKey: attemptKey);

// 4. Relire l'état complet depuis la base
final reloaded = await service.findAttempt(record.eventId);
```

> **Contrainte à respecter :** `attemptKey` doit être générée **avant** la
> première consultation d'indice, car les indices sont enregistrés avant que
> l'identifiant définitif de la tentative n'existe.

### 5.4 Persistance

Tout passe par `LearningEventRepository` : **append-only, idempotent,
transactionnel**. L'historique ne peut être ni modifié ni supprimé. Un rejeu
ne crée pas de doublon. Aucune migration n'est nécessaire pour utiliser le
moteur.

### 5.5 État courant de l'application

`lib/app.dart` affiche un `HomePage` technique (deux compteurs). Il n'y a
**aucun écran d'exercice**. La navigation n'existe pas.

---

## 6. Résumé pour le designer

| Écran | Faisable aujourd'hui ? | Blocage |
|---|---|---|
| **S1** Accès au chapitre | ✅ Oui | titre « PGDC » à conserver tel quel |
| **S2** Énoncé + champ | ⚠️ Partiellement | **type de réponse inconnu** → clavier à trancher |
| **S2** Indices progressifs | ✅ Oui | ordre garanti, épuisement signalé |
| **S2** Retour A / B | ✅ Oui | composable sans modifier le moteur |
| **S2** Retour C | ⚠️ Théoriquement | aucun fait n'est produit en conditions réelles |
| **S2** Retour D | ❌ Non | pas de traitement de la clarification |
| **S2** Retour E | ✅ Oui | sera le cas le plus fréquent aujourd'hui |
| **S4** Vérification | ⚠️ Partiellement | pas de lien « tâche de suite » → exercice |
| **S2** Brouillon | ❌ Non | aucun mécanisme de sauvegarde |
| **Rendu mathématique** | ❌ Non | traitement à décider |

---

## 7. Arbitrages demandés avant conception

1. **Type de réponse** — ajouter un champ explicite au modèle, ou déduire ?
2. **Titre du cas D** — inventer un titre générique, ou l'ask au
   responsable pédagogique ?
3. **Clarification** — construire le contrat manquant, ou accepter que le cas D
   reste informatif ?
4. **Brouillon** — mémoire d'écran, ou persistance via les événements ?
5. **Rendu mathématique** — substitutions simples, ou bibliothèque de rendu ?
   L'énoncé contient `a = 8`, `b = 12`, `÷` : il faut décider si l'écran
   transforme ces caractères ou si une bibliothèque de rendu est introduite.
6. **« Tu maîtrises ce point »** — cette formulation contredit la règle de
   séparation des faits. Quelle reformulation adopter ?

Tant que ces six points ne sont pas tranchés, construire les écrans conduit
à inventer des données, ce que les règles du projet interdisent.
