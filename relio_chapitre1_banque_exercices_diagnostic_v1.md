# Relio — Chapitre 1 : Arithmétique (3e)
## Banque pilote d’exercices et cas de diagnostic — v1.0

**Statut :** contenu mathématique validé par le responsable pédagogique du projet, enseignant de mathématiques.  
**Source du programme :** les intitulés des trois leçons proviennent des captures du programme fournies. Les exercices, critères et scénarios ci-dessous sont la conception pédagogique de Relio.

## Règles de test du moteur

Pour chaque tentative, enregistrer les faits observables : réponse, étapes disponibles, indices consultés, correction, aide donnée et réussite autonome/avec aide. Une cause d’erreur reste une hypothèse tant qu’elle n’est pas étayée.

- Une réussite avec indice = progrès, pas réussite autonome.
- Après une erreur, diagnostiquer avec une question courte si plusieurs causes sont possibles.
- Après une remédiation, proposer une tâche différente.
- Ne pas conclure à un acquis confirmé sur une seule réponse correcte.

---

# Leçon 1 — PGCD : algorithme des soustractions

## Exercice 1 — Découverte guidée
**Énoncé élève :** Calcule le PGCD de 18 et 12 avec des soustractions successives.

**Résultat attendu :**
- 18 − 12 = 6 → couple (12, 6)
- 12 − 6 = 6 → couple (6, 6)
- PGCD(18, 12) = 6

**Indice 1 :** « Soustrais le plus petit nombre du plus grand. »
**Indice 2 :** « Après 18 − 12, travaille avec 12 et 6. »
**Compréhension :** « À quel moment t’arrêtes-tu ? »
**Réponse attendue :** lorsque les deux nombres sont égaux ; cette valeur est le PGCD.

## Exercice 2 — Réussite autonome
**Énoncé élève :** Calcule le PGCD de 15 et 10 par soustractions successives.

**Résultat attendu :** (15,10) → (10,5) → (5,5), donc PGCD = 5.

**Observation de diagnostic :**
- résultat faux avec une soustraction correcte au départ : poursuivre l’observation, ne pas conclure immédiatement ;
- soustraction dans le mauvais sens : hypothèse d’erreur de procédure ;
- résultat correct sans étapes visibles : demander brièvement « Peux-tu montrer une étape ? »

## Exercice 3 — Transfert
**Énoncé élève :** Calcule le PGCD de 21 et 14 avec la même méthode, puis explique comment tu sais que tu peux t’arrêter.

**Résultat attendu :** (21,14) → (14,7) → (7,7), donc PGCD = 7.

## Exercice 4 — Vérification ultérieure
**Énoncé élève :** Quelques exercices plus tard, calcule le PGCD de 20 et 12 par soustractions successives.

**Résultat attendu :** (20,12) → (12,8) → (8,4) → (4,4), donc PGCD = 4.

**But :** vérifier que la procédure est réutilisée plus tard, et non seulement mémorisée dans le contexte de l’exercice initial.

---

# Leçon 2 — « PGDC » : algorithme d’Euclide

> Le libellé « PGDC » est conservé ici comme transcription de la capture à vérifier. Dans les énoncés mathématiques, on utilise **PGCD** sous réserve de la confirmation éditoriale du titre.

## Exercice 5 — Division euclidienne guidée
**Énoncé élève :** Calcule le PGCD de 30 et 18 avec l’algorithme d’Euclide.

**Résultat attendu :**
- 30 = 18 × 1 + 12
- 18 = 12 × 1 + 6
- 12 = 6 × 2 + 0
- PGCD = 6

**Indice 1 :** « Divise le plus grand nombre par le plus petit et note le reste. »
**Indice 2 :** « Le nouveau couple est le diviseur et le reste. »
**Compréhension :** « Quand l’algorithme s’arrête-t-il ? »
**Réponse attendue :** quand le reste est nul ; le dernier reste non nul est le PGCD.

## Exercice 6 — Réussite autonome
**Énoncé élève :** Calcule le PGCD de 42 et 30 avec l’algorithme d’Euclide.

**Résultat attendu :**
- 42 = 30 × 1 + 12
- 30 = 12 × 2 + 6
- 12 = 6 × 2 + 0
- PGCD = 6

## Exercice 7 — Transfert et comparaison
**Énoncé élève :** Calcule le PGCD de 48 et 18 avec l’algorithme d’Euclide. Puis indique une différence entre cette méthode et celle des soustractions successives.

