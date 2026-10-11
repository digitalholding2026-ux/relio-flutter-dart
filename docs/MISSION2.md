# Mission 2 — Intégration du chapitre 1 « Arithmétique »

Intégration de la banque pilote d'exercices et des cas de diagnostic D1 à D8
dans le socle technique existant.

> Le contenu pédagogique est une **transcription fidèle** de
> `relio_chapitre1_banque_exercices_diagnostic_v1.md`. Aucune valeur, énoncé,
> réponse ni intervention n'a été inventé.

---

## 1. Ce qui a été intégré

| Élément | Quantité | Source |
|---|---|---|
| Exercices validés | **11** | § « Leçon 1/2/3 » |
| Cas de diagnostic | **8** (D1–D8) | § « Cas de diagnostic moteur » |
| Tâches de vérification | 6 | couples cités dans D1–D6 |
| Indices progressifs | 4 (ex. 1 et 5, deux chacun) | énoncés des exercices |

Répartition des 11 exercices, conforme au document :

| Leçon | Exercices |
|---|---|
| Leçon 1 — PGCD, soustractions successives | 1, 2, 3, 4 |
| Leçon 2 — « PGDC », algorithme d'Euclide | 5, 6, 7 |
| Leçon 3 — Relation PPCM / PGCD | 8, 9, 10, 11 |

---

## 2. Fichiers créés

### Domaine — `lib/domain/curriculum/`

| Fichier | Rôle |
|---|---|
| `exercise.dart` | Modèle d'exercice : leçon, énoncé, critères de correction, étapes, indices ordonnés, compréhension, tâche de suivi |
| `diagnostic_case.dart` | Cas D1–D8 : observations, **hypothèses**, intervention, vérification |
| `hint_trajectory.dart` | Trajectoire des indices et classification autonome / assistée |
| `diagnostic_engine.dart` | Détection, hypothèses, intervention, gestion de l'incertitude |
| `chapter1_bank.dart` | **Transcription fidèle** des 11 exercices et 8 diagnostics |
| `chapter1_service.dart` | Pont vers le dépôt d'événements existant, correction des réponses |

### Tests — `test/curriculum/`

| Fichier | Tests |
|---|---|
| `chapter1_bank_test.dart` | 28 |
| `chapter1_integration_test.dart` | 29 |
| `diagnostic_engine_test.dart` | 30 |

---

## 3. Migrations de base de données

**Aucune.**

C'est un choix délibéré, et non un oubli. Le suivi des indices exigé par la
mission aurait pu justifier de nouvelles colonnes ; il n'en a pas besoin.

Les indices sont enregistrés comme **événements `hint_requested` distincts**,
dans la table existante `learning_events` via le champ `metadata`. Conséquences :

- **aucune migration**, donc aucun risque de perte de données ;
- l'ordre réel de consultation est conservé nativement (chaque indice est un
  événement horodaté) ;
- la distinction autonome / assistée est **dérivée** de l'historique, jamais
  stockée.

Le schéma reste donc identique (v2), ce qui préserve la compatibilité avec les
50 tests du socle.

---

## 4. Faits et hypothèses : séparation appliquée

| Type | Exemples | Stocké ? |
|---|---|---|
| **Fait** | réponse saisie, résultat de correction, indice consulté, ordre de consultation | oui |
| **Hypothèse** | erreur de procédure, confusion PGCD/PPCM, isolement algébrique | jamais comme fait |

`DiagnosticHypothesis` est un type distinct de `AttemptObservation`. Aucune
hypothèse n'est jamais confirmée : `HypothesisConfidence` s'arrête à
`indicated`, et D6 conserve **deux causes concurrentes** car une seule erreur
ne prouve pas une confusion conceptuelle.

**Aucun champ de maîtrise** n'a été ajouté. Un test le vérifie explicitement
sur `PRAGMA table_info`.

---

## 5. D5 et D6 — priorité de test

La mission demande de ne pas confondre isolement algébrique et confusion
conceptuelle.

| Cas | Déclencheur | Hypothèse | Intervention |
|---|---|---|---|
| **D5** | PGCD correct, PPCM faux | « Isolement de l'inconnue ou calcul » | « Dans la relation, que dois-tu diviser par quoi ? » |
| **D6** | Confusion PGCD/PPCM | « Distinction conceptuelle fragile » **+** « Erreur de saisie » | « Cherches-tu un diviseur commun ou un multiple commun ? » |

