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
  /// Accent orange : zigzag et point. Couleur unique de l'accent : ni degrade,
  /// ni ombre, ni transparence.
  static const Color mark = Color(0xFFF56207);

  /// Indigo du « R », du second zigzag et du wordmark — identique au `primary`
  /// de `RelioPalette`.
  static const Color wordmark = Color(0xFF1F3A6E);

  /// Noir des declinaisons monochrome.
  static const Color monoBlack = Color(0xFF000000);

  /// Blanc des declinaisons monochrome et du mark inverse sur fond indigo.
  static const Color monoWhite = Color(0xFFFFFFFF);

  /// Fond du splash et de l'icone applicative.
  static const Color splashBackground = Color(0xFFFFFFFF);

  /// Fond de l'icone applicative : meme indigo que le wordmark.
  static const Color iconBackground = Color(0xFF1F3A6E);

  /// Interlettrage du wordmark : -1,5 %.
  static const double wordmarkTracking = -0.015;

  /// Interlettrage de la signature.
  static const double signatureTracking = 0.0;

  /// Ecartement mark ↔ wordmark en disposition horizontale, en unites.
  static const double horizontalGap = 20;

  /// Ecartement mark ↔ wordmark en disposition verticale, en unites.
  static const double verticalGap = 12;

  /// Taille de la signature, en fraction de la hauteur de capitale du mot.
  ///
  /// Mesure sur la specification : le mot est pose a 176 unites de corps et la
  /// signature a 31. Les deux partagent la meme fonte, donc le rapport des
  /// corps vaut celui des hauteurs de capitale.
  static const double signatureCapRatio = 31 / 176;

  /// Ecartement entre le bas du mot et le haut de la signature, en fraction
  /// de la hauteur de capitale du mot.
  ///
  /// Ce n'est pas un ecartement de grille du mark : il se mesure entre deux
  /// lignes de texte, donc depuis la ligne de base du mot. Dans la
  /// specification, la ligne de base du mot est a y = 218 et le haut de
  /// capitale de la signature a y = 265,45, soit 47,45 unites, pour une
  /// hauteur de capitale de mot de 128,08.
  static const double signatureGapRatio = 0.37;

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

/// Ce sur quoi le mark est pose, et donc de quelles couleurs il separe.
///
/// Le mark n'est pas monochrome : le « R » et le second zigzag portent la
/// couleur de base, le zigzag et le point portent l'accent. La declinaison
/// depend donc du fond, pas du mark seul.
enum RelioMarkVariant {
  /// Sur fond clair : « R » et second zigzag en indigo, accent orange.
  onLight,

  /// Sur fond indigo : « R » et second zigzag en blanc, accent orange.
  ///
  /// C'est la declinaison de l'icone applicative.
  onIndigo,

  /// Tout en noir : impression sur fond clair.
  monoBlack,

  /// Tout en blanc : impression sur fond sombre.
  monoWhite,
}

/// Les deux couleurs effectivement employeees par une declinaison.
({Color base, Color accent}) relioMarkColors(RelioMarkVariant variant) =>
    switch (variant) {
      RelioMarkVariant.onLight => (base: RelioBrand.wordmark, accent: RelioBrand.mark),
      RelioMarkVariant.onIndigo => (base: RelioBrand.monoWhite, accent: RelioBrand.mark),
      RelioMarkVariant.monoBlack => (base: RelioBrand.monoBlack, accent: RelioBrand.monoBlack),
      RelioMarkVariant.monoWhite => (base: RelioBrand.monoWhite, accent: RelioBrand.monoWhite),
    };

/// Traduit une trace de la geometrie en `Path`.
///
/// Les noeuds sont lus tels quels : aucune conversion, aucune approximation.
/// C'est ce qui garantit que l'ecran et le SVG decrivent la meme forme.
Path relioMarkPath(List<RelioMarkNode> nodes) {
  final Path path = Path();
  for (final RelioMarkNode node in nodes) {
    switch (node) {
      case RelioMarkMoveTo(:final double x, :final double y):
        path.moveTo(x, y);
      case RelioMarkLineTo(:final double x, :final double y):
        path.lineTo(x, y);
      case RelioMarkQuadTo(
          :final double cx,
          :final double cy,
          :final double x,
          :final double y,
        ):
        path.quadraticBezierTo(cx, cy, x, y);
      case RelioMarkClose():
        path.close();
    }
  }
  // `evenOdd` sur TOUTES les traces : le « R » est ajoure, et son contre doit
  // disparaitre. Sur une trace simple, le remplissage est inchange.
  path.fillType = PathFillType.evenOdd;
  return path;
}

/// Peint le mark Relio.
///
/// Rendu vectoriel et independant de la taille : les traces viennent de
/// [RelioMarkGeometry] et la seule mise a l'echelle est la transformation du
/// canvas.
class RelioMarkPainter extends CustomPainter {
  /// Cree le painter du mark.
  const RelioMarkPainter({
    this.variant = RelioMarkVariant.onLight,
    this.background,
    this.backgroundRadius = 0,
  });

  /// Declinaison chromatique.
  final RelioMarkVariant variant;

  /// Fond optionnel, peint avant le mark. `null` pour un fond transparent.
  final Color? background;

  /// Rayon des coins du fond, en unites de grille.
  ///
  /// A zero, le fond est un carre plein. L'icone applicative demande un fond a
  /// coins arrondis.
  final double backgroundRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    if (side <= 0) return;

