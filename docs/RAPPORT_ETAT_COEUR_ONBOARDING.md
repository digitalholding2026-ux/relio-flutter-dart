# Rapport — État du cœur pour l'intégration onboarding

**Date :** 12 octobre 2026
**Objet :** inventaire des API réellement disponibles pour le parcours
d'onboarding (Prénom → Test d'entrée → Clôture), avant figeage de la
spécification d'intégration.
**Périmètre :** lecture seule. Aucun code modifié lors de cette passe.

---

## Partie 1 — État technique du dépôt

| Élément | Valeur |
|---|---|
| Branche | `main`, synchronisée avec `origin/main` |
| Commit | `5108565` — « Coeur metier du test d'entree de cinq questions » (12/10/2026) |
| Working tree | propre (aucune modification) |
| `flutter analyze` | **No issues found!** (15,0 s) |
| `flutter test` | **All tests passed!** — 608 tests |

**Bouton « Commencer » : corrigé et fonctionnel.** Il existe bien dans
l'arbre (règle 10 respectée), et `app.dart:125` appelle
`markFirstLaunchCompleted()` avant de basculer vers l'accueil. La mission
est close.

---

## Partie 2 — Inventaire des API réellement disponibles

Point d'entrée unique à utiliser : **`EntryTestOnboarding`**
(`lib/domain/entrytest/entry_test_onboarding.dart`). Elle orchestre déjà
`SettingsRepository` + `EntryTestRepository`. L'interface ne doit rien
manipuler en dehors.

| # | Capacité | État | API (signature) |
|---|---|---|---|
| 1 | Lire le prénom | ✅ existe | `Future<String> storedName()` → prénom trimé, `''` si absent. Test alternatif `Future<bool> hasValidName()`. Clé : `learner.name` |
| 2 | Enregistrer le prénom | ✅ existe | `Future<void> setName(String name)` sur `SettingsRepository`. Trim automatique. Via `EntryTestOnboarding` : **pas d'équivalent** → utiliser `SettingsRepository` |
| 3 | Démarrer / reprendre une session | ✅ existe | `Future<EntryTestSession> openSession()` — reprise si elle existe, création sinon |
| 4 | Obtenir la question courante | ✅ existe | `EntryTestSession? get nextQuestion` → première question sans réponse. `EntryTestQuestion` expose `statement`, `order`, `answerType` (`enum EntryTestAnswerType {integer, choice}`), `choices`, `isChoice` |
| 5 | Nombre total de questions | ✅ existe | `EntryTestSession.questions.length` et `List<EntryTestQuestion> get questions` sur l'orchestrateur. Position : `EntryTestSession.answeredCount` / `remainingCount` |
| 6 | Soumettre avec idempotence | ✅ existe | `Future<EntryTestAnswer> submitAnswer({required EntryTestSession session, required EntryTestQuestion question, required String rawAnswer})` |
| 7 | Confirmer la persistance | ✅ existe | Le `Future` ne se complète qu'**après** commit SQLite en transaction. En cas d'échec, l'exception **remonte** et l'interface n'avance pas. Réponse : `EntryTestAnswer` |
| 8 | Fin de session / absence de question | ✅ existe | `session.nextQuestion == null` = plus rien à répondre. `session.isCompleted`, `session.isReadyToComplete`, `completeSession()` pour clore |
| 9 | Marquer première ouverture | ⚠️ **partiel** | Lecture : `Future<bool> hasCompletedFirstLaunch()`. Écriture : `Future<void> markFirstLaunchCompleted()`. **Voir Partie 4** |

---

## Partie 3 — Précisions sur les trois points sensibles

### a) Idempotence — l'interface ne fournit aucun identifiant

L'identifiant est **généré intégralement côté cœur**, jamais côté
interface. Il est déterministe : `entry-test:<sessionId>:answer:<questionId>`.
La déduplication repose sur la clé primaire de `learning_events`, avec
vérification d'existence explicite dans la transaction.

Conséquence directe : `submitAnswer` ne prend **aucun paramètre
d'identifiant**. Deux RETOURS au clavier ne font pas deux doublons. La
spécification d'intégration n'a donc rien à fournir de ce côté.

Un cas à connaître : si la même question est soumise avec une réponse
**différente**, l'événement d'origine est conservé tel quel et la méthode
renvoie un `EntryTestAnswer` recalculé. Aucune réécriture d'historique —
l'historique est append-only.

### b) Reprise : le cœur sait reprendre AU MILIEU, pas seulement au début

`openSession()` applique la logique suivante :

