# Rapport — Refonte UX/UI du parcours d’entrée

Date : 2026-10-16. Branche : `main`. APK : `apk/relio-socle-v0.4.2-refonte-parcours-marque.apk` (22,4 Mo) sur `apk-build`.

## Périmètre tenu

Composition des six écrans uniquement. Logique pédagogique, questions,
stockage, `firstLaunchCompleted`, reprise de session : intouchés.
Aucune dépendance ajoutée. Aucun `AppBar`. Aucun texte hors liste.

## Fichiers ajoutés

- `lib/presentation/screens/onboarding/entry_kit.dart` — grille commune
  (24 / 32 / 12), `EntryButton`, `EntryDots`, `EntryTransition` (fondu
  275 ms), `EntryMark`, `EntryAction`.
- `test/presentation/entry_composition_test.dart` — 16 verrous (tailles,
  bouton, pastilles, ancrage, `spaceBetween`, transitions, `AppBar`).

## Fichiers modifiés (parcours)

- `opening_page.dart` — mark 160 dp, fond `#EEF2FA`, aucun texte, 1,8 s,
  tap n'importe où pour passer.
- `welcome_page.dart` — mark 100 dp, titre Display 28 `#0E1821`,
  sous-titre + question Body 16, bouton ancré en bas.
- `entry_test_intro_page.dart` — mark 80 dp, titre Title 22, paragraphe
  Body 16 à gauche, phrase de fin BodyStrong `#0E1821` à 24 dp, 5 pastilles
  vides (légende retirée : texte non listé), bouton en bas.
- `name_page.dart` — personnage 64 dp, titre + nouveau sous-titre, champ
  56 dp à 32 dp, bouton avec état de chargement (retrait du rétrécissement
  140 → 80, le fondu croisé prend le relais).
- `entry_test_page.dart` — barre 24 dp + pastilles (remplies = réponses),
  « N sur 5 » en Caption dessous, carte à 24 dp, options 56 dp / rayon 12 /
  écart 12, bouton avec chargement.
- `closing_page.dart` — personnage 120 dp fixe (croissance retirée),
  « Merci {prénom}. » Display 28 + corps centré, bouton en bas.
- `onboarding_flow.dart`, `app.dart` — `EntryTransition` entre étapes et
  entre moments (ouverture, bienvenue, parcours).
- `onboarding_metrics.dart` — `entryTransitionMs = 275`, options 56 dp,
  sortie ouverture 200 ms (1,8 s total) ; tailles du personnage supprimees
  (remplacees par `EntryBrand`).
- `relio_strings.dart` — textes découpés en parties **sans réécriture** :
  la concaténation restitue chaque texte validé au caractère près
  (titre + sous-titre + question = message ; idem intro et clôture,
  titre « Merci {prénom}. » mis à part, imposé par la mission).
- `pubspec.yaml` — `0.4.2+15` → `0.4.2+16` (versionCode).

## Fichiers modifiés (tests)

`entry_screens_test`, `onboarding_entry_flow_test`, `entry_journey_test`,
`onboarding_name_and_closing_test`, `onboarding_entry_test_screen_test`,
`onboarding_audit_test`, `onboarding_overlap_test`,
`onboarding_audit_states_test` — finders alignés sur les textes découpés,
tailles 64/24/120, titre + corps de clôture, bouton en chargement
(indicateur à la place du texte), pastilles sans légende, fondus de 275 ms.

## Vérifications exécutées

- `flutter analyze` : **No issues found!**
- `flutter test` : **710 tests, tous verts (All tests passed!)**,
  dont les 688 existants et 16 nouveaux verrous de composition
  (+ 7 wordmark et ajustements marque, voir rapport marque).
- `flutter build apk --release --target-platform android-arm64` :
  `build/app/outputs/flutter-apk/app-release.apk` (22,4 Mo),
  publié en `apk/relio-socle-v0.4.2-refonte-parcours-marque.apk`.

## Critères d'acceptation

| Critère | Résultat |
|---|---|
| Prénom sans collision logo/titre | vérifié (`onboarding_overlap_test`) |
| Logo 64 dp prénom, 24 dp test | vérifié (`entry_composition_test`) |
| Bouton navy solide, sans contour | vérifié (style résolu par état) |
| 5 pastilles + « N sur 5 » Caption | vérifié |
| Aucun `spaceBetween` | vérifié (grep + test des colonnes pleine largeur) |
| Bouton ancré en bas | vérifié (bas d'écran − 24 dp) |
| Transitions 250–300 ms, fondu | 275 ms, vérifié |
| 360 × 640 à 1,3 sans débordement | vérifié (audits) |
| Tests existants verts | 688/688 |
| `flutter analyze` propre | oui |

## Découvertes hors périmètre

- `tester.tap(..., warnIfMissed: false)` lève quand même sur finder vide
  (Flutter 3.47) : les doubles-taps utilisent un garde explicite.
- `AnimatedSwitcher` garde l'ancien écran 275 ms : les `findsNothing`
  exigent un pompage ≥ 300 ms (`laisserResoudre` passé à 10 × 50 ms).
- Désactivé à 40 %/60 % sous 4,5:1 : voulu par la mission ; WCAG exempte
  les composants inactifs (noté dans le test).
- Gradle a auto-installé la plateforme Android 35 (compileSdk résolu).
- Légende « Cinq questions, une par une » retirée (texte non listé) ;
  les pastilles restent, sans compteur.
