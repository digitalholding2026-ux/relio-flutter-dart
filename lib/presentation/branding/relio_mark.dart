/// Marque « Relio » — couleurs, rendu et composants.
///
/// La GEOMETRIE vit dans `relio_mark_geometry.dart`, en Dart pur, pour rester
/// partageable avec le generateur de SVG. Ce fichier n ajoute que ce qui
/// releve de Flutter : les couleurs, le painter et les widgets.
///
/// Le SVG est genere a partir des memes constantes que le painter, et
/// `test/branding/mark_geometry_test.dart` verifie que les deux ne divergent
/// pas.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'relio_mark_geometry.dart';

export 'relio_mark_geometry.dart';

/// Couleurs et declinaisons de la marque.
///
/// Les valeurs hexadecimales sont exactes et ne sont jamais remplacees par un
/// nom de couleur : la specification l'exige pour les SVG, et l'usage unique
/// doit etre le meme partout.
abstract final class RelioBrand {
  /// Orange du mark. Couleur unique du mark : ni degrade, ni ombre, ni
  /// transparence.
  static const Color mark = Color(0xFFF56207);

  /// Indigo du wordmark — identique au `primary` de `RelioPalette`.
  static const Color wordmark = Color(0xFF1F3A6E);

  /// Noir des declinaisons monochrome.
  static const Color monoBlack = Color(0xFF000000);

  /// Blanc des declinaisons monochrome et du mark inverse sur fond orange.
  static const Color monoWhite = Color(0xFFFFFFFF);

  /// Fond du splash.
  static const Color splashBackground = Color(0xFFFFFFFF);

  /// Interlettrage du wordmark : -1,5 %.
  static const double wordmarkTracking = -0.015;

  /// Ecartement mark ↔ wordmark en disposition horizontale, en unites.
  static const double horizontalGap = 20;

  /// Ecartement mark ↔ wordmark en disposition verticale, en unites.
  static const double verticalGap = 12;

  /// Largeur du wordmark « Relio » en Inter SemiBold, en em.
  ///
  /// Mesure sur la fonte embarquee (`assets/fonts/Inter-SemiBold.ttf`,
  /// 2048 unites/em) : somme des avances de R, e, l, i et o, soit
  /// 1990/2048 em, avant interlettrage.
  ///
  /// Recalcule par `test/branding/wordmark_metrics_test.dart` : si la fonte
  /// change, ce test echoue plutot que de laisser un lockup mal aligne.
  static const double wordmarkAdvanceEm = 1990 / 2048;

  /// Largeur du wordmark avec interlettrage applique, en em.
  ///
  /// L'interlettrage s'applique aux 4 intervalles du mot.
  static const double wordmarkWidthEm =
      wordmarkAdvanceEm + wordmarkTracking * 4;

  /// Hauteur de capitale d'Inter SemiBold, en em.
  ///
  /// Lue dans la table `OS/2` de la fonte embarquee (1490/2048 em).
  static const double wordmarkCapHeightEm = 1490 / 2048;
}

/// Peint le mark Relio.
///
/// Rendu vectoriel et independant de la taille : les valeurs viennent de
/// [RelioMarkGeometry] et la seule mise a l'echelle est la transformation du
/// canvas. Le meme painter sert donc la variante principale et la variante
/// compacte, selon l'epaisseur demandee.
class RelioMarkPainter extends CustomPainter {
  /// Cree le painter du mark.
  ///
  /// [stroke] par defaut suit la taille logique demandee : en dessous de
  /// [RelioMarkGeometry.compactThresholdDp], le trait s'epaissit
  /// automatiquement pour rester visible.
  const RelioMarkPainter({
    this.color = RelioBrand.mark,
    this.stroke,
    this.background,
    this.unitsPerPixel = 1,
  });

  /// Couleur du trait et des cercles. Le mark n'a qu'une seule couleur.
  final Color color;

  /// Epaisseur de trait en unites de grille.
  ///
  /// Si `null`, [RelioMarkGeometry.strokeForSize] decide selon la taille.
  final double? stroke;

  /// Fond optionnel, peint avant le mark. `null` pour un fond transparent.
  final Color? background;

  /// Taille du mark en pixels logiques, pour un `unitsPerPixel` de 1.
  ///
  /// Sert a choisir automatiquement la variante de trait.
  final double unitsPerPixel;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    if (side <= 0) return;

    // Le mark est dessine dans ses propres unites puis mis a l'echelle pour
    // occuper le carre. Le trait reste donc exprime dans les MEMES unites,
    // quelle que soit la taille de rendu.
    final double thickness =
        stroke ?? RelioMarkGeometry.strokeForSize(side / unitsPerPixel);

