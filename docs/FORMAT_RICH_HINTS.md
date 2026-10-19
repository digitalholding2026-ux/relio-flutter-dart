# Format attendu pour les fiches RichHint définitives

Ce document décrit le format que j'attends pour intégrer tes fiches dans
`lib/domain/curriculum/chapter1_bank.dart`. Il correspond exactement aux
modèles déjà en place, testés et validés.

---

## 1. Vue d'ensemble

Chaque exercice peut porter une liste de fiches. Une fiche a un **titre** et
une liste de **blocs**. Le moteur calcule le budget ; l'interface ne fait que
l'afficher.

```
Exercice
 └── hints: List<RichHint>          ← tes fiches
      ├── RichHint
      │    ├── order     : int      ← 1, 2, 3…
      │    ├── title     : String   ← titre de la fiche
      │    ├── blocks    : List<HintBlock>
      │    └── isFinal   : bool     ← déduit du budget, ne pas le saisir
      └── …
```

---

## 2. Les quatre types de blocs

### `TextBlock` — explication en corps de texte

```
TextBlock('Soustrais le plus petit nombre du plus grand.')
```

Rendu : Body 16 / Regular, sans encadré.

### `MathBlock` — formule ou calcul

```
MathBlock('18 − 12 = 6')
MathBlock('PGCD(18, 12) = PGCD(12, 6)')
```

Rendu : encadré gris `#F3F4F6`, bordure `#E4E7EC`, rayon 8, padding 12.
Passe par le **formateur mathématique existant** : variables isolées en
italique, chiffres en tabulaire, opérateurs droits, acronymes (PGCD, PPCM)
jamais italiques.

> ⚠️ Écris les opérateurs avec leur vrai glyphe : `−` (U+2212 moins),
> `×` (U+00D7), `÷` (U+00F7), `=` (U+003D). Un `-` ascii n'est pas reconnu
> comme opérateur par le formateur.

### `HighlightBlock` — le point à retenir

```
HighlightBlock('Le PGCD est toujours plus petit que les deux nombres.')
```

Rendu : fond orange pâle `#FEF0E6`, liseré gauche orange `#F56207` de 4 dp,
texte indigo `#1F3A6E` gras.

### `HandoffBlock` — retour vers l'élève

```
HandoffBlock('Et toi, quel nombre tu soustrais en premier ?')
```

Rendu : indigo `#1F3A6E` gras, sans encadré, suivi d'un filet si d'autres blocs
suivent.

> Un `HandoffBlock` attend une **action** de l'élève, pas une lecture. C'est
> le seul bloc qui soit une question.

---

## 3. Deux formats possibles, au choix

### Option A — Dart direct (recommandé pour cette banque)

Le plus simple : j'insère ton code dans `chapter1_bank.dart`. Aucun outil
supplémentaire, aucune conversion.

```dart
hints: <RichHint>[
  RichHint(
    order: 1,
    title: '💡 Comprendre cette étape',
    blocks: <HintBlock>[
      TextBlock('Soustrais le plus petit nombre du plus grand.'),
      MathBlock('18 − 12 = 6'),
      HighlightBlock('On continue tant que les deux nombres sont différents.'),
    ],
  ),
  RichHint(
    order: 2,
    title: '💡 Comprendre cette étape',
    blocks: <HintBlock>[
      TextBlock('Tu as trouvé 6. On recommence avec 12 et 6.'),
      MathBlock('12 − 6 = 6'),
      HandoffBlock('Essaie avec un autre couple de nombres.'),
    ],
  ),
],
```

### Option B — JSON (recommandé si tu produis les fiches en lots)

Je te fournis un script de conversion JSON → Dart, et un test qui vérifie que
chaque fiche est bien convertible.

```json
{
  "exerciseId": "ch1-ex-1-pgcd-soustractions-guide",
  "hints": [
    {
      "order": 1,
      "title": "💡 Comprendre cette étape",
      "blocks": [
        { "type": "text",     "text": "Soustrais le plus petit du plus grand." },
        { "type": "math",     "text": "18 − 12 = 6" },
        { "type": "highlight", "text": "On continue tant que les nombres diffèrent." }
      ]
    }
  ]
}
```

---

## 4. Règles que j'applique automatiquement

Tu n'as pas à t'en préoccuper, mais voici ce qui est vérifié par les tests :

| Règle | Effet |
|---|---|
| `order` unique et croissant à partir de 1 | `hintId` = `h<order>`, stable dans l'historique |
| `isFinal` non saisi | déduit : `order == nombre de fiches` |
| Aucun texte vide | un bloc vide est rejeté, pas affiché |
| Un bloc `math` doit contenir un opérateur ou une égalité | sinon il devient un `TextBlock` |

---

## 5. Ce dont j'ai besoin de toi

**Le strict minimum :** le titre, les blocs, dans l'ordre, pour chaque fiche.

**Utile en plus :** la réponse à la question de handoff, si elle existe. Elle
n'est pas rendue dans la fiche (le bloc ne porte qu'une invitation), mais elle
pourra alimenter la trace d'apprentissage plus tard. Écris-la en commentaire,
ou dans un champ séparé si tu préfères.

---

## 6. Ce qui ne change pas

- La **logique de correction** n'est pas touchée.
- Le **parcours d'entrée** et les **5 questions** ne sont pas touchés.
- L'**historique** reste append-only : un indice consommé est un fait.
- Les `ExerciseHint` actuels sont conservés : ils servent d'historique de
  session (`HintArea`). Tes fiches s'ajoutent à côté, sans les remplacer.

---

## 7. Reste à faire après réception

> **Fait.** Les fiches des leçons 1 et 2 sont intégrées dans
> `chapter1_bank.dart` sous `richHints`. Voir le commit
> « Intégration du budget progressif et des fiches définitives ».

1. ~~Intégration des fiches dans `chapter1_bank.dart`.~~ — **fait**.
2. `flutter analyze` + `flutter test` — **774 tests verts**.
3. Build de l'APK et publication en **GitHub Release** (règle 2).

> Reste ouvert : les fiches de la **leçon 3** (relation PPCM–PGCD) ne sont pas
> encore rédigées. Ces exercices n'offrent donc aucune aide tant qu'elles
> manquent.