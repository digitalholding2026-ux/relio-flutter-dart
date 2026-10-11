# Interface — parcours élève chapitre 1

Écrans S1 et S2 du parcours élève. Ce document décrit ce qui est affiché,
ce qui ne l'est pas, et pourquoi.

---

## 1. Ce qui est livré

| Écran | Fichier | Contenu |
|---|---|---|
| **S1** Accès au chapitre | `presentation/screens/chapter_access_page.dart` | 3 leçons empilées |
| **S2** Exercice | `presentation/screens/exercise_page.dart` | Énoncé, champ, indices, panneau |
| Navigation | `app.dart` (`LearnerFlow`) | S1 → S2, brouillons de session |

**Screens de remplacement** : l'ancien `HomePage` (compteurs techniques) a été
supprimé. L'application ouvre désormais directement sur S1.

---

## 2. Principes tenus

| Contrainte | Application |
|---|---|
| Contenu mathématique inchangé | Aucune valeur, énoncé ou correction touché |
| « PGDC » conservé tel quel | Affiché sans correction, aucun test ne le corrige |
| Aucun code D1–D8 affiché | Test dédié : `aucun code diagnostic ni cause n'est affiché` |
| Aucune cause affirmée | Panneau E formulé en ignorance assumée |
| Aucune capacité simulée | Panneaux C et D **non implémentés** : le moteur ne les produit pas |
| Pas de mécanique de jeu | Tests dédié sur XP, badge, série, pourcentage |
| Pas de compteur de progression | Aucun indicateur d'avancement |
| Règles non réimplémentées | L'écran **consomme** `selectFeedback`, il ne décide pas |

---

## 3. S1 — Accès au chapitre

Titre « Chapitre 1 » (caption), « Arithmétique » (display 28/700), phrase
d'introduction. Puis trois cartes sélectionnables, aux intitulés exacts :

- `PGCD : algorithme des soustractions`
- `« PGDC » : algorithme d'Euclide`
- `Relation entre le PPCM et le PGCD de deux entiers naturels`

**Aucun compteur.** Le retour est désactivé : S1 est la racine en V1.

---

## 4. S2 — Exercice

### Structure

```
[ barre haute : retour + titre de leçon tronqué ]
┌ zone défilante ────────────────────────┐
│  carte énoncé                          │
│  mention de transparence (3, 7, 11)    │
│  indices consultés                     │
│  panneau de retour                     │
└────────────────────────────────────────┘
┌ barre fixe ────────────────────────────┐
│  bannière d'erreur (dismissible)       │
│  champ de réponse (56 dp)              │
│  « Demander un indice »                │
│  « Valider » (52 dp)                   │
└────────────────────────────────────────┘
```

**La barre d'action est hors de la zone défilante.** C'est délibéré : le champ
reste visible au-dessus du clavier et « Valider » n'est jamais masqué, comme
l'exigent les critères d'acceptation.

### Clavier

| Exercices | Clavier | Règle |
|---|---|---|
| 1 à 9 | numérique | chiffres et `-` uniquement |
| 10 et 11 | alphanumérique | texte libre |

> **Cette répartition est une règle d'interface V1**, définie dans
> `presentation/rules/v1_screen_rules.dart`. Elle ne provient d'aucune donnée
> du moteur, qui n'expose pas de type de réponse. Le filtre numérique est
> effectif : `abc` est refusé à la saisie.

### Mention de transparence

Affichée **uniquement** sur les exercices 3, 7 et 11, en Caption
`textSecondary`, sans icône ni encadré :

| Exercice | Texte |
|---|---|
| 3 | La réponse finale est vérifiée automatiquement ; la justification n'est pas encore évaluée. |
| 7 | La réponse finale est vérifiée automatiquement ; la comparaison n'est pas encore évaluée. |
| 11 | L'évaluation de la rédaction n'est pas encore complète. |

---

## 5. S2 — Panneaux de retour

