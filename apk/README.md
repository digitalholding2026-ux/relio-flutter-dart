# Relio — APK de démonstration

Cette branche contient uniquement l'**artefact compilé**, pratique pour le
télécharger et l'installer sur un téléphone.

## Fichiers

| Fichier | Taille | Contenu |
|---|---|---|
| `apk/relio-socle-v0.4.2-prenom.apk` | ~22,1 Mo | **Dernier build.** Correction du chevauchement sur l'écran du prénom |
| `apk/relio-socle-v0.4.1-demarrage.apk` | ~22,1 Mo | Démarrage corrigé — mais titre et personnage superposés |
| `apk/relio-socle-v0.4.0-parcours-entree.apk` | ~22,1 Mo | ⚠️ **Ne pas installer** — écran d'introduction invisible |
| `apk/relio-socle-v0.3.9-marque.apk` | ~22,1 Mo | Nouveau mark, icône d'application et logo principal |
| `apk/relio-socle-v0.3.9-audit.apk` | ~22,1 Mo | Audit onboarding : trois corrections d'affichage |
| `apk/relio-socle-v0.3.8-onboarding.apk` | ~22,1 Mo | Onboarding complet : prénom, test d'entrée, clôture |
| `apk/relio-socle-v0.3.7-marqueurs-onboarding.apk` | ~21,9 Mo | Marqueurs d'onboarding |
| `apk/relio-socle-v0.3.6-test-entree.apk` | ~21,9 Mo | Test d'entrée de cinq questions |
| `apk/relio-socle-v0.3.5-bouton-entree.apk` | ~21,9 Mo | Bouton d'entrée |
| `apk/relio-socle-v0.3.4-logo.apk` | ~21,9 Mo | Ancienne marque : deux points et une courbe |
| `apk/relio-socle-v0.3.4-navigation.apk` | ~21,9 Mo | Navigation à trois onglets, Accueil, Apprendre, Profil |
| `apk/relio-socle-v0.3.4-relation-ppcm.apk` | ~21,7 Mo | Contrat « relation PPCM–PGCD appliquée » |
| `apk/relio-socle-v0.3.4-ecran-entree.apk` | ~21,9 Mo | Écran d'entrée animé |
| `apk/relio-socle-v0.3.4-corrections.apk` | ~21,9 Mo | Corrections d'affichage |
| `apk/relio-socle-v0.3.3-typographie.apk` | ~21,7 Mo | Police Inter + formateur typographique |
| `apk/relio-socle-v0.3.2-verification-transfert.apk` | ~21,9 Mo | Cœur de la vérification de transfert |
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

`relio-socle-v0.4.2-prenom.apk` — **fin de la série de correctifs**.

Reprend tout le `0.4.1` et corrige le dernier défaut connu : sur l'écran du
prénom, le titre « Comment tu t'appelles ? » passait **sur le personnage**,
avec 50 px de recouvrement.

L'écran est passé d'une superposition à une disposition en colonne —
personnage en haut, titre et champ dans la place restante, bouton en bas.
Aucun changement de design par rapport à `0.4.1` : c'est la même
répartition, sans que les deux éléments se marchent dessus.

> Les versions précédentes restent utilisables mais portent ce défaut :
> **`0.4.0` est bloqué**, **`0.4.1` fonctionne mais le prénom est mal
> composé**. Installez `0.4.2`.

### Précédent build

`relio-socle-v0.4.1-demarrage.apk` — **correction du démarrage bloqué**.

Sur la version précédente, l'application s'ouvrait sur un écran presque
blanc : cinq petits points en haut, aucun texte, aucun bouton, et plus
rien. **Le parcours était inutilisable.**

La cause : quatre écrans lisaient la valeur de leur animation directement
dans `build()`, sans s'abonner à l'animation. Le contrôleur tournait, mais
l'écran ne se redessinait jamais — et comme tout le contenu apparaissait par
un fondu, il restait invisible. Aucun message, aucune erreur : seulement un
écran vide.

