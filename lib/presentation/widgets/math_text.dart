/// Formateur typographique minimal pour les textes à notation mathématique.
///
/// PÉRIMÈTRE STRICT, chapitre 1.
///
/// Ce que fait EXACTEMENT ce formateur :
///
///  - reconnaît une **fraction écrite `chiffres/chiffres`** (`1/2`, `12/5`,
///    `3/4`) et la rend EMPILÉE : numérateur, barre horizontale, dénominateur
///    ([FractionSpan]). C'est la notation des cahiers et des manuels ;
///  - met en évidence le contenu de `<red>...</red>` en [kHighlightRed], et
///    retire les balises du texte visible. Une fraction peut être entièrement
///    rouge, et du rouge peut entourer une fraction ou une opération ;
///  - met en italique une **variable isolée** (une lettre minuscule seule,
///    entourée d'un espace, d'un `=`, d'une parenthèse ou d'une virgule) ;
///  - passe les **chiffres** en chiffres tabulaires ;
///  - laisse les **opérateurs** (`+ − × ÷ =`) et parenthèses inchangés,
///    donc uprights ;
///  - ne touche à aucun mot.
///
/// DIVISION OU FRACTION ? Seul le SLASH fait une fraction. Les divisions
/// écrites avec `÷` (« 24 ÷ 6 ») restent en ligne : le formateur ne les
/// transforme jamais.
///
/// Ce qu'il ne fait PAS, et ne fera pas sans nouvelle décision :
///
///  - ni exposants, ni racines, ni sommes, ni intégrales ;
///  - aucune fraction écrite avec des espaces (« 1 / 2 ») : seule la forme
///    collée `chiffres/chiffres` est reconnue, car elle seule est sans ambiguïté ;
///  - aucune mise en page multi-ligne de calcul ;
///  - aucune tentative de comprendre le sens mathématique du texte ;
///  - aucune bibliothèque externe.
///
/// PRINCIPE DE ROBUSTESSE : toute notation non reconnue est laissée
/// **telle quelle**. Un texte imparfaitement formaté vaut mieux qu'un texte
/// mal formaté. Le formateur ne réécrit jamais un mot : il choisit un style
/// par fragment, et la seule chose qu'il retire est une balise qu'il sait lire
/// (`<red>`, `</red>`).
///
/// NETTOYAGE DES BALISES : une étape SÉPARÉE, [normalizeTutorText], retire les
/// délimiteurs LaTeX et remplace les opérateurs ASCII par leurs glyphes. Elle
/// est appliquée aux seules réponses du tuteur, avant [MathText] : le texte de
/// l'élève n'est jamais réécrit.
library;

import 'package:flutter/foundation.dart' as diagnostics;
import 'package:flutter/material.dart';

import 'fraction_span.dart';

/// Un fragment de texte et son style.
///
/// L'unité de sortie du formateur : jamais un caractère isolé, toujours un
/// fragment maximal partageant le même traitement.
///
/// Une **fraction** est un fragment d'un autre genre : son [text] reste la
/// notation source (`1/2`), mais [numerator] et [denominator] permettent de
/// l'empiler. La concaténation des [text] rend donc le texte visible, au
/// caractère près — les balises `<red>`, elles, sont retirées.
class MathFragment {
  const MathFragment({
    required this.text,
    this.italic = false,
    this.tabular = false,
    this.highlighted = false,
  })  : numerator = null,
        denominator = null;

  /// Fraction empilée : [top] au-dessus de [bottom].
  const MathFragment.fraction({
    required String top,
    required String bottom,
    this.highlighted = false,
  })  : text = '$top/$bottom',
        italic = false,
        tabular = true,
        numerator = top,
        denominator = bottom;

  /// Le texte, jamais modifié.
  final String text;

  /// Variable mathématique : à rendre en italique.
  final bool italic;

  /// Contient des chiffres : à rendre en tabulaire.
  final bool tabular;

  /// Fragment encadré par `<red>` : à rendre en [kHighlightRed].
  final bool highlighted;

  /// Numérateur, ou `null` quand le fragment n'est pas une fraction.
  final String? numerator;

  /// Dénominateur, ou `null` quand le fragment n'est pas une fraction.
  final String? denominator;

  /// Ce fragment doit-il être empilé en fraction ?
  bool get isFraction => numerator != null && denominator != null;

  @override
  String toString() {
    final String rouge = highlighted ? ', red' : '';
    if (isFraction) {
      return 'MathFragment.fraction("$numerator/$denominator"$rouge)';
    }
    return 'MathFragment("$text"${italic ? ', italic' : ''}'
        '${tabular ? ', tabular' : ''}$rouge)';
  }
}

