/// Barre de progression commune aux écrans d'apprentissage.
///
/// Une seule forme pour l'accueil, le catalogue et la vue des leçons : un
/// trait plein sur un rail arrondi. La couleur vient de l'appelant — elle
/// porte un état, jamais une décoration.
library;

import 'package:flutter/material.dart';

import '../theme/relio_theme.dart';

/// Barre de progression fine, sans chiffre.
class RelioProgressBar extends StatelessWidget {
  /// Crée une barre de progression.
  const RelioProgressBar({
    super.key,
    required this.ratio,
    required this.color,
    required this.track,
    this.height = RelioSizes.lessonBarHeight,
  });

  /// Part remplie, entre 0 et 1. Les valeurs hors bornes sont ramenées dans
  /// l'intervalle : une donnée incohérente ne doit pas peindre hors du rail.
  final double ratio;

  /// Couleur du trait rempli.
  final Color color;

  /// Couleur du rail.
  final Color track;

  /// Hauteur du trait.
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: track,
            borderRadius: RelioRadius.pillAll,
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: constraints.maxWidth * ratio.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: RelioRadius.pillAll,
            ),
          ),
        );
      },
    );
  }
}
