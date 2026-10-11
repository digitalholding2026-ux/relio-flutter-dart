# Les 11 objets `Exercise` intégrés — chapitre 1 « Arithmétique »

Extraction **directe depuis le code** (`lib/domain/curriculum/chapter1_bank.dart`),
produite par exécution réelle et non par relecture.

Commit de référence : `bf1dc5b`.

> Rappel : `acceptedValues` liste les **nombres entiers** acceptés ;
> `acceptedExpressions` liste les **chaînes** acceptées après normalisation
> (minuscules, espaces réduits, `*` → `×`). Les deux sont OR entre eux.

---

## Vue d'ensemble

| # | Identifiant | Leçon | Valeur attendue | Indices | Suivi |
|---|---|---|---|---|---|
| 1 | `ch1-ex-1-pgcd-soustractions-guide` | `lecon-1` | `6` | **2** | — |
| 2 | `ch1-ex-2-pgcd-soustractions-autonome` | `lecon-1` | `5` | 0 | `ch1-ex-4-…` |
| 3 | `ch1-ex-3-pgcd-soustractions-transfert` | `lecon-1` | `7` | 0 | — |
| 4 | `ch1-ex-4-pgcd-soustractions-verification` | `lecon-1` | `4` | 0 | — |
| 5 | `ch1-ex-5-euclide-guide` | `lecon-2` | `6` | **2** | — |
| 6 | `ch1-ex-6-euclide-autonome` | `lecon-2` | `6` | 0 | — |
| 7 | `ch1-ex-7-euclide-transfert-comparaison` | `lecon-2` | `6` | 0 | `ch1-ex-4-…` |
| 8 | `ch1-ex-8-ppcm-pgcd-application` | `lecon-3` | `36` | 0 | — |
| 9 | `ch1-ex-9-ppcm-isoler-inconnue` | `lecon-3` | `24` | 0 | `ch1-ex-8-…` |
| 10 | `ch1-ex-10-verification-relation` | `lecon-3` | `135` | 0 | — |
| 11 | `ch1-ex-11-choix-de-methode` | `lecon-3` | *(texte)* | 0 | — |

**Répartition :** leçon 1 → 4, leçon 2 → 3, leçon 3 → 4.

**Seuls 2 exercices sur 11 ont des indices** (n° 1 et 5). Pour les 9 autres,
le bouton « Demander un indice » n'a rien à afficher : `nextHint()` renvoie
`null` dès le premier appel. Ce n'est pas un défaut du moteur, c'est ce que
contient la banque.

---

## Leçon 1 — `PGCD : algorithme des soustractions`

### 1 · `ch1-ex-1-pgcd-soustractions-guide`

- **Énoncé :** Calcule le PGCD de 18 et 12 avec des soustractions successives.
- **Validation :** `acceptedValues: [6]` · `acceptedExpressions: ['6']`
- **Drapeaux :** `expectsJustification: false` · `expectsComparison: false`
- **Correction :** `PGCD(18, 12) = 6`
- **Étapes attendues (3) :**
  - `[operation]` 18 − 12 = 6
  - `[operation]` 12 − 6 = 6
  - `[finalResult]` PGCD(18, 12) = 6
- **Indices (2) :**
  - `#1` (methode) Soustrais le plus petit nombre du plus grand.
  - `#2` (methode) Après 18 − 12, travaille avec 12 et 6.
- **Compréhension :** « À quel moment t'arrêtes-tu ? »
  → *Lorsque les deux nombres sont égaux ; cette valeur est le PGCD.*
- **Suivi :** `null` — **Diagnostics :** `[]`

### 2 · `ch1-ex-2-pgcd-soustractions-autonome`

- **Énoncé :** Calcule le PGCD de 15 et 10 par soustractions successives.
- **Validation :** `acceptedValues: [5]` · `acceptedExpressions: ['5']`
- **Correction :** `(15,10) → (10,5) → (5,5), donc PGCD = 5.`
- **Étapes attendues (2) :**
  - `[intermediatePair]` (15, 10) → (10, 5)
  - `[finalResult]` PGCD = 5
- **Indices :** aucun — **Compréhension :** aucune
- **Suivi :** `ch1-ex-4-pgcd-soustractions-verification`
- **Diagnostics :** `[D1, D2]`

### 3 · `ch1-ex-3-pgcd-soustractions-transfert`

- **Énoncé :** Calcule le PGCD de 21 et 14 avec la même méthode, puis explique comment tu sais que tu peux t'arrêter.
- **Validation :** `acceptedValues: [7]` · `acceptedExpressions: ['7']`
- **Drapeaux :** `expectsJustification: **true**`
- **Correction :** `(21,14) → (14,7) → (7,7), donc PGCD = 7.`
- **Étapes attendues (2) :**
  - `[intermediatePair]` (21, 14) → (14, 7)
  - `[finalResult]` PGCD = 7
- **Indices :** aucun — **Suivi :** `null` — **Diagnostics :** `[]`

### 4 · `ch1-ex-4-pgcd-soustractions-verification`

