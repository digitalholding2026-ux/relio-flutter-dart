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

> **Depuis la mission de fiabilisation**, cette répartition n'est plus une
> convention d'interface : le clavier est déduit de
> `CorrectionCriterion.answerType`, lui-même déduit des critères de
> correction (`acceptedValues` et nature des expressions acceptées). Le
> résultat est identique — exercices 1 à 9 numériques, 10 et 11
> alphanumériques — mais une divergence entre clavier et correction devient
> désormais impossible. Le filtre numérique reste effectif : `abc` est
> refusé à la saisie.

> **Attention, la tâche de contrôle D6** (`ch1-verify-ppcm-6-8`) attend
> elle aussi du texte : la banque exige de nommer les deux valeurs
> (`ppcm=24;pgcd=2`). Le contrat la classe correctement en `text`.

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

> **Depuis la mission de fiabilisation :** une fois le panneau affiché,
> « Valider » est **neutralisé**. Sans cela, un élève pressé pouvait
> empiler plusieurs tentatives identiques dans un historique append-only,
> donc inrattrapable. « Réessayer » et « Exercice suivant » restent les
> seules voies vers une nouvelle tentative.
| **E** | faux,pas de diagnostic | neutre | — | Pas encore. Je n'arrive pas à voir où ça bloque. Essaie encore, je regarde. | Réessayer |
| **non évaluable** | `isEvaluated == false` | neutre | — | Je n'ai pas reconnu ta réponse. Vérifie qu'elle est bien écrite. | Réessayer |
| **non concluant** | exercice 11, non reconnu | neutre | — | Je ne peux pas encore vérifier cette formulation avec certitude. Relis ta réponse, ou essaie une autre formulation. | Réessayer, Continuer |

### Verrouillage après validation

**Dès qu'un panneau est affiché**, le champ et « Valider » sont verrouillés.

| Élément | État verrouillé |
|---|---|
| Champ de réponse | Visible, valeur relisible, **non éditable** ; ni focus, ni clavier, ni copier-coller. Bordure outline, texte à 72 % d'opacité |
| « Valider » | **Visible**, état désactivé standard (opacité réduite) |
| « Demander un indice » | **Visible** s'il l'était, désactivé |
| Clavier | **Fermé** dès l'apparition du panneau |

Le verrouillage est une règle d'**interface**, dérivée de la seule présence
d'un panneau. Il ne touche ni le moteur, ni la classification, ni le
brouillon : le brouillon est conservé tel quel, seule l'édition est bloquée.

> **Détail d'implémentation.** Le verrouillage repose sur trois Leviers :
> `readOnly`, `enableInteractiveSelection: false` et `AbsorbPointer`.
> Poser `focusNode.canRequestFocus = false` ne fonctionne **pas** : le
> widget `Focus` interne de `TextField` réécrase cette valeur à chaque
> rebuild, silencieusement.

### Déverrouillage

| Action | Effet |
|---|---|
| « Exercice suivant » | Exercice suivant, brouillon du précédent **effacé**, champ vidé, déverrouillé, **focus repris** |
| « Réessayer » | Même exercice, panneau masqué, champ vidé, déverrouillé, focus repris, **indices effacés** |
| Retour par la flèche AppBar | **Brouillon conservé tel quel** : valeur, panneau et verrouillage intacts à la réouverture |
| « Continuer » (ex. 11) | Destination **non tranchée**. Reste S1, et n'est donc pas désactivé — S1 *est* une destination |

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

> **Depuis la mission de fiabilisation**, la règle d'ouverture est
> *écrite et testée* dans `domain/curriculum/transfer_verification.dart` :
> réussite **ET** autonomie **ET** tâche associée. Le bouton reste fermé
> faute de la troisième condition — et s'ouvrira seul le jour où la banque
> déclarera un suivi vers une tâche de contrôle, sans nouvelle ligne de code.
> Les associations candidates à arbitrer sont listées dans
> `docs/VERIFICATION.md`.

---

## 9. Tests

**272 tests** après les missions de fiabilisation et de verrouillage
(180 au départ).