/// Rouge de mise en évidence.
///
/// `#B91C1C` plutôt que `#DC2626` : le rouge plus sombre garde un contraste
/// supérieur à 4,5:1 sur les fonds clairs de l'application (blanc, gris des
/// encadrés, orange pâle des points à retenir) et sur les bulles du tuteur.
const Color kHighlightRed = Color(0xFFB91C1C);

/// Balise de mise en évidence, telle que le moteur et le modèle l'écrivent.
const String kRedOpenTag = '<red>';
const String kRedCloseTag = '</red>';

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

/// Motif d'une fraction empilée : `chiffres/chiffres`.
///
/// Les bornes écartent les nombres qui font partie d'une écriture plus longue :
/// `10/12/2026` n'est pas une fraction. Seule une paire isolée est reconnue.
/// Aucun espace n'est toléré : `24 / 6` est une division écrite à la main, et
/// `24 ÷ 6` n'est jamais concerné.
final RegExp _fractionPattern = RegExp(r'(?<![\d/])(\d+)/(\d+)(?![\d/])');

/// Découpe [text] en fragments stylables.
///
/// Fonction PURE : aucun widget, aucun style, aucun contexte. C'est ce qui
/// la rend testable directement, et réutilisable pour les interventions du
/// moteur le jour où celles-ci s'afficheront.
///
/// MISE EN ÉVIDENCE : `<red>...</red>` colore son contenu en [kHighlightRed].
/// Les balises sont retirées du texte visible. Une fraction peut être
/// entièrement rouge (`<red>1/2</red>`), et du rouge peut encadrer plusieurs
/// fragments (`(2 × <red>4</red>)`).
List<MathFragment> formatMathText(String text) {
  if (text.isEmpty) return const <MathFragment>[];

  final fragments = <MathFragment>[];
  for (final run in _highlightRuns(text)) {
    fragments.addAll(_formatRun(run.text, highlighted: run.highlighted));
  }

  // Un fragment italique doit rester une lettre isolée : le découpage ne
  // doit jamais fusionner une variable avec son voisin.
  assert(fragments.every((f) => !f.italic || f.text.length == 1),
      'un fragment italique doit être une lettre isolée');

  return fragments;
}

/// Portion de texte partageant le même état de mise en évidence.
class _Run {
  const _Run(this.text, {required this.highlighted});

  final String text;
  final bool highlighted;
}

/// Sépare le texte de ses balises `<red>` / `</red>`.
///
/// La profondeur est gérée : les balises peuvent être imbriquées, même si
/// `<red>` dans `<red>` ne change rien au rendu. Les balises sont RETIRÉES du
/// texte visible. Une fermante orpheline est ignorée, une ouvrante non fermée
/// colore jusqu'à la fin : mieux vaut un rendu imparfait qu'un texte qui
/// affiche du balisage.
List<_Run> _highlightRuns(String text) {
  final runs = <_Run>[];
  final buffer = StringBuffer();
  var depth = 0;

  void flush() {
    if (buffer.isEmpty) return;
    runs.add(_Run(buffer.toString(), highlighted: depth > 0));
    buffer.clear();
  }

  var i = 0;
  while (i < text.length) {
    if (text.startsWith(kRedOpenTag, i)) {
      flush();
      depth++;
      i += kRedOpenTag.length;
      continue;
    }
    if (text.startsWith(kRedCloseTag, i)) {
      flush();
      if (depth > 0) depth--;
      i += kRedCloseTag.length;
      continue;
    }
    buffer.write(text[i]);
    i++;
  }
  flush();
  return runs;
}

/// Découpe un texte SANS balise en fragments.
List<MathFragment> _formatRun(String text, {required bool highlighted}) {
  if (text.isEmpty) return const <MathFragment>[];

  final variables = _variablePositions(text);
  final fractions = _fractionPattern.allMatches(text).toList();
  final fragments = <MathFragment>[];

  bool estVariable(int i) => i >= 0 && i < text.length && variables.contains(i);
  bool estChiffre(int i) =>
      i >= 0 && i < text.length && _contientChiffre(text[i]);

  void ajouterTexte(int debut, int fin) {
    if (fin <= debut) return;
    fragments.add(MathFragment(
      text: text.substring(debut, fin),
      italic: estVariable(debut),
      tabular: _contientChiffre(text[debut]),
      highlighted: highlighted,
    ));
  }

  var cursor = 0;
  var i = 1;
  var prochaine = 0;

  while (true) {
    // Une fraction commence-t-elle exactement ici ? Elle est traitée d'un
    // bloc : le reste du texte garde ses découpages habituels.
    if (prochaine < fractions.length && fractions[prochaine].start == cursor) {
      final match = fractions[prochaine];
      fragments.add(MathFragment.fraction(
        top: match.group(1)!,
        bottom: match.group(2)!,
        highlighted: highlighted,
      ));
      cursor = match.end;
      prochaine++;
      i = cursor + 1;
      if (cursor >= text.length) break;
      continue;
    }

    if (i >= text.length) {
      ajouterTexte(cursor, text.length);
      break;
    }

    final fractionAlaFin =
        prochaine < fractions.length && fractions[prochaine].start == i;
    final change = fractionAlaFin ||
        estVariable(i) != estVariable(cursor) ||
        estChiffre(i) != estChiffre(i - 1);

    if (change) {
      ajouterTexte(cursor, i);
      cursor = i;
    }
    i++;
  }

  return fragments;
}

