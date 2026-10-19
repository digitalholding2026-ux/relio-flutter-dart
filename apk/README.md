# Relio — APK de démonstration

Cette branche contient uniquement les **artefacts compilés**, pratique pour les
télécharger et les installer sur un téléphone.

Les anciens APK ont été retirés de cette branche : elle servait de fourre-tout
et atteignait un poids qui rendait le dépôt pénible à cloner. Seuls les
derniers builds sont conservés ici. Le code, lui, est sur `main`.

## Fichiers

| Fichier | Taille | Contenu |
|---|---|---|
| `apk/relio-socle-v0.4.2-budget-fiches-definitives.apk` | 22,5 Mo | **Dernier build.** Budget progressif et fiches définitives des leçons 1 et 2 |
| `apk/relio-socle-v0.4.2-indices-riches.apk` | 22,5 Mo | Fiches d'indices riches (Bottom Sheet) et budget d'aide |

## Téléchargement

Ouvrir le fichier choisi depuis cette branche sur GitHub, puis **Raw** pour
télécharger le binaire.

## ⚠️ Installer le dernier

Les `versionCode` augmentent à chaque build. Android **refuse** d'installer un
APK dont le `versionCode` est inférieur ou égal à celui déjà installé :
**installez `relio-socle-v0.4.2-budget-fiches-definitives.apk`**, pas
l'avant-dernier.

## Installation

1. Copier l'APK sur le téléphone.
2. L'ouvrir depuis le gestionnaire de fichiers.
3. Autoriser « sources inconnues » / « installer des applications
   inconnues » quand Android le demande.

## Prérequis

- **Android 7.0 (API 24) minimum** — imposé par la dépendance SQLite, pas
  par Relio lui-même.
- `versionCode` 18, `targetSdk` 36.
- L'APK embarque les architectures `arm64-v8a`, `armeabi-v7a` et `x86_64` :
  il s'installe sur la quasi-totalité des téléphones Android actuels.

## Signature

Le fichier est signé avec une **clé de debug**. C'est suffisant pour un essai
local, mais ce n'est pas publiable sur le Play Store. La clé de publication
réelle reste à créer (voir `docs/ARCHITECTURE.md` sur `main`).

## Contenu du dernier build

`relio-socle-v0.4.2-budget-fiches-definitives.apk` — **budget progressif et
fiches définitives**.

### Les fiches sont définitives

Les leçons 1 et 2 (exercices 1 à 7) portent leur contenu rédigé, et non plus
une phrase générique par indice :

- **texte** en corps 16 ;
- **formule encadrée** en gris, passée au formateur mathématique (les signes
  `−`, `×`, `÷` sont ceux de la source) ;
- **point à retenir** sur fond orange avec liseré ;
- **retour vers l'élève** en indigo gras, qui attend une action et non une
  lecture.

Chaque fiche s'ouvre dans le panneau glissant déjà connu, à 75 % de la hauteur
maximum, avec l'énoncé qui reste visible au-dessus.

### L'aide se retire vraiment dans la leçon

Le budget n'est plus le nombre de fiches du dossier : il décroît d'exercice en
exercice, de `M` fiches au premier à 1 au dernier.

- Leçon 1 (PGCD par soustractions) : **3 → 2 → 1 → 1**
- Leçon 2 (algorithme d'Euclide) : **3 → 2 → 1**
- Leçon 3 (relation PPCM–PGCD) : **aucune fiche**, donc aucune aide

Le libellé du bouton suit le budget restant : « Demander un indice », puis
« Indice suivant », puis « Indice final ».

> **Une règle arithmétique à connaître pour lire l'application** : un exercice
> ne peut jamais proposer plus d'aides que le nombre de fiches qu'il possède.
> C'est pourquoi l'exercice 3, qui n'a qu'une fiche, s'arrête à une seule aide
> même si la règle de la leçon lui en accorde deux.

### L'interface passe en indigo et orange officiels

Boutons, navigation et titres sont désormais en **indigo `#1F3A6E`** et
**orange `#F56207`**.

Le **logo garde ses couleurs mesurées** (`#0E1821` et `#FE7904`) : ce sont deux
usages distincts — la marque livrée et l'interface — et non une dérive.

### Vérifications

- `flutter analyze` : **No issues found !**
- `flutter test` : **774 tests verts** (756 + 18 nouveaux)
- `versionCode` 18 — Android refusera toute installation antérieure

Non vérifié sur appareil réel.

### Précédent build

`relio-socle-v0.4.2-indices-riches.apk` — **fiches d'indices riches et budget
d'aide**.

Les indices ne sont plus de simples phrases affichées sous l'énoncé : ils
s'ouvrent dans une **fiche** en panneau glissant, et leur consommation suit un
budget. Les quatre natures de blocs et le bouton d'aide à libellé variable
sont déjà en place, mais le **contenu des fiches restait celui de la banque**,
tel quel, sans reformulation. C'est précisément ce que le build ci-dessus
corrige.

## ⚠️ Branche de distribution, pas de développement

- `main` porte le code. C'est là que le développement se fait.
- `apk-build` porte les binaires. Elle ne contient aucun code à modifier.

Le code de cette branche est identique à `main`. Ne pas y développer.