| Fichier | Tests | Couvre |
|---|---|---|
| `test/curriculum/correction_test.dart` | 32 | Réponses exactes, variantes équivalentes, erreurs, non évaluables, contrat clavier |
| `test/presentation/answer_lock_test.dart` | 23 | Verrouillage après validation, retour AppBar, déverrouillage, les 5 panneaux |
| `test/curriculum/transfer_and_observations_test.dart` | 14 | Observations réellement productibles, associations de vérification |
| `test/presentation/parcours_reliability_test.dart` | 13 | Double soumission, clavier ouvert, erreur technique, navigation |
| `test/presentation/typography_test.dart` | 10 | Police embarquée, licence, axe `wght`, rendu d'énoncé |
| `test/presentation/learner_flow_test.dart` | 34 | Parcours S1→S2, indices, panneaux, brouillon, navigation |
| `test/presentation/layout_test.dart` | 12 | 360×640, textScale 1.3, cibles tactiles, thème |
| Autres (socle, moteur, persistance) | 134 | inchangés |

Résultats réels :

```
flutter analyze  → No issues found!
flutter test     → 00:23 +272: All tests passed!
```

### Deux vrais défauts trouvés par ces tests

1. **Brouillon non écrit.** `onChanged` ne reportait pas la saisie dans le
   brouillon : un retour vers S1 perdait la réponse. Corrigé, plus une
   sauvegarde en `dispose`.
2. **Cible tactile du retour à 24 dp** au lieu des 48 dp exigés. Corrigé par
   extension de la zone cliquable.

---

## 10. Limites restantes

> État **après** la mission de fiabilisation (chapitre 1). Les points
> résolus sont signalés ; ils restent listés pour la traçabilité.

1. ~~**Police Inter non embarquée.**~~ **RÉSOLU.** Le fichier
   `assets/fonts/Inter-Regular.ttf` est dans le dépôt, avec sa licence SIL
   OFL 1.1 (`assets/fonts/Inter-OFL.txt`). Inter étant une police
   **variable**, chaque style déclare l'axe `wght` : sans cela Flutter rend
   tout en 400 et simule les graisses.

2. ~~**Aucun rendu mathématique.**~~ **PARTIELLEMENT RÉSOLU.** Un rendu
   léger met en italique les variables d'affectation (`a = 8`, `b = 12`).
   `÷`, `×` et `−` s'affichent déjà correctement en texte brut. **Aucune
   dépendance ajoutée** : ni MathJax, ni KaTeX, ni parseur d'expression.
   Voir `presentation/widgets/math_statement.dart`.

3. **Saisie non évaluable rare.** Sur les 9 exercices à clavier numérique, le
   filtre empêche toute saisie non reconnue.

4. **Panneaux C et D absents**, faute de moteur. Le cas E sera le cas le plus
   fréquent en conditions réelles. Voir `docs/VERIFICATION.md`, § 4 : une
   seule observation (`reussite_apres_indice`) est réellement productible.

5. **Pas de tests d'interruption réelle** (background/foreground) : vérifié par
   construction uniquement.

6. **Aucune validation sur appareil Android réel.** Les tests sont
   automatisés et s'exécutent sur un moteur de test hors écran. `adb devices`
   ne retourne aucun appareil et aucun émulateur n'est installé dans cet
   environnement. Les vérifications « clavier ouvert » simulent un clavier de
   300 px via `MediaQuery.viewInsets`, ce qui ne reproduit pas fidèlement le
   comportement d'un clavier système (animation, Suggestions, hauteur réelle
   selon l'appareil). Une relecture sur téléphone reste nécessaire.

7. **Réponses hors nomenclature non évaluables.** Le moteur ne calcule pas :
   `96/6` sur l'exercice 9 vaut 16 (faux), mais comme cette expression n'est
   pas transcrite dans la banque, elle est classée **non évaluable** plutôt
   que fausse. C'est la bonne prudence, mais l'élève reçoit alors « Je n'ai
   pas reconnu ta réponse » sur une réponse qui est bel et bien fausse.

---

## 11. Lancer

```bash
flutter pub get
flutter test
flutter run          # appareil Android
```

L'application ouvre sur S1. Parcours : choisir une leçon → premier exercice →
répondre → « Valider » → panneau de retour.
