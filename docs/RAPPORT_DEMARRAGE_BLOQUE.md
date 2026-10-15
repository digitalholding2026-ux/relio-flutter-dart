# Rapport — Démarrage bloqué de Relio

> Contexte : après l'intégration de l'expérience d'entrée (parcours en sept
> étapes).
> Version livrée : `0.4.1+14` — `relio-socle-v0.4.1-demarrage.apk`.
> Commits : `b4a4269` (correctif), `4d514a0` (largeur du texte), `e3508a5`
> (publication).

---

## 1. Symptôme constaté sur appareil

L'application était installée sur un téléphone Android. Au lancement :

- écran presque entièrement **blanc** ;
- **cinq petits points** visibles en haut ;
- aucun texte, aucun bouton, aucun écran d'accueil ;
- l'application **restait dans cet état** et ne progressait pas.

Le parcours d'entrée était inutilisable : l'élève ne pouvait pas sortir de
l'écran.

---

## 2. Cause précise

### 2.1 Le mécanisme

Quatre écrans lisaient la valeur de leur `AnimationController` **directement
dans `build()`**, sans s'abonner à l'animation :

```dart
// AVANT — le contrôleur tourne, mais l'écran ne se redessine jamais
@override
Widget build(BuildContext context) {
  final double t = Curves.easeOut.transform(_block(index)); // _reveal.value
  return Opacity(opacity: t, child: /* … */);
}
```

`build()` n'est rejoué que si un **autre** élément de l'arbre le demande.
Ces écrans n'ont aucune autre source de reconstruction : le contrôleur
tourne, et l'écran reste peint à son état initial.

Or tout leur contenu apparaît par un fondu démarré à `Opacity 0`. L'écran
reste donc **entièrement transparent** : invisible, sans exception, sans
log, sans blocage technique.

### 2.2 Pourquoi l'état observé est exactement « cinq points »

L'apparition est décalée : chaque bloc atteint son opacité 1 à un instant
différent de la chronologie.

| Bloc | Visible à partir de |
|---|---|
| Les cinq pastilles | 277 ms |
| Le texte | 362 ms |
| Le bouton | 631 ms |

Une reconstruction déclenchée vers 300 ms repeint donc l'écran avec les
pastilles à 1 et le reste à 0 — **exactement l'état décrit**. Plus aucune
reconstruction ensuite : l'écran reste figé.

### 2.3 Les quatre écrans concernés

| Fichier | Statut | Symptôme |
|---|---|---|
| `lib/presentation/screens/onboarding/entry_test_intro_page.dart` | ajouté par la mission précédente | **blocage signalé** |
| `lib/presentation/screens/onboarding/welcome_page.dart` | ajouté par la mission précédente | tout invisible |
| `lib/presentation/screens/onboarding/closing_page.dart` | **préexistant** | texte et bouton à 0 en permanence |
| `lib/presentation/screens/onboarding/name_page.dart` | **préexistant** | figé à la sortie |

Deux de ces écrans étaient **déjà cassés avant la mission précédente**.
Celle-ci a importé le défaut sur deux écrans nouveaux sans le révéler.

### 2.4 Pourquoi 674 tests passaient

`find.text(...)` renvoie `true` pour un widget **présent dans l'arbre même
s'il est peint à `Opacity 0`**. Les tests existants vérifiaient la
*présence* du texte et du bouton, jamais leur *visibilité*.

**Il manquait une catégorie de test, pas une assertion.**

---

## 3. Corrections apportées

### 3.1 Abonnement à l'animation

`AnimatedBuilder` dans les quatre écrans. Pour la clôture, qui anime trois
contrôleurs, `Listenable.merge` les regroupe :

```dart
return AnimatedBuilder(
  animation: Listenable.merge(<Listenable>[_grow, _text, _button]),
  builder: (BuildContext context, _) => Scaffold(…),
);
```

### 3.2 « Réduire les animations » masquait l'écran du prénom

`name_page.dart` fixait `contentOpacity` à **0** quand les animations sont
réduites : ni titre, ni champ, ni bouton. Ce réglage d'accessibilité
rendait l'écran inutilisable.

