# Relio — APK de démonstration

Cette branche contient uniquement l'**artefact compilé**, pratique pour le
télécharger et l'installer sur un téléphone.

## Fichiers

| Fichier | Taille | Contenu |
|---|---|---|
| `apk/relio-socle-v0.3.2-verification-transfert.apk` | ~21,9 Mo | **Dernier build.** Cœur de la vérification de transfert |
| `apk/relio-socle-v0.3.1-verrouillage.apk` | ~21,9 Mo | Verrouillage du champ après validation |
| `apk/relio-socle-v0.3.0-fiabilisation.apk` | ~21,9 Mo | Fiabilisation du parcours et des réponses |
| `apk/relio-socle-v0.3.0-parcours-ch1.apk` | ~21,5 Mo | Écrans S1 / S2 |
| `apk/relio-socle-v0.2.0-mission2.apk` | ~20,3 Mo | Moteur pédagogique du chapitre 1 |
| `apk/relio-socle-v0.1.0.apk` | ~20,3 Mo | Socle technique |

## Téléchargement

Ouvrir le fichier choisi depuis cette branche sur GitHub, puis **Raw** pour
télécharger le binaire.

## ⚠️ Installer dans l'ordre

Les `versionCode` increases à chaque build (1 → 2). Android **refuse**
d'installer un APK dont le `versionCode` est inférieur ou égal à celui déjà
installé. Pour mettre à jour, installer le **dernier** fichier, dans l'ordre
chronologique ci-dessus.

## Installation

1. Copier l'APK sur le téléphone.
2. L'ouvrir depuis le gestionnaire de fichiers.
3. Autoriser « sources inconnues » / « installer des applications
   inconnues » quand Android le demande.

## Prérequis

- **Android 7.0 (API 24) minimum** — imposé par la dépendance SQLite, pas
  par Relio lui-même.
- Architecture `arm64-v8a` : couvre la quasi-totalité des téléphones
  Android actuels. Les anciennes architectures 32 bits ne sont pas incluses
  dans ce build.

## Signature

Le fichier est signé avec une **clé de debug**. C'est suffisant pour un
essai local, mais ce n'est pas publiable sur le Play Store. La clé de
publication réelle reste à créer (voir `docs/ARCHITECTURE.md`, point à
arbitrer n° 6).

## Contenu du dernier build

`relio-socle-v0.3.2-verification-transfert.apk` — cœur métier de la
vérification de transfert du chapitre 1 :

- **Association activée** : exercice 1 (`PGCD(18,12)`) → tâche
  `PGCD(16,12) par soustractions`, couple différent, même méthode ;
- **Deux associations laissées inactives** : `PGCD(35,20)` (son énoncé ne
  demande pas Euclide et c'est le contrôle du cas D4) et
  `PPCM de 10 et 15` (la valeur seule suffit, la relation n'est pas
  vérifiée) ;
- le moteur expose désormais **ce que l'évaluateur contrôle réellement** :
  seule la valeur finale, **jamais la méthode** ;
- quatre issues distinctes pour le résultat : réussite, échec évaluable,
  **indéterminé**, **erreur technique**. Les deux dernières ne produisent
  aucune conclusion ni remédiation ;
- après un échec sans difficulté étayée : reprise guidée **sans diagnostic
  affirmatif**, et les contenus manquants sont signalés.

> **L'écran S4 reste fermé dans cette version.** Ce build pose la logique
> métier ; son affichage relève de l'interface.

### Précédent build

`relio-socle-v0.3.1-verrouillage.apk` — verrouillage de l'écran S2 après
validation :

- le champ de réponse reste **visible et relisible**, mais devient non
  éditable : ni focus, ni clavier, ni copier-coller ;
- « Valider » reste **visible**, désactivé ;
- « Demander un indice » reste visible s'il l'était, désactivé ;
- le clavier se **ferme** dès l'apparition du panneau ;
- un retour par la flèche de l'AppBar **conserve le panneau** : à la
  réouverture, l'élève retrouve exactement l'état quitté ;
- « Exercice suivant » vide et déverrouille le champ, avec reprise du focus.

Le moteur pédagogique, la classification et le contenu mathématique sont
**inchangés** : c'est une règle d'interface, dérivée de la seule présence
d'un panneau affiché.

### Précédent build

`relio-socle-v0.3.0-fiabilisation.apk` — fiabilisation du parcours du
chapitre 1 :

- **Correction** : les réponses mathématiquement équivalentes sont désormais
  reconnues (`÷` et `/`, `×`, `*`, `x`, accents, espaces). Un entier saisi à
  l'exercice 11 n'est plus enregistré comme **faux** : il est **non
  évaluable**. Les accents français ne font plus rejeter une bonne réponse.
- **Type de réponse** : le clavier est désormais déduit des critères de
  correction, au lieu d'une convention de position.
- **Parcours** : « Valider » est neutralisé après soumission — plus de
  tentatives identiques empilées dans l'historique immuable.
- **Police Inter** embarquée (licence SIL OFL 1.1), variables d'énoncé en
  italique, sans dépendance ajoutée.

Voir `docs/INTERFACE.md` et `docs/VERIFICATION.md` sur `main`.

> **Ce build n'a pas été testé sur un appareil Android réel** : aucun
> téléphone ni émulateur n'est disponible dans l'environnement de
> compilation. Les tests sont automatisés.

## ⚠️ Branche de distribution, pas de développement

- `main` porte le code. C'est là que le développement se fait.
- `apk-build` porte les binaires. Elle grossit à chaque nouveau build.

Le code de cette branche est identique à `main`. Ne pas y développer.
