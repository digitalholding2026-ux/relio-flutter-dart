/// Lockups Relio — mark, wordmark trace et signature assembles.
///
/// Les deux dispositions prevues par la specification :
///  - horizontale, pour en-tete, splash et ecran large ;
///  - verticale, pour launcher icon, splash et ecran carre.
///
/// Le mot et la signature forment un seul bloc : la signature est une
/// baseline du lockup, pas un element flottant. Ils sont donc poses dans la
/// meme colonne et l'ecartement se mesure depuis le bas du mot.
///
/// Le mot est TRACE, pas compose : `RelioWordmark` peint la geometrie
/// `RelioWordmarkGeometry`, a la hauteur demandee. Le rapport entre le mark
/// et le mot est mesure sur le logo livre.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'relio_mark.dart';

/// Ecarts de la specification, re-exposes ici pour les tests.
const double kHorizontalGap = 4.5;
const double kVerticalGap = 4.5;

/// Rapport entre la hauteur du mark et la hauteur du wordmark.
///
/// Mesure sur le logo livre : mark de 491 px pour un mot de 300 px.
const double kMarkToWordmarkRatio = 1.637;

/// Le mot et la signature, empiles.
///
/// Ce bloc est le second element des deux lockups : le poser une seule fois
/// evite que les deux dispositions ne divergent.
class _WordBlock extends StatelessWidget {
  const _WordBlock({
    required this.wordHeight,
    required this.variant,
    this.color,
  });

  final double wordHeight;
  final RelioMarkVariant variant;

  /// Couleur du mot et de la signature, par defaut celle de la declinaison.
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RelioWordmark(
            wordHeight: wordHeight,
            variant: variant,
            wordmarkColor: color,
          ),
          SizedBox(height: wordHeight * RelioBrand.signatureGapRatio),
          RelioSignature(
            capHeight: wordHeight * RelioBrand.signatureCapRatio,
            color: color ?? relioMarkColors(variant).base,
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
    this.wordmarkColor,
    this.gapUnits = kHorizontalGap,
  });

  /// Hauteur du wordmark, en pixels logiques.
  ///
  /// C'est aussi la commande de taille du lockup entier : le mark se cale sur
  /// cette hauteur via [kMarkToWordmarkRatio].
  final double markSize;

  /// Declinaison chromatique du mark.
  final RelioMarkVariant variant;

  /// Couleur du mot et de la signature, par defaut celle de la declinaison.
  final Color? wordmarkColor;

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
        _WordBlock(
          wordHeight: markSize,
          variant: variant,
          color: wordmarkColor,
        ),
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
    this.wordmarkColor,
    this.gapUnits = kVerticalGap,
  });

  /// Cote du mark, en pixels logiques.
  final double markSize;

  /// Declinaison chromatique du mark.
  final RelioMarkVariant variant;

  /// Couleur du mot et de la signature, par defaut celle de la declinaison.
  final Color? wordmarkColor;

  /// Ecartement mark ↔ bloc de texte, en unites de grille du mark.
  final double gapUnits;

  @override
  Widget build(BuildContext context) {
    final double gap = gapUnits * markSize / RelioMarkGeometry.grid;
    // Le mark est plus haut que large : le lockup vertical se dimensionne
    // sur le mark, et le bloc se centre dessous.
    final double wordHeight = markSize / kMarkToWordmarkRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RelioMark(size: markSize, variant: variant),
        SizedBox(height: math.max(gap, 8)),
        _WordBlock(
          wordHeight: wordHeight,
          variant: variant,
          color: wordmarkColor,
        ),
      ],
    );
  }
}
