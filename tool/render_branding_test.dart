/// Production des declinaisons raster : launcher icon et splash.
///
/// Le rendu passe par [RelioMarkPainter], donc par la meme geometrie que le
/// SVG et que l'ecran. Les images produites sont ecrites dans :
///  - `assets/branding/launcher/` pour les declinaisons de reference ;
///  - `android/app/src/main/res/mipmap-*/` pour l'icon Android ;
///  - `android/app/src/main/res/drawable-*/` pour le splash.
///
/// ```
/// flutter test tool/render_branding_test.dart
/// ```
///
/// Les regles appliquees :
///  - grille adaptative Android 108 dp, zone sure 66 dp ;
///  - le mark occupe 55 % de la zone sure, soit 36.3 dp ;
///  - variante COMPACTE dans le launcher : le trait y est sous 48 dp.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_mark.dart';

/// Encode une image en PNG et l'ecrit sur le disque.
Future<void> _ecrirePng(ui.Image image, String chemin) async {
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('encodage PNG impossible pour $chemin');
  File(chemin)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data.buffer.asUint8List());
}

/// Rend le mark centre dans un carre, avec un fond optionnel.
Future<ui.Image> _rendre({
  required double canvas,
  required double mark,
  required Color couleur,
  required double stroke,
  Color? fond,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas c = Canvas(recorder);

  // `toByteData` exige une image avec un calque alpha. On dessine donc un
  // premier quad blanc transparent (ou la couleur de fond) avant tout le reste,
  // ce qui garantit la presence du calque sans modifier le rendu visible.
  c.drawRect(
    Rect.fromLTWH(0, 0, canvas, canvas),
    Paint()..color = fond ?? const Color(0x00000000),
  );

  if (fond != null) {
    c.drawRect(Rect.fromLTWH(0, 0, canvas, canvas), Paint()..color = fond);
  }

  // Le painter centre le mark dans le carre qu'on lui donne. Pour obtenir un
  // mark de `mark` pixels au sein d'un canvas de `canvas` pixels, on le peint
  // dans un carre de cote `mark`, translate au centre du canvas.
  c.save();
  c.translate((canvas - mark) / 2, (canvas - mark) / 2);
  RelioMarkPainter(
    color: couleur,
    stroke: stroke,
    unitsPerPixel: mark,
  ).paint(c, Size(mark, mark));
  c.restore();

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(canvas.round(), canvas.round());
  picture.dispose();
  return image;
}

/// Charge une fonte depuis le disque et l'enregistre sous [famille].
///
/// Indispensable pour rendre le wordmark : sans cela, `TextPainter` ne trouve
/// pas la famille et dessine des rectangles a la place des lettres.
Future<void> _chargerPolice(String chemin, String famille) async {
  final File f = File(chemin);
  if (!f.existsSync()) {
    throw StateError('police introuvable : $chemin');
  }
  final FontLoader loader = FontLoader(famille)
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(f.readAsBytesSync())),
    );
  await loader.load();
}

/// Densites Android : multiplicateur px par dp pour les icones legacy.
const Map<String, double> _legacyDp = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

/// Cotes des icones legacy, en dp.
const double _legacyIconDp = 48;

/// Facteur de densite des icones ADAPTATIVES : grille de 108 dp.
const Map<String, double> _adaptiveDp = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

