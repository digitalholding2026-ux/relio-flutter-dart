# Rapport de fin — Cœur de la vérification de transfert, chapitre 1

**Périmètre :** moteur pédagogique, banque, associations, règles de
déclenchement, traitement des résultats, tests.

**Hors périmètre, respecté :** écrans, composants visuels, navigation,
textes d'interface. Aucune ligne de présentation n'a été modifiée.

Ce document est le **rapport de mission**. L'état technique de référence
reste dans [`VERIFICATION.md`](VERIFICATION.md) ; ce rapport dit ce qui a
été fait, ce qui a été refusé, et ce qui reste à décider.

---

## 1. Résumé

Sur les trois associations proposées par le fondateur, **une a été activée
et deux ont été laissées inactives**, après confrontation au contenu réel
des tâches cibles. Les conditions impératives posées pour les associations B
et C n'étaient pas réunies : ni la méthode d'Euclide, ni la relation
PPCM–PGCD ne sont vérifiables par l'évaluateur actuel.

Le moteur a été complété pour que l'interface **ne puisse pas sur-promettre** :
ce que la vérification contrôle réellement est désormais exposé par le moteur,
et les quatre issues d'un résultat sont distinguées sans recoupement.

| | Avant | Après |
|---|---|---|
| Associations actives | 0 | **1** (exercice 1) |
| Associations évaluées et motivées | 0 | **3** |
| Issues de résultat distinguées | 1 (booléen) | **4** |
| Tests | 273 | **317** |

---

## 2. Fichiers du cœur modifiés

| Fichier | Nature |
|---|---|
| `lib/domain/curriculum/chapter1_bank.dart` | Association A déclarée via le `followUpTask` existant |
| `lib/domain/curriculum/transfer_verification.dart` | `TransferEvidence`, `TransferCheckProfile`, `kTransferMethodIsEvaluable`, `profileOf` |
| `lib/domain/curriculum/transfer_outcome.dart` | **Nouveau** — 4 issues, `TransferRecovery`, `RecoveryKind`, `MissingContent` |
| `test/curriculum/transfer_core_test.dart` | **Nouveau** — 44 tests |
| `test/curriculum/transfer_and_observations_test.dart` | Adapté à l'association activée |
| `docs/VERIFICATION.md`, `docs/BUILD.md`, `AGENTS.md` | Documentation |

**Aucune migration de base de données.** Aucun schéma touché :
`kSchemaVersion` est inchangé.

---

## 3. Association A — activée

**Exercice 1 `PGCD(18, 12)` → `PGCD(16, 12)` par soustractions.**

Cinq critères vérifiés par test automatisé :

1. la tâche existe et est de nature `verificationTask` ;
2. elle évalue le **calcul** du PGCD (PGCD(16,12) = 4, vérifié
   arithmétiquement) ;
3. sa méthode attendue correspond : l'énoncé dit « **par souctions
   successives** », comme l'exercice source ;
4. elle porte sur un **couple différent** — sans quoi il n'y aurait aucun
   transfert à vérifier ;
5. elle est **autonome** : aucun diagnostic n'est requis pour l'atteindre.

---

## 4. Associations B et C — laissées inactives

### B — Exercice 5 (Euclide) → `PGCD(35, 20)`

Deux raisons **cumulatives** :

1. **L'énoncé ne demande pas la méthode.** Il dit « PGCD(35, 20) », sans
   mention d'Euclide. Répondre `5` ne prouve aucune procédure : le résultat
   est vrai quelle que soit la méthode employée, y compris un devinette.
2. **La tâche a un autre sens dans le document validé.** Elle est le contrôle
   du cas **D4**, déclenché par le fait `arret_avec_reste_non_nul` — une
   difficulté de **critère d'arrêt**, pas un transfert de méthode.

### C — Exercice 8 → `PPCM de 10 et 15, avec PGCD 5`

La tâche accepte `30`, `(10*15)/5` **et** `150/5`. La relation est donc
*acceptée*, jamais *exigée* : un élève qui écrit seulement `30` passe.
Présenter cela comme une vérification de « l'utilisation de la relation »
serait une sur-promission. C'est aussi le contrôle du cas **D5**.

> Dans les deux cas, la règle générale a été respectée : on n'a pas associé
> deux éléments « parce qu'ils sont du même chapitre », et on n'a pas
> modifié les énoncés ni les titres pour forcer la correspondance.

---

## 5. Règles de déclenchement

Implémentées dans `transfer_verification.dart`, cumulatives, dans cet ordre :

| Ordre | Condition | Motif de refus |
|---|---|---|
| 1 | La tentative a réussi | `notSuccessful` |
| 2 | La réussite est autonome | `notAutonomous` |
| 3 | Une tâche de vérification est liée | `noLinkedTask` |

Les trois motifs existants ont été **conservés tels quels**.

- Une réussite **avec aide** reste un progrès accompagné : elle n'ouvre
  jamais la vérification.
- Aucune réussite, même autonome, ne conclut à une maîtrise générale : une
  tâche porte sur un couple, pas sur une leçon.

**Après rechargement SQLite**, la classification est recalculée depuis les
événements d'indices persistés — jamais relue depuis un état stocké. Un test
spécifique le vérifie dans les deux sens (assistée → non autonome, autonome
→ déclenchement).

---

## 6. Traitement du résultat — quatre issues disjointes

`TransferOutcomePolicy.assess` distingue :

| Issue | Signification | Conclusion pédagogique | Remédiation |
|---|---|---|---|
| `success` | réponse conforme | oui, sur la tâche observée | non applicable |
| `evaluableFailure` | évaluée, non conforme | oui | propose une reprise |
| `indeterminate` | non évaluable, ou abandon | **non** | **jamais** |
| `technicalError` | évaluation impossible | **non** | **jamais** |

