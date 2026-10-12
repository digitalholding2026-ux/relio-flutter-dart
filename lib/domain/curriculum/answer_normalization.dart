/// Normalisation des saisies d'eleve.
///
/// Regle : ces fonctions ne décident RIEN. Elles rapprochent deux écritures
/// de la MEME reponse pour que la comparaison litterale ne produise pas de
/// faux negatif.
///
/// Elles n'ajoutent aucune reponse attendue a la banque : la liste des
/// formulations acceptees reste celle du document valide. Ce qui est traite
/// ici, c'est l'orthographe du calcul, pas son contenu.
library;

/// Accents francais ramenes a leur lettre de base.
///
/// Un eleve tape « verifie » ou « verifie » : les deux reponses sont la
/// meme. Sans ce pliage, une redaction correcte serait rejetee pour une
/// raison qui n'a rien de mathématique.
const Map<String, String> _diacritics = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'ç': 'c', 'ć': 'c', 'č': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ß': 'ss',
};

/// Remplace chaque caractère accentué par sa lettre de base.
String foldAccents(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}

/// Normalise une saisie pour comparaison textuelle.
///
/// Transformations appliquees, toutes purement typographiques :
///  - casse ignoree ;
///  - espaces, tabulations et retours a la ligne supprimes ;
///  - `*`, `×` et `x` (entre deux chiffres) unifies en `*` ;
///  - `÷` et `/` unifies en `/` ;
///  - les trois tirets CAD unifies en `-` ;
///  - accents francais plies sur leur lettre de base ;
///  - ponctuation de fin (`.,;`, `!`) supprimee.
///
/// Le resultat reste une chaine : aucune valeur n'est calculee ici.
String normalizeAnswer(String raw) {
  // La casse est abaissee EN PREMIER : le tableau des accents ne couvre que
  // les lettres accentuees minuscules, et « 12 X 8 » doit finir reconnu comme
  // « 12 * 8 ».
  var s = foldAccents(raw.toLowerCase().trim());

  // Symboles d'operation unifies avant tout le reste.
  s = s.replaceAll('\u00d7', '*'); // ×
  s = s.replaceAll('\u00f7', '/'); // ÷

  // La lettre « x » n'est un signe multiplicatif qu'ENTRE deux chiffres.
  // Sinon elle resterait une lettre : « ppcm » ne contient pas de x, mais
  // un mot contenant « x » ne doit surtout pas devenir un produit.
  s = s.replaceAllMapped(
    RegExp(r'(?<=[0-9])[ ]*x[ ]*(?=[0-9])'),
    (_) => '*',
  );

  // Tirets typographiques unifies.
  s = s.replaceAll('\u2212', '-'); // −
  s = s.replaceAll('\u2013', '-'); // –
  s = s.replaceAll('\u2014', '-'); // —

  // Espaces : y compris insecables.
  s = s.replaceAll(RegExp(r'[\s\u00a0]+'), '');

  // Ponctuation de fin.
  s = s.replaceAll(RegExp(r'[.,;!]+$'), '');

  return s;
}

/// La forme normalisee ne contient-elle AUCUNE lettre ?
///
/// Sert a distinguer une expression arithmetique (« 96/4 ») d'une
/// formulation en langue naturelle (« verifie »). Aucune lettre ne signifie
/// aucun mot : le critere n'a donc pas de forme textuelle a comparer.
bool looksNumeric(String raw) {
  return !normalizeAnswer(raw).contains(RegExp(r'[a-z]'));
}

/// Analyse une saisie en entier.
///
/// Tolere les espaces et la virgule decimale. Ne tolere PAS un nombre
/// decimal : les 11 exercices du chapitre 1 demandent un entier, et un
/// decimal doit rester « non evaluable » plutot que d'etre tronque.
int? parseInteger(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  return int.tryParse(cleaned);
}