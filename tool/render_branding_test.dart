/// Production des declinaisons raster de reference et du splash.
///
/// Le rendu passe par [RelioMarkPainter], donc par la meme geometrie que le
/// SVG et que l'ecran. Les images produites sont ecrites dans :
///  - `assets/branding/launcher/` pour les declinaisons de reference ;
///  - `android/app/src/main/res/drawable-*/` pour le splash.
///
/// Les PNG du lanceur Android (`mipmap-*/`) viennent eux de l'icone livree
/// (`tool/brand_launcher.py`) : eux seuls portent les pages blanches du
/// livre, qui n'existent pas dans la geometrie vectorielle.
///
/// ```
/// flutter test tool/render_branding_test.dart
/// ```
///
/// Les regles appliquees :
///  - grille adaptative Android 108 dp, zone sure 66 dp ;
///  - le mark occupe 55 % de la zone sure, soit 36.3 dp ;
///  - le mark est dimensionne par son ENCRE, jamais par un carre englobant.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_lockup.dart';
import 'package:relio/presentation/branding/relio_mark.dart';

/// Encode une image en PNG et l'ecrit sur le disque.
Future<void> _ecrirePng(ui.Image image, String chemin) async {
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('encodage PNG impossible pour $chemin');
  File(chemin)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data.buffer.asUint8List());
}

/// Cote du carre a donner au painter pour obtenir un mark de [largeur]
/// pixels de largeur reelle.
///
/// Le painter inscrit le mark en limitant sa HAUTEUR. Pour raisonner en
/// largeur d'encre — ce qui est ce que voit l'oeil — il faut donc lui donner
/// un carre plus haut que large que la largeur demandee.
double _cotePourLargeur(double largeur) =>
    largeur * RelioMarkGeometry.inkHeight / RelioMarkGeometry.inkWidth;

/// Rend le mark seul, centre dans un canvas, sur un fond eventuel.
///
/// [largeurMark] est la largeur REELLE de l'encre du mark dans le canvas.
/// Le fond, lui, occupe tout le canvas.
Future<ui.Image> _rendreMark({
  required double canvas,
  required double largeurMark,
  required RelioMarkVariant variant,
  Color? fond,
  double rayonFond = 0,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas c = Canvas(recorder);

  // `toByteData` exige une image avec un calque alpha. On dessine donc un
  // premier quad transparent avant tout le reste, ce qui garantit la presence
  // du calque sans modifier le rendu visible.
  c.drawRect(
    Rect.fromLTWH(0, 0, canvas, canvas),
    Paint()..color = const Color(0x00000000),
  );

  if (fond != null) {
    final Rect box = Rect.fromLTWH(0, 0, canvas, canvas);
    c.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(rayonFond)),
      Paint()..color = fond,
    );
  }

  final double cote = _cotePourLargeur(largeurMark);
  c.save();
  c.translate((canvas - cote) / 2, (canvas - cote) / 2);
  RelioMarkPainter(variant: variant).paint(c, Size(cote, cote));
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

/// Dessine le lockup vertical — mark, mot, signature — centre dans [cote].
///
/// Le meme bloc que `RelioLockupVertical`, compose ici directement : le
/// renderer ecrit des images, il ne monte pas de widget.
///
/// La taille est CALCULEE, jamais posee en dur : on part de la hauteur du
/// mark, on en deduit le mot (rapport `kMarkToWordmarkRatio`), puis la
/// signature (rapport `signatureCapRatio`). Le bloc complet est ensuite centre
/// dans le carre, ce qui garantit qu'il ne déborde sur aucune resolution.
void _dessinerLockupVertical(Canvas c, double cote) {
  // Hauteur du bloc, en fraction de la hauteur du mark : le mot vaut
  // 1 / 1.637, la signature 0.14 fois le mot, plus les deux ecarts.
  // On raisonne en unites de hauteur du mark, puis on met a l'echelle.
  const double gapMarkText = RelioBrand.verticalGap / RelioMarkGeometry.grid;
  const double wordRatio = 1 / kMarkToWordmarkRatio;
  final double wordAspect = RelioWordmarkGeometry.inkWidth /
      RelioWordmarkGeometry.inkHeight;

  final double signatureCapAtMark =
      wordRatio * RelioBrand.signatureCapRatio;
  final double signatureFontAtMark =
      signatureCapAtMark / RelioBrand.interCapHeightEm;
  final double blockAtMark = 1 +
      gapMarkText +
      wordRatio +
      wordRatio * RelioBrand.signatureGapRatio +
      signatureFontAtMark;

  // Le bloc occupe 78 % de la cote : assez grand pour etre lu, assez petit
  // pour laisser respirer l'ecran.
  final double markHeight = cote * 0.78 / blockAtMark;
  final double markWidth =
      markHeight * RelioMarkGeometry.inkWidth / RelioMarkGeometry.inkHeight;
  final double wordHeight = markHeight * wordRatio;
  final double wordWidth = wordHeight * wordAspect;

  final double fontSize = markHeight * signatureFontAtMark;
  final TextPainter signature = _texte(
    RelioSignature.text,
    fontSize,
    RelioBrand.wordmark,
  );

  // Centrage du bloc REELLEMENT occupe.
  final double block =
      markHeight +
      gapMarkText * markHeight +
      wordHeight +
      wordRatio * markHeight * RelioBrand.signatureGapRatio +
      signature.height;

  double y = (cote - block) / 2;

  c.save();
  c.translate((cote - markWidth) / 2, y);
  RelioMarkPainter(variant: RelioMarkVariant.onLight).paint(
    c,
    Size(markHeight * RelioMarkGeometry.inkHeight / RelioMarkGeometry.inkWidth,
        markHeight),
  );
  c.restore();
  y += markHeight + gapMarkText * markHeight;

  c.save();
  c.translate((cote - wordWidth) / 2, y);
  const RelioWordmarkPainter(variant: RelioMarkVariant.onLight).paint(
    c,
    Size(wordWidth, wordHeight),
  );
  c.restore();
  y += wordHeight + wordRatio * markHeight * RelioBrand.signatureGapRatio;

  signature.paint(c, Offset((cote - signature.width) / 2, y));
}