**Résultat attendu :**
- 48 = 18 × 2 + 12
- 18 = 12 × 1 + 6
- 12 = 6 × 2 + 0
- PGCD = 6
**Élément de comparaison accepté :** l’algorithme d’Euclide utilise les divisions euclidiennes et peut réduire le nombre d’étapes.

---

# Leçon 3 — Relation entre le PPCM et le PGCD de deux entiers naturels

## Exercice 8 — Application directe
**Énoncé élève :** On sait que PGCD(12,18) = 6. Calcule PPCM(12,18) à l’aide de la relation entre PGCD et PPCM.

**Résultat attendu :**
12 × 18 = 6 × PPCM(12,18)
PPCM(12,18) = 216 ÷ 6 = 36.

## Exercice 9 — Isoler l’inconnue
**Énoncé élève :** Pour deux entiers positifs \(a=8\) et \(b=12\), on sait que leur PGCD vaut 4. Calcule leur PPCM.

**Résultat attendu :** PPCM = (8 × 12) ÷ 4 = 24.

**Diagnostic algébrique distinct :**
Si l’élève identifie correctement les valeurs et la relation mais ne sait pas isoler le PPCM, demander : « Quel calcul permet d’obtenir le PPCM seul ? »
Si nécessaire, proposer d’abord une égalité numérique simple à compléter. Ne pas étiqueter l’erreur comme une difficulté de PGCD/PPCM sans autre preuve.

## Exercice 10 — Vérification par la relation
**Énoncé élève :** On propose PGCD(9,15) = 3 et PPCM(9,15) = 45. Vérifie ces deux valeurs avec la relation.

**Résultat attendu :** 9 × 15 = 135 et 3 × 45 = 135 ; la relation est vérifiée. (La vérification de la relation seule ne prouve pas toujours séparément chaque valeur ; une autre méthode peut être nécessaire si l’une des valeurs est incertaine.)

## Exercice 11 — Choix de méthode
**Énoncé élève :** Pour deux entiers positifs, tu connais leur produit et leur PGCD. Quelle relation peux-tu utiliser pour retrouver leur PPCM ? Explique en une phrase.

**Réponse attendue :** produit des deux entiers = PGCD × PPCM ; donc PPCM = produit ÷ PGCD.

---

# Cas de diagnostic moteur — à tester explicitement

| Cas | Réponse / comportement observé | Hypothèse possible | Intervention courte | Tâche de vérification |
|---|---|---|---|---|
| D1 | Une soustraction est fausse | Erreur de calcul ou de procédure | « Quelle opération as-tu faite ici ? » | PGCD(16, 12) par soustractions |
| D2 | L’élève poursuit après deux valeurs égales | Critère d’arrêt mal compris | « Que remarques-tu sur les deux nombres ? » | PGCD(14, 7) |
| D3 | Division euclidienne correcte, mauvais couple repris ensuite | Rôle du reste mal compris | « Quels sont le diviseur et le reste ? » | PGCD(24, 16) |
| D4 | L’élève s’arrête quand le reste est non nul | Critère d’arrêt de l’algorithme incertain | « Le reste est-il nul ? » | PGCD(35, 20) |
| D5 | PGCD correct, PPCM faux par division inversée | Isolement de l’inconnue ou calcul | « Dans la relation, que dois-tu diviser par quoi ? » | PPCM de 10 et 15, avec PGCD 5 |
| D6 | L’élève confond PGCD et PPCM | Distinction conceptuelle fragile | « Cherches-tu un diviseur commun ou un multiple commun ? » | Distinguer PGCD et PPCM de 6 et 8 |
| D7 | Réussite seulement après indice | Procédure en cours d’acquisition | Féliciter le progrès, ne pas compter comme réussite autonome | Nouvel exercice sans indice |
| D8 | Bonne réponse sans démarche visible | Stratégie inconnue | « Montre une étape de ton calcul. » | Couple différent, sans aide |

**Important :** ces observations ne suffisent pas toujours à attribuer une cause unique. Si plusieurs explications sont possibles, Relio pose une question de clarification ou garde le diagnostic ouvert.

## Critères de test du prototype

Le prototype sera prêt à être examiné dans l’application lorsque :
1. les 11 exercices et leurs réponses attendues sont intégrés ;
2. les indices sont fournis progressivement, sans afficher d’emblée toute la solution ;
3. les tentatives autonomes sont distinguées des réussites avec aide ;
4. les cas D1 à D8 produisent des interventions adaptées sans transformer une hypothèse en fait ;
5. une réussite ultérieure est vérifiée sur une tâche différente ;
6. les questions de diagnostic restent courtes pour la voix.

