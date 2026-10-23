/// Préparation d'un texte avant lecture à voix haute.
///
/// Le texte AFFICHÉ n'est jamais modifié : cette fonction ne fabrique que la
/// chaîne donnée au moteur de synthèse vocale. Elle existe pour que la voix
/// dise « A M sur A B » là où l'écran montre `AM/AB`, et « moins » là où
/// l'écran montre `−`.
///
/// Règles appliquées, dans cet ordre :
///  - les balises `<red>` disparaissent (elles ne se prononcent pas) ;
///  - `AM/AB` devient « A M sur A B » ; `3/4` devient « 3 sur 4 » ;
///  - les opérateurs deviennent des mots (`−`, `+`, `=`, `×`, `÷`…) ;
///  - les variables en majuscules sont épelées (`AB` → « A B ») ;
///  - les espaces multiples sont réduits.
library;

/// Texte prononçable correspondant à [input].
///
/// Une chaîne vide ou composée d'espaces rend une chaîne vide : le service
/// audio n'appelle alors pas le moteur.
String speechText(String input) {
  if (input.trim().isEmpty) return '';

  var text = input;

  // Balises de mise en évidence : elles ne se prononcent pas.
  text = text.replaceAll(RegExp(r'</?red>', caseSensitive: false), ' ');

  // Espaces insécables et fines, fréquents dans les libellés Relio.
  text = text
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u202F', ' ')
      .replaceAll('\u2009', ' ');

  // Fractions de variables : « AM/AB » se dit « A M sur A B ».
  text = text.replaceAllMapped(
    RegExp(r'\b([A-Z]{1,3})\s*/\s*([A-Z]{1,3})\b'),
    (Match m) => '${_spell(m.group(1)!)} sur ${_spell(m.group(2)!)}',
  );

  // Fractions numériques simples : « 3/4 » → « 3 sur 4 ».
  text = text.replaceAllMapped(
    RegExp(r'\b(\d+)\s*/\s*(\d+)\b'),
    (Match m) => '${m.group(1)} sur ${m.group(2)}',
  );

  // Opérateurs et symboles mathématiques.
  const Map<String, String> words = <String, String>{
    '−': ' moins ',
    '–': ' moins ',
    '×': ' fois ',
    '÷': ' divisé par ',
    '+': ' plus ',
    '=': ' égal à ',
    '%': ' pour cent ',
    '≠': ' différent de ',
    '≤': ' inférieur ou égal à ',
    '≥': ' supérieur ou égal à ',
    '√': ' racine carrée de ',
    'Δ': ' delta ',
    'π': ' pi ',
    '°': ' degrés ',
    '²': ' au carré ',
    '³': ' au cube ',
    '^': ' puissance ',
  };
  for (final MapEntry<String, String> entry in words.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }

  // Tiret de soustraction : entre deux nombres, ou isolé entre deux espaces.
  // Un trait d'union de mot (« peut-être ») n'est jamais touché.
  text = text.replaceAllMapped(
    RegExp(r'(?<=\d)\s*-\s*(?=\d)'),
    (Match _) => ' moins ',
  );
  text = text.replaceAll(RegExp(r'\s-\s'), ' moins ');

  // Barre oblique restante : une division se dit « sur ».
  text = text.replaceAll('/', ' sur ');

  // Variables en majuscules restantes : « AB » → « A B ».
  text = text.replaceAllMapped(
    RegExp(r'\b[A-Z]{2,3}\b'),
    (Match m) => _spell(m.group(0)!),
  );

  // Pictogrammes : ils n'ont pas à être lus.
  text = text.replaceAll(
    RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
    ' ',
  );

  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Épelle des majuscules : `AM` → `A M`.
String _spell(String letters) => letters.split('').join(' ');
