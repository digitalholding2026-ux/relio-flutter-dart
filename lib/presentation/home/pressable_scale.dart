/// Effet d'appui commun à toutes les cartes de l'accueil.
///
/// Un appui rapproche brièvement la carte de 3 % : le geste se voit avant même
/// que la navigation ait commencé. L'effet est volontairement court (90 ms) et
/// purement visuel — il ne retarde jamais l'action, qui part au relâchement.
///
/// ACCESSIBILITÉ : ce widget ne remplace pas une cible tactile ni un libellé.
/// Il enveloppe un contenu déjà lisible et annonce son rôle via [Semantics].
library;

import 'package:flutter/material.dart';

/// Enveloppe un contenu cliquable d'un léger effet d'échelle à l'appui.
class PressableScale extends StatefulWidget {
  /// Crée l'effet d'appui.
  const PressableScale({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
    this.reduceAnimations = false,
  });

  /// Action déclenchée au relâchement.
  final VoidCallback onTap;

  /// Contenu mis à l'échelle.
  final Widget child;

  /// Échelle atteinte pendant l'appui.
  final double scale;

  /// Supprime l'animation : l'échelle reste à 1.
  ///
  /// Respecte la préférence « réduire les animations » de l'élève.
  final bool reduceAnimations;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool scaled = _pressed && !widget.reduceAnimations;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) {
          _setPressed(false);
          widget.onTap();
        },
        // Le fond est transparent : l'ensemble de la carte reste touchable,
        // y compris ses marges intérieures.
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scaled ? widget.scale : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