Trois défauts corrigés :

- **le contenu ne s'affichait plus** sur l'introduction au questionnaire, la
  bienvenue, le prénom et la clôture ;
- **« réduire les animations » masquait l'écran du prénom** — ni titre, ni
  champ, ni bouton ;
- **le mot « Relio » et sa signature n'occupaient aucune largeur**, et se
  superposaient à la marque avant de sortir de l'écran. Visible aussi sur
  l'accueil.

> ⚠️ **`relio-socle-v0.4.0-parcours-entree.apk` est défectueux** : c'est la
> version du blocage ci-dessus. L'installer ne fait que reproduire l'écran
> blanc. Il est conservé pour la trace ; **installez la 0.4.2 à la place**.

Cette série n'a **pas** été vérifiée sur un téléphone : l'environnement de
compilation n'a ni appareil ni émulateur. Le parcours a été validé par
tests automatisés et par capture du rendu réel des écrans, ce qui a détecté
le défaut, mais **le comportement tactile reste à confirmer sur appareil**.

### Précédent build

`relio-socle-v0.4.0-parcours-entree.apk` — parcours d'entrée en sept étapes,
**mais bloqué à l'introduction du questionnaire** (voir ci-dessus).

1. **Ouverture** — le logo se révèle, sans bouton et sans attente. L'écran
   enchaîne tout seul, et rien n'y est enregistré : si l'élève le quitte,
   il le reverra.
2. **Bienvenue** — « Salut, moi c'est Relio !… », bouton **Commencer**.
3. **Introduction au questionnaire** — cinq pastilles qui promettent une
   étape courte. **C'est le seul endroit où `entryScreenSeen` est écrit.**
4. **Prénom** — 24 caractères maximum, lettres et espaces uniquement,
   première lettre en majuscule.
5. **Questionnaire** — cinq questions, sans indice, sans correction, sans
   score ni diagnostic.
6. **Conclusion** — « Merci {prénom} ! Je commence à mieux te connaître. »
7. **Accueil**.

Le parcours reprend exactement où il s'était arrêté. Abandonner au milieu du
questionnaire ne le fait pas disparaître : les réponses déjà enregistrées
sont conservées, et l'élève retrouve la question suivante.

> Une réponse n'est enregistrée qu'une fois l'écriture **confirmée**. Si elle
> échoue, l'élève reste sur la question, sa saisie n'est pas effacée et il
> peut réessayer sans jamais créer de doublon.

### Précédent build

`relio-socle-v0.3.9-marque.apk` — **la marque Relio est entièrement
remplacée** par les deux fichiers fournis, propagés à toute l'application :

- **nouveau mark** : un « R » ajouré, deux zigzags et un point orange ;
- **icône d'application** : fond indigo à coins arrondis, mark en blanc et
  orange, déclarée en calques Android séparés — le fond n'est plus cuit
  dans l'image, donc les masques des constructeurs ne le rognent plus ;
- **splash** : fond blanc, mark, « Relio » puis la signature
  « Les maths, c'est ton terrain ! », le tout en Inter SemiBold ;
- **écran d'entrée** : le personnage animé est le nouveau mark. Il garde
  **exactement trois mouvements** — le « R » respire, le point pulse
  décalé, le zigzag d'accent ondule ;
- **en-tête d'accueil** : lockup horizontal avec le nouveau mark.

La marque est **générée**, pas dessinée : la géométrie vit dans un seul
fichier, et le SVG, les PNG et le rendu à l'écran lisent la même
définition. Un test rejoue l'import depuis la spécification versionnée et
échoue si la géométrie en dérive.

### Précédent build

`relio-socle-v0.3.4-logo.apk` — **l'ancienne marque Relio**, deux cercles
(Ø 28 et Ø 15,4) reliés par une courbe, en `#F56207` seul, avec splash,
icône d'application et en-tête d'accueil. Conservé pour comparaison.