    final box = RelioMarkGeometry.boundingBox(thickness);
    final double boxWidth = box.right - box.left;
    final double boxHeight = box.bottom - box.top;

    // Le facteur tient compte de la boite englobante reelle, trait compris,
    // pour que rien ne soit rogne meme quand le trait s'epaissit.
    final double factor = math.min(side / boxWidth, side / boxHeight);

    canvas.save();
    canvas.translate(
      (size.width - boxWidth * factor) / 2,
      (size.height - boxHeight * factor) / 2,
    );
    canvas.scale(factor);
    // Recalage sur la boite englobante, et non sur la grille brute : la
    // grille de 100 unites n'est pas le rectangle occupe par le mark.
    canvas.translate(-box.left, -box.top);

    if (background case final Color bg) {
      canvas.drawRect(
        Rect.fromLTRB(box.left, box.top, box.right, box.bottom),
        Paint()..color = bg,
      );
    }

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(
      const Offset(RelioMarkGeometry.centerRightX, RelioMarkGeometry.centerRightY),
      RelioMarkGeometry.radiusRight,
      fill,
    );
    canvas.drawCircle(
      const Offset(RelioMarkGeometry.centerLeftX, RelioMarkGeometry.centerLeftY),
      RelioMarkGeometry.radiusLeft,
      fill,
    );

    final Path curve = Path()
      ..moveTo(RelioMarkGeometry.curveStartX, RelioMarkGeometry.centerLineY)
      ..cubicTo(
        RelioMarkGeometry.curveControl1X,
        RelioMarkGeometry.curveControlY,
        RelioMarkGeometry.curveControl2X,
        RelioMarkGeometry.curveControlY,
        RelioMarkGeometry.curveEndX,
        RelioMarkGeometry.centerLineY,
      );

    canvas.drawPath(
      curve,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(RelioMarkPainter old) =>
      old.color != color ||
      old.stroke != stroke ||
      old.background != background ||
      old.unitsPerPixel != unitsPerPixel;
}

/// Le mark seul, a la taille demandee.
///
/// Se place dans un `SizedBox` carre. La couleur est unique : le mark n'a pas
/// de variante bichrome.
class RelioMark extends StatelessWidget {
  /// Cree le mark.
  const RelioMark({
    super.key,
    required this.size,
    this.color = RelioBrand.mark,
    this.stroke,
    this.background,
  });

  /// Cote du carre occupe, en pixels logiques.
  ///
  /// Sous [RelioMarkGeometry.compactThresholdDp], le trait s'epaissit
  /// automatiquement : c'est la variante compacte.
  final double size;

  /// Couleur du mark.
  final Color color;

  /// Force l'epaisseur du trait, en unites de grille, si besoin.
  final double? stroke;

  /// Fond optionnel.
  final Color? background;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: RelioMarkPainter(
            color: color,
            stroke: stroke,
            background: background,
            unitsPerPixel: size,
          ),
        ),
      );
}

/// Le wordmark « Relio ».
///
/// Inter SemiBold 600, interlettrage -1,5 %, couleur indigo. Aucune fioriture :
/// ni ombre, ni italique, ni contour.
class RelioWordmark extends StatelessWidget {
  /// Cree le wordmark a une hauteur donnee.
  const RelioWordmark({
    super.key,
    required this.capHeight,
    this.color = RelioBrand.wordmark,
  });

  /// Hauteur de capitale souhaitee, en pixels logiques.
  ///
  /// La largeur decoule de la fonte : elle n'est pas forcée, ce qui evite de
  /// deformer les glyphes.
  final double capHeight;

  /// Couleur du texte.
  final Color color;

  @override
  Widget build(BuildContext context) {
    // La hauteur de capitale commande la taille de police. La largeur est laissee
    // au moteur de texte : la contraindre deformationnerait les glyphes, et la
    // fonte reste la reference.
    final double fontSize = capHeight / RelioBrand.wordmarkCapHeightEm;

    return SizedBox(
      height: capHeight,
      child: CustomPaint(
        painter: _WordmarkPainter(fontSize: fontSize, color: color),
        // La largeur reelle est publiee par le painter via son child minimal.
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  const _WordmarkPainter({required this.fontSize, required this.color});

  final double fontSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: 'Relio',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          color: color,
          letterSpacing: RelioBrand.wordmarkTracking * fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Centrage vertical sur la hauteur de capitale : la zone posee par
    // TextPainter inclut l'ascendante et la descendante, plus hautes que les
    // capitales themselves.
    final double dy = size.height / 2 - painter.height / 2;
    painter.paint(canvas, Offset(0, dy));
  }

  @override
  bool shouldRepaint(_WordmarkPainter old) =>
      old.fontSize != fontSize || old.color != color;
}