Réduire les animations doit retirer le mouvement, **jamais l'information**.

### 3.3 Écran blanc sans issue au démarrage

`RelioApp` pouvait rester indéfiniment sur `_SplashGate` — un fond blanc —
si la lecture du drapeau ne répondait pas.

- délai borné à **8 s** ;
- au-delà, écran d'erreur explicite avec un bouton **Réessayer** ;
- le réessai **relit** le drapeau depuis le début, sans rien supposer de
  l'échec précédent.

### 3.4 Le mot et la signature n'occupaient aucune largeur

Défaut trouvé par capture de rendu, **distinct du blocage**.

`RelioWordmark` et `RelioSignature` peignaient leur texte via un
`CustomPaint` dont l'enfant valait `SizedBox.shrink()`. La boîte mesurait
donc **zéro de largeur** : la mise en page ignorait le mot, et le texte se
superposait à la marque avant de sortir de l'écran.

Mesure du lockup complet, avant et après :

| | Largeur annoncée |
|---|---|
| Avant | **50,9 dp** — soit la largeur du mark seul |
| Après | **210,7 dp** |

Remplacé par un `Text`, avec gouttière forcée et `height: 1` pour fixer la
boîte à la taille du corps. Le mot devient aussi sélectionnable et lisible
par un lecteur d'écran.

Le défaut touchait également **l'accueil**, qui affiche le même lockup.

---

## 4. Fichiers modifiés

| Fichier | Modification |
|---|---|
| `lib/presentation/screens/onboarding/entry_test_intro_page.dart` | `AnimatedBuilder` |
| `lib/presentation/screens/onboarding/welcome_page.dart` | `AnimatedBuilder` |
| `lib/presentation/screens/onboarding/closing_page.dart` | `AnimatedBuilder` + `Listenable.merge` |
| `lib/presentation/screens/onboarding/name_page.dart` | `AnimatedBuilder` + opacité corrigée |
| `lib/presentation/branding/relio_mark.dart` | `Text` à la place des deux painters |
| `lib/app.dart` | délai borné, `_Stage.startupFailed`, écran de réessai |
| `lib/presentation/strings/relio_strings.dart` | libellés de l'écran d'erreur |
| `pubspec.yaml` | `0.4.1+14` |

---

## 5. Tests ajoutés

Le cœur du correctif est la couverture, pas le code.

### 5.1 `test/presentation/onboarding_visibility_test.dart`

Vérifie l'**opacité effective**, pas la présence dans l'arbre. C'est le
test qui manquait, et il échoue sur le code d'avant.

- sur les quatre écrans, `min(opacity) == 1` une fois l'animation terminée ;
- l'animation progresse réellement d'une image à l'autre ;
- le lockup occupe une largeur réelle et tient dans 360 dp.

### 5.2 `test/presentation/entry_journey_test.dart`

Le parcours réel, de bout en bout, sur base réelle :

- **A → G** : ouverture, bienvenue, introduction, prénom, les cinq questions
  répondues, clôture, accueil ;
- **B** : prénom déjà connu, parcours inachevé → le test démarre ;
- **C** : parcours terminé → l'accueil s'ouvre directement ;
- **H** : fermeture et réouverture en cours de questionnaire → reprise à la
  bonne question, sans redemander ce qui est déjà saisi.

### 5.3 `tool/capture_parcours_test.dart`

Capture le **rendu réel** de chaque écran à 360 × 640, police Inter chargée.
Une capture d'un écran bloqué donne une image blanche — ce que les assertions
d'arbre ne savent pas voir.

| Capture | Écran | Verdict |
|---|---|---|
| `2-bienvenue.png` | Bienvenue | correct — lockup entier, texte, bouton |
| `3-introduction.png` | Introduction au questionnaire | **correct — c'était l'écran bloqué** |
| `4-prenom.png` | Prénom | **défaut de mise en page, voir § 5.4** |
| `6-cloture.png` | Clôture | correct — texte exact, bouton, aucun recouvrement |

