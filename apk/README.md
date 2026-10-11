# Relio — APK de démonstration

Cette branche contient uniquement l'**artefact compilé**, pratique pour le
télécharger et l'installer sur un téléphone.

## Fichier

| Fichier | Taille |
|---|---|
| `apk/relio-socle-v0.1.0.apk` | ~20,3 Mo |

## Téléchargement

Ouvrir le fichier `apk/relio-socle-v0.1.0.apk` depuis cette branche sur
GitHub, puis **Raw** pour télécharger le binaire.

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

## Contenu de cette version

Socle technique de la Mission 1 : structure des notions mathématiques,
événements d'apprentissage, persistance locale SQLite hors ligne. **Aucun
contenu pédagogique** — l'écran d'accueil n'affiche que des compteurs, vides
par conception.

## ⚠️ Branche de distribution, pas de développement

- `main` porte le code. C'est là que le développement se fait.
- `apk-build` porte les binaires. Elle grossit à chaque nouveau build.

Le code de cette branche est identique à `main`. Ne pas y développer.
