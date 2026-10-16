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
import 'relio_wordmark_geometry.dart';

export 'relio_mark_geometry.dart';
export 'relio_wordmark_geometry.dart';

/// Couleurs et declinaisons de la marque.
///
/// Les valeurs hexadecimales sont exactes et ne sont jamais remplacees par un
/// nom de couleur : la specification l'exige pour les SVG, et l'usage unique
/// doit etre le meme partout.
abstract final class RelioBrand {
  /// Accent orange : pages et gland. Couleur unique de l'accent : ni degrade,
  /// ni ombre, ni transparence.
  static const Color mark = Color(0xFFFE7904);

  /// Navy de la structure, du wordmark et de la signature — identique au
  /// `primary` de `RelioPalette`.
  static const Color wordmark = Color(0xFF0E1821);

  /// Navy d'appui : fond pressé du bouton principal.
  ///
  /// Dérivé du navy par assombrissement (~0,75), comme l'ancien
  /// `#172C56` l'était de l'ancien indigo.
  static const Color wordmarkPressed = Color(0xFF0A1219);

  /// Noir des declinaisons monochrome.
  static const Color monoBlack = Color(0xFF000000);

  /// Blanc des declinaisons monochrome et du mark inverse sur fond navy.
  static const Color monoWhite = Color(0xFFFFFFFF);

  /// Fond du splash et de l'icone applicative.
  static const Color splashBackground = Color(0xFFFFFFFF);

  /// Fond de l'icone applicative : orange de la marque.
  static const Color iconBackground = Color(0xFFFE7904);

  /// Interlettrage du wordmark : les lettres sont tracees, pas composees.
  ///
  /// L'espacement est fige dans la geometrie, et non ajuste au rendu.
  static const double wordmarkTracking = 0.0;

  /// Interlettrage de la signature.
  static const double signatureTracking = 0.0;

  /// Ecartement mark ↔ wordmark en disposition horizontale, en unites.
  ///
  /// Mesure sur le logo livre : 22 px pour un mark de 491 px, soit 4,5
  /// unites de grille.
  static const double horizontalGap = 4.5;

  /// Ecartement mark ↔ wordmark en disposition verticale, en unites.
  ///
  /// Sans reference livree : meme valeur qu'en horizontal.
  static const double verticalGap = 4.5;

  /// Taille de la signature, en fraction de la hauteur du mot.
  ///
  /// Mesure sur le logo livre : capitale du « A » de 42 px pour un mot de
  /// 300 px.
  static const double signatureCapRatio = 0.14;

  /// Ecartement entre le bas du mot et le haut de la signature, en fraction
  /// de la hauteur du mot.
  ///
  /// Mesure sur le logo livre : 46 px pour un mot de 300 px.
  static const double signatureGapRatio = 0.153;

  /// Hauteur de capitale d'Inter SemiBold, en em.
  ///
  /// Lue dans la table `OS/2` de la fonte embarquee (1490/2048 em). Ne sert
  /// qu'a la signature, qui reste composee en fonte : le mot est trace.
  static const double interCapHeightEm = 1490 / 2048;
}

/// Ce sur quoi le mark est pose, et donc de quelles couleurs il separe.
///
/// Le mark n'est pas monochrome : le chapeau, le fût, la courbe et le balayage
/// portent la couleur de base, les pages et le gland portent l'accent. La
/// declinaison depend donc du fond, pas du mark seul.
enum RelioMarkVariant {
  /// Sur fond clair : structure en navy, accent orange.
  onLight,

  /// Sur fond navy : structure en blanc, accent orange.
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
  // `evenOdd` sur TOUTES les traces : les remplissages restent corrects meme
  // si une trace porte plusieurs contours. Sur une trace simple, le
  // remplissage est inchange.
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
  /// Source unique du mot : le generateur de SVG s'en sert pour ses libelles,
  /// afin que l'ecran et le fichier ne puissent pas diverger. Les lettres
  /// sont tracees, pas composees.
  static const String text = 'relio';

  /// Cree le wordmark a une hauteur donnee.
  const RelioWordmark({
    super.key,
    required this.wordHeight,
    this.variant = RelioMarkVariant.onLight,
    this.wordmarkColor,
  });

  /// Hauteur du mot souhaitee, en pixels logiques.
  ///
  /// C'est la commande de taille du bloc de texte : la signature se cale
  /// dessus via [RelioBrand.signatureCapRatio].
  final double wordHeight;

  /// Declinaison chromatique des lettres.
  final RelioMarkVariant variant;

  /// Couleur de la structure, par defaut celle de la declinaison.
  ///
  /// Permet au lockup d'imposer sa couleur sans changer de declinaison.
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final double width = wordHeight *
        RelioWordmarkGeometry.inkWidth /
        RelioWordmarkGeometry.inkHeight;
    return SizedBox(
      width: width,
      height: wordHeight,
      child: CustomPaint(
        painter: RelioWordmarkPainter(
          variant: variant,
          wordmarkColor: wordmarkColor,
        ),
      ),
    );
  }
}

/// Peint le wordmark « relio » trace.
///
/// Meme source que le SVG : [RelioWordmarkGeometry]. Les roles chromatiques
/// suivent les declinaisons du mark.
class RelioWordmarkPainter extends CustomPainter {
  /// Cree le painter du wordmark.
  const RelioWordmarkPainter({
    this.variant = RelioMarkVariant.onLight,
    this.wordmarkColor,
  });

  /// Declinaison chromatique.
  final RelioMarkVariant variant;

  /// Couleur de la structure, par defaut celle de la declinaison.
  final Color? wordmarkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = RelioWordmarkGeometry.inkWidth;
    final double h = RelioWordmarkGeometry.inkHeight;
    if (w <= 0 || h <= 0) return;
    final double factor = size.height / h;
    final double drawnWidth = w * factor;

    canvas.save();
    canvas.translate((size.width - drawnWidth) / 2, 0.0);
    canvas.scale(factor);
    canvas.translate(-RelioWordmarkGeometry.wordBox.left,
        -RelioWordmarkGeometry.wordBox.top);

    final ({Color base, Color accent}) c = relioMarkColors(variant);
    final Color base = wordmarkColor ?? c.base;

    for (final RelioMarkPart part in RelioWordmarkGeometry.parts) {
      canvas.drawPath(
        relioMarkPath(part.nodes),
        Paint()
          ..color = part.role == RelioMarkRole.accent ? c.accent : base
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(RelioWordmarkPainter old) =>
      old.variant != variant || old.wordmarkColor != wordmarkColor;
}

/// La signature de marque, sous le wordmark.
///
/// « Apprendre aujourd’hui, réussir demain » pose en Inter SemiBold, dans le
/// navy du wordmark. C'est une baseline : elle appartient au lockup, jamais
/// au mark seul — un mark sur un lanceur n'a pas de signature.
///
/// [RelioSignature.text] est la seule source du texte : le generateur SVG
/// s'en sert aussi, pour que le SVG et l'ecran ne puissent pas diverger.
class RelioSignature extends StatelessWidget {
  const RelioSignature({super.key, required this.capHeight, this.color = RelioBrand.wordmark});

  /// Texte de la signature.
  static const String text = 'Apprendre aujourd\u2019hui, réussir demain';

  /// Hauteur de capitale souhaitee, en pixels logiques.
  final double capHeight;

  /// Couleur du texte.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fontSize = capHeight / RelioBrand.interCapHeightEm;
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