### Précédent build

`relio-socle-v0.3.4-navigation.apk` — navigation globale et écrans
d'accueil, d'apprentissage et de profil :

- **trois onglets permanents** en barre basse : Accueil, Apprendre, Profil.
  Aucun autre onglet, même grisé ;
- l'application **ouvre sur Accueil**, plus sur S1 ;
- **piles indépendantes** : changer d'onglet ne réinitialise pas la pile de
  l'onglet quitté — le brouillon de saisie, les indices et la position de
  défilement sont restaurés au retour ;
- **Accueil** : en-tête « Bonjour » (+ prénom), carte « Commence ici » qui
  ouvre S1, carte « Programme de 3e » qui bascule sur Apprendre ;
- **Apprendre** : chapitre 1 actif, chapitres suivants « Bientôt
  disponible » et non cliquables ;
- **Profil** : identité (nom, classe), affichage (taille de texte, contraste
  renforcé), accessibilité (réduire les animations). Préférences persistées
  **localement**, sans compte ni synchronisation ;
- **S1** est atteinte depuis Apprendre : sa flèche de retour ramène à
  l'écran Apprendre ;
- **S2 masque la barre de navigation** : l'exercice occupe l'espace, sa barre
  d'action fixe reste seule ;
- schéma de stockage passé en **version 3** (préférences), sans perte
  d'historique d'apprentissage.

Aucun pourcentage, aucun score, aucun badge, aucune progression, aucun code
diagnostique interne, aucun compte, aucune mécanique de jeu. La taille de texte
choisée dans le profil ne réduit jamais celle réglée dans le système.

### Précédent build

`relio-socle-v0.3.4-navigation.apk` — navigation globale :

- **trois onglets permanents** en barre basse : Accueil, Apprendre, Profil ;
- l'application **ouvre sur Accueil**, plus sur S1 ;
- **piles indépendantes** par onglet ;
- schéma de stockage passé en **version 3** (préférences).

### Précédent build

`relio-socle-v0.3.4-relation-ppcm.apk` — la tâche de vérification
`PPCM de 10 et 15, avec PGCD 5` vérifie désormais réellement l'**application
écrite** de la relation :

- **`30` seul n'est plus accepté** : le bon résultat sans démonstration ne
  prouve rien ;
- un calcul écrit comportant la division est exigé et **évalué** — `10*15/5`,
  `150/5`, `150 ÷ 5`, `10 × 15 / 5`, `10*15/5 = 30` sont acceptés ;
- un calcul faux reste un **échec évaluable** : `10*15/6` est une erreur de
  l'élève, pas une incertitude ;
- un résultat juste mais un membre de droite faux (`10*15/5 = 25`) n'est pas
  déclaré réussi.

> **L'association de transfert reste inactive** : la condition technique est
> remplie, l'activation est une décision pédagogique.

### Précédent build

`relio-socle-v0.3.3-typographie.apk` — police et rendu mathématique :

- **Inter réellement embarquée**, en quatre poids (400 / 500 / 600 / 700)
  plus un italique, sous-ensemble latin et latin étendu. Chaque fichier porte
  son poids : aucun réglage d'axe n'est nécessaire ;
- l'italique des variables est un **vrai fichier**, pas un oblique simulé ;
- les accents français (`é è à ç ô î û œ`, majuscules accentuées) sont
  inclus et vérifiés ;
- **formateur typographique** sur les énoncés et les indices : variables
  isolées en italique, chiffres en tabulaire, opérateurs et parenthèses
  inchangés, acronymes jamais italiques ;
- aucune bibliothèque de rendu mathématique ajoutée.

> Ce build reste **sans validation sur appareil réel** : aucun téléphone ni
> émulateur n'est disponible dans l'environnement de compilation.

### Précédent build

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