/// Trace une ligne de texte avec la fonte de marque.
TextPainter _texte(
  String texte,
  double fontSize,
  Color couleur, {
  double tracking = 0,
}) =>
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          color: couleur,
          letterSpacing: tracking * fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

/// Rend le lockup vertical seul, sur fond transparent.
///
/// Utilise par le decorateur `bitmap` d'Android, qui centre l'image sur la
/// fenetre : le fond reste donc transparent, seul le dessin est fourni.
Future<ui.Image> _rendreSplashLogo(double cote) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas c = Canvas(recorder);
  c.drawRect(
    Rect.fromLTWH(0, 0, cote, cote),
    Paint()..color = const Color(0x00000000),
  );
  _dessinerLockupVertical(c, cote);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(cote.round(), cote.round());
  picture.dispose();
  return image;
}

/// Rend le splash : fond blanc, lockup vertical centre.
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
  _dessinerLockupVertical(c, cote);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(cote.round(), cote.round());
  picture.dispose();
  return image;
}

/// Densites Android : multiplicateur px par dp pour les icones legacy.
const Map<String, double> _legacyDp = <String, double>{
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

  testWidgets('declinaisons de taille exportables', (WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final double dp in [1024.0, 512.0, 192.0, 96.0, 48.0, 24.0]) {
        // Variante presence : fond orange, mark navy. C'est l'icone de
        // l'application en grandeur (les parties orange s'y confondent avec
        // le fond, comme sur l'icone livree).
        final ui.Image presence = await _rendreMark(
          canvas: dp,
          largeurMark: dp * 0.72,
          variant: RelioMarkVariant.onIndigo,
          fond: RelioBrand.iconBackground,
          rayonFond: RelioMarkGeometry.iconCornerRadiusRatio * dp,
        );
        await _ecrirePng(presence, '$launcher/presence-${dp.toInt()}.png');
        presence.dispose();

        // Variante sobre : fond blanc, mark en declinaison claire.
        final ui.Image sobre = await _rendreMark(
          canvas: dp,
          largeurMark: dp * 0.72,
          variant: RelioMarkVariant.onLight,
          fond: RelioBrand.monoWhite,
          rayonFond: RelioMarkGeometry.iconCornerRadiusRatio * dp,
        );
        await _ecrirePng(sobre, '$launcher/sobre-${dp.toInt()}.png');
        sobre.dispose();

        // Mark seul, sur fond transparent.
        final ui.Image seul = await _rendreMark(
          canvas: dp,
          largeurMark: dp * 0.86,
          variant: RelioMarkVariant.onLight,
        );
        await _ecrirePng(seul, '$launcher/mark-${dp.toInt()}.png');
        seul.dispose();
      }

      // iOS : 1024 px, sans transparence et sans coins arrondis — l'OS les
      // applique lui-meme. Le fond occupe donc tout le carre.
      final ui.Image ios = await _rendreMark(
        canvas: 1024,
        largeurMark: 1024 * 0.72,
        variant: RelioMarkVariant.onIndigo,
        fond: RelioBrand.iconBackground,
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
      // on produit une densite par repertoire, au format attendu par le
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