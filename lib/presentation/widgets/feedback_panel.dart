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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(RelioSizes.cardRadius),
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
                fontVariations: RelioTheme.w600,
                fontFamily: RelioTheme.fontFamily,
                color: _foreground,
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
              color: selection.title.isEmpty ? RelioColors.text : _foreground,
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
        style: RelioButtons.primary(),
        child: const Text(RelioStrings.retry),
      ));
    }
    if (selection.showNext) {
      buttons.add(OutlinedButton(
        onPressed: onNext,
        style: RelioButtons.secondary(),
        child: const Text(RelioStrings.nextExercise),
      ));
    }
    if (selection.showContinue) {
      buttons.add(OutlinedButton(
        onPressed: onContinue,
        style: RelioButtons.secondary(),
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

  Color get _background => switch (selection.panel) {
        FeedbackPanel.successAutonomous => RelioColors.successBackground,
        FeedbackPanel.successAssisted => RelioColors.hintBackground,
        FeedbackPanel.noInformation => RelioColors.background,
        FeedbackPanel.notRecognised => RelioColors.background,
        FeedbackPanel.inconclusive => RelioColors.background,
      };

  Color get _foreground => switch (selection.panel) {
        FeedbackPanel.successAutonomous => RelioColors.successText,
        FeedbackPanel.successAssisted => RelioColors.hintText,
        _ => RelioColors.text,
      };
}