Une erreur technique ne devient jamais une difficulté pédagogique : elle ne
produit ni verdict, ni remédiation, ni vérification de remplacement. Un test
vérifie que les quatre issues sont **toutes distinctes**.

---

## 7. Après un échec

| Situation | Choix | Contenu |
|---|---|---|
| Un fait étaye une difficulté **et** la banque fournit la consolidation | `targetedConsolidation` | *inatteignable aujourd'hui* |
| Sinon | `guidedReview` | *aucun* |

**La consolidation ciblée est écrite mais inatteignable.** Aucune des deux
conditions n'est remplie : aucune observation du parcours nominal
n'identifie une difficulté, et la banque ne contient aucune activité de
remédiation. La branche est écrite dans sa forme finale pour que l'ajout
d'un contenu validé soit une ligne de donnée, pas une refonte.

`nextVerification` vaut `null` : aucune tâche distincte n'est déclarée. Refaire
la tâche qui vient d'échouer ne serait pas une seconde vérification.

---

## 8. Limites d'évaluation qui subsistent

**La méthode de résolution n'est vérifiable nulle part.**
`kTransferMethodIsEvaluable` vaut `false` pour toute la banque.

Raison : le modèle contient `Exercise.expectedSteps`, mais ce sont des étapes
**attendues**, pas **recueillies**. L'élève ne saisit qu'un résultat final.
Conclure « la méthode est vérifiée » attribuerait au moteur une capacité
qu'il n'a pas, et affirmerait une procédure jamais observée.

Le moteur expose désormais ce fait (`TransferCheckProfile`), afin qu'aucune
couche supérieure ne puisse annoncer une vérification de méthode.

**Observations toujours non produites.** Une seule observation est
productible, `reussite_apres_indice`, et uniquement sur une réussite. Les
sept autres exigent le raisonnement intermédiaire :

`soustraction_fausse`, `poursuit_apres_valeurs_egales`,
`mauvais_couple_repris`, `arret_avec_reste_non_nul`,
`pgcd_correct_ppcm_faux`, `confusion_pgcd_ppcm`,
`reponse_correcte_sans_demarche`.

**Fait relevé au passage.** `recordAttempt` ne produit jamais
`AnswerOutcome.abandoned` : une soumission vide est évaluée, donc classée
`incorrect`. Seule l'interface empêche ce cas d'arriver ; la branche
correspondante reste donc défensive. Signalé, non modifié — la classification
relève des règles de gestion d'erreur.

---

## 9. Tests

Commandes réellement exécutées :

```
flutter analyze   → No issues found!          (5,7 s)
flutter test      → 00:23 +317: All tests passed!
```

**44 tests nouveaux** (`transfer_core_test.dart`), couvrant les 13 points
d'acceptation :

1. réussite autonome + tâche associée → déclenchement ;
2. réussite avec aide → pas de déclenchement ;
3. exercice échoué → pas de déclenchement ;
4. association absente ou invalide → pas de déclenchement ;
5. les trois associations confrontées au contenu réel avant activation ;
6. un autre couple ne prouve pas la méthode si l'évaluateur ne la contrôle pas ;
7. la tâche PPCM ne prétend vérifier la relation que si elle le fait ;
8. consolidation ciblée uniquement si la difficulté est étayée ;
9. difficulté inconnue → reprise guidée sans diagnostic affirmatif ;
10. indéterminé / erreur technique → aucune conclusion ;
11. nouvelle vérification distincte de la tâche initiale ;
12. classification correcte après rechargement SQLite ;
13. aucun doublon d'événement, tests existants verts.

Les **273 tests préexistants restent verts**. Aucun test n'a été supprimé.

> Un test a d'abord échoué puis a été corrigé : la classification assistée
> ne survit au rechargement que si l'indice a réellement été consigné comme
> événement. Le test utilisait `hintOrders` sans cela et obtenait
> `autonomousSuccess`. Il utilise désormais le flux réel de l'application.

---

## 10. Décisions pédagogiques encore nécessaires

Classées par taille d'extension.

### 10.1 Activer B — vérifier la méthode, trois paliers

1. **Le plus petit** : reformuler l'énoncé pour qu'il **exige** les
   divisions euclidiennes. *Ne vérifie toujours pas la méthode employée.*
2. **Intermédiaire** : accepter une réponse en deux lignes
   (`35=20x1+15 ; 15=5x3+0`). *Contrôle une trace écrite, pas le
   raisonnement.*
3. **Le seul complet** : capter le raisonnement et le comparer à
   `expectedSteps`. *Nécessite une interface de saisie — hors périmètre.*

### 10.2 Activer C — vérifier la relation

Modifier le critère de `verify-ppcm-10-15` pour que la valeur seule ne
suffise plus. **Impact assumé : `30` seul deviendrait refusé.**

### 10.3 Consolidation

Trois éléments manquent, dans cet ordre : un **type de difficulté**, une
**activité de consolidation**, une **tâche de vérification distincte**.

Le moteur signale `MissingContent.consolidationActivity` et
`MissingContent.distinctVerificationTask` plutôt que de combler le vide.

---

## 11. Portée de ce build

**L'écran S4 reste fermé.** Cette mission pose la logique métier ; son
affichage relève de l'interface. La règle et les profils sont donc exposés
au moteur sans qu'aucun écran soit modifié : une interface qui lirait
`TransferCheckProfile.provesMethod == false` ne pourra pas annoncer que la
méthode a été vérifiée.

Aucun contenu mathématique n'a été modifié. « PGDC » est conservé tel quel.