1. lit l'identifiant mémorisé (`entry_test.session_id`) ;
2. s'il est introuvable, cherche la dernière session démarrée — il ne crée
   pas de session neuve en silence ;
3. sinon crée une session.

`nextQuestion` est calculé depuis l'ordre **déclaré** des questions, jamais
depuis l'ordre de lecture SQLite. Reprise à la question 3 sur 5 possible.

Si la session est **déjà terminée**, elle est renvoyée telle quelle et
**jamais rouverte** : une seule passation en V1.

### c) Réponses non évaluables — l'équivalent `isEvaluated` existe déjà

`EntryTestCorrection` porte deux booléens **orthogonaux** (et non un enum) :
`isEvaluated` et `isCorrect`, plus `get isIndeterminate => !isEvaluated`.
Constante partagée : `EntryTestCorrection.notEvaluated`.

Trois issues distinctes, jamais confondues : correcte /
incorrecte-évaluable / **non évaluable**. Une réponse illisible ou un choix
hors liste n'est jamais classée fausse.

L'information est persistée : le booléen part en métadonnée sous la clé
`evaluated`. Une réponse non évaluable reste donc consultable.

---

## Partie 4 — Blocages identifiés

### Blocage unique : la clôture de parcours (capacité 9, et la fin du parcours)

**Ce qui manque.** Deux choses distinctes :

1. **`EntryTestOnboarding` n'expose ni lecture ni écriture du marqueur de
   première ouverture.** `hasCompletedFirstLaunch()` et
   `markFirstLaunchCompleted()` existent sur `SettingsRepository`, mais ne
   sont pas relayés par l'orchestrateur.
2. **Un conflit d'autorité non tranché.** Aujourd'hui, deux endroits
   écrivent ce marqueur :
   - `app.dart:125` — dès le clic sur « Commencer » ;
   - `entry_test_onboarding.dart:180` — à la fin de la session complète.

   Or ce second point applique une règle plus stricte : un test à moitié
   fait **ne doit pas** marquer la fin du parcours, pour permettre la
   reprise. Mais le premier n'attend rien et marque dès l'entrée dans
   l'application.

**Ce que l'interface ne peut donc pas faire aujourd'hui.** Elle ne peut pas
enchaîner « Commencer → prénom → test » de façon fiable : le clic sur
« Commencer » poserait le drapeau avant que le test soit fait, et l'écran
d'entrée ne serait plus rejoué après une fermeture en cours de test.

**Ce qui est proposé côté cœur** (à valider, aucun code écrit à ce stade) :

- exposer sur `EntryTestOnboarding` les deux delegates, pour que toute la
  lecture/écriture du parcours passe par un seul point ;
- trancher l'autorité. Deux options :
  - **(A)** le marqueur n'est écrit que par `finishSession()`, et l'écran
    d'entrée passe sous condition — plus cohérent avec la décision 6
    documentée dans le code ;
  - **(B)** séparer deux drapeaux, l'un pour l'écran d'intro, l'autre pour
    le parcours pédagogique.

**Option recommandée : (A).** Elle rend la décision 6 réellement applicable
et supprime la double autorité.

---

## Défaut signalé séparément, non corrigé

`EntryTestSession.withAnswer()`
(`lib/domain/entrytest/entry_test_session.dart`, ligne 149)
**écrase silencieusement** la réponse existante d'une question si elle est
appelée deux fois avec la même question :

```dart
answers: <String, EntryTestAnswer>{...answers, answer.questionId: answer},
```

Son commentaire affirme au contraire qu'« une réponse déjà persistée n'est
jamais écrasée ».

Ce n'est **pas** un blocage aujourd'hui : la persistance réelle est
append-only et protégée par identifiant déterministe, et le code de
production n'appelle pas cette méthode. Mais c'est une divergence entre le
commentaire et le comportement, susceptible de mordre si l'orchestrateur
s'appuie un jour dessus. Signalé, non touché.

---

## Synthèse

**L'onboarding peut être intégré jusqu'à la passation complète du test
d'entrée — prénom, ouverture/reprise de session, question courante,
compteur, soumission idempotente, persistance confirmée, clôture — avec
l'existant. Au-delà, un blocage doit être levé : l'autorité d'écriture du
marqueur de première ouverture, aujourd'hui disputée entre le bouton
« Commencer » et la fin de session, et non exposée par
`EntryTestOnboarding`.**

Deux précisions qui conditionnent la spécification d'intégration :

- l'interface **ne fournit aucun identifiant** d'idempotence — il est dérivé
  côté cœur, de la session et de la question ;
- la **reprise fonctionne au milieu du test**, pas seulement au début.