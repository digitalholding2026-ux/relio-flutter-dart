/// Formateur typographique des textes à notation mathématique.
///
/// PÉRIMÈTRE — chapitres 1 et 2.
///
/// Ce que fait EXACTEMENT ce formateur :
///
///  - reconnaît une **fraction écrite `terme/terme`** (`1/2`, `12/5`, `3/4`,
///    `AM/AB`, `4,5/AC`) et la rend EMPILÉE : numérateur, barre horizontale,
///    dénominateur ([FractionSpan]). C'est la notation des cahiers et des
///    manuels. Les termes admis sont les nombres (entiers ou décimaux) et les
///    variables (`x`, `AM`, `AB`) ;
///  - met en évidence le contenu de `<red>...</red>` en [kHighlightRed], et
///    retire les balises du texte visible. Une fraction peut être entièrement
///    rouge, et du rouge peut entourer une fraction ou une opération ;
///  - met en italique une **variable** (lettre minuscule seule, ou groupe de
///    1 à 3 majuscules : `AM`, `AB`, `MN`) et lui applique la police serif :
///    une variable mathématique ne se confond ni avec un mot, ni avec le
///    signe de multiplication × ;
///  - reconnaît un **exposant** écrit `^2` (`x^2`, `b^2`, `4a^2`, `x^{2}`)
///    et le rend plus petit et surélevé — les exposants ne sont jamais
///    interprétés comme du texte ;
///  - passe les **chiffres** en chiffres tabulaires ;
///  - laisse les **opérateurs** (`+ − × ÷ =`) et parenthèses inchangés,
///    donc uprights ;
///  - ne touche à aucun mot.
///
/// DIVISION OU FRACTION ? Seul le SLASH fait une fraction. Les divisions
/// écrites avec `÷` (« 24 ÷ 6 ») restent en ligne : le formateur ne les
/// transforme jamais. Un slash entouré d'espaces (« 24 / 6 ») reste du texte,
/// et une date (`10/12/2026`) n'est jamais une fraction.
///
/// Les mots du dictionnaire ne deviennent jamais des fractions : `et/ou`
/// n'est pas reconnu, car ses deux termes sont des mots minuscules de plus
/// d'une lettre. Seules les variables isolées (majuscules ou lettre minuscule
/// seule) et les nombres sont empilés.
///
/// Ce qu'il ne fait PAS, et ne fera pas sans nouvelle décision :
///
///  - ni racines dessinées, ni sommes, ni intégrales (les symboles Unicode
///    `√`, `Δ`, `≠`, `≤`, `≥`, `∈`, `∅` sont, eux, acceptés tels quels) ;
///  - aucune fraction écrite avec des espaces (« 1 / 2 ») : seule la forme
///    collée `terme/terme` est reconnue, car elle seule est sans ambiguïté ;
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
  }) : numerator = null,
       denominator = null,
       exponent = null;

  /// Fraction empilée : [top] au-dessus de [bottom].
  const MathFragment.fraction({
    required String top,
    required String bottom,
    this.highlighted = false,
  }) : text = '$top/$bottom',
       italic = false,
       tabular = true,
       numerator = top,
       denominator = bottom,
       exponent = null;

  /// Exposant : [value] rendu petit et surélevé.
  ///
  /// Le [text] conserve le caret (`^2`) afin que la concaténation des
  /// fragments rende toujours la source, au caractère près.
  const MathFragment.superscript({
    required String value,
    this.highlighted = false,
  }) : text = '^$value',
       italic = false,
       tabular = false,
       numerator = null,
       denominator = null,
       exponent = value;

  /// Le texte, jamais modifié.
  final String text;

  /// Variable mathématique : à rendre en italique serif.
  final bool italic;

  /// Contient des chiffres : à rendre en tabulaire.
  final bool tabular;

  /// Fragment encadré par `<red>` : à rendre en [kHighlightRed].
  final bool highlighted;

  /// Numérateur, ou `null` quand le fragment n'est pas une fraction.
  final String? numerator;

  /// Dénominateur, ou `null` quand le fragment n'est pas une fraction.
  final String? denominator;

  /// Contenu de l'exposant, sans le caret, ou `null`.
  final String? exponent;

  /// Ce fragment doit-il être empilé en fraction ?
  bool get isFraction => numerator != null && denominator != null;

  /// Ce fragment doit-il être rendu en exposant ?
  bool get isSuperscript => exponent != null;

  @override
  String toString() {
    final String rouge = highlighted ? ', red' : '';
    if (isFraction) {
      return 'MathFragment.fraction("$numerator/$denominator"$rouge)';
    }
    if (isSuperscript) {
      return 'MathFragment.superscript("$exponent"$rouge)';
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
const String _delimiters = ' \t\n=(),+−×÷/[];:^';

/// Famille serif des variables mathématiques.
///
/// Aucun fichier n'est embarqué : `serif` est la famille générique du
/// système (Noto Serif sur Android). Les replis couvrent les postes de
/// développement Windows et macOS, où la famille générique peut manquer.
const String kMathVariableFontFamily = 'serif';

/// Replis de la police des variables, dans l'ordre d'essai.
const List<String> kMathVariableFontFallbacks = <String>[
  'Noto Serif',
  'Georgia',
  'Times New Roman',
];

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

/// Un terme est-il une variable mathématique ?
///
/// Admis : une lettre minuscule seule (`x`, `a`) ou un groupe de 1 à 3
/// majuscules (`M`, `AB`, `AM`, `MN`). Les acronymes du programme restent
/// exclus. Les mots minuscules de deux lettres et plus (`et`, `ou`, `km`)
/// ne sont donc jamais des variables : c'est ce qui protège `et/ou` et les
/// unités (`km/h`) d'une transformation en fraction.
bool isMathVariable(String term) {
  if (term.isEmpty || term.length > 3) return false;
  if (kProgrammeAcronyms.contains(term)) return false;

  if (term.length == 1) {
    final int unit = term.codeUnitAt(0);
    return (unit >= 0x61 && unit <= 0x7A) || (unit >= 0x41 && unit <= 0x5A);
  }

  for (var i = 0; i < term.length; i++) {
    final int unit = term.codeUnitAt(i);
    if (unit < 0x41 || unit > 0x5A) return false;
  }
  return true;
}

/// Un terme est-il un nombre (entier ou décimal) ?
bool isMathNumber(String term) {
  if (term.isEmpty) return false;
  final int first = term.codeUnitAt(0);
  if (first < 0x30 || first > 0x39) return false;

  for (var i = 1; i < term.length; i++) {
    final int unit = term.codeUnitAt(i);
    final bool chiffre = unit >= 0x30 && unit <= 0x39;
    final bool separateur = unit == 0x2C || unit == 0x2E;
    if (!chiffre && !separateur) return false;
  }
  return true;
}

/// Motif d'une fraction empilée : `terme/terme`.
///
/// Les termes sont des nombres (`12`, `4,5`) ou des variables (`x`, `AM`).
/// Les bornes écartent les écritures plus longues : `10/12/2026` n'est pas
/// une fraction, et `2x/3` reste du texte (le terme `2x` n'est ni un nombre
/// ni une variable isolée). Aucun espace n'est toléré : `24 / 6` est une
/// division écrite à la main, et `24 ÷ 6` n'est jamais concerné.
final RegExp _fractionPattern = RegExp(
  r'(?<![A-Za-z0-9/])'
  r'(\d+(?:[.,]\d+)?|[A-Z]{1,3}|[a-z])'
  r'/'
  r'(\d+(?:[.,]\d+)?|[A-Z]{1,3}|[a-z])'
  r'(?![A-Za-z0-9/])',
);

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

  // Un fragment italique doit rester une variable isolée : le découpage ne
  // doit jamais fusionner une variable avec son voisin.
  assert(
    fragments.every((f) => !f.italic || isMathVariable(f.text)),
    'un fragment italique doit être une variable',
  );

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

  final variables = _variableSpans(text);
  final fractions = _fractionPattern.allMatches(text).toList();
  final fragments = <MathFragment>[];

  bool estVariable(int i) {
    for (final span in variables) {
      if (i >= span.start && i < span.end) return true;
    }
    return false;
  }

  bool estChiffre(int i) =>
      i >= 0 && i < text.length && _contientChiffre(text[i]);

  void ajouterTexte(int debut, int fin) {
    if (fin <= debut) return;
    fragments.add(
      MathFragment(
        text: text.substring(debut, fin),
        italic: estVariable(debut),
        tabular: _contientChiffre(text[debut]),
        highlighted: highlighted,
      ),
    );
  }

  var cursor = 0;
  var prochaine = 0;

  while (cursor < text.length) {
    // Une fraction commence-t-elle exactement ici ? Elle est traitée d'un
    // bloc : le reste du texte garde ses découpages habituels.
    if (prochaine < fractions.length && fractions[prochaine].start == cursor) {
      final match = fractions[prochaine];
      fragments.add(
        MathFragment.fraction(
          top: match.group(1)!,
          bottom: match.group(2)!,
          highlighted: highlighted,
        ),
      );
      cursor = match.end;
      prochaine++;
      continue;
    }

    // Un exposant commence-t-il ici ? `^` disparaît de l'affichage, mais
    // reste dans le texte du fragment pour que la source soit reconstructible.
    final exposant = _exponentAt(text, cursor);
    if (exposant != null) {
      fragments.add(
        MathFragment.superscript(
          value: exposant.value,
          highlighted: highlighted,
        ),
      );
      cursor = exposant.end;
      continue;
    }

    var i = cursor + 1;
    while (i < text.length) {
      if (prochaine < fractions.length && fractions[prochaine].start == i) {
        break;
      }
      if (_exponentAt(text, i) != null) break;
      if (estVariable(i) != estVariable(cursor)) break;
      if (estChiffre(i) != estChiffre(i - 1)) break;
      i++;
    }

    ajouterTexte(cursor, i);
    cursor = i;
  }

  return fragments;
}

bool _contientChiffre(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

/// Exposant reconnu à partir d'un caret.
class _Exponent {
  const _Exponent(this.value, this.end);

  /// Contenu de l'exposant, sans caret ni accolades.
  final String value;

  /// Index du premier caractère après l'exposant.
  final int end;
}

/// Lit `^2`, `^12` ou `^{2}` à partir de [index].
///
/// Retourne `null` quand le caret n'ouvre pas un exposant lisible : le texte
/// est alors laissé tel quel, caret compris.
_Exponent? _exponentAt(String text, int index) {
  if (index < 0 || index >= text.length || text[index] != '^') return null;

  var i = index + 1;
  if (i >= text.length) return null;

  if (text[i] == '{') {
    final close = text.indexOf('}', i + 1);
    if (close < 0) return null;
    final value = text.substring(i + 1, close);
    if (value.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z0-9+−-]+$').hasMatch(value)) return null;
    return _Exponent(value, close + 1);
  }

  final unit = text.codeUnitAt(i);
  final bool lettre =
      (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A);
  final bool chiffre = unit >= 0x30 && unit <= 0x39;
  if (!lettre && !chiffre) return null;

  // Les chiffres consécutifs forment un seul exposant (`x^12`).
  var end = i + 1;
  if (chiffre) {
    while (end < text.length && _contientChiffre(text[end])) {
      end++;
    }
  }
  return _Exponent(text.substring(i, end), end);
}

/// Nettoie une réponse du tuteur avant affichage.
///
/// Le modèle écrit parfois du LaTeX (`\(`, `\)`) ou des opérateurs ASCII
/// (`-`, `*`). Ce nettoyage est PUREMENT typographique :
///
///  - les délimiteurs `\(`, `\)`, `\[`, `\]` sont retirés ;
///  - les commandes `\times`, `\div`, `\cdot` deviennent `×`, `÷`, `×` ;
///  - les commandes et mots `\Delta`/`Delta`, `\emptyset`/`emptyset`,
///    `\in`/`in` deviennent `Δ`, `∅`, `∈` ;
///  - `!=` et `<>` deviennent `≠`, `<=` et `>=` deviennent `≤` et `≥` ;
///  - `sqrt(x)` devient `√x` (`√(2x + 1)` quand le radicande est composé) ;
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

  String cleaned = text
      .replaceAll(r'\(', '')
      .replaceAll(r'\)', '')
      .replaceAll(r'\[', '')
      .replaceAll(r'\]', '')
      .replaceAll(r'\times', '×')
      .replaceAll(r'\div', '÷')
      .replaceAll(r'\cdot', '×')
      .replaceAll(r'\Delta', 'Δ')
      .replaceAll(r'\emptyset', '∅')
      .replaceAll(r'\neq', '≠')
      .replaceAll(r'\leq', '≤')
      .replaceAll(r'\geq', '≥')
      .replaceAll(r'\in', '∈');

  // Racines : le radicande simple perd ses parenthèses (`√x`), un radicande
  // composé les garde (`√(2x + 1)`), faute de barre de radical dessinée.
  cleaned = cleaned.replaceAllMapped(RegExp(r'sqrt\s*\(([^()]*)\)'), (
    Match match,
  ) {
    final String radicande = match.group(1)!.trim();
    if (radicande.isEmpty) return '√';
    final bool simple = RegExp(r'^[A-Za-z0-9.,]+$').hasMatch(radicande);
    return simple ? '√$radicande' : '√($radicande)';
  });

  // Comparaisons ASCII : elles n'ont de sens que comme symboles.
  cleaned = cleaned
      .replaceAll('!=', '≠')
      .replaceAll('<>', '≠')
      .replaceAll('<=', '≤')
      .replaceAll('>=', '≥');

  // Mots isolés : jamais au milieu d'un autre mot (`in` dans « ainsi »).
  cleaned = cleaned
      .replaceAll(RegExp(r'\bDelta\b'), 'Δ')
      .replaceAll(RegExp(r'\bemptyset\b'), '∅')
      .replaceAll(RegExp(r'\bin\b'), '∈');

  // Opérateur binaire : le seul cas où le glyphe mathématique est sûr.
  // Les délimiteurs ne sont pas consommés par le match, donc les opérateurs
  // successifs (« 2*3*4 ») sont tous traités.
  return cleaned.replaceAllMapped(RegExp(r'(?<=[\d)])\s*([-*])\s*(?=[\d(])'), (
    Match match,
  ) {
    final segment = match.group(0)!;
    final operator = match.group(1)!;
    final index = segment.indexOf(operator);
    return '${segment.substring(0, index)}${_operatorGlyph(operator)}'
        '${segment.substring(index + 1)}';
  });
}

/// Glyphe typographique d'un opérateur ASCII.
String _operatorGlyph(String operator) => switch (operator) {
  '-' => '−',
  '*' => '×',
  _ => operator,
};

/// Positions des variables dans [text].
///
/// Deux familles :
///  - une lettre minuscule isolée (`x`, `a`), seule ou après un coefficient
///    numérique (`4a`) ;
///  - un groupe de 1 à 3 majuscules (`M`, `AB`, `AM`), jamais collé à une
///    autre lettre.
///
/// Les acronymes (`PGCD`, `PPCM`) et les codes alphanumériques (`D1`, `S2`)
/// ne sont jamais des variables : le premier par la longueur, les seconds
/// parce qu'un chiffre les jouxte.
List<_Span> _variableSpans(String text) {
  final spans = <_Span>[];

  for (var i = 0; i < text.length; i++) {
    final int unit = text.codeUnitAt(i);
    final bool majuscule = unit >= 0x41 && unit <= 0x5A;
    final bool minuscule = unit >= 0x61 && unit <= 0x7A;
    if (!majuscule && !minuscule) continue;

    final String? avant = i == 0 ? null : text[i - 1];
    if (avant != null && _estLettre(avant)) continue;

    if (majuscule) {
      var fin = i + 1;
      while (fin < text.length) {
        final int suivant = text.codeUnitAt(fin);
        if (suivant < 0x41 || suivant > 0x5A) break;
        fin++;
      }
      final String terme = text.substring(i, fin);
      if (!isMathVariable(terme)) continue;
      // Un mot capitalisé (« Calcule », « Soustrais ») n'est pas une
      // variable : la majuscule initiale est suivie d'une minuscule.
      if (fin < text.length && _estLettre(text[fin])) continue;
      // `D1`, `S2` : un chiffre colle le code à une référence, pas à une
      // variable mathématique.
      if (fin < text.length && _contientChiffre(text[fin])) continue;
      spans.add(_Span(i, fin));
      i = fin - 1;
      continue;
    }

    final String? apres = i + 1 >= text.length ? null : text[i + 1];
    final bool isolee = isIsolatedVariable(text[i], avant, apres);
    // Coefficient : `4a`, `2x`. Le chiffre qui précède est un facteur, pas
    // une lettre du mot.
    final bool coefficient =
        avant != null &&
        _contientChiffre(avant) &&
        (apres == null || _delimiters.contains(apres) || apres == '^');
    if (!isolee && !coefficient) continue;
    if (apres != null && _estLettre(apres)) continue;

    spans.add(_Span(i, i + 1));
  }

  return spans;
}

/// Intervalle `[start, end)` d'une variable.
class _Span {
  const _Span(this.start, this.end);

  final int start;
  final int end;
}

bool _estLettre(String c) {
  final u = c.codeUnitAt(0);
  if ((u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A)) return true;
  // Latin accentué : « Vérifie », « Écris ». Sans cette borne, la majuscule
  // initiale d'un mot accentué passerait pour une variable.
  return u >= 0xC0 && u <= 0x24F;
}

/// Texte à notation mathématique, mis en forme par le formateur.
///
/// À utiliser partout où du contenu peut porter une notation : **énoncés**,
/// **indices**, **choix du test d'entrée**, **réponses du tuteur**. Les
/// libellés d'interface fixes (titres de panneaux, messages système) ne
/// passent pas par ici : ils n'ont pas de notation à traiter.
class MathText extends StatelessWidget {
  const MathText({super.key, required this.text, required this.style});

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
    final TextStyle styleEffectif = DefaultTextStyle.of(context).style
        .merge(style);

    final TextStyle encre = styleEffectif;

    return Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          for (final (int index, MathFragment fragment) in fragments.indexed)
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
                      ? encre.copyWith(color: kHighlightRed)
                      : encre,
                  numeratorStyle: _fractionPartStyle(
                    fragment.numerator!,
                    styleEffectif,
                    fragment.highlighted ? kHighlightRed : null,
                  ),
                  denominatorStyle: _fractionPartStyle(
                    fragment.denominator!,
                    styleEffectif,
                    fragment.highlighted ? kHighlightRed : null,
                  ),
                ),
              )
            else if (fragment.isSuperscript)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  // Le décalage est proportionnel au corps du texte : un
                  // exposant dans un petit libellé monte moins qu'un exposant
                  // dans un grand énoncé.
                  offset: Offset(0, -(encre.fontSize ?? 14) * 0.32),
                  child: Text(
                    fragment.exponent!,
                    style: encre.copyWith(
                      fontSize: (encre.fontSize ?? 14) * 0.7,
                      fontFeatures: const <FontFeature>[_tabular],
                    ),
                  ),
                ),
              )
            else if (_estEgal(fragment) && _estEntreFractions(fragments, index))
              // Le signe `=` d'une égalité de fractions est centré sur leur
              // hauteur : sinon il resterait posé sur la ligne de base, donc
              // sous le milieu de la barre de fraction. Un `=` de calcul
              // ordinaire reste un fragment de texte, recherchable comme tel.
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Text(
                  fragment.text,
                  style: encre.merge(_styleFor(fragment)),
                ),
              )
            else
              TextSpan(text: fragment.text, style: _styleFor(fragment)),
        ],
      ),
    );
  }

  /// Le fragment est-il le seul signe `=` (espaces compris) ?
  static bool _estEgal(MathFragment fragment) =>
      !fragment.isFraction &&
      !fragment.isSuperscript &&
      fragment.text.trim() == '=';

  /// Le signe `=` sépare-t-il deux fractions empilées ?
  static bool _estEntreFractions(List<MathFragment> fragments, int index) {
    final bool avant = index > 0 && fragments[index - 1].isFraction;
    final bool apres =
        index + 1 < fragments.length && fragments[index + 1].isFraction;
    return avant && apres;
  }

  /// Style d'une partie de fraction : serif italique pour une variable,
  /// chiffres tabulaires sinon.
  TextStyle _fractionPartStyle(String part, TextStyle base, Color? color) {
    final TextStyle style = isMathVariable(part)
        ? base.copyWith(
            fontFamily: kMathVariableFontFamily,
            fontFamilyFallback: kMathVariableFontFallbacks,
            fontStyle: FontStyle.italic,
            fontFeatures: null,
          )
        : base.copyWith(fontFeatures: const <FontFeature>[_tabular]);
    return color == null ? style : style.copyWith(color: color);
  }

  TextStyle _styleFor(MathFragment fragment) {
    if (!fragment.italic && !fragment.tabular && !fragment.highlighted) {
      return const TextStyle();
    }

    return TextStyle(
      // Variable : police serif italique. Le fichier italique de la famille
      // système est sélectionné quand il existe ; à défaut, le moteur
      // incline la romaine. Dans les deux cas, la variable se distingue du
      // texte droit et du signe ×.
      fontFamily: fragment.italic ? kMathVariableFontFamily : null,
      fontFamilyFallback: fragment.italic ? kMathVariableFontFallbacks : null,
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