| Panneau | Déclencheur | Fond | Titre | Message | Actions |
|---|---|---|---|---|---|
| **A** | correct, 0 indice | vert | Bonne réponse. | Tu as réussi cet exercice sans aide. | Exercice suivant |
| **B** | correct, ≥ 1 indice | ambre | Bonne réponse. | Tu as réussi cet exercice avec de l'aide. | Exercice suivant |
| **E** | faux,pas de diagnostic | neutre | — | Pas encore. Je n'arrive pas à voir où ça bloque. Essaie encore, je regarde. | Réessayer |
| **non évaluable** | `isEvaluated == false` | neutre | — | Je n'ai pas reconnu ta réponse. Vérifie qu'elle est bien écrite. | Réessayer |
| **non concluant** | exercice 11, non reconnu | neutre | — | Je ne peux pas encore vérifier cette formulation avec certitude. Relis ta réponse, ou essaie une autre formulation. | Réessayer, Continuer |

**Panneaux C et D : non implémentés.** Le moteur ne produit ni observation,
ni traitement de clarification. Les concevoir sans moteur serait simuler une
capacité inexistante.

> Le panneau « non évaluable » est **inatteignable sur les exercices 1 à 9** :
> le filtre numérique interdit une saisie non reconnue. Il ne s'atteint que
> sur les exercices 10 et 11.

---

## 6. S2 — États techniques

| État | Traitement |
|---|---|
| Saisie vide | Message inline, **aucun appel moteur**, disparaît à la 1re frappe |
| Erreur d'envoi | Bannière dismissible + « Réessayer », **saisie jamais effacée** |
| Erreur de chargement | Non déclenchable en V1 : la banque est locale, pas de réseau |
| Chargement | Non déclenchable en V1 : lecture synchrone |

---

## 7. Brouillon

Conservé **en mémoire d'écran**, par identifiant d'exercice
(`ExerciseDraft`, dans `LearnerFlow`).

| Situation | Saisie | Indices |
|---|---|---|
| Demander un indice | préservée | ajoutés |
| Retour S1 puis réouverture | restaurée | restaurés |
| « Réessayer » | vidée | vidés |
| Fermeture forcée de l'app | **perdue** | **perdus** |

> La perte à la fermeture est une **limite assumée en V1**, pas un défaut
> masqué. Elle est documentée ici et dans le code. Aucun événement n'est écrit
> dans l'historique d'apprentissage pour un brouillon.

---

## 8. S4 — Non ouvert

Aucun bouton « Vérifier ma maîtrise ». La banque n'expose aucune association
exercice ↔ tâche de vérification : les tâches sont rattachées aux diagnostics
D1–D6, pas au parcours nominal.

---

## 9. Tests

**180 tests**, dont **46** nouveaux pour l'interface.

| Fichier | Tests | Couvre |
|---|---|---|
| `test/presentation/learner_flow_test.dart` | 34 | Parcours S1→S2, indices, panneaux, brouillon, navigation |
| `test/presentation/layout_test.dart` | 12 | 360×640, textScale 1.3, cibles tactiles, thème |

Résultats réels :

```
flutter analyze  → No issues found!
flutter test     → 00:16 +180: All tests passed!
```

### Deux vrais défauts trouvés par ces tests

1. **Brouillon non écrit.** `onChanged` ne reportait pas la saisie dans le
   brouillon : un retour vers S1 perdait la réponse. Corrigé, plus une
   sauvegarde en `dispose`.
2. **Cible tactile du retour à 24 dp** au lieu des 48 dp exigés. Corrigé par
   extension de la zone cliquable.

---

## 10. Limites restantes

1. **Police Inter non embarquée.** `fontFamily: 'Inter'` est déclaré, mais le
   fichier de police n'est pas dans le dépôt : Flutter bascule sur la police
   par défaut. La conformité typographique n'est donc pas visuelle.

2. **Aucun rendu mathématique.** `statement` est du texte brut. `÷` et `×`
   s'affichent tels quels, et les variables (`a = 8`) ne sont pas en italique,
   faute de parseur d'énoncé.

3. **Saisie non évaluable rare.** Sur les 9 exercices à clavier numérique, le
   filtre empêche toute saisie non reconnue.

4. **Panneaux C et D absents**, faute de moteur. Le cas E sera le cas le plus
   fréquent en conditions réelles.

5. **Pas de tests d'interruption réelle** (background/foreground) : vérifié par
   construction uniquement.

---

## 11. Lancer

```bash
flutter pub get
flutter test
flutter run          # appareil Android
```

L'application ouvre sur S1. Parcours : choisir une leçon → premier exercice →
répondre → « Valider » → panneau de retour.
