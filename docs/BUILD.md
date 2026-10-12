# Build et exécution sur Android

## Prérequis

| Outil | Version utilisée |
|---|---|
| Flutter | 3.47.7 (stable, Dart 3.13.5) |
| JDK | 17 |
| Android SDK | platform android-36, build-tools 36.0.0 |
| NDK | 28.2.13676358 |
| CMake | 3.22.1 (fourni par le SDK) |

## Note importante sur le NDK

Le NDK **est** requis, contrairement à ce que la nature du projet laisse
supposer. La dépendance transitive `jni` — amenée par
`path_provider_android` — compile du code natif via CMake.

La version par défaut du plugin Flutter (28.2.13676358) n'était **pas**
proposée par le `sdkmanager` de cet environnement, qui n'exposait que la
série 27.x et renvoyait `Package not found`. Le NDK a donc été téléchargé
directement depuis le dépôt Google :

```
https://dl.google.com/android/repository/android-ndk-r27c-windows.zip
```

Il est extrait dans `android-sdk/ndk/28.2.13676358`, avec `source.properties`
aligné sur la version attendue par Gradle. La version est épinglée dans
`android/app/build.gradle.kts`.

Sur une machine disposant d'un `sdkmanager` à jour, l'installation
habituelle suffit :

```
sdkmanager "ndk;28.2.13676358"
```

## `minSdk`

`minSdk = 21` est déclaré dans `android/app/build.gradle.kts`, mais
l'analyseur de manifest du APK signale **24**. La valeur 24 est imposée par
les dépendances actuelles (`sqlite3_flutter_libs` / `sqlite3`), et non par
Relio. Pour descendre en dessous, il faudrait une chaîne de dépendances
compatible avec les API 21 — arbitrage non fait à ce stade.

## Commandes

```bash
flutter pub get
dart run build_runner build      # régénère lib/data/db/app_database.g.dart
flutter analyze                  # doit rester à "No issues found!"
flutter test
flutter build apk --debug
flutter build apk --release
```

## Tests

`flutter test` exécute **362 tests**.

| Domaine | Tests |
|---|---|
| Socle (persistance, événements, migrations) | 50 |
| Moteur pédagogique chapitre 1 | 87 |
| Interface S1/S2 et verrouillage du champ | 112 |
| Fiabilisation, correction, vérification de transfert | 68 |

## Résultats obtenus

| Cible | Résultat |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **50 tests, tous verts** |
| `flutter build apk --debug` | ✅ `app-debug.apk` (152 Mo, toutes ABIs) |
| `flutter build apk --release --target-platform android-arm64` | ✅ `app-release.apk` (**20,3 Mo**) |

Vérification du APK de release :

| Attribut | Valeur |
|---|---|
| `applicationId` | `com.relio.relio` |
| `versionName` | `0.3.4` |
| `versionCode` | `6` |
| `minSdk` | 24 |
| Bibliothèques natives | `libsqlite3.so` (arm64-v8a, armeabi-v7a, x86_64), `libapp.so`, `libflutter.so` |

La présence de `libsqlite3.so` pour les trois architectures confirme que la
persistance locale sera fonctionnelle sur appareil réel.

## Limite : exécution non vérifiée sur appareil

Aucun émulateur n'est installé sur cette machine et aucun appareil n'est
connecté (`adb devices` ne retourne rien ; le répertoire `emulator` et
`system-images` sont absents du SDK). La compilation et l'empaquetage Android
sont donc validés, mais **le lancement sur un appareil réel n'a pas pu être
effectué**.

Pour lever cette réserve :

```bash
flutter emulators            # lister
flutter emulators --create   # créer un AVD
flutter run                  # lancer
```

Les tests automatisés couvrent en revanche le comportement applicatif :
écran d'accueil alimenté par une vraie base locale (`widget_test.dart`),
et persistance hors ligne sur disque (`offline_persistence_test.dart`).

## Signature

La configuration `release` utilise la clé de **debug**
(`signingConfig = signingConfigs.getByName("debug")`), fournie par le
scaffold Flutter. Elle est signalée en commentaire dans
`android/app/build.gradle.kts` et listée comme point à arbitrer dans
`ARCHITECTURE.md`. Aucune diffusion réelle ne doit se faire en l'état.




