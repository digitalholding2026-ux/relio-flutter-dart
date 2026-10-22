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
    this.selectedClarification,
    this.onClarificationSelected,
    this.onClarificationSubmit,
    this.nextLabel,
  });

  /// Contenu et actions a afficher.
  final FeedbackSelection selection;

  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onContinue;

  /// Libelle du bouton de passage a la suite, ou `null` pour le libelle du
  /// parcours (« Exercice suivant »).
  ///
  /// Une seance courte ne mene pas a l'exercice suivant de la lecon : son
  /// appelant fournit donc le mot juste (« Suivant », « Retour a l'accueil »).
  final String? nextLabel;

  /// Option actuellement choisie dans le panneau D.
  final String? selectedClarification;

  /// Appele quand l'eleve choisit une option du panneau D.
  final ValueChanged<String>? onClarificationSelected;

  /// Appele quand l'eleve valide sa clarification.
  final VoidCallback? onClarificationSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final content = _content(palette);

    // Panneau C : carte blanche, liseré orange a gauche.
    if (selection.panel == FeedbackPanel.intervention) {
      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: RelioRadius.cardAll,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: palette.brand),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(RelioSpacing.cardInner),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: _background(palette),
        borderRadius: RelioRadius.cardAll,
        border: selection.panel == FeedbackPanel.clarification
            ? Border.all(color: palette.outline)
            : null,
      ),
      child: content,
    );
  }

  Widget _content(RelioPalette palette) {
    return Column(
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
            color: selection.title.isEmpty
                ? palette.textPrimary
                : _foreground(palette),
          ),
        ),
        if (selection.panel == FeedbackPanel.clarification) ...<Widget>[
          const SizedBox(height: RelioSpacing.cardGap),
          _clarificationOptions(palette),
          const SizedBox(height: RelioSpacing.cardGap),
          FilledButton(
            onPressed: selectedClarification == null
                ? null
                : onClarificationSubmit,
            child: const Text(RelioStrings.clarificationSubmit),
          ),
        ],
        if (selection.showRetry ||
            selection.showNext ||
            selection.showContinue) ...<Widget>[
          const SizedBox(height: RelioSpacing.cardGap),
          _actions(),
        ],
      ],
    );
  }

  Widget _clarificationOptions(RelioPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final option in selection.clarificationOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: RelioRadius.cardAll,
                onTap: () => onClarificationSelected?.call(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RelioSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selectedClarification == option
                        ? palette.hintBackground
                        : palette.surface,
                    borderRadius: RelioRadius.cardAll,
                    border: Border.all(
                      color: selectedClarification == option
                          ? palette.brand
                          : palette.outline,
                      width: selectedClarification == option ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        selectedClarification == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selectedClarification == option
                            ? palette.brand
                            : palette.textSecondary,
                      ),
                      const SizedBox(width: RelioSpacing.sm),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: RelioTheme.fontFamily,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _actions() {
    final buttons = <Widget>[];

    if (selection.showRetry) {
      buttons.add(
        FilledButton(onPressed: onRetry, child: const Text(RelioStrings.retry)),
      );
    }
    if (selection.showNext) {
      buttons.add(
        OutlinedButton(
          onPressed: onNext,
          child: Text(nextLabel ?? RelioStrings.nextExercise),
        ),
      );
    }
    if (selection.showContinue) {
      buttons.add(
        OutlinedButton(
          onPressed: onContinue,
          child: const Text(RelioStrings.continueLabel),
        ),
      );
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
    FeedbackPanel.intervention => p.surface,
    FeedbackPanel.clarification => p.surface,
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