L'outil est ce qui a révélé le défaut de largeur du § 3.4. Il a aussi révélé
celui du § 5.4.

### 5.4 Défaut trouvé APRÈS le correctif — titre et personnage superposés

Défaut **préexistant**, distinct du blocage, **non corrigé** à ce jour.

Sur l'écran du prénom, le titre « Comment tu t'appelles ? » passe **sur le
personnage**. Mesuré à 360 × 640 :

| Élément | Occupe |
|---|---|
| Personnage | 182 → 302 |
| Titre | 252 → 308 |
| Champ | 332 → 388 |
| Bouton | 572 → 620 |

Recouvrement de **50 px** entre le bas du personnage et le titre.

**Cause :** `name_page.dart` compose l'écran avec un `Stack` — personnage
`Align` d'un côté, contenu centré de l'autre. Les deux se superposent donc par
construction. `closing_page.dart` a exactement été corrigé de cette façon
(le commentaire qui s'y trouve décrit le défaut), mais `name_page.dart` a
gardé le `Stack`.

**Pourquoi aucun test ne l'a vu :** `tester.takeException()` ne signale **pas**
un chevauchement de `Stack` — seuls les débordements de `Flex` lèvent. Un
`expect(tester.takeException(), isNull)` passe donc malgré le recouvrement.

**Non corrigé ici**, le rapport se terminant sur le correctif de démarrage et
la publication. La correction est connue : reprendre la disposition en
colonne de `closing_page.dart`, ou ancrer le personnage dans le tiers
supérieur comme le fait déjà `entry_test_page.dart`.

---

## 6. Résultats

| Vérification | Résultat |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **688 tests passés** |
| Build APK release | **22,1 Mo** |

---

## 7. Limites de la vérification

**Cette version n'a pas été lancée sur un téléphone Android.**

L'environnement de compilation n'a ni appareil connecté ni émulateur
possible : `HypervisorPlatform` est `Disabled`, et l'activer exigerait un
redémarrage de la machine. Aucun test sur appareil n'a donc été réalisé.

**Ce qui a été vérifié :** tests automatisés, et capture du rendu réel des
**quatre écrans du parcours** à la résolution de référence. Trois des quatre
sont visuellement corrects ; l'écran du prénom porte un défaut de mise en page
distinct (§ 5.4), **présent dans l'APK publié**.

**Ce qui ne l'a pas été :**

- le rendu tactile réel des trois nouveaux boutons ;
- l'apparition effective du clavier Android sur le champ prénom et les
  questions numériques ;
- le comportement du bouton Retour Android ;
- la reprise après passage en arrière-plan ;
- la fluidité perçue des animations.

Ces points restent à confirmer sur un téléphone. C'est la seule vérification
qui manque, et elle n'est pas substituable.

---

## 8. Leçon retenue

La mission précédente a été déclarée terminée sur la base de
`flutter analyze` et de 674 tests verts. **Ces deux signaux étaient
insuffisants**, et je ne les avais pas complétés par une vérification de
visibilité ni par une capture.

Trois règles en découlent, désormais appliquées au dépôt :

1. **Un `find.text(...)` qui passe ne prouve pas que l'écran est visible.**
   Tester l'opacité.
2. **Un écran animé doit s'abonner à son animation.** Lire `.value` dans
   `build()` est un bug silencieux : il ne lève rien et ne s'inscrit dans
   aucun journal.
3. **`pumpAndSettle` ne convient pas à un écran qui attend entre deux
   animations** : pendant un `Future.delayed` aucune frame n'est attendue,
   donc la boucle rend la main avant que le contenu soit apparu. Un test peut
   ainsi conclure qu'un écran est prêt alors qu'il est encore vide.

---

## 9. Avertissement de distribution

`relio-socle-v0.4.0-parcours-entree.apk` est **défectueux** : c'est la
version du blocage décrit ci-dessus. L'installer ne fait que reproduire
l'écran blanc. Il est conservé pour la trace — la règle 7 du dépôt interdit
de supprimer un APK publié sans demande explicite.

**Installer `relio-socle-v0.4.1-demarrage.apk` à la place.**