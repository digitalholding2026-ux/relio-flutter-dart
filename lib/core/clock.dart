/// Horloge injectable.
///
/// Les dates sont toujours en UTC : le fuseau de l'appareil peut changer,
/// et l'historique d'apprentissage doit rester comparable dans le temps.
library;

/// Source de l'heure courante. Injectable pour rendre les tests déterministes.
typedef Clock = DateTime Function();

/// Horloge réelle : UTC.
DateTime systemClockUtc() => DateTime.now().toUtc();

/// Horloge figée sur une date donnée, pour les tests.
Clock fixedClock(DateTime instant) => () => instant.toUtc();

/// Rend une date lisible et sans ambiguïté de fuseau.
String formatUtc(DateTime date) => date.toUtc().toIso8601String();
