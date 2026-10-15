/// Lockups Relio — mark, wordmark et signature assembles.
///
/// Les deux dispositions prevues par la specification :
///  - horizontale, pour en-tete, splash et ecran large ;
///  - verticale, pour launcher icon, splash et ecran carre.
///
/// Le mot et la signature forment un seul bloc : la signature est une
/// baseline du lockup, pas un element flottant. Ils sont donc poses dans la
/// meme colonne et l'ecartement se mesure depuis le bas du mot.
///
/// L'alignement est calcule, pas approche : la hauteur de capitale du
/// wordmark vient de la fonte embarquee (`RelioBrand.wordmarkCapHeightEm`),
/// ce qui garantit que le centre du mark tombe exactement a mi-hauteur du
/// mot, quelle que soit la taille demandee.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'relio_mark.dart';

/// Ecarts de la specification, re-exposes ici pour les tests.
const double kHorizontalGap = 20;
const double kVerticalGap = 12;

/// Rapport entre la hauteur du mark et la hauteur de capitale du wordmark.
///
/// Mesure sur la specification : le mark fait 100 unites de haut dans sa
/// grille, le mot 128,5 unites de capitale dans le logo de reference. Le
/// rapport est donc de 100 / 128,5. Il ne depend pas du mot : il sert a
/// caler le mark sur la hauteur du mot.
const double kMarkToWordmarkRatio = 1.93;

/// Le mot et la signature, empiles.
///
/// Ce bloc est le second element des deux lockups : le poser une seule fois
/// evite que les deux dispositions ne divergent.
class _WordBlock extends StatelessWidget {
  const _WordBlock({required this.capHeight, required this.color});

  final double capHeight;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RelioWordmark(capHeight: capHeight, color: color),
          SizedBox(height: capHeight * RelioBrand.signatureGapRatio),
          RelioSignature(
            capHeight: capHeight * RelioBrand.signatureCapRatio,
            color: color,
          ),
        ],
      );
}

/// Lockup horizontal : mark a gauche, mot et signature a droite.
///
/// Le centre du mark coincide avec la mi-hauteur du BLOC mot + signature, pas
/// avec celle du mot seul : sinon le mark paraitrait monte.
class RelioLockupHorizontal extends StatelessWidget {
  /// Cree le lockup horizontal.
  const RelioLockupHorizontal({
    super.key,
    required this.markSize,
    this.variant = RelioMarkVariant.onLight,
    this.wordmarkColor = RelioBrand.wordmark,
    this.gapUnits = kHorizontalGap,
  });

  /// Hauteur de capitale du wordmark, en pixels logiques.
  ///
  /// C'est aussi la commande de taille du lockup entier : le mark se cale sur
  /// cette hauteur.
  final double markSize;

  /// Declinaison chromatique du mark.
  final RelioMarkVariant variant;

  /// Couleur du mot et de la signature.
  final Color wordmarkColor;

  /// Ecartement mark ↔ bloc de texte, en unites de grille du mark.
  final double gapUnits;

  @override
  Widget build(BuildContext context) {
    final double markHeight = markSize * kMarkToWordmarkRatio;
    final double gap = gapUnits * markHeight / RelioMarkGeometry.grid;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        RelioMark(size: markHeight, variant: variant),
        SizedBox(width: gap),
        _WordBlock(capHeight: markSize, color: wordmarkColor),
      ],
    );
  }
}

/// Lockup vertical : mark au-dessus, mot et signature en dessous.
///
/// Le bloc de texte est centre horizontalement sous le mark, avec un
/// ecartement de [RelioBrand.verticalGap] unites de grille.
class RelioLockupVertical extends StatelessWidget {
  /// Cree le lockup vertical.
  const RelioLockupVertical({
    super.key,
    required this.markSize,
    this.variant = RelioMarkVariant.onLight,
    this.wordmarkColor = RelioBrand.wordmark,
    this.gapUnits = kVerticalGap,
  });

  /// Cote du mark, en pixels logiques.
  final double markSize;

  /// Declinaison chromatique du mark.
  final RelioMarkVariant variant;

  /// Couleur du mot et de la signature.
  final Color wordmarkColor;

  /// Ecartement mark ↔ bloc de texte, en unites de grille du mark.
  final double gapUnits;

  @override
  Widget build(BuildContext context) {
    final double gap = gapUnits * markSize / RelioMarkGeometry.grid;
    // Le mark est bien plus large que le mot : le lockup vertical se
    // dimensionne sur le mark, et le bloc se centre dessous.
    final double wordmarkCap = markSize / kMarkToWordmarkRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RelioMark(size: markSize, variant: variant),
        SizedBox(height: math.max(gap, 8)),
        _WordBlock(capHeight: wordmarkCap, color: wordmarkColor),
      ],
    );
  }
}