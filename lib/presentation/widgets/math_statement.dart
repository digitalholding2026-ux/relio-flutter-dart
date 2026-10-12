/// Rendu LEGER des symboles et variables d'un énoncé.
///
/// OBJECTIF ASSUMÉ : ce n'est PAS un moteur de rendu mathématique, et ça ne
/// doit pas le devenir. La mission est explicitement de ne pas ajouter une
/// dépendance lourde « uniquement pour mettre quelques variables en
/// italique ».
///
/// Ce que fait ce composant :
///  - met en italique les variables d'une affectation (`a = 8`, `b = 12`) ;
///  - conserve `÷`, `×` et `−` tels quels : ils sont déjà dans la police et
///    s'affichent correctement en texte brut.
///
/// Ce qu'il ne fait PAS, volontairement :
///  - pas d'analyse d'expression ;
///  - pas de fractions, d'exposants ou de racines ;
///  - pas de second passage de LaTeX : le document validé n'en contient pas.
///
/// Toute généralisation ultérieure relève d'une décision pédagogique ET
/// d'un choix de dépendance, pas de ce fichier.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as diagnostics;

import '../theme/relio_theme.dart';

/// Une variable simple : une lettre minuscule suivie de `=`.
///
/// Le motif ne CONSOMME que la lettre : les espaces autour du signe égal
/// restent dans le texte normal, et ne sont donc pas mis en italique.
final RegExp _variableAvecAffectation = RegExp(r'\b([a-z])(?=\s*=)');

/// Énoncé rendu avec ses variables en italique.
class MathStatement extends StatelessWidget {
  const MathStatement({
    super.key,
    required this.statement,
    required this.style,
  });

  /// Texte brut de l'énoncé.
  final String statement;

  /// Style de base appliqué à l'énoncé.
  final TextStyle style;

  /// Style des variables : l'italique seul, tout le reste est conservé.
  TextStyle get _variableStyle => style.copyWith(
        fontVariations: RelioTheme.fontStyleItalic,
        fontStyle: FontStyle.italic,
      );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _buildSpans(), style: style),
    );
  }

  /// Découpe l'énoncé : le texte reste intact, seules les lettres de
  /// variable reçoivent l'italique.
  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    var index = 0;

    for (final match in _variableAvecAffectation.allMatches(statement)) {
      final letterStart = match.start;
      final letterEnd = match.end;

      if (letterStart > index) {
        spans.add(TextSpan(text: statement.substring(index, letterStart)));
      }
      spans.add(TextSpan(
        text: statement.substring(letterStart, letterEnd),
        style: _variableStyle,
      ));
      index = letterEnd;
    }

    if (index < statement.length) {
      spans.add(TextSpan(text: statement.substring(index)));
    }

    return spans;
  }

  @override
  void debugFillProperties(diagnostics.DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(diagnostics.StringProperty('statement', statement));
  }
}