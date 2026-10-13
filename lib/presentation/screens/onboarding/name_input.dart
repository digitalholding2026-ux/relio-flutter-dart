/// Saisie du prénom — filtrage et capitalisation.
///
/// La LOGIQUE est ici, sous forme de fonctions PURES, et le widget ne fait
/// que les appeler. C'est ce qui permet de tester le clavier — chiffres,
/// emojis, tirets, apostrophes — sans passer par une simulation tactile.
///
/// AUCUNE règle de forme : ni longueur minimale, ni controle de syllabage.
/// Un prénom passe dès qu'il est non vide. Le test d'entrée mesure un
/// niveau, jamais une graphie.
library;

/// Un caractère est-il autorisé dans un prénom ?
///
/// Autorisé : lettres latines, espace, trait d'union, apostrophe.
///
/// Sont rejetés à la frappe : chiffres, ponctuation, symboles, emojis. Le
/// rejet se fait à la frappe — le caractère ne s'inscrit jamais — plutôt
/// qu'à la validation, pour que l'élève ne voie pas de message d'erreur
/// alors qu'il n'y a rien à corriger.
bool isNameCharacter(String character) {
  if (character.isEmpty) return false;

  // Les espaces et les traits d'union se tapped directement ; les apostrophes
  // existent en deux écritures (droite et typographique) selon le clavier du
  // téléphone, et l'élève ne doit pas choisir entre les deux.
  if (character == ' ' || character == '-' || character == "'" ||
      character == '\u2019') {
    return true;
  }

  final int code = character.codeUnitAt(0);

  // Lettres latines : A-Z, a-z, et les lettres accentuées (U+00C0 à U+024F).
  final bool latinUpper = code >= 0x41 && code <= 0x5A;
  final bool latinLower = code >= 0x61 && code <= 0x7A;
  final bool latinAccented = code >= 0xC0 && code <= 0x24F;
  return latinUpper || latinLower || latinAccented;
}

/// Ne conserve que les caractères autorisés.
String sanitizeName(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int i in input.runes) {
    final String character = String.fromCharCode(i);
    if (isNameCharacter(character)) buffer.write(character);
  }
  return buffer.toString();
}

/// Capitalise la première lettre et laisse le reste inchangé.
///
/// Une seule fois, à la validation : capitaliser à la frappe ferait sauter le
/// curseur, et capitaliser tout le nom imposerait une casse que l'élève
/// n'a peut-être pas voulue.
String capitalizeName(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

/// Nettoie puis capitalise : le format transmis au cœur.
///
/// Le cœur reçoit un prénom déjà cleansé, mais il ne le valide pas — cette
/// fonction est le dernier filet de l'interface, pas une règle métier.
String prepareName(String input) => capitalizeName(sanitizeName(input).trim());