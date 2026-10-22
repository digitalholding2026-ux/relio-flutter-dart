/// Signal technique qu'un tuteur peut joindre a sa reponse.
///
/// Le modele ne modifie jamais l'interface directement : il ajoute un
/// marqueur en fin de message, que ce fichier retire de l'affichage et
/// traduit en faits de la liste fermee [kTutorReportableFacts].
///
/// Pourquoi un marqueur plutot qu'une analyse de texte libre : une phrase
/// comme « tu as peut-etre confondu… » n'est pas une observation. Seul un
/// code explicite, choisi dans une liste fermee, autorise le moteur a ouvrir
/// un diagnostic. Un code inconnu est ignore.
library;

import '../curriculum/observation_collector.dart';

/// Expression du marqueur. Volontairement stricte : minuscules, tirets bas.
final RegExp _signalPattern = RegExp(r'\[\[relio-erreur:([a-z_]+)\]\]');

/// Reponse du tuteur, separee de son eventuel signal.
class TutorErrorSignal {
  const TutorErrorSignal({required this.text, required this.facts});

  /// Texte a afficher, marqueurs retires.
  final String text;

  /// Faits d'erreur reconnus, dans la liste fermee.
  final Set<String> facts;

  /// Y a-t-il au moins un fait exploitable ?
  bool get hasFacts => facts.isNotEmpty;
}

/// Extrait les marqueurs d'une reponse brute.
///
/// Un marqueur inconnu est retire de l'affichage mais n'ajoute aucun fait :
/// le modele ne peut pas inventer un diagnostic.
TutorErrorSignal parseTutorErrorSignal(String raw) {
  final facts = <String>{};
  for (final match in _signalPattern.allMatches(raw)) {
    final fact = match.group(1);
    if (fact != null && kTutorReportableFacts.contains(fact)) {
      facts.add(fact);
    }
  }

  final text = raw.replaceAll(_signalPattern, '').trim();
  return TutorErrorSignal(text: text, facts: facts);
}
