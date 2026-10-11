# Relio

Tuteur personnel de mathématiques, destiné notamment aux élèves francophones
du Cameroun.

Ce dépôt contient le **socle technique** (Mission 1) : structures de données,
persistance locale hors ligne, versionnage et migrations. Il ne contient
**aucun contenu pédagogique** — les notions et les règles d'apprentissage
seront définies dans les missions suivantes.

## État actuel

| Livrable | État |
|---|---|
| Socle fonctionnel Flutter exécutable sur Android | ✅ |
| Structures de notions et d'événements documentées | ✅ |
| Persistance locale hors ligne | ✅ |
| Versionnage et migrations testés (v1 → v2) | ✅ |
| Tests | ✅ **50 tests, tous verts** |
| Analyse statique | ✅ `No issues found!` |
| Contenu pédagogique | ⛔ volontairement absent |

## Démarrage

```bash
flutter pub get
dart run build_runner build   # génère le code Drift
flutter test
flutter run                  # nécessite un appareil ou un émulateur
```

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — choix techniques, modèle de
  données, persistance, migrations, **points restant à arbitrer**.
- [`docs/BUILD.md`](docs/BUILD.md) — prérequis, build Android, vérification
  des artefacts.

## Structure

```
lib/
  core/          identifiants, horloge injectable
  domain/        modèle métier — ne connaît ni Flutter ni SQL
    notion/      notions mathématiques
    learning/    événements d'apprentissage (faits observés)
  data/db/       Drift : schéma, migrations, mapping
  presentation/  interface
test/            50 tests
```

## Principe directeur

> Construire une base fiable sans figer prématurément l'intelligence
> pédagogique de Relio.

Le stockage ne contient que des **faits observables** : dates, réponses,
résultats, erreurs constatées, indices proposés, notions, contexte. Aucun
champ de maîtrise, de score ou de niveau n'existe. Les règles pédagogiques
futures s'appuieront sur cet historique brut, sans migration de schéma.

## Licence

Non définie — à arbitrer.