bool _contientChiffre(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

/// Nettoie une réponse du tuteur avant affichage.
///
/// Le modèle écrit parfois du LaTeX (`\(`, `\)`) ou des opérateurs ASCII
/// (`-`, `*`). Ce nettoyage est PUREMENT typographique :
///
///  - les délimiteurs `\(`, `\)`, `\[`, `\]` sont retirés ;
///  - les commandes `\times`, `\div`, `\cdot` deviennent `×`, `÷`, `×` ;
///  - `-` et `*` deviennent `−` et `×` **uniquement entre deux opérandes**
///    (chiffre ou parenthèse). Un tiret de mot (« peut-être », « a-t-il »)
///    n'est donc jamais touché.
///
/// Le SLASH est volontairement conservé : `1/2` est une fraction, et c'est le
/// formateur qui l'empile. Une division doit passer par `÷`.
///
/// Aucune autre réécriture : la fonction ne comprend pas le sens du texte,
/// elle ne fait que remplacer des glyphes. Le texte de l'élève n'est jamais
/// passé par ici : ses mots restent exactement les siens.
String normalizeTutorText(String text) {
  if (text.isEmpty) return text;

  final cleaned = text
      .replaceAll(r'\(', '')
      .replaceAll(r'\)', '')
      .replaceAll(r'\[', '')
      .replaceAll(r'\]', '')
      .replaceAll(r'\times', '×')
      .replaceAll(r'\div', '÷')
      .replaceAll(r'\cdot', '×');

  // Opérateur binaire : le seul cas où le glyphe mathématique est sûr.
  // Les délimiteurs ne sont pas consommés par le match, donc les opérateurs
  // successifs (« 2*3*4 ») sont tous traités.
  return cleaned.replaceAllMapped(
    RegExp(r'(?<=[\d)])\s*([-*])\s*(?=[\d(])'),
    (Match match) {
      final segment = match.group(0)!;
      final operator = match.group(1)!;
      final index = segment.indexOf(operator);
      return '${segment.substring(0, index)}${_operatorGlyph(operator)}'
          '${segment.substring(index + 1)}';
    },
  );
}

/// Glyphe typographique d'un opérateur ASCII.
String _operatorGlyph(String operator) => switch (operator) {
      '-' => '−',
      '*' => '×',
      _ => operator,
    };

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
/// À utiliser partout où du contenu peut porter une notation : **énoncés**,
/// **indices**, **choix du test d'entrée**, **réponses du tuteur**. Les
/// libellés d'interface fixes (titres de panneaux, messages système) ne
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

    // Le style effectif d'un fragment de texte est celui que [Text.rich]
    // compose avec le [DefaultTextStyle] ambiant. Les fractions sont des
    // widgets, hors de cette composition : il faut leur passer le résultat.
    final TextStyle styleEffectif =
        DefaultTextStyle.of(context).style.merge(style);

    return Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          for (final fragment in fragments)
            if (fragment.isFraction)
              WidgetSpan(
                // `middle` : le milieu de la fraction coïncide avec le milieu
                // de la ligne. La ligne de base des mots voisins ne bouge
                // pas ; seule la hauteur de ligne grandit.
                alignment: PlaceholderAlignment.middle,
                child: FractionSpan(
                  numerator: fragment.numerator!,
                  denominator: fragment.denominator!,
                  style: fragment.highlighted
                      ? styleEffectif.copyWith(color: kHighlightRed)
                      : styleEffectif,
                ),
              )
            else
              TextSpan(
                text: fragment.text,
                style: _styleFor(fragment),
              ),
        ],
      ),
    );
  }

  TextStyle _styleFor(MathFragment fragment) {
    if (!fragment.italic && !fragment.tabular && !fragment.highlighted) {
      return const TextStyle();
    }

    return TextStyle(
      // `fontStyle: italic` sélectionne le FICHIER italique de la famille
      // Inter : contours réellement inclinés, pas un oblique simulé.
      fontStyle: fragment.italic ? FontStyle.italic : null,
      fontFeatures: fragment.tabular ? const <FontFeature>[_tabular] : null,
      color: fragment.highlighted ? kHighlightRed : null,
    );
  }

  @override
  void debugFillProperties(diagnostics.DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(diagnostics.StringProperty('text', text));
  }
}