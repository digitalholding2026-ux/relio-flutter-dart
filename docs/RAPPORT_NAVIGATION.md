# Rapport de mission — Navigation globale, Accueil, Profil, identité visuelle

**Prompt source :** « Navigation globale, Accueil, Profil, identité visuelle — Relio »
**Date :** 11 octobre 2026
**Branche code :** `main` @ `9b1799a`
**Branche binaire :** `apk-build` @ `fe44ed2`
**Verdict :** livrable, avec **deux dépendances bloquantes** signalées et non contournées.

---

## 1. Synthèse

La mission portait sur six étapes. Quatre étaient neuves, deux étaient déjà
livrées dans le dépôt avant l'intervention — ce qui n'était pas évident et a
changeé le périmètre réel.

| Étape | Objet | État | Remarque |
|---|---|---|---|
| 1.1 | Police Inter | ✅ **Déjà livrée** | 5 fichiers dans `assets/fonts/`, poids épinglés |
| 1.2 | Tokens de design | ✅ Livré cette mission | Palette à deux variantes + espacements + rayons + typo |
| 1.3 | Formateur mathématique | ✅ **Déjà livrée** | `math_text.dart`, 25 tests dédiés |
| 1.4 | Logo | ⛔ **Bloquée** | Fichiers SVG/PNG non fournis |
| 2 | Barre basse à 3 onglets | ✅ Livré cette mission | `app_shell.dart` |
| 3 | Écran Accueil | ✅ Livré cette mission | `home_page.dart` |
| 4 | Écran Apprendre | ✅ Livré cette mission | `learn_page.dart` |
| 5 | Écran Profil | ✅ Livré cette mission | `profile_page.dart` |
| 6 | Ajustements S1 / S2 | ✅ Livré cette mission | Flèche retour + barre masquée |

**Livrables chiffrés :** 7 fichiers créés, 16 modifiés, **+3 128 / −327 lignes**,
**38 tests nouveaux** (362 → 400).

**APK :** `apk/relio-socle-v0.3.4-navigation.apk` — **21,87 Mo**
`SHA256 53E9A663124E062F26CC47DC41A3CC667EC59B3C48D5EEFB12E8D7370C8499DC`

---

## 2. Constat préalable : deux étapes déjà livrées

Le prompt présentait les six étapes comme à produire. L'examen du code a montré
que **deux l'étaient déjà** :

- **1.1 — Police Inter.** Les cinq fichiers sont versionnés
  (`Inter-Regular`, `Inter-Medium`, `Inter-SemiBold`, `Inter-Bold`,
  `Inter-Italic-Regular`), déclarés dans `pubspec.yaml` avec licence SIL OFL
  1.1. Chaque fichier porte son `wght` **épinglé** : `fontWeight` suffit à
  sélectionner le poids, aucun `fontVariations` n'est nécessaire. Budget réel :
  **397,8 Ko**, au-dessus de la cible de ~300 Ko — écart déjà assumé avant
  cette mission, non modifié.
- **1.3 — Formateur typographique.** `math_text.dart` existe et respecte le
  périmètre demandé : variables isolées en italique, chiffres tabulaires,
  opérateurs uprights, acronymes exclus, robustesse « ne jamais réécrire un
  caractère ». 25 tests le verrouillent, dont les six vérifications
  explicitement demandées (`PGCD de 18 et 12`, `a = 8 et b = 12`,
  `(8 × 12) ÷ 4`, `Après 18 − 12…`, `PGCD(12,18) = 6`, « PGDC »).

Ces deux étapes n'ont donc pas été réécrites. **Réécrire du travail correct et
testé aurait été une perte sèche** et aurait introduit un risque de régression
sur la partie la plus sensible de l'interface.

> ⚠️ **Défaut documentaire préexistant, non corrigé :** l'en-tête de
> `relio_theme.dart` affirmait encore que la police « n'est pas embarquée dans
> le dépôt » et que Flutter « bascule silencieusement sur la police par
> défaut ». C'était faux depuis la livraison des polices. L'affirmation a été
> retirée lors de la réécriture du fichier, mais ce genre de commentaire
> périmé mérite une vigilance.

---

## 3. Étape 1.2 — Tokens de design

### Ce qui a été fait

`relio_theme.dart` a été réécrit autour d'une **palette instanciable** :

