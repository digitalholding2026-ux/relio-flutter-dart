# Rapport — Fiabiliser l'évaluation de la relation PPCM–PGCD

Cible : la tâche `ch1-verify-ppcm-10-15`.

**Périmètre respecté :** aucun écran, composant, navigation, style ni texte
d'interface modifié. Vérifié : `git status -- lib/presentation` est vide.

---

## 1. Le problème constaté

La tâche acceptait `30`, `(10*15)/5` et `150/5`. Répondre `30` suffisait
donc à réussir, alors que rien n'y démontrait la relation. Une réussite
pouvait être attribuée à la relation PPCM–PGCD sans la moindre trace de son
usage : c'est une sur-promission.

## 2. Fichiers du cœur modifiés

| Fichier | Nature |
|---|---|
| `lib/domain/curriculum/arithmetic_expression.dart` | **Nouveau** — évaluateur d'expressions arithmétiques sûr |
| `lib/domain/curriculum/exercise.dart` | + `PpcmRelation`, + `CorrectionCriterion.ppcmRelation` |
| `lib/domain/curriculum/chapter1_service.dart` | + `_correcterParRelation`, branche dédiée dans `correct()` |
| `lib/domain/curriculum/chapter1_bank.dart` | contrat posé sur `verify-ppcm-10-15` uniquement |
| `lib/domain/curriculum/transfer_verification.dart` | + `TransferEvidence.relationApplied`, + `provesRelation` |
| `test/curriculum/ppcm_relation_contract_test.dart` | **Nouveau** — 30 tests |

Trois tests existants ont été **réécrits, pas affaiblis** : ils encodaient
l'ancien contrat (`30` accepté). Chacun vérifie aujourd'hui la même valeur
attendue sous le nouveau contrat, et le motif du changement est écrit dans
le test.

## 3. Le nouveau contrat

`PpcmRelation` porte les données de la relation et se vérifie lui-même
(`isCoherent`). La correction a **quatre issues distinctes** :

| Réponse écrite | Issue | Raison |
|---|---|---|
| `30` | **non évaluable** | le résultat sans démonstration ne prouve rien ; ce n'est pas un échec |
| `6*5` | **non évaluable** | juste arithmétiquement, mais ne montre pas la relation |
| `10*15/5` | **réussite** | division écrite, valeur correcte |
| `10*15/6` | **échec évaluable** | calcul cohérent, résultat faux : c'est un fait |
| `10*15/5 = 25` | **échec évaluable** | le calcul est juste, le résultat annoncé ne l'est pas |
| `je ne sais pas` | **non évaluable** | écriture incompréhensible |

**L'évaluateur calcule au lieu de comparer à une liste.** C'est ce qui
permet d'accepter `150/5`, `300/10`, `15*10/5`, `(10*15)/5`, `10 × 15 / 5`
sans les énumérer, tout en refusant un nombre seul.

## 4. Formes acceptées et refusées

**Acceptées** — toutes comportent une division et valent 30 :
`10*15/5`, `(10*15)/5`, `((10*15))/5`, `150/5`, `300/10`, `15*10/5`,
`10*15÷5`, `150 ÷ 5`, `10 × 15 / 5`, `(10*15)/5*1`, `10*15/5 = 30`,
`150/5 = 30`.

**Refusées** :

| Forme | Issue | Pourquoi |
|---|---|---|
| `30`, ` 30 `, `030` | non évaluable | nombre seul |
| `6*5`, `5*6` | non évaluable | pas de division |
| `10*15/6`, `20*15/5` | échec | calcul faux, bien écrit |
| `5/(10*15)` | échec | division inversée — l'erreur de D5 |
| `10*15/5 = 25` | échec | résultat annoncé faux |
| `10x15/5` | non évaluable | `x` n'est **pas** un signe ici ; le moteur ne devine pas |
| `je ne sais pas`, `??`, `abc` | non évaluable | incompréhensible |

## 5. Confirmation : `30` seul ne suffit plus

Trois tests l'affirment explicitement : `30`, ` 30 ` et `030` sont
`isCorrect == false` **et** `isEvaluated == false`. Le résultat correct
n'est plus qualifié de réussite, mais il n'est pas non plus traité comme une
erreur de l'élève.

## 6. Résultats réels

```
flutter analyze   → No issues found!    (5,0 s)
flutter test      → 00:22 +362: All tests passed!
```

**362 tests** (332 avant, +30 nouveaux). Aucun test supprimé. Les quatre
tests qui encodaient l'ancien contrat ont été réécrits, et non affaiblis.

## 7. Décision sur l'association de transfert

**L'association exercice 8 → `verify-ppcm-10-15` reste INACTIVE.**

La condition technique posée par la mission est désormais **remplie** :
`profileOf(...)` renvoie `relationApplied` et `provesRelation == true`. Un
test le verrouille.

Mais deux raisons de ne pas l'activer sans feu vert :

1. La tâche reste, dans le document validé, le **contrôle du cas D5**, dont
   le fait déclencheur est `pgcd_correct_ppcm_faux`. La détourner vers le
   parcours nominal lui retire son sens d'origine.
2. Une réussite démontre l'**application écrite** de la relation, pas la
   méthode de raisonnement. `provesMethod` reste `false`.

L'activation est une ligne de donnée (`followUpTask`) : elle ne demande
aucun développement.

## 8. Défaut trouvé au passage

La tâche disposait d'un clavier **numérique**, déduit de `acceptedValues`
non vide. Or il était impossible d'y taper une formule : **la tâche était
littéralement non riusable**. Le nouveau contrat vide `acceptedValues`, donc
le type de réponse devient `text` et le clavier devient alphanumérique —
**automatiquement**, par la règle déjà en place. Aucun fichier d'interface
n'a été touché.

C'est un cas concret qui justifie la décision prise en mission de fiabilisation
de dériver le clavier du critère de correction plutôt que de la position dans
la banque.

## 9. Limites restantes

- **Le `x` de multiplication n'est pas reconnu.** `10x15/5` est non
  évaluable. L'accepter créerait un risque de confusion avec une lettre ;
  le refus vaut mieux qu'une interprétation.
- **Pas de virgule décimale, pas de priorités implicites ex Beyond :**
  seuls `+ − * / × ÷ ( )` sont compris, plus un `=` final.
- **Ce qui est vérifié est l'écrit, pas le raisonnement.** Un élève peut
  écrire `150/5` sans avoir compris. Le contrat exige une **démonstration**,
  pas une preuve d'intelligence.
- **`AnswerOutcome.abandoned` reste produit par personne** : inchangé,
  documenté.
- **Aucune validation sur appareil réel** : aucun téléphone ni émulateur.

## 10. Contrat de données minimal pour la suite

Si la méthode devait un jour être vérifiée — et non plus seulement la
relation écrite — il faudrait, côté interface (hors périmètre ici) :

1. une saisie en plusieurs champs (opérandes et opération), ou une liste
   d'étapes ;
2. un événement portant ces étapes, actuellement inexistant au schéma.

`Exercise.expectedSteps` existe déjà côté modèle, mais rien ne le reçoit :
c'est aujourd'hui une description, pas une collecte.