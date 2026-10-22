/// Fin d'une session rapide — « J'ai 5 minutes ».
///
/// UN SEUL ÉCRAN, UN SEUL BOUTON : la session est finie, l'élève n'a plus
/// rien à valider. Le retour ramène à l'accueil, dans la pile de l'onglet
/// Accueil — la session n'a jamais fait passer par S1.
///
/// Aucun bilan chiffré : ni nombre de réussites, ni score. Le message est une
/// clôture, pas une évaluation (règle 5).
library;

import 'package:flutter/material.dart';

import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Écran de fin de session rapide.
class QuickSessionEndPage extends StatelessWidget {
  /// Crée l'écran.
  const QuickSessionEndPage({super.key, required this.onHome});

  /// Retour à l'accueil.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          RelioStrings.quickSessionTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: RelioTheme.fontFamily,
            color: palette.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: RelioSpacing.horizontal,
              vertical: RelioSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: palette.brand,
                ),
                const SizedBox(height: RelioSpacing.lg),
                Text(
                  RelioStrings.quickSessionEndTitle,
                  textAlign: TextAlign.center,
                  style: RelioType.title(palette),
                ),
                const SizedBox(height: RelioSpacing.md),
                Text(
                  RelioStrings.quickSessionEndMessage,
                  textAlign: TextAlign.center,
                  style: RelioType.body(palette),
                ),
                const SizedBox(height: RelioSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onHome,
                    child: const Text(RelioStrings.quickBackHome),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
