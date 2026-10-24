# Rapport — Intégration globale de la voix

Vérification du chantier « narrateur / lecteur / conversationaliste » sur le
commit `f910a65`, et publication de l'APK correspondant.

## Ce qui est en place

| Exigence | État | Où |
|---|---|---|
| Dépendances `flutter_tts`, `speech_to_text`, `permission_handler` | ✅ | `pubspec.yaml` |
| Permissions micro + requêtes TTS / reconnaissance (Android 11+) | ✅ | `android/app/src/main/AndroidManifest.xml` |
| Service audio central, une action chasse l'autre | ✅ | `lib/services/audio/audio_service.dart` |
| Nettoyage du texte (`<red>`, `AM/AB`, `−`, `+`, `=`, `/`, pictogrammes) | ✅ | `lib/services/audio/speech_text.dart` |
| Interrupteur « Voix du tuteur », désactivé par défaut | ✅ | `learner_settings.dart`, `profile_page.dart` |
| Icône globale muet / son sur les écrans principaux | ✅ | `voice_toggle_button.dart` (accueil, apprendre, révision, chapitre, exercice, fin de session, profil) |
| Bouton « Écouter » sur l'énoncé, sans modifier l'affichage | ✅ | `exercise_page.dart`, `listen_button.dart` |
| Lecture du retour après validation (et après erreur signalée) | ✅ | `exercise_page.dart` (`_readFeedback`) |
| Bouton « Écouter » dans la fiche d'indice | ✅ | `rich_hint_sheet.dart` |
| Salutation automatique de l'accueil, si la voix est active | ✅ | `home_page.dart` |
| Micro dans le chat + état visuel rouge | ✅ | `relio_tutor_sheet.dart` (icône `mic` / `mic_none_rounded`, teinte `#D92D20`) |
| Haut-parleur sur chaque bulle du tuteur | ✅ | `relio_tutor_sheet.dart` |
| Arrêt de la voix et du micro à la sortie d'écran | ✅ | `app_shell.dart`, `home_page.dart`, `exercise_page.dart`, `rich_hint_sheet.dart`, `relio_tutor_sheet.dart` |
| Message doux si le micro est indisponible | ✅ | `RelioStrings.microphoneUnavailable` (SnackBar, jamais de dialogue bloquant) |
| Audio non bloquant | ✅ | tous les appels sont `unawaited` ou faits derrière `try` |

## Ce qui a été mesuré

- `flutter analyze` → `No issues found!`
- `flutter test` → `All tests passed!` (1093 tests)
- Build release `android-arm64` avec `TUTOR_API_KEY` injecté par
  `--dart-define`, vérifié dans `libapp.so` par `tool/verify_apk_key.ps1`.

## Correctif de build

Le commit `f910a65` ne produisait pas d'APK. `permission_handler: ^13.0.2`
tirait `permission_handler_android` 14.1.0, qui déclare `compileSdk = 37` :

```
Failed to find target with hash string 'android-37' in: C:\Android\Sdk
```

La version 37 du SDK n'est publiée que sous les hash `android-37.0`,
`37.1`, `37.2` — aucune plateforme `android-37` n'existe — et l'AGP 9.1.0
plafonne de toute façon à 36. Le plugin est donc épinglé à la branche 12.x
(implémentation `permission_handler_android` 13.0.1, `compileSdk 35`).
L'API employée (`Permission.microphone.status` / `.request`) est inchangée.

## Écarts assumés

- Aucun test de widget dédié au bouton micro ni à l'icône globale : le
  comportement du service et du nettoyage de texte est couvert
  (`test/services/audio_service_test.dart`, `test/services/speech_text_test.dart`),
  l'intégration visuelle ne l'est pas.
- `Info.plist` n'existe pas : la cible est Android uniquement (règle 3).