- **`RelioPalette`** — palette immuable, deux constructeur :
  `standard()` et `contrast()`. Les jetons de couleur de la spécification sont
  tous présents, plus `brand` (#F56207), `surface` et `shadow`.
- **`RelioPaletteScope`** — `InheritedWidget` qui diffuse la palette courante.
- **`RelioSpacing`** — échelle 4/8/12/16/20/24/32.
- **`RelioRadius`** — 8 / 12 / 16 / 999.
- **`RelioSizes`** — dimensions des composants, dont `bottomNavHeight = 56`.
- **`RelioType`** — `display` 28/Bold, `title` 22/SemiBold, `subtitle`
  17/SemiBold, `body` 16/Regular, `bodyStrong` 16/SemiBold, `caption`
  13/Medium, `numeric` 20/Medium tabulaire.

### Pourquoi une palette instanciable et non des constantes

La contrainte « contraste renforcé modifie effectivement la palette sur **tous**
les écrans » est **incompatible** avec des constantes statiques : une constante
ne peut pas changer à l'exécution. La migration de tous les widgets vers une
lecture par contexte (`RelioPaletteScope.of(context)`) était donc **inévitable**,
pas optionnelle.

### Règle de contraste respectée

AA minimum sur tout le texte. **Aucune information n'est portée par la seule
couleur** : l'état actif d'un onglet se lit par la couleur **et** par le poids
du trait (SemiBold/M Medium) ; le segment de taille de texte porte son
libellé ; les panneaux de retour portent un titre.

---

## 4. Étape 2 — Navigation globale

### Pile par onglet

Chaque onglet possède **son propre `Navigator`**, construit une fois et conservé
dans un `IndexedStack`. Conséquence directe : changer d'onglet ne détruit pas
l'onglet quitté — brouillon de saisie, indices et position de défilement sont
restaurés au retour. C'est vérifié par deux tests.

`RelioTab` est une **énumération fermée** : c'est la façon la plus simple de
garantir qu'aucun quatrième onglet ne puisse être ajouté par accident.

« Révisions », « Progression » et « Paramètres » n'existent nulle part — un
test échoue si l'un de ces libellés apparaît, même grisé.

### Un défaut réel corrigé en cours de route

« Commence ici » (Accueil) empilait S1 dans la pile de l'onglet Apprendre
**sans basculer sur cet onglet**. S1 était donc invisible : le bouton ne
faisait rien de perceptible. Corrigé — `_openChapter1` bascule sur l'onglet
puis empile. Ce bug n'apparaissait qu'à l'écran, pas dans les types.

---

## 5. Étapes 3 à 5 — Les trois écrans

### Accueil

En-tête « Bonjour » (+ prénom si renseigné), carte principale « Commence ici »
(ombre légère, hauteur généreuse), carte secondaire « Programme de 3e »
(plate). La **zone basse est volontairement vide** : y loger une carte
« À revoir » sans moteur de recommandation serait **simuler une capacité
inexistante**, ce que la consigne interdit explicitement.

### Apprendre

Chapitre 1 actif avec chevron ; chapitres 2 et 3 génériques, « Bientôt
disponible », sans chevron et non cliquables.

> Les intitulés officiels des chapitres suivants ne sont **pas** inventés.
> Inventer un intitulé de chapitre relèverait du contenu pédagogique fabriqué,
> interdit par la règle 8 d'`AGENTS.md`.

### Profil

Exactement les trois sections demandées : Identité (nom modifiable, classe « 3e »
non modifiable), Affichage (taille de texte, contraste renforcé), Accessibilité
(réduire les animations). Aucun avatar, aucune photo, aucune section
Progression, aucun score, aucune synchronisation, aucun compte, aucun thème
sombre.

**Persistance :** locale, immédiate, sans bouton « Enregistrer ». La perte à la
désinstallation est assumée en V1.

---

## 6. Étape 6 — Ajustements S1 / S2

### S1 — plus racine

S1 est atteinte depuis Apprendre (carte du chapitre 1) ou depuis Accueil
(« Commence ici »), qui convergent vers la **même** pile. Sa flèche de retour
est active et ramène à l'écran Apprendre. Un test le vérifie.

### S2 — barre basse masquée

S2 lève lui-même un signal `onFullscreenChanged`, que la coquille exécute.

> **Décision d'architecture à signaler.** Une première implémentation masquait
> la barre selon la **profondeur de la pile**. C'était faux : S1 et S2 sont
> tous deux empilés, la profondeur ne les distingue pas, et la barre disparaît
> donc à tort sur S1. Le signal est désormais **explicite**, levé par l'écran
> qui sait ce dont il a besoin.

> **Conséquence assumée, à valider.** La barre masquée sur S2 rend les onglets
> **inatteignables depuis l'exercice**. C'est la lecture directe de la
> consigne (« sur S2, la barre de navigation basse doit être masquée pour
> préserver la barre d'action fixe »). L'élève sort par la flèche de retour.
> Un test verrouille ce comportement. Si l'on souhaite pouvoir changer d'onglet
> depuis l'exercice, c'est une **discussion à trancher**, pas un contournement.

---

## 7. Stockage — schéma v3

| Élément | Valeur |
|---|---|
| `kSchemaVersion` | **3** (était 2) |
| Nouvelle table | `app_settings (key TEXT PK, value TEXT)` |
| Étape de migration | `_migratedV2ToV3()`, explicite |
| Test de migration | 6 tests dédiés |

La table est un **stockage clé/valeur** : ces préférences sont un petit nombre
de chaînes courtes et hétérogènes (un prénom, un booléen, un indice d'échelle),
et ce modèle évite d'ajouter une colonne — donc une migration — à chaque
nouveau réglage.

**Aucune dépendance ajoutée**, conformément à la contrainte « pas de
dépendance Flutter superflue » : le stockage passe par Drift, déjà présent.

**Règle 5 respectée :** ni `maitrise`, ni `score`, ni `niveau`, ni
`progression`, ni `moyenne` dans le modèle **et** dans le schéma. Un réglage
d'affichage est un confort d'usage, pas une observation de l'élève. Un test
scanne le nom des tables et échoue si l'un de ces mots apparaît.

**Règle 6 respectée :** migration explicite + test de **préservation des
données** (`event-v2` survit intact, événement, tentative et réponse).

---

## 8. Trois défauts trouvés et corrigés

Ils sont listés parce qu'ils **n'auraient pas été détectés** sans les tests.

### 8.1 Débordement de 4 px sur Accueil

Les cartes d'accueil avaient une hauteur **fixe** (`SizedBox(height: 132)`).
L'ajout de la barre basse (56 dp) a rendu cette hauteur insuffisante :
`RenderFlex overflowed by 4.0 pixels`. Remplacées par
`ConstrainedBox(minHeight:)` — elles restent généreuses, mais grandissent au
lieu de déborder. La barre basse a également été durcie (`Flexible` + troncature
sur le libellé) pour rester infranchissable, un débordement dans la barre
rendant **tous** les onglets inatteignables.

### 8.2 Échelle de texte verrouillée — défaut d'accessibilité

Première implémentation : `minScaleFactor` **et** `maxScaleFactor` calés sur la
préférence du Profil. Conséquence : le réglage d'accessibilité du téléphone
était **annulé** — un élève qui agrandit la police de son appareil ne le sentirait
pas dans Relio.

Corrigé : la préférence de Relio est un **plancher**, jamais un plafond. Le
système reste respecté. C'est un défaut d'accessibilité réel, pas un détail
cosmétique.

### 8.3 Signal de barre basse erroné

Voir §6.

---

## 9. Contraintes absolues — vérification

| Contrainte | État | Preuve |
|---|---|---|
| Contenu mathématique de la banque inchangé | ✅ | Aucun fichier de `lib/domain/curriculum`, `learning`, `catalog` modifié |
| « PGDC » jamais corrigé | ✅ | 4 occurrences conservées ; test dédié |
| Aucun code D1–D8 visible | ✅ | Test sur les trois onglets |
| Aucun compte / synchro / avatar / badge | ✅ | Test sur le Profil |
| Aucun pourcentage, score, niveau, progression | ✅ | Tests sur les trois onglets |
| Pas de réimplémentation des règles pédagogiques | ✅ | `presentation/rules/` inchangé |
| S1 et S2 non dégradés | ✅ | Les 4 suites historiques passent, après réadaptation de leurs harnais |
| Aucune dépendance superflue | ✅ | `pubspec.yaml` inchangé |
| Moteur pédagogique non modifié | ✅ | `flutter test` : 400/400 |
| Tests du moteur non modifiés | ✅ | Aucun fichier de `test/curriculum/` touché |

---

## 10. Tests

**400 tests passent** (362 avant) — `flutter analyze` : *No issues found!*

| Fichier | Tests | État |
|---|---|---|
| `navigation_test.dart` | **31** | **Nouveau** — trois écrans, navigation, piles |
| `migration_test.dart` | 14 | +6 (v2 → v3) |
| `layout_test.dart` | 13 | +1 (échelle d'espacements/rayons) |
| `learner_flow_test.dart` | 34 | réadapté |
| `answer_lock_test.dart` | 23 | réadapté |
| `parcours_reliability_test.dart` | 13 | réadapté |

> **Point de méthode.** Quatre suites historiques failaient parce qu'elles
> pompaient l'application en supposant que **S1 était la racine**. Plutôt que
> d'affaiblir ces tests, le parcours réel a été rejoué dans chacun
> (Accueil → Apprendre → chapitre 1 → leçon). Les tests vérifient donc
> l'application telle qu'un élève la traverse réellement.

---

## 11. Dépendances non levées

Conformément à la consigne, ces points ont été **remontés et non contournés**.

### 11.1 ⛔ Logo (étape 1.4) — BLOQUÉ

Les fichiers SVG / PNG du mark, du wordmark, de l'icône de launcher et du
splash **n'ont pas été fournis**. Aucun logo n'a été inventé : une approximation
fausse dans un produit destiné aux élèves serait pire qu'une absence.

Il manque : mark, wordmark, launcher icon, splash, déclinaisons 1024 → 24 dp.

**Impact :** l'identité visuelle de marque n'est pas livrée. Les couleurs
`brand` (#F56207) sont en revanche déjà réservées dans les tokens, prêtes à
accueillir le mark.

### 11.2 ⛔ Bouton « Continuer » de l'exercice 11 — BLOQUÉ

La destination n'est pas tranchée. Le bouton **reste actif** et ramène vers S1.
Il n'a pas été désactivé : S1 **est** une destination valide, donc désactiver
le bouton aurait supprimé une actionpossible.

**Impact :** le comportement final du panneau « non concluant » reste à confirmer.

---

## 12. Décisions à valider par le responsable pédagogique

Trois décisions ont été prises pour lever des blocages techniques. Aucune
nengage de contenu pédagogique, mais toutes modifient un comportement visible.

1. **Onglets inatteignables depuis S2** (§6). Conséquence directe de la
   consigne « barre masquée sur S2 ». À confirmer, ou à discuter un compromis —
   par exemple une barre qui s'efface au défilement de l'énoncé.
2. **S1 sans barre de statut** : masqué ou visible ? La consigne dit « la barre
   peut rester visible sur S1 ». Actuel : **visible**, choix le plus simple.
3. **Aucun contenu sur la zone basse d'Accueil**, en attendant un moteur de
   recommandation. Afficher un vide assumé plutôt qu'une fausse promesse.

---

## 13. Limites et risques assumés

- **Aucune validation sur appareil réel.** L'environnement n'a ni téléphone ni
  émulateur. Les 400 tests sont automatisés ; le rendu visuel, la lisibilité à
  360 × 640 et le comportement du clavier virtuel restent à confirmer sur un
  téléphone.
- **APK signé avec la clé de debug.** Acceptable pour un test local, non
  publiable sur le Play Store. Inchangé.
- **Les préférences sont perdues à la désinstallation**, conformément à la
  consigne. Pas de synchronisation.
- **`AGENTS.md` est désormais en retard sur le dépôt.** Il annonce 362 tests et
  un schéma v2 ; le dépôt est à 400 tests et schéma v3. Ce document porte les
  règles de travail du projet : sa mise à jour relève du responsable, elle n'a
  pas été faite unilatéralement.
- **Écarts de nommage conformes à l'existant** : `RelioBottomNav` (coquille) vs
  `RelioColors` supprimé. Choix fait pour éviter un quasi-doublon.

---

## 14. Historique des commits

| Branche | Commit | Contenu |
|---|---|---|
| `main` | `9b1799a` | Code source — 23 fichiers, +3 128 / −327 |
| `apk-build` | `fe44ed2` | `apk/relio-socle-v0.3.4-navigation.apk` + README |

> Le second build d'APK, lancé après le commit du code, a produit un fichier
> **strictement identique** à celui déjà poussé (worktree resté vide après
> copie). Aucun doublon de 22 Mo n'a donc été ajouté à l'historique, et
> `main` ne contient aucun binaire.

---

## 15. Vérification finale

```
flutter analyze   →  No issues found!
flutter test      →  All tests passed!  (400)
flutter build     →  build\app\outputs\flutter-apk\app-release.apk (21,87 Mo)
```

Installation : Android 7.0 (API 24) minimum, architecture `arm64-v8a`,
« sources inconnues » à autoriser, signé avec la clé de debug.

Télécharger :
<https://github.com/digitalholding2026-ux/relio-flutter-dart/tree/apk-build/apk>