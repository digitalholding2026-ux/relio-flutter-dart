/// Zone d'affichage des indices consignes.
///
/// Les indices restent visibles une fois consignes : ils s'ajoutent en bas de
/// la zone, dans l'ordre fourni par le moteur.
library;

import 'package:flutter/material.dart';

import '../../domain/curriculum/rich_hint.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import 'math_text.dart';

/// Liste ordonnee des indices deja consignes.
class HintArea extends StatelessWidget {
  const HintArea({super.key, required this.hints});

  /// Fiches consignes, dans l'ordre de consultation.
  ///
  /// Vide a l'ouverture : la zone ne reserve aucun espace.
  final List<RichHint> hints;

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

  final RichHint hint;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: palette.hintBackground,
        borderRadius: RelioRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            RelioStrings.hintLabel(hint.order),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: RelioTheme.fontFamily,
              color: palette.hintText,
            ),
          ),
          const SizedBox(height: 6),
          // Rappel COMPACT, pas le contenu de la fiche.
          //
          // Le contenu entier appartient au panneau. Le recopier ici
          // empilerait les mots dans l'ecran de l'eleve, allongerait la
          // colonne au point de repousser le panneau de correction hors du
          // viewport, et n'apporterait rien : l'eleve vient de le lire.
          MathText(
            text: hint.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.45,
              fontFamily: RelioTheme.fontFamily,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
