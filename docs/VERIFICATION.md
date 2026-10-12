# Vérification de transfert — modèle, état et décisions en attente

**Objet :** où en est la logique métier de la vérification de transfert du
chapitre 1, ce qui est activé, ce qui ne l'est pas, et ce qu'il faut trancher.

Périmètre : moteur pédagogique, banque, associations, règles de
déclenchement, traitement des résultats. L'interface n'est pas traitée ici.

---

## 1. Les règles de déclenchement

Écrites dans `lib/domain/curriculum/transfer_verification.dart`, cumulatives,
vérifiées dans cet ordre :

| Ordre | Condition | Motif de refus |
|---|---|---|
| 1 | La tentative a **réussi** | `notSuccessful` |
| 2 | La réussite est **autonome** (aucun indice) | `notAutonomous` |
| 3 | Une **tâche de vérification** est liée à l'exercice | `noLinkedTask` |

- Une réussite **avec aide** reste un progrès accompagné. Elle n'ouvre
  jamais la vérification : la classification est déduite de la trajectoire
  des indices, donc recalculée au rechargement, jamais stockée.
- **Aucune réussite, même autonome, ne conclut à une maîtrise générale.**
  Une tâche porte sur un couple, pas sur une leçon.

## 2. Associations — une active sur trois

Les trois associations proposées par le fondateur ont été confrontées au
**contenu réel** des tâches cibles. Résultat :

| | Association | Décision |
|---|---|---|
| **A** | ex1 `PGCD(18,12)` → `PGCD(16,12)` par soustractions | ✅ **ACTIVÉE** |
| **B** | ex5 `PGCD(30,18)` Euclide → `PGCD(35,20)` | ❌ **INACTIVE** |
| **C** | ex8 `PPCM(12,18)` → `PPCM de 10 et 15, PGCD 5` | ❌ **INACTIVE** |

### A — activée

L'exercice 1 demande le PGCD par soustractions successives ; la tâche cible
annonce « PGCD(16, 12) **par soustractions successives** », porte sur un
**couple différent**, est de même leçon, et sa correction compare la valeur
attendue (PGCD(16,12) = 4, vérifié arithmétiquement). Elle est
autonome : elle ne dépend d'aucun diagnostic.

### B — inactive : la méthode n'est pas vérifiable

Deux raisons, cumulatives :

1. **L'énoncé ne demande pas la méthode.** Il dit « PGCD(35, 20) », sans
   mention d'Euclide. Répondre `5` ne prouve aucune procédure.
2. **La tâche a un autre sens dans le document validé.** Elle est le contrôle
   du cas **D4**, déclenché par le fait `arret_avec_reste_non_nul` — un
   problème de **critère d'arrêt**, pas un transfert de méthode.

### C — la relation est désormais vérifiée, association inactive

La tâche porte un contrat `PpcmRelation` : `acceptedValues` est vide, donc
`30` seul n'est plus accepté. Un calcul écrit comportant la division est
exigé, évalué, et doit donner 30. Détail dans
`RAPPORT_PPCM_RELATION.md`.

`TransferEvidence.relationApplied` et `provesRelation == true` le confirment
au moteur.

L'**association reste inactive** : la condition technique est remplie, mais
son activation est une décision pédagogique du fondateur, pas une conséquence
du code.

## 3. Ce que l'évaluateur contrôle réellement

`TransferCheckProfile` expose deux faits, sans interprétation :

| Propriété | Valeur | Lecture |
|---|---|---|
| `scope` | `finalValueOnly` | seule la valeur finale est comparée |
| `methodIsEvaluable` | **toujours `false`** | la méthode n'est jamais contrôlée |

**Pourquoi la méthode n'est pas vérifiable.** Le modèle contient
`Exercise.expectedSteps`, mais ce sont des étapes **attendues**, pas
**recueillies** : l'élève ne saisit qu'un résultat final. `PGCD(35,20) = 5`
est vrai que l'élève ait utilisé Euclide, énuméré les diviseurs, ou deviné.
Affirmer « la méthode est vérifiée » serait attribuer au moteur une capacité
qu'il n'a pas.

