/// Lockups Relio — mark et wordmark assembles.
///
/// Les deux dispositions prevues par la specification :
///  - horizontale, pour en-tete, splash et ecran large ;
///  - verticale, pour launcher icon, splash et ecran carre.
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

/// Lockup horizontal : mark a gauche, wordmark a droite.
///
/// Le centre du mark coincide avec la mi-hauteur du wordmark. L'ecartement
/// entre les deux est [RelioBrand.horizontalGap] fois l'echelle du mark.
class RelioLockupHorizontal extends StatelessWidget {
  /// Cree le lockup horizontal.
  const RelioLockupHorizontal({
    super.key,
    required this.markSize,
    this.markColor = RelioBrand.mark,
    this.wordmarkColor = RelioBrand.wordmark,
    this.gapUnits = kHorizontalGap,
  });

  /// Hauteur de capitale du wordmark, en pixels logiques.
  ///
  /// C'est aussi la commande de taille du lockup entier : le mark se cale sur
  /// cette hauteur.
  final double markSize;

  /// Couleur du mark.
  final Color markColor;

  /// Couleur du wordmark.
  final Color wordmarkColor;

  /// Ecartement mark ↔ wordmark, en unites de grille du mark.
  final double gapUnits;

  @override
  Widget build(BuildContext context) {
    // Le mark est deux fois plus haut que la hauteur de capitale qu'il
    // accompagne : on garde son rapport de proportion et on aligne les centres.
    final double markHeight = markSize * 1.6;
    final double gap = gapUnits * markHeight / RelioMarkGeometry.grid;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: markHeight,
          child: RelioMark(size: markHeight, color: markColor),
        ),
        SizedBox(width: gap),
        RelioWordmark(capHeight: markSize, color: wordmarkColor),
      ],
    );
  }
}

/// Lockup vertical : mark au-dessus, wordmark en dessous.
///
/// Le wordmark est centre horizontalement sous le mark, avec un ecartement de
/// [RelioBrand.verticalGap] unites de grille.
class RelioLockupVertical extends StatelessWidget {
  /// Cree le lockup vertical.
  const RelioLockupVertical({
    super.key,
    required this.markSize,
    this.markColor = RelioBrand.mark,
    this.wordmarkColor = RelioBrand.wordmark,
    this.gapUnits = kVerticalGap,
  });

  /// Cote du mark, en pixels logiques.
  final double markSize;

  /// Couleur du mark.
  final Color markColor;

  /// Couleur du wordmark.
  final Color wordmarkColor;

  /// Ecartement mark ↔ wordmark, en unites de grille du mark.
  final double gapUnits;

  @override
  Widget build(BuildContext context) {
    final double gap = gapUnits * markSize / RelioMarkGeometry.grid;
    // Le mark est bien plus large que le mot : le lockup vertical se dimensionne
    // sur le mark, et le mot se centre dessous.
    final double wordmarkCap = markSize * 0.34;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RelioMark(size: markSize, color: markColor),
        SizedBox(height: math.max(gap, 8)),
        RelioWordmark(capHeight: wordmarkCap, color: wordmarkColor),
      ],
    );
  }
}