Quand les **deux** observations sont présentes simultanément, le moteur
**laisse le diagnostic ouvert** et pose une seule question de clarification
(« Peux-tu calculer le PGCD seul, puis le PPCM seul ? ») plutôt que de trancher.

Sur le dépassement de `DiagnosticContext.maxClarifications` (2), le moteur
cesse de questionner — le document source interdit l'enchaînement indéfini de
mini-questions.

---

## 6. Résultats réels des vérifications

### `flutter analyze`

```
Analyzing Relio...
No issues found!
```

### `flutter test`

```
00:08 +137: All tests passed!
```

| Lot | Tests |
|---|---|
| Socle (existant, non modifié) | 50 |
| Curriculum (nouveau) | 87 |
| **Total** | **137** |

### Les 12 points exigés

| # | Exigence | Couvert par |
|---|---|---|
| 1 | Chargement des 11 exercices | `1. Chargement des 11 exercices` |
| 2 | Cohérence ids et réponses | `2. Cohérence des identifiants…` |
| 3 | Consultation et enregistrement des indices | `3. Consultation…` |
| 4 | Autonome vs assistée | `4. Réussite autonome vs assistée` |
| 5 | Historique des indices par tentative | `5. Conservation de l'historique…` |
| 6 | Persistance et relecture | `6. Persistance et relecture…` |
| 7 | Séparation observations / hypothèses | `7. Separation observations…` |
| 8 | Déclenchement D1 à D8 | `8. Declenchement des diagnostics…` |
| 9 | Comportement de D5 | `9. Comportement specifique de D5` |
| 10 | Comportement de D6 | `10. Comportement specifique de D6` |
| 11 | Tâche de suivi après remédiation | `11. Tache de suivi apres remediation` |
| 12 | Diagnostic incertain, sans répétition | `12. Diagnostic incertain…` |

Les tests vérifient le **comportement réel** : classification dérivée après
relecture depuis SQLite, ordre chronologique des indices, hypothèses
concurrentes, garde-fou de la tâche de suivi.

---

## 7. Limites restantes

1. **Aucune interface.** Cette mission intègre le moteur, pas l'écran. Les
   exercices sont utilisables par un appelant, mais rien n'est encore
   affiché à l'élève.

2. **Détection des observations.** Le moteur consomme des observations
   codées (`soustraction_fausse`). Leur **production** à partir d'une réponse
   réelle (analyse des étapes de résolution) n'est pas implémentée : c'est le
   travail d'un analyseur de pas-à-pas, hors périmètre.

3. **Intitulé « PGDC »** (leçon 2) conservé tel quel, avec un indicateur
   `requiresEditorialConfirmation`. Aucune correction automatique n'a été
   appliquée.

4. **Pas de suivi de remédiation chiffré.** La tâche de suivi est *proposée* ;
   rien ne mesure encore si elle a réussi.

5. **Un seul chapitre.** Aucun mécanisme n'est encore prévu pour les 15 autres.

---

## 8. Lancer et tester

```bash
flutter pub get
flutter analyze      # No issues found!
flutter test         # 137 tests
flutter run          # sur un appareil Android
```

### Exemple d'utilisation du moteur

```dart
final service = Chapter1Service(LearningEventRepository(db));

final exercise = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

// 1. L'élève consulte l'indice 1 (avant soumission)
await service.recordHintRequested(
  attemptKey: 'tentative-1',
  exercise: exercise,
  hintOrder: 1,
);

// 2. Il soumet une bonne réponse
final record = await service.recordAttempt(
  exercise: exercise,
  rawAnswer: '6',
  attemptKey: 'tentative-1',
);

// 3. La classification est dérivée : assistée, jamais autonome
print(record.classification);  // assistedSuccess
print(record.isAutonomous);    // false
```

---

## 9. Confirmation d'intégration

- ✅ **11 exercices** intégrés et vérifiés arithmétiquement
- ✅ **8 diagnostics (D1–D8)** intégrés, chacun testé sur son observation
- ✅ Indices progressifs, ordre réel conservé
- ✅ Faits et hypothèses séparés, aucune maîtrise stockée
- ✅ Tâches de vérification post-remédiation, toujours différentes de l'exercice échoué

**Aucun exercice ni diagnostic ne reste à traiter.**
