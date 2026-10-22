# Diagnostics explicites et reprise de la progression

## Problèmes constatés

1. Les erreurs de l’exercice 1 affichaient le panneau générique **E** au lieu
   de l’intervention ciblée **C** : le collecteur d’observations ne peut pas
   déduire une cause d’un simple résultat faux.
2. En rouvrant une leçon, S1 chargeait toujours l’exercice 1, même après une
   réussite.
3. « Exercice suivant » pouvait passer à la leçon suivante.

## Corrections

### 1. Correspondances explicites `errorCases`

`Exercise` porte désormais :

```dart
final Map<String, String> errorCases;
```

La clé est la réponse normalisée, la valeur un identifiant de cas D1…D8.
`Chapter1Service.diagnoseAnswer()` consulte cette carte **avant** le chemin
fondé sur les observations. Une correspondance ouvre directement le panneau C
avec l’intervention du cas, sans clarification.

Exercice 1 (réponse attendue `6`) :

```dart
errorCases: <String, String>{'5': 'D1', '0': 'D2', '3': 'D3'},
```

D’autres exercices déjà reliés à des diagnostics portent leurs
correspondances observables (`ex2`, `ex6`, `ex8`). L’exercice 9 conserve le
chemin D5 + D6, qui doit rester une clarification : aucune carte ne le
court-circuite.

Sans correspondance, le comportement précédent est inchangé : observations
strictement lisibles, puis panneau E si rien n’est démontrable.

### 2. Reprise au premier exercice non terminé

`LearnerProgress.resumeExerciseForLesson()` lit les réussites de la leçon :

- premier exercice absent de l’historique de réussite ;
- si tous sont terminés, premier exercice de la leçon, ouvert en révision.

`RelioApp._openLesson()` relit l’historique avant d’ouvrir S2. Le titre de S2
affiche alors **« Révision »**.

### 3. « Exercice suivant » reste dans la leçon

`V1ScreenRules.nextAfter()` filtre désormais sur la leçon. Après le dernier
exercice, le bouton ramène à S1 ; il ne bascule pas sur la leçon suivante.

## Vérifications

```bash
flutter analyze
flutter test
```

Tests ajoutés ou adaptés :

- `test/curriculum/diagnostic_activation_test.dart` — carte de l’exercice 1,
  priorité sur les observations, réponse non mappée ;
- `test/presentation/diagnostic_panels_test.dart` — panneau C sur `5` ;
- `test/learning/learner_progress_test.dart` — reprise et leçon maîtrisée ;
- `test/presentation/progress_resume_test.dart` — S1 reprend au bon exercice,
  dernier exercice → S1, titre « Révision » ;
- `test/presentation/answer_lock_test.dart` — conservation du brouillon quand
  l’exercice reste le premier non terminé.

Aucune migration de schéma : ces informations sont dérivées de l’historique
existant, qui reste la seule source de vérité.
