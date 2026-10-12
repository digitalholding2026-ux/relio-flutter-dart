/// Évaluation d'expressions arithmétiques écrites par l'élève.
///
/// SÛR PAR CONSTRUCTION : la fonction n'échoue jamais. Tout ce qu'elle ne
/// comprend pas renvoie `null`, ce qui signifie « non évaluable » — jamais
/// « faux ».
///
/// Vocabulaire accepté, volontairement minimal :
///   chiffres, `+`, `-`, `*`, `/`, `×`, `÷`, parenthèses, espaces, `=`.
///
/// Tout autre caractère (lettre, puissance, virgule décimale, symbole) rend
/// l'expression NON ÉVALUABLE. Aucune tentative d'interpréter ce qui n'est
/// pas reconnu : une expression non comprise ne doit jamais être transformée
/// en réponse fausse.
library;

/// Résultat de l'évaluation d'une expression arithmétique.
class ArithmeticValue {
  const ArithmeticValue._(
    this.value,
    this.usedDivision,
    this.isBareNumber, {
    this.equalityHolds = true,
  });

  /// Valeur numérique, ou `null` si l'expression n'a pas pu être comprise.
  final double? value;

  /// L'expression comportait-elle une division ?
  ///
  /// Distingue « 10*15/5 » de « 6*5 ». Les deux valent 30, mais seule la
  /// première montre la relation PPCM = produit ÷ PGCD.
  final bool usedDivision;

  /// L'expression n'était-elle qu'un nombre seul ?
  ///
  /// « 30 » est le résultat, sans aucune trace du calcul. Ce n'est pas une
  /// démonstration de la relation.
  final bool isBareNumber;

  /// Quand un `=` a été écrit, les deux membres sont-ils égaux ?
  ///
  /// `10*15/5 = 25` : le calcul est juste, le résultat ANNONCÉ ne l'est pas.
  /// Sans ce drapeau, l'évaluateur ne verrait que 30 et validerait à tort.
  final bool equalityHolds;

  /// L'expression a-t-elle été comprise ?
  bool get isEvaluable => value != null;
}

/// Évalue [expression], ou renvoie une valeur non évaluable.
///
/// Prend en charge une égalité : `10*15/5 = 30`. Le membre de gauche doit
/// s'évaluer, celui de droite doit lui être égal.
ArithmeticValue evaluateArithmetic(String expression) {
  final texte = expression.trim();
  if (texte.isEmpty) return const ArithmeticValue._(null, false, false);

  final morceaux = texte.split('=');
  if (morceaux.length > 2) {
    return const ArithmeticValue._(null, false, false);
  }

  final gauche = _evaluerMembre(morceaux[0]);
  if (!gauche.isEvaluable) return const ArithmeticValue._(null, false, false);

  if (morceaux.length == 2) {
    final droite = _evaluerMembre(morceaux[1]);
    if (!droite.isEvaluable) return const ArithmeticValue._(null, false, false);
    if (!_proches(gauche.value!, droite.value!)) {
      // L'égalité est fausse : le calcul est cohérent, le résultat ANNONCÉ ne
      // l'est pas. La valeur rendue reste celle du membre gauche, mais
      // `equalityHolds` à false empêche de valider.
      return ArithmeticValue._(
        gauche.value,
        gauche.usedDivision || droite.usedDivision,
        false,
        equalityHolds: false,
      );
    }
    return ArithmeticValue._(gauche.value, gauche.usedDivision, false);
  }

  return gauche;
}

bool _proches(double a, double b) => (a - b).abs() < 1e-9;

/// Évalue un membre isolé (sans `=`).
ArithmeticValue _evaluerMembre(String membre) {
  final sansEspaces = membre.replaceAll(RegExp(r'\s+'), '');
  if (sansEspaces.isEmpty) {
    return const ArithmeticValue._(null, false, false);
  }

  // Un nombre seul : résultat sans démonstration.
  if (RegExp(r'^[0-9]+$').hasMatch(sansEspaces)) {
    final valeur = double.tryParse(sansEspaces);
    return ArithmeticValue._(valeur, false, true);
  }

  final tokens = _tokeniser(sansEspaces);
  if (tokens == null) return const ArithmeticValue._(null, false, false);

  final p = _Parser(tokens);
  final resultat = p.expression();
  if (resultat == null || !p.estEntierementConsomme()) {
    return const ArithmeticValue._(null, false, false);
  }

  return ArithmeticValue._(
    resultat.valeur,
    resultat.division,
    false,
  );
}

/// Convertit la chaîne en jetons, ou `null` si un caractère est inconnu.
List<String>? _tokeniser(String s) {
  final jetons = <String>[];
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (RegExp(r'[0-9]').hasMatch(c)) {
      var j = i;
      while (j < s.length && RegExp(r'[0-9]').hasMatch(s[j])) {
        j++;
      }
      jetons.add(s.substring(i, j));
      i = j;
      continue;
    }
    if (c == '+' || c == '-' || c == '*' || c == '/') {
      jetons.add(c);
      i++;
      continue;
    }
    if (c == '\u00d7') {
      jetons.add('*'); // ×
      i++;
      continue;
    }
    if (c == '\u00f7') {
      jetons.add('/'); // ÷
      i++;
      continue;
    }
    if (c == '(' || c == ')') {
      jetons.add(c);
      i++;
      continue;
    }
    return null; // caractère non reconnu : expression non évaluable
  }
  return jetons;
}

class _Nombre {
  const _Nombre(this.valeur, this.division);
  final double valeur;
  final bool division;
}

/// Analyse descendante : somme → produit → facteur.
class _Parser {
  _Parser(this.jetons);

  final List<String> jetons;
  int _i = 0;

  bool get _termine => _i >= jetons.length;

  String? _suivant() => _termine ? null : jetons[_i];

  void _avancer() => _i++;

  _Nombre? expression() {
    final premier = produit();
    if (premier == null) return null;

    // Accumulateur NON nullable : Dart ne promeut plus une variable une fois
    // réassignée, d'où la séparation entre le résultat initial et l'accumulateur.
    var acc = premier;
    while (true) {
      final op = _suivant();
      if (op == '+' || op == '-') {
        _avancer();
        final droite = produit();
        if (droite == null) return null;
        acc = _Nombre(
          op == '+' ? acc.valeur + droite.valeur : acc.valeur - droite.valeur,
          acc.division || droite.division,
        );
      } else {
        return acc;
      }
    }
  }

  _Nombre? produit() {
    final premier = facteur();
    if (premier == null) return null;

    var acc = premier;
    while (true) {
      final op = _suivant();
      if (op == '*' || op == '/') {
        _avancer();
        final droite = facteur();
        if (droite == null) return null;
        if (op == '/') {
          if (droite.valeur == 0) return null; // division par zéro
          acc = _Nombre(acc.valeur / droite.valeur, true);
        } else {
          acc = _Nombre(
            acc.valeur * droite.valeur,
            acc.division || droite.division,
          );
        }
      } else {
        return acc;
      }
    }
  }

  _Nombre? facteur() {
    final t = _suivant();
    if (t == null) return null;

    if (t == '(') {
      _avancer();
      final interieur = expression();
      if (interieur == null) return null;
      if (_suivant() != ')') return null;
      _avancer();
      return interieur;
    }

    if (_termine || _suivant() == ')') return null;
    if (!RegExp(r'^[0-9]+$').hasMatch(t)) return null;
    _avancer();

    final valeur = double.tryParse(t);
    if (valeur == null) return null;
    return _Nombre(valeur, false);
  }

  bool estEntierementConsomme() => _termine;
}