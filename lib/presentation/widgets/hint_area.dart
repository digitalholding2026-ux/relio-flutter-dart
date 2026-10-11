/// Zone d'affichage des indices consignes.
///
/// Les indices restent visibles une fois consignes : ils s'ajoutent en bas de
/// la zone, dans l'ordre fourni par le moteur.
library;

import 'package:flutter/material.dart';

import '../../domain/curriculum/exercise.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Liste ordonnee des indices deja consignes.
class HintArea extends StatelessWidget {
  const HintArea({super.key, required this.hints});

  /// Indices consignes, dans l'ordre de consultation.
  ///
  /// Vide a l'ouverture : la zone ne reserve aucun espace.
  final List<ExerciseHint> hints;

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final hint in hints) ...<Widget>[
          _HintTile(hint: hint),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HintTile extends StatelessWidget {
  const _HintTile({required this.hint});

  final ExerciseHint hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: RelioColors.hintBackground,
        borderRadius: BorderRadius.circular(RelioSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            RelioStrings.hintLabel(hint.order),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: RelioTheme.fontFamily,
              color: RelioColors.hintText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.45,
              fontFamily: RelioTheme.fontFamily,
              color: RelioColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