## 4. Traitement du résultat

`TransferOutcomePolicy.assess` sépare quatre issues **disjointes** :

| Issue | Signification | Conclusion pédagogique |
|---|---|---|
| `success` | réponse conforme | oui, sur la tâche observée |
| `evaluableFailure` | évaluée et non conforme | oui |
| `indeterminate` | non évaluable, ou abandon | **non** |
| `technicalError` | évaluation impossible | **non** |

`indeterminate` et `technicalError` ne produisent **ni conclusion, ni
remédiation, ni vérification de remplacement**. Une erreur technique ne
sername jamais de difficulté pédagogique.

## 5. Après un échec

`TransferRecovery` :

| Situation | Choix | Contenu |
|---|---|---|
| Un fait étaye une difficulté **et** la banque fournit la consolidation | `targetedConsolidation` | *inatteignable aujourd'hui* |
| Sinon | `guidedReview` | *aucun* |

La consolidation ciblée est **écrite mais inatteignable** : aucune
observation du parcours nominal n'identifie une difficulté (voir § 6), et
aucune activité de remédiation n'existe dans la banque. Les deux conditions
ne sont réunies ni l'une ni l'autre.

`nextVerification` est également `null` : aucune tâche distincte n'est
déclarée. Refaire la tâche échouée ne serait pas une seconde vérification.

## 6. Observations toujours non produites

`observation_collector.dart` ne produit que `reussite_apres_indice`, et
uniquement sur une **réussite**. Aucune des sept autres n'est déductible
d'un résultat final seul :

`soustraction_fausse`, `poursuit_apres_valeurs_egales`,
`mauvais_couple_repris`, `arret_avec_reste_non_nul`,
`pgcd_correct_ppcm_faux`, `confusion_pgcd_ppcm`,
`reponse_correcte_sans_demarche`.

## 7. Contenus et décisions encore nécessaires

Classés par taille d'extension, du plus petit au plus grand.

### 7.1 Pour activer B — vérifier la méthode (3 paliers)

1. **Le plus petit** : reformuler l'énoncé de la tâche pour qu'il **exige**
   les divisions euclidiennes, et accepter les divisions comme réponses.
   *Ne contrôle toujours pas la méthode réellement employée.*
2. **Intermédiaire** : autoriser une réponse en deux lignes
   (`35=20x1+15 ; 15=5x3+0`) via `acceptedExpressions`. *Contrôle une
   trace écrite, pas le raisonnement.*
3. **Le seul complet** : capter le raisonnement (liste d'étapes) et le
   comparer à `expectedSteps`. * Nécessite une interface de saisie — hors
   périmètre de cette mission.*

### 7.2 Pour activer C — FAIT sur le plan technique

La valeur seule ne suffit plus : le contrat `PpcmRelation` exige un calcul
écrit comportant la division, et l'évaluateur le calcule. **Reste à
décider** si l'association exercice 8 → cette tâche est activée, compte
tenu du fait qu'elle reste le contrôle du cas **D5**
(`pgcd_correct_ppcm_faux`).

### 7.3 Pour une consolidation ciblée

Trois éléments manquent, dans cet ordre : un **type de difficulté**,
une **activité de consolidation**, une **tâche de vérification distincte**.
Aucun n'existe dans la banque. Le moteur signale
`MissingContent.consolidationActivity` et
`MissingContent.distinctVerificationTask` plutôt que de combler le vide.

### 7.4 Fait relevé au passage

`recordAttempt` ne produit jamais `AnswerOutcome.abandoned` : une soumission
vide est évaluée, donc classée `incorrect`. Seule l'interface empêche
ce cas d'arriver. La branche `abandoned` de `assess` reste donc défensive.