void main() {
  const String launcher = 'assets/branding/launcher';
  const String res = 'android/app/src/main/res';

  // La police Inter doit etre chargee explicitement : hors du bundle de
  // l'application, le moteur ne connait pas la famille et rendrait le texte
  // en rectangles pleins — c'est exactement ce que produit un glyphe manquant.
  setUpAll(() async {
    await _chargerPolice('assets/fonts/Inter-SemiBold.ttf', 'Inter');
  });

  testWidgets('launcher : icones legacy et adaptatives, variante sobre', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // --- Icones legacy : 48 dp, mark orange sur fond blanc ---------------
      for (final MapEntry<String, double> e in _legacyDp.entries) {
        final double px = _legacyIconDp * e.value;
        final ui.Image icon = await _rendre(
          canvas: px,
          mark: px * 0.72,
          couleur: RelioBrand.mark,
          stroke: RelioMarkGeometry.strokeCompact,
          fond: RelioBrand.monoWhite,
        );
        await _ecrirePng(icon, '$res/mipmap-${e.key}/ic_launcher.png');
        icon.dispose();

        // Un seul visuel pour toutes les densites.
        final ui.Image rond = await _rendre(
          canvas: px,
          mark: px * 0.72,
          couleur: RelioBrand.mark,
          stroke: RelioMarkGeometry.strokeCompact,
          fond: RelioBrand.monoWhite,
        );
        await _ecrirePng(rond, '$res/mipmap-${e.key}/ic_launcher_round.png');
        rond.dispose();
      }

      // --- Icone adaptative : 108 dp -------------------------------------
      // Le mark doit tenir dans la zone sure ET laisser de la respiration :
      // 55 % de la zone sure, donc 36.3 dp sur la grille de 108 dp.
      for (final MapEntry<String, double> e in _adaptiveDp.entries) {
        final double grid = RelioMarkGeometry.androidGridDp * e.value;
        final double markDp = RelioMarkGeometry.androidMarkSizeDp * e.value;

        // Premier plan : mark orange, fond TRANSPARENT. La zone sure reste
        // degagee, conformement aux contraintes des masques constructeur.
        final ui.Image fg = await _rendre(
          canvas: grid,
          mark: markDp,
          couleur: RelioBrand.mark,
          stroke: RelioMarkGeometry.strokeCompact,
        );
        await _ecrirePng(fg, '$res/mipmap-${e.key}/ic_launcher_foreground.png');
        fg.dispose();

        // Arriere-plan : aplat orange plein, sans mark. L'icon adaptative
        // compose les deux : le fond ne doit porter aucun dessin.
        final ui.Image aplat = await _rendreAplat(grid, RelioBrand.mark);
        await _ecrirePng(aplat, '$res/mipmap-${e.key}/ic_launcher_background.png');

        // Couche monochrome : Android 13+ la teinte selon le theme du systeme.
        // Elle doit porter UNIQUEMENT le mark, en noir, sur fond transparent :
        // c'est la seule forme qui survive a une teinte appliquee par l'OS.
        final ui.Image mono = await _rendre(
          canvas: grid,
          mark: markDp,
          couleur: RelioBrand.monoBlack,
          stroke: RelioMarkGeometry.strokeCompact,
        );
        await _ecrirePng(mono, '$res/mipmap-${e.key}/ic_launcher_monochrome.png');
        mono.dispose();

        // Copie de reference dans assets, pour documentation et impression.
        final ui.Image refFg = await _rendre(
          canvas: grid,
          mark: markDp,
          couleur: RelioBrand.mark,
          stroke: RelioMarkGeometry.strokeCompact,
        );
        await _ecrirePng(refFg, '$launcher/adaptive-foreground-${e.key}.png');
        refFg.dispose();
        await _ecrirePng(aplat, '$launcher/adaptive-background-${e.key}.png');
        aplat.dispose();
      }
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('launcher : declinaisons de taille exportables', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Variante presence : mark blanc sur fond orange.
      for (final double dp in [1024.0, 512.0, 192.0, 96.0, 48.0, 24.0]) {
        final double stroke = RelioMarkGeometry.strokeForSize(dp);
        final ui.Image presence = await _rendre(
          canvas: dp,
          mark: dp * 0.62,
          couleur: RelioBrand.monoWhite,
          stroke: stroke,
          fond: RelioBrand.mark,
        );
        await _ecrirePng(presence, '$launcher/presence-${dp.toInt()}.png');
        presence.dispose();

        // Variante sobre : mark orange sur fond blanc.
        final ui.Image sobre = await _rendre(
          canvas: dp,
          mark: dp * 0.62,
          couleur: RelioBrand.mark,
          stroke: stroke,
          fond: RelioBrand.monoWhite,
        );
        await _ecrirePng(sobre, '$launcher/sobre-${dp.toInt()}.png');
        sobre.dispose();

        // Mark seul, sur fond transparent.
        final ui.Image seul = await _rendre(
          canvas: dp,
          mark: dp * 0.8,
          couleur: RelioBrand.mark,
          stroke: stroke,
        );
        await _ecrirePng(seul, '$launcher/mark-${dp.toInt()}.png');
        seul.dispose();
      }

      // iOS : 1024 px, sans transparence et sans coins arrondis â€” l'OS les
      // applique lui-meme.
      final ui.Image ios = await _rendre(
        canvas: 1024,
        mark: 1024 * 0.62,
        couleur: RelioBrand.monoWhite,
        stroke: RelioMarkGeometry.strokePrimary,
        fond: RelioBrand.mark,
      );
      await _ecrirePng(ios, '$launcher/ios-1024.png');
      ios.dispose();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('splash : fond blanc, lockup vertical centre', (WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final double dp in [480.0, 720.0, 1080.0, 1440.0]) {
        final ui.Image image = await _rendreSplash(dp);
        await _ecrirePng(image, '$launcher/splash-${dp.toInt()}.png');
        image.dispose();
      }

      // Le splash Android est consomme par `drawable/launch_background.xml` :
      // on produit une densite par repertoire, au format expected par le
      // decorateur `bitmap` d'Android.
      for (final MapEntry<String, double> e in _legacyDp.entries) {
        final ui.Image image = await _rendreSplashLogo(288 * e.value);
        await _ecrirePng(image, '$res/drawable-${e.key}/splash_logo.png');
        image.dispose();
      }
      // Densite de base, pour le dossier `drawable` sans suffixe.
      final ui.Image base = await _rendreSplashLogo(288);
      await _ecrirePng(base, '$res/drawable/splash_logo.png');
      base.dispose();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// Rend le lockup vertical seul, sur fond transparent.
///
/// Utilise par le decorateur `bitmap` d'Android, qui centre l'image sur la
/// fenetre : le fond reste donc transparent, seul le dessin est fourni.
Future<ui.Image> _rendreSplashLogo(double cote) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas c = Canvas(recorder);

  // Le mark occupe environ 120 dp de large sur un splash de telephone ; dans
  // l'image carree il laisse de la place au mot en dessous.
  final double markDp = cote * 0.58;
  c.save();
  c.translate((cote - markDp) / 2, cote * 0.06);
  RelioMarkPainter(
    color: RelioBrand.mark,
    stroke: RelioMarkGeometry.strokePrimary,
    unitsPerPixel: markDp,
  ).paint(c, Size(markDp, markDp));
  c.restore();

  // Le mot, centre, avec l'interlettrage de la specification.
  final double fontSize = cote * 0.135;
  final TextPainter wordmark = TextPainter(
    text: TextSpan(
      text: 'Relio',
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: RelioBrand.wordmark,
        letterSpacing: RelioBrand.wordmarkTracking * fontSize,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  wordmark.paint(c, Offset((cote - wordmark.width) / 2, cote * 0.72));

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(cote.round(), cote.round());
  picture.dispose();
  return image;
}

/// Aplat de couleur pleine, sans mark.
Future<ui.Image> _rendreAplat(double cote, Color couleur) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, cote, cote),
    Paint()..color = couleur,
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(cote.round(), cote.round());
  picture.dispose();
  return image;
}

/// Rend le splash : fond blanc, mark centre, wordmark en dessous.
///
/// Les resolutions usuelles Android sont des portfolios : on garde un format
/// carre pour la reference, la mise a l'echelle reelle se fait a l'affichage.
Future<ui.Image> _rendreSplash(double cote) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas c = Canvas(recorder);

  c.drawRect(
    Rect.fromLTWH(0, 0, cote, cote),
    Paint()..color = RelioBrand.splashBackground,
  );

  // Le mark fait environ 55 % du cote sur le splash : lisible sans ecraser
  // l'ecran.
  final double markDp = cote * 0.55;
  c.save();
  c.translate((cote - markDp) / 2, (cote - markDp) / 2 - cote * 0.06);
  RelioMarkPainter(
    color: RelioBrand.mark,
    stroke: RelioMarkGeometry.strokePrimary,
    unitsPerPixel: markDp,
  ).paint(c, Size(markDp, markDp));
  c.restore();

  // Le wordmark est pose par le meme moteur de texte que dans l'application.
  final double fontSize = cote * 0.09;
  final TextPainter wordmark = TextPainter(
    text: TextSpan(
      text: 'Relio',
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: RelioBrand.wordmark,
        letterSpacing: RelioBrand.wordmarkTracking * fontSize,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  wordmark.paint(c, Offset((cote - wordmark.width) / 2, cote * 0.72));

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(cote.round(), cote.round());
  picture.dispose();
  return image;
}

