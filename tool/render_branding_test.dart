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

/// Rend le mark seul, centre dans un canvas, sur un fond eventuel.
///
/// [largeurMark] est la largeur REELLE de l'encre du mark dans le canvas.
/// Le fond, lui, occupe tout le canvas : c'est ce qu'attend Android pour un
/// calque d'icone adaptative.
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
  // Hauteur du bloc, en fraction du cote : le mark occupe 1 unite de hauteur,
  // le mot 1 / 1.93, la signature 1 / 1.93 x 0.176, plus les deux ecarts.
  // On raisonne en unites de hauteur du mark, puis on met a l'echelle.
  const double gapMarkText = RelioBrand.verticalGap / RelioMarkGeometry.grid;
  const double wordmarkCapRatio = 1 / kMarkToWordmarkRatio;

  final double fontSizeAtMark = 1 / (kMarkToWordmarkRatio * RelioBrand.wordmarkCapHeightEm);
  final double wordmarkHeightAtMark = fontSizeAtMark * 1.21;
  final double signatureHeightAtMark =
      fontSizeAtMark * RelioBrand.signatureCapRatio * 1.21;
  final double blockAtMark = 1 +
      gapMarkText +
      wordmarkHeightAtMark +
      wordmarkCapRatio * RelioBrand.signatureGapRatio +
      signatureHeightAtMark;

  // Le bloc occupe 78 % de la cote : assez grand pour etre lu, assez petit
  // pour laisser respirer l'ecran.
  final double markHeight = cote * 0.78 / blockAtMark;
  final double markWidth = markHeight * RelioMarkGeometry.inkWidth / RelioMarkGeometry.inkHeight;

  final double fontSize = markHeight * fontSizeAtMark;
  final TextPainter wordmark = _texte(
    RelioWordmark.text,
    fontSize,
    RelioBrand.wordmark,
    tracking: RelioBrand.wordmarkTracking,
  );
  final TextPainter signature = _texte(
    RelioSignature.text,
    fontSize * RelioBrand.signatureCapRatio,
    RelioBrand.wordmark,
  );

  // Centrage du bloc REELLEMENT occupe, et non d'une estimation : les hauteurs
  // de ligne sont mesurees sur la fonte.
  final double block =
      markHeight +
      gapMarkText * markHeight +
      wordmark.height +
      wordmarkCapRatio * markHeight * RelioBrand.signatureGapRatio +
      signature.height;

  double y = (cote - block) / 2;

  c.save();
  c.translate((cote - markWidth) / 2, y);
  RelioMarkPainter(variant: RelioMarkVariant.onLight).paint(
    c,
    Size(markHeight * RelioMarkGeometry.inkHeight / RelioMarkGeometry.inkWidth, markHeight),
  );
  c.restore();
  y += markHeight + gapMarkText * markHeight;

  wordmark.paint(c, Offset((cote - wordmark.width) / 2, y));
  y += wordmark.height + wordmarkCapRatio * markHeight * RelioBrand.signatureGapRatio;

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

  testWidgets('launcher : icones legacy et adaptatives', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // --- Icones legacy : 48 dp, fond indigo, mark en declinaison claire ---
      //
      // Le fond porte l'indigo de la marque et le mark y est en blanc : c'est
      // l'icone fournie dans la specification. Un aplat orange avec un mark
      // orange y serait illisible.
      for (final MapEntry<String, double> e in _legacyDp.entries) {
        final double px = _legacyIconDp * e.value;
        final double rayon = RelioMarkGeometry.iconCornerRadiusRatio * px;
        final double inset = RelioMarkGeometry.iconBackgroundInsetRatio * px;
        final double largeur = px - 2 * inset;

        final ui.Image icon = await _rendreMark(
          canvas: px,
          largeurMark: largeur * 0.72,
          variant: RelioMarkVariant.onIndigo,
          fond: RelioBrand.iconBackground,
          rayonFond: rayon,
        );
        await _ecrirePng(icon, '$res/mipmap-${e.key}/ic_launcher.png');
        icon.dispose();

        // La variante « round » est un disque : pas de coins arrondis a
        //Chooser, le rayon vaut la moitie du cote.
        final ui.Image rond = await _rendreMark(
          canvas: px,
          largeurMark: largeur * 0.62,
          variant: RelioMarkVariant.onIndigo,
          fond: RelioBrand.iconBackground,
          rayonFond: px / 2,
        );
        await _ecrirePng(rond, '$res/mipmap-${e.key}/ic_launcher_round.png');
        rond.dispose();
      }

      // --- Icone adaptative : 108 dp -------------------------------------
      // Le mark doit tenir dans la zone sure ET laisser de la respiration :
      // 55 % de la zone sure, donc 36.3 dp sur la grille de 108 dp.
      for (final MapEntry<String, double> e in _adaptiveDp.entries) {
        final double grid = RelioMarkGeometry.androidGridDp * e.value;
        final double largeurMarkDp = RelioMarkGeometry.androidMarkWidthDp * e.value;

        // Premier plan : mark en declinaison claire, fond TRANSPARENT. La zone
        // sure reste degagee, conformement aux masques constructeur.
        final ui.Image fg = await _rendreMark(
          canvas: grid,
          largeurMark: largeurMarkDp,
          variant: RelioMarkVariant.onIndigo,
        );
        await _ecrirePng(fg, '$res/mipmap-${e.key}/ic_launcher_foreground.png');

        // Arriere-plan : aplat indigo, sans mark.
        //
        // Le fond ne doit porter aucun dessin. Il porte la couleur, et c'est
        // ce qui rend le mark blanc lisible.
        final ui.Image aplat = await _rendreAplat(grid, RelioBrand.iconBackground);
        await _ecrirePng(aplat, '$res/mipmap-${e.key}/ic_launcher_background.png');

        // Couche monochrome : Android 13+ la teinte selon le theme du systeme.
        // Elle doit porter UNIQUEMENT le mark, en noir, sur fond transparent :
        // c'est la seule forme qui survive a une teinte appliquee par l'OS.
        final ui.Image mono = await _rendreMark(
          canvas: grid,
          largeurMark: largeurMarkDp,
          variant: RelioMarkVariant.monoBlack,
        );
        await _ecrirePng(mono, '$res/mipmap-${e.key}/ic_launcher_monochrome.png');

        // Copies de reference dans assets, pour documentation et impression.
        // Elles sont ecrites AVANT toute liberation : une `ui.Image` liberee
        // ne peut plus etre encodee.
        await _ecrirePng(fg, '$launcher/adaptive-foreground-${e.key}.png');
        await _ecrirePng(aplat, '$launcher/adaptive-background-${e.key}.png');
        await _ecrirePng(mono, '$launcher/adaptive-monochrome-${e.key}.png');
        fg.dispose();
        aplat.dispose();
        mono.dispose();
      }
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('launcher : declinaisons de taille exportables', (WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final double dp in [1024.0, 512.0, 192.0, 96.0, 48.0, 24.0]) {
        // Variante presence : fond indigo, mark en declinaison claire. C'est
        // l'icone de l'application, en grandeur.
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