- **Énoncé :** Quelques exercices plus tard, calcule le PGCD de 20 et 12 par soustractions successives.
- **Validation :** `acceptedValues: [4]` · `acceptedExpressions: ['4']`
- **Correction :** `(20,12) → (12,8) → (8,4) → (4,4), donc PGCD = 4.`
- **Étapes attendues (3) :**
  - `[intermediatePair]` (20, 12) → (12, 8)
  - `[intermediatePair]` (12, 8) → (8, 4)
  - `[finalResult]` PGCD = 4
- **Indices :** aucun — **Suivi :** `null` — **Diagnostics :** `[]`

---

## Leçon 2 — `« PGDC » : algorithme d'Euclide`

> Intitulé **conservé tel quel**, y compris « PGDC ». Ne pas corriger.

### 5 · `ch1-ex-5-euclide-guide`

- **Énoncé :** Calcule le PGCD de 30 et 18 avec l'algorithme d'Euclide.
- **Validation :** `acceptedValues: [6]` · `acceptedExpressions: ['6']`
- **Correction :** `PGCD = 6`
- **Étapes attendues (4) :**
  - `[operation]` 30 = 18 × 1 + 12
  - `[operation]` 18 = 12 × 1 + 6
  - `[operation]` 12 = 6 × 2 + 0
  - `[finalResult]` PGCD = 6
- **Indices (2) :**
  - `#1` (methode) Divise le plus grand nombre par le plus petit et note le reste.
  - `#2` (methode) Le nouveau couple est le diviseur et le reste.
- **Compréhension :** « Quand l'algorithme s'arrête-t-il ? »
  → *Quand le reste est nul ; le dernier reste non nul est le PGCD.*
- **Suivi :** `null` — **Diagnostics :** `[]`

### 6 · `ch1-ex-6-euclide-autonome`

- **Énoncé :** Calcule le PGCD de 42 et 30 avec l'algorithme d'Euclide.
- **Validation :** `acceptedValues: [6]` · `acceptedExpressions: ['6']`
- **Correction :** `PGCD = 6`
- **Étapes attendues (4) :** 42 = 30 × 1 + 12 · 30 = 12 × 2 + 6 · 12 = 6 × 2 + 0 · PGCD = 6
- **Indices :** aucun — **Suivi :** `null`
- **Diagnostics :** `[D3, D4]`

### 7 · `ch1-ex-7-euclide-transfert-comparaison`

- **Énoncé :** Calcule le PGCD de 48 et 18 avec l'algorithme d'Euclide. Puis indique une différence entre cette méthode et celle des soustractions successives.
- **Validation :** `acceptedValues: [6]` · `acceptedExpressions: ['6']`
- **Drapeaux :** `expectsComparison: **true**`
- **Correction :** `PGCD = 6`
- **Étapes attendues (5) :** 48 = 18 × 2 + 12 · 18 = 12 × 1 + 6 · 12 = 6 × 2 + 0 · PGCD = 6
  - `[comparison]` L'algorithme d'Euclide utilise les divisions euclidiennes et peut réduire le nombre d'étapes.
- **Indices :** aucun — **Suivi :** `ch1-ex-4-pgcd-soustractions-verification`
- **Diagnostics :** `[]`

---

## Leçon 3 — `Relation entre le PPCM et le PGCD de deux entiers naturels`

### 8 · `ch1-ex-8-ppcm-pgcd-application`

- **Énoncé :** On sait que PGCD(12,18) = 6. Calcule PPCM(12,18) à l'aide de la relation entre PGCD et PPCM.
- **Validation :** `acceptedValues: [36]` · `acceptedExpressions: ['36']`
- **Correction :** `12 × 18 = 6 × PPCM(12,18) ; PPCM = 216 ÷ 6 = 36.`
- **Étapes attendues (2) :**
  - `[operation]` 12 × 18 = 6 × PPCM(12,18)
  - `[finalResult]` PPCM(12,18) = 216 ÷ 6 = 36
- **Indices :** aucun — **Suivi :** `null`
- **Diagnostics :** `[D5, D6]`

### 9 · `ch1-ex-9-ppcm-isoler-inconnue`

- **Énoncé :** Pour deux entiers positifs a = 8 et b = 12, on sait que leur PGCD vaut 4. Calcule leur PPCM.
- **Validation :** `acceptedValues: [24]` · `acceptedExpressions: ['24', '(8*12)/4', '96/4']`
- **Correction :** `PPCM = (8 × 12) ÷ 4 = 24.`
- **Étapes attendues (1) :** `[finalResult]` PPCM = (8 × 12) ÷ 4 = 24
- **Indices :** aucun — **Suivi :** `ch1-ex-8-ppcm-pgcd-application`
- **Diagnostics :** `[D5, D6]`

> Seule réponse **non numérique** de la leçon. Le type de réponse est ambigu :
> 24 et `(8*12)/4` sont tous deux acceptés.

### 10 · `ch1-ex-10-verification-relation`

- **Énoncé :** On propose PGCD(9,15) = 3 et PPCM(9,15) = 45. Vérifie ces deux valeurs avec la relation.
- **Validation :** `acceptedValues: [135]` · `acceptedExpressions: ['135', 'verifie', 'oui']`
- **Correction :** `9 × 15 = 135 et 3 × 45 = 135 ; la relation est vérifiée. La vérification de la relation seule ne prouve pas toujours séparément chaque valeur.`
- **Étapes attendues (3) :** `[operation]` 9 × 15 = 135 · `[operation]` 3 × 45 = 135 · `[justification]` La relation est vérifiée.
- **Indices :** aucun — **Suivi :** `null` — **Diagnostics :** `[]`

> Accepte du texte (`verifie`, `oui`) : impossible de trancher entre
> clavier numérique et alphabétique par déduction.

### 11 · `ch1-ex-11-choix-de-methode`

- **Énoncé :** Pour deux entiers positifs, tu connais leur produit et leur PGCD. Quelle relation peux-tu utiliser pour retrouver leur PPCM ? Explique en une phrase.
- **Validation :** `acceptedValues: []` · `acceptedExpressions: ['ppcm = produit / pgcd']`
- **Drapeaux :** `expectsJustification: **true**`
- **Correction :** `Produit des deux entiers = PGCD × PPCM ; donc PPCM = produit ÷ PGCD.`
- **Étapes attendues (2) :**
  - `[justification]` produit des deux entiers = PGCD × PPCM
  - `[justification]` PPCM = produit ÷ PGCD
- **Indices :** aucun — **Suivi :** `null` — **Diagnostics :** `[]`

> **Seul exercice sans valeur numérique attendue.** Une relation rédigée est
> attendue : la comparaison est textuelle et **stricte** (une formulation
> correcte différente sera refusée).

---

## Liens vers les tâches de vérification

Aucun des 11 exercices ne pointe vers une tâche de vérification. Les liens
`followUpTask` existants pointent vers **d'autres exercices du parcours** :

| Depuis | `followUpTask` | Nature |
|---|---|---|
| Exercice 2 | `ch1-ex-4-…` | exercice du parcours |
| Exercice 7 | `ch1-ex-4-…` | exercice du parcours |
| Exercice 9 | `ch1-ex-8-…` | exercice du parcours |

**Les tâches de vérification sont référencées par les DIAGNOSTICS, pas par
les exercices.** C'est le comportement voulu : la banque prescrit une tâche
de contrôle *après une remédiation*, donc attachée à un cas D, et non à un
parcours nominal.

### Les 6 tâches de vérification (`kind: verificationTask`)

| Identifiant | Leçon | Énoncé | Validation |
|---|---|---|---|
| `ch1-verify-pgcd-16-12` | `lecon-1` | PGCD(16, 12) par soustractions successives. | `[4]` · `['4']` |
| `ch1-verify-pgcd-14-7` | `lecon-1` | PGCD(14, 7). | `[7]` · `['7']` |
| `ch1-verify-pgcd-24-16` | `lecon-1` | PGCD(24, 16). | `[8]` · `['8']` |
| `ch1-verify-pgcd-35-20` | `lecon-2` | PGCD(35, 20). | `[5]` · `['5']` |
| `ch1-verify-ppcm-10-15` | `lecon-3` | PPCM de 10 et 15, avec PGCD 5. | `[30]` · `['30', '(10*15)/5', '150/5']` |
| `ch1-verify-ppcm-6-8` | `lecon-3` | Distinguer PGCD et PPCM de 6 et 8. | `[24]` · `['24', 'ppcm=24;pgcd=2', 'pgcd=2;ppcm=24']` |

Aucune n'a d'étape attendue, ni indice, ni suivi, ni diagnostic : ce sont des
contrôles ponctuels.

### Qui pointe vers quoi

| Diagnostic | Tâche de vérification |
|---|---|
| `D1` | `ch1-verify-pgcd-16-12` |
| `D2` | `ch1-verify-pgcd-14-7` |
| `D3` | `ch1-verify-pgcd-24-16` |
| `D4` | `ch1-verify-pgcd-35-20` |
| `D5` | `ch1-verify-ppcm-10-15` |
| `D6` | `ch1-verify-ppcm-6-8` |
| `D7` | *exercice du parcours* : `ch1-ex-3-…`, sans indice |
| `D8` | *exercice du parcours* : `ch1-ex-6-…`, sans aide |

> `D7` et `D8` vérifient sur un **exercice du parcours**, pas sur une tâche
> dédiée : la banque demande « un nouvel exercice sans indice ».

---

## Ce que ces objets ne contiennent pas

L'audit complet est dans [`AUDIT_MOTEUR.md`](AUDIT_MOTEUR.md). En bref, aucun
de ces objets n'expose :

- **un type de réponse** — impossible de choisir le clavier ;
- **un rendu mathématique** — `statement` est du texte brut contenant `÷`, `×` ;
- **une progression ou un niveau** — interdit par le schéma, aucune donnée
  n'existe ;
- **une étape d'analyse du pas-à-pas** — `expectedSteps` décrit l'attendu,
  mais aucun code ne compare les étapes réellement saisies par l'élève.
