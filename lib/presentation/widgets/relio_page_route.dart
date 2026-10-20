/// Route à glissement latéral, commune à tous les écrans empilés.
///
/// POURQUOI UNE ROUTE MAISON : le changement d'écran doit se lire comme un
/// déplacement, pas comme une substitution. La page arrive de la droite et
/// s'installe en 240 ms ; le retour la reconduit à droite en 200 ms.
///
/// L'amplitude est volontairement faible (10 % de la largeur) : au-delà, le
/// glissement devient une animation que l'on regarde au lieu d'un mouvement
/// qui accompagne la lecture.
library;

import 'package:flutter/material.dart';

/// Empile [builder] avec un glissement de la droite vers la gauche.
class RelioPageRoute<T> extends PageRouteBuilder<T> {
  /// Crée la route.
  ///
  /// [reduceAnimations] met les durées à zéro : l'écran apparaît d'un coup,
  /// comme le demande la préférence d'accessibilité de l'élève.
  RelioPageRoute({
    required WidgetBuilder builder,
    super.settings,
    bool reduceAnimations = false,
  }) : super(
          transitionDuration: reduceAnimations
              ? Duration.zero
              : const Duration(milliseconds: 240),
          reverseTransitionDuration: reduceAnimations
              ? Duration.zero
              : const Duration(milliseconds: 200),
          pageBuilder: (BuildContext context, Animation<double> animation,
                  Animation<double> secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            if (reduceAnimations) return child;

            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.10, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}