    // Le mark est dessine dans ses propres unites puis mis a l'echelle pour
    // occuper le carre. Comme il n'y a plus de trait a epaissir, la mise a
    // l'echelle est unique : plus rien ne depend de la taille de rendu.
    final double factor = side / RelioMarkGeometry.inkHeight;
    final double drawnWidth = RelioMarkGeometry.inkWidth * factor;

    canvas.save();
    canvas.translate((size.width - drawnWidth) / 2, 0.0);
    canvas.scale(factor);
    canvas.translate(-RelioMarkGeometry.boundingBox.left, -RelioMarkGeometry.boundingBox.top);

    if (background case final Color bg) {
      final Rect box = Rect.fromLTRB(
        RelioMarkGeometry.boundingBox.left,
        RelioMarkGeometry.boundingBox.top,
        RelioMarkGeometry.boundingBox.right,
        RelioMarkGeometry.boundingBox.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(backgroundRadius)),
        Paint()..color = bg,
      );
    }

    final ({Color base, Color accent}) c = relioMarkColors(variant);

    for (final RelioMarkPart part in RelioMarkGeometry.parts) {
      canvas.drawPath(
        relioMarkPath(part.nodes),
        Paint()
          ..color = part.role == RelioMarkRole.accent ? c.accent : c.base
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    canvas.drawCircle(
      Offset(RelioMarkGeometry.dot.centerX, RelioMarkGeometry.dot.centerY),
      RelioMarkGeometry.dot.radius,
      Paint()
        ..color = c.accent
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(RelioMarkPainter old) =>
      old.variant != variant ||
      old.background != background ||
      old.backgroundRadius != backgroundRadius;
}

/// Le mark seul, a la taille demandee.
///
/// Se place dans un `SizedBox` carre.
class RelioMark extends StatelessWidget {
  /// Cree le mark.
  const RelioMark({
    super.key,
    required this.size,
    this.variant = RelioMarkVariant.onLight,
    this.background,
    this.backgroundRadius = 0,
  });

  /// Cote du carre occupe, en pixels logiques.
  final double size;

  /// Declinaison chromatique.
  final RelioMarkVariant variant;

  /// Fond optionnel.
  final Color? background;

  /// Rayon des coins du fond, en unites de grille.
  final double backgroundRadius;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: RelioMarkPainter(
            variant: variant,
            background: background,
            backgroundRadius: backgroundRadius,
          ),
        ),
      );
}

/// Le wordmark « Relio ».
///
/// Inter SemiBold 600, interlettrage -1,5 %, couleur indigo. Aucune fioriture :
/// ni ombre, ni italique, ni contour.
class RelioWordmark extends StatelessWidget {
  /// Texte du wordmark.
  ///
  /// Source unique : le generateur de SVG s'en sert pour ses libelles, afin
  /// que l'ecran et le fichier ne puissent pas diverger.
  static const String text = 'Relio';

  /// Cree le wordmark a une hauteur donnee.
  const RelioWordmark({
    super.key,
    required this.capHeight,
    this.color = RelioBrand.wordmark,
  });

  /// Hauteur de capitale souhaitee, en pixels logiques.
  final double capHeight;

  /// Couleur du texte.
  final Color color;

  /// Corps de police correspondant à [capHeight].
  ///
  /// La hauteur de capitale d'Inter SemiBold vaut 1490/2048 em : c'est elle,
  /// et non le corps, qui commande la taille optique du mot.
  double get fontSize => capHeight / RelioBrand.wordmarkCapHeightEm;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.left,
        // `height: 1` et une gouttière forcée fixent la boîte à `fontSize`.
        //
        // Le mot occupe alors une place RÉELLE dans la mise en page. Ce n'était
        // pas le cas avant : le texte était peint par un `CustomPaint` dont
        // l'enfant valait zéro, donc la boîte mesurait zéro de large, et le mot
        // se superposait au mark avant de sortir de l'écran.
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          color: color,
          letterSpacing: RelioBrand.wordmarkTracking * fontSize,
          height: 1,
        ),
        strutStyle: StrutStyle.fromTextStyle(
          TextStyle(fontSize: fontSize),
          forceStrutHeight: true,
        ),
      );
}

/// La signature de marque, sous le wordmark.
///
/// « Les maths, c'est ton terrain ! » pose en Inter SemiBold, dans l'indigo du
/// wordmark. C'est une baseline : elle appartient au lockup, jamais au mark
/// seul — un mark sur un lanceur n'a pas de signature.
///
/// [RelioSignature.text] est la seule source du texte : le generateur SVG
/// s'en sert aussi, pour que le SVG et l'ecran ne puissent pas diverger.
class RelioSignature extends StatelessWidget {
  const RelioSignature({super.key, required this.capHeight, this.color = RelioBrand.wordmark});

  /// Texte de la signature.
  static const String text = 'Les maths, c\u2019est ton terrain !';

  /// Hauteur de capitale souhaitee, en pixels logiques.
  final double capHeight;

  /// Couleur du texte.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fontSize = capHeight / RelioBrand.wordmarkCapHeightEm;
    return Text(
      text,
      textAlign: TextAlign.left,
      // Même géométrie de boîte que le wordmark : voir [RelioWordmark] pour
      // l'explication — c'est la raison pour laquelle la signature occupait
      // elle aussi une place de largeur nulle.
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: color,
        letterSpacing: RelioBrand.signatureTracking * fontSize,
        height: 1,
      ),
      strutStyle: StrutStyle.fromTextStyle(
        TextStyle(fontSize: fontSize),
        forceStrutHeight: true,
      ),
    );
  }
}