/// Panneau de retour apres soumission.
///
/// PRESENTATION SEULEMENT : le contenu provient entierement de
/// [FeedbackSelection], lui-meme deduit des faits renvoyes par le moteur.
/// Ce widget ne decide rien.
library;

import 'package:flutter/material.dart';

import '../rules/feedback_selection.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Panneau colore selon le cas, avec ses actions.
class FeedbackPanelView extends StatelessWidget {
  const FeedbackPanelView({
    super.key,
    required this.selection,
    required this.onRetry,
    required this.onNext,
    required this.onContinue,
  });

  /// Contenu et actions a afficher.
  final FeedbackSelection selection;

  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: _background(palette),
        borderRadius: RelioRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (selection.title.isNotEmpty) ...<Widget>[
            Text(
              selection.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: RelioTheme.fontFamily,
                color: _foreground(palette),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            selection.message,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontFamily: RelioTheme.fontFamily,
              color: selection.title.isEmpty ? palette.textPrimary : _foreground(palette),
            ),
          ),
          if (selection.showRetry ||
              selection.showNext ||
              selection.showContinue) ...<Widget>[
            const SizedBox(height: RelioSpacing.cardGap),
            _actions(context),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final buttons = <Widget>[];

    if (selection.showRetry) {
      buttons.add(FilledButton(
        onPressed: onRetry,
        child: const Text(RelioStrings.retry),
      ));
    }
    if (selection.showNext) {
      buttons.add(OutlinedButton(
        onPressed: onNext,
        child: const Text(RelioStrings.nextExercise),
      ));
    }
    if (selection.showContinue) {
      buttons.add(OutlinedButton(
        onPressed: onContinue,
        child: const Text(RelioStrings.continueLabel),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final button in buttons) ...<Widget>[
          button,
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Color _background(RelioPalette p) => switch (selection.panel) {
        FeedbackPanel.successAutonomous => p.successBackground,
        FeedbackPanel.successAssisted => p.hintBackground,
        FeedbackPanel.noInformation => p.background,
        FeedbackPanel.notRecognised => p.background,
        FeedbackPanel.inconclusive => p.background,
      };

  Color _foreground(RelioPalette p) => switch (selection.panel) {
        FeedbackPanel.successAutonomous => p.successText,
        FeedbackPanel.successAssisted => p.hintText,
        _ => p.textPrimary,
      };
}
