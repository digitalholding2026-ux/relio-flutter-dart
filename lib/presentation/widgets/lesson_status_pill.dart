/// Pastille d'état d'une leçon.
///
/// Le libellé est OBLIGATOIRE : la couleur seule ne dirait rien à un élève
/// daltonien, et ne dirait rien du tout à un lecteur d'écran. Le point coloré
/// double le texte, il ne le remplace pas.
library;

import 'package:flutter/material.dart';

import '../theme/relio_theme.dart';

/// Pastille « En cours », « À revoir » ou « Maîtrisé ».
class LessonStatusPill extends StatelessWidget {
  /// Crée une pastille d'état.
  const LessonStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  /// Libellé de l'état.
  final String label;

  /// Couleur du point et du texte.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RelioSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: RelioRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: RelioSizes.statusDot,
            height: RelioSizes.statusDot,
            decoration: BoxDecoration(
              color: color,
              borderRadius: RelioRadius.pillAll,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: RelioType.badge(palette).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
