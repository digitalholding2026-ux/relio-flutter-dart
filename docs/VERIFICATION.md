# Vérification de transfert — modèle et associations manquantes

**Objet :** pourquoi l'écran S4 (« Vérifier ma maîtrise ») reste fermé, ce
qu'il faudrait pour l'ouvrir, et ce qui doit être décidé par le responsable
pédagogique avant de le faire.

Ce document ne décrit pas une fonctionnalité. Il décrit une **décision en
attente**, et les données qui la bloquent.

---

## 1. La règle, fixée dès aujourd'hui

Le code de `lib/domain/curriculum/transfer_verification.dart` applique déjà
les conditions d'affichage. Elles sont cumulatives, et vérifiées dans cet
ordre :

| Ordre | Condition | Sinon |
|---|---|---|
| 1 | La tentative a **réussi** | refus : `notSuccessful` |
| 2 | La réussite est **autonome** (aucun indice consulté) | refus : `notAutonomous` |
| 3 | Une **tâche de vérification** est associée à l'exercice | refus : `noLinkedTask` |

Deux consequences non négociables :

- **Une réussite obtenue avec un indice ne peut jamais ouvrir S4.** Le
  classement `assistedSuccess` est déduit de la trajectoire des indices, il
  n'est pas stocké : la garantie est structurelle, pas une convention
  d'écran.
- **Une réussite sur un seul exercice ne authorizes aucune conclusion
  générale.** S4 porterait sur une tâche de contrôle distincte, jamais sur
  le chapitre entier.

## 2. Pourquoi S4 est fermé aujourd'hui

`TransferVerification.taskFor` lit le champ `followUpTask` de la banque, et
ne l'accepte que si la cible est de nature `verificationTask`.

**Or, dans la banque actuelle, aucune cible ne l'est.** État vérifié :

| Exercice | `followUpTask` | Nature de la cible |
|---|---|---|
| `ch1-ex-2-...` | `ch1-ex-4-...` | exercice du parcours |
| `ch1-ex-7-...` | `ch1-ex-4-...` | exercice du parcours |
| `ch1-ex-9-...` | `ch1-ex-8-...` | exercice du parcours |

Les six tâches de vérification existent, mais ne sont rattachées qu'aux cas
de diagnostic :

| Cas | Tâche de contrôle |
|---|---|
| D1 | `ch1-verify-pgcd-16-12` |
| D2 | `ch1-verify-pgcd-14-7` |
| D3 | `ch1-verify-pgcd-24-16` |
| D4 | `ch1-verify-pgcd-35-20` |
| D5 | `ch1-verify-ppcm-10-15` |
| D6 | `ch1-verify-ppcm-6-8` |

Or ces cas ne se déclenchent qu'avec des observations que l'interface ne
produit pas (voir `AUDIT_MOTEUR.md`, § 5.1, et le § 4 ci-dessous). Le
parcours nominal n'atteint donc **jamais** une tâche de contrôle.

## 3. Associations candidates — À VALIDER

Les six lignes ci-dessous sont des **candidats proposés pour arbitrage**, pas
des associations. Aucune n'est implémentée. Les rattacher automatiquement
serait précisément ce que la mission interdit : deux éléments qui
« concernent le même chapitre » ne sont pas, par cela, une paire de
vérification.

| Exercice | Tâche candidate | Argument possible | Ce qu'il faudrait confirmer |
|---|---|---|---|
| `ex1` PGCD(18,12) soustractions | `verifyPgcd16And12` | même méthode, couple différent | le contrôle de D1 vaut-il aussi pour l'exercice guidé ? |
| `ex2` PGCD(15,10) soustractions | `verifyPgcd14And7` | critère d'arrêt isolé (D2) | pertinent seulement si l'élève maîtrise le critère d'arrêt |
| `ex4` PGCD(20,12) soustractions | `verifyPgcd24And16` | contrôle après remediations D1/D3 | le « quelques exercices plus tard » de l'énoncé est-il une temporalité de contrôle ? |
| `ex5` PGCD(30,18) Euclide | `verifyPgcd35And20` | contrôle de l'algorithme (D4) | quel moment du parcours ? |
| `ex6` PGCD(42,30) Euclide | `verifyPpcm6And8` | — | aucun argument : ne pas rattacher |
| `ex8` PPCM(12,18) | `verifyPpcm10And15` | relation PPCM/PGCD isolée (D5) | le contrôle porte-t-il sur l'isolement ou sur la distinction des notions ? |

**Règle retenue :** tant que ces six lignes ne sont pas validées une à une,
`taskFor` renvoie `null` et S4 reste fermé. Aucune ligne de code ne devra
être écrite le jour de la validation : la règle lira la donnée et
s'ouvrira d'elle-même.

## 4. Pourquoi les observations manquent toujours

| Observation attendue | Produced ? | Raison |
|---|---|---|
| `reussite_apres_indice` | ✅ oui | déduite de la trajectoire des indices |
| `soustraction_fausse` | ❌ non | exigerait le pas-à-pas ; l'élève ne saisit qu'un résultat final |
| `poursuit_apres_valeurs_egales` | ❌ non | idem |
| `mauvais_couple_repris` | ❌ non | idem |
| `arret_avec_reste_non_nul` | ❌ non | idem |
| `pgcd_correct_ppcm_faux` | ❌ non | exigerait deux réponses distinctes sur un même couple |
| `confusion_pgcd_ppcm` | ❌ non | exigerait le nommage explicite des deux notions |
| `reponse_correcte_sans_demarche` | ❌ non | l'interface ne capture aucune démarche |

`lib/domain/curriculum/observation_collector.dart` ne produit que le premier
fait. C'est délibéré : `PGCD(18, 12) = 6` est vrai, mais le chemin qui y mène
peut être juste ou faux, et **les données ne le distinguent pas**. En déduire
une cause serait inventer le raisonnement de l'élève.

## 5. Ce qu'il faudrait pour ouvrir S4

1. **Valider les associations du § 3** — décision pédagogique.
2. **Ajouter `followUpTask` pointant sur une tâche de contrôle** dans
   `chapter1_bank.dart` — transcription du document validé.
3. **Décider le comportement en cas d'échec de la tâche de contrôle** :
   quelle consolidation proposer, et avec quel contenu ? La banque ne
   fournit aujourd'hui que des questions d'intervention, jamais de contenu
   de remédiation.
4. **Définir le résultat indéterminé et l'erreur technique** : dans ces deux
   cas, aucun panneau pédagogique ne doit s'afficher, au même titre qu'en S2.

Aucune de ces quatre étapes n'est du ressort du code seul.