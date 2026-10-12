/// Formateur typographique minimal pour les textes à notation mathématique.
///
/// PÉRIMÈTRE STRICT, chapitre 1.
///
/// Ce que fait EXACTEMENT ce formateur :
///
///  - met en italique une **variable isolée** (une lettre minuscule seule,
///    entourée d'un espace, d'un `=`, d'une parenthèse ou d'une virgule) ;
///  - passe les **chiffres** en chiffres tabulaires ;
///  - laisse les **opérateurs** (`+ − × ÷ =`) et parenthèses inchangés,
///    donc uprights ;
///  - ne touche à aucun mot.
///
/// Ce qu'il ne fait PAS, et ne fera pas sans nouvelle décision :
///
///  - ni fractions, ni exposants, ni racines, ni sommes, ni intégrales ;
///  - aucune mise en page multi-ligne de calcul ;
///  - aucune tentative de comprendre le sens mathématique du texte ;
///  - aucune bibliothèque externe.
///
/// PRINCIPE DE ROBUSTESSE : toute notation non reconnue est laissée
/// **telle quelle**. Un texte imparfaitement formaté vaut mieux qu'un texte
/// mal formaté. Le formateur ne réécrit jamais un caractère : il ne fait que
/// choisir un style par fragment.
library;

import 'package:flutter/foundation.dart' as diagnostics;
import 'package:flutter/material.dart';

/// Un fragment de texte et son style.
///
/// L'unité de sortie du formateur : jamais un caractère isolé, toujours un
/// fragment maximal partageant le même traitement.
class MathFragment {
  const MathFragment({
    required this.text,
    this.italic = false,
    this.tabular = false,
  });

  /// Le texte, jamais modifié.
  final String text;

  /// Variable mathématique : à rendre en italique.
  final bool italic;

  /// Contient des chiffres : à rendre en tabulaire.
  final bool tabular;

  @override
  String toString() =>
      'MathFragment("$text"${italic ? ', italic' : ''}'
      '${tabular ? ', tabular' : ''})';
}

/// Acronymes du programme, jamais italiques.
///
/// Ils sont en MAJUSCULES : la règle des variables (lettre minuscule isolée)
/// ne peut donc pas les atteindre. Cette liste est maintenue malgré tout, en
/// garde-fou explicite : si une règle de détection évoluait, elle ne doit
/// jamais pouvoir attraper un acronyme.
const Set<String> kProgrammeAcronyms = <String>{
  'PGCD',
  'PPCM',
  // « PGDC » : transcription fautive de la source, conservée telle quelle.
  // Elle n'est jamais corrigée, et jamais italique.
  'PGDC',
};

/// Délimiteurs qui signalent une variable isolée.
///
/// VOLONTAIREMENT EXCLUS : le point, la tiret et l'apostrophe. En français,
/// ils sont des signes de ponctuation, pas des séparateurs algébriques :
/// « souviens-toi » et « l'élève » ne doivent produire aucun italique.
const String _delimiters = ' \t\n=(),+−×÷';

/// Une lettre minuscule isolée est-elle une variable ?
///
/// [before] et [after] sont les caractères encadrant la lettre, ou `null`
/// en bord de texte.
bool isIsolatedVariable(String letter, String? before, String? after) {
  if (letter.length != 1) return false;
  if (letter.codeUnitAt(0) < 0x61 || letter.codeUnitAt(0) > 0x7A) {
    return false; // pas a-z : majuscule, chiffre, symbole
  }

  final avantOk = before == null || _delimiters.contains(before);
  final apresOk = after == null || _delimiters.contains(after);
  return avantOk && apresOk;
}

/// Découpe [text] en fragments stylables.
///
/// Fonction PURE : aucun widget, aucun style, aucun contexte. C'est ce qui
/// la rend testable directement, et réutilisable pour les interventions du
/// moteur le jour où celles-ci s'afficheront.
List<MathFragment> formatMathText(String text) {
  if (text.isEmpty) return const <MathFragment>[];

  final variables = _variablePositions(text);
  final fragments = <MathFragment>[];

  bool estVariable(int i) => i >= 0 && i < text.length && variables.contains(i);
  bool estChiffre(int i) =>
      i >= 0 && i < text.length && _contientChiffre(text[i]);

  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    final finDeFragment = i == text.length;
    final change = !finDeFragment &&
        (estVariable(i) != estVariable(start) ||
            estChiffre(i) != estChiffre(i - 1));

    if (finDeFragment || change) {
      final fragment = text.substring(start, i);
      if (fragment.isNotEmpty) {
        fragments.add(MathFragment(
          text: fragment,
          italic: estVariable(start),
          tabular: _contientChiffre(fragment),
        ));
      }
      start = i;
    }
  }

  // Un fragment italique doit rester une lettre isolée : le découpage ne
  // doit jamais fusionner une variable avec son voisin.
  assert(fragments.every((f) => !f.italic || f.text.length == 1),
      'un fragment italique doit être une lettre isolée');

  return fragments;
}

bool _contientChiffre(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

/// Positions des variables isolées dans [text].
Set<int> _variablePositions(String text) {
  final positions = <int>{};
  for (var i = 0; i < text.length; i++) {
    final avant = i == 0 ? null : text[i - 1];
    final apres = i + 1 >= text.length ? null : text[i + 1];

    // Acronymes : garde-fou explicite, même si la règle des lettres
    // minuscules les rend déjà inatteignables.
    if (kProgrammeAcronyms.contains(_motAutour(text, i).toUpperCase())) {
      continue;
    }

    if (isIsolatedVariable(text[i], avant, apres)) positions.add(i);
  }
  return positions;
}

/// Mot contenant [index], pour exclure les acronymes.
String _motAutour(String text, int index) {
  var debut = index;
  var fin = index + 1;
  while (debut > 0 && _estMot(text[debut - 1])) {
    debut--;
  }
  while (fin < text.length && _estMot(text[fin])) {
    fin++;
  }
  return text.substring(debut, fin);
}

bool _estMot(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A);
}

/// Texte à notation mathématique, mis en forme par le formateur.
///
/// À utiliser sur les **énoncés** et les **indices** uniquement. Les
/// libellés d'interface (titres de panneaux, boutons, messages fixes) ne
/// passent pas par ici : ils n'ont pas de notation à traiter.
class MathText extends StatelessWidget {
  const MathText({
    super.key,
    required this.text,
    required this.style,
  });

  /// Texte source, jamais modifié.
  final String text;

  /// Style de base.
  final TextStyle style;

  /// Chiffres tabulaires : ajoutés aux caractéristiques déjà présentes.
  static const FontFeature _tabular = FontFeature.tabularFigures();

  @override
  Widget build(BuildContext context) {
    final fragments = formatMathText(text);

    return Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          for (final fragment in fragments)
            TextSpan(
              text: fragment.text,
              style: _styleFor(fragment),
            ),
        ],
      ),
    );
  }

  TextStyle _styleFor(MathFragment fragment) {
    if (!fragment.italic && !fragment.tabular) return const TextStyle();

    return TextStyle(
      // `fontStyle: italic` sélectionne le FICHIER italique de la famille
      // Inter : contours réellement inclinés, pas un oblique simulé.
      fontStyle: fragment.italic ? FontStyle.italic : null,
      fontFeatures: fragment.tabular ? const <FontFeature>[_tabular] : null,
    );
  }

  @override
  void debugFillProperties(diagnostics.DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(diagnostics.StringProperty('text', text));
  }
}