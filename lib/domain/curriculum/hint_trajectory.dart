/// Trajectoire des indices d'une tentative, et classification de la réussite.
///
/// Règle centrale du document source :
///
/// > Une réussite avec indice = progrès, pas réussite autonome.
///
/// Cette contrainte est respectée SANS aucun booléen stocké en base :
/// la réussite assistée se DÉDUIT de la trajectoire réelle des indices.
/// L'historique reste ainsi la seule source de vérité, et aucun état
/// stocké ne peut contredire les événements observés.
library;

import 'exercise.dart';
import 'rich_hint.dart';
import 'rich_hint_adapter.dart';

/// Comment s'est terminée une tentative.
///
/// Classification dérivée des FAITS, non stockée.
enum AttemptClassification {
  /// Réussite sans aucun indice : seule situation valant réussite
  /// autonome.
  autonomousSuccess,

  /// Réussite APRÈS consultation d'au moins un indice.
  ///
  /// C'est un PROGRÈS, jamais une réussite autonome (règle du document).
  assistedSuccess,

  /// Réponse soumise et fausse, sans indice consulté.
  incorrect,

  /// Réponse soumise et fausse, après indice : l'étape suivante est la
  /// remédiation, pas la réussite autonome.
  assistedIncorrect,

  /// Tentative incomplète ou non concluante (abandon, réponse non évaluée).
  incomplete,
}

/// Un indice effectivement consulté par l'élève.
class ConsumedHint {
  const ConsumedHint({
    required this.order,
    required this.consumedAt,
    this.hintId,
  });

  /// Rang de l'indice tel que défini dans la banque (1, 2, …).
  final int order;

  /// Instant de consultation, en UTC.
  final DateTime consumedAt;

  /// Identifiant du contenu d'indice, si connu.
  final String? hintId;

  @override
  String toString() => 'ConsumedHint(#$order)';
}

/// Reconstitue la trajectoire des indices d'une tentative et en déduit la
/// classification de la tentative.
class HintTrajectory {
  HintTrajectory(Iterable<ConsumedHint> hints)
      : _hints = List<ConsumedHint>.of(hints)
          ..sort((a, b) {
            final byTime = a.consumedAt.compareTo(b.consumedAt);
            // À horodatage identique, l'ordre de la banque départage.
            return byTime != 0 ? byTime : a.order.compareTo(b.order);
          });

  final List<ConsumedHint> _hints;

  /// Indices consultés, dans l'ordre chronologique de consultation.
  ///
  /// C'est l'ORDRE RÉEL de consultation, qui peut différer de l'ordre de
  /// la banque : rien n'oblige l'élève à consulter les indices 1, 2, 3…
  List<ConsumedHint> get hints => List.unmodifiable(_hints);

  /// Rangs des indices consultés.
  Set<int> get consumedOrders => _hints.map((h) => h.order).toSet();

  /// Nombre d'indices consultés.
  int get length => _hints.length;

  /// Au moins un indice a-t-il été consulté ?
  bool get hasHints => _hints.isNotEmpty;

  /// Prochain indice disponible selon l'ordre de la banque.
  ///
  /// `null` si tous les indices ont déjà été distribués.
  RichHint? nextAvailable(Exercise exercise) {
    return nextRichHintAfter(exercise, consumedOrders);
  }

  /// Classifie une tentative à partir des faits observés.
  ///
  /// Paramètres :
  ///  - [outcome] : résultat observable de la correction ;
  ///  - [isEmpty] : l'élève a-t-il laissé la réponse vide ?
  ///
  /// La règle « réussite autonome » n'est déclenchée que si AUCUN indice
  /// n'a été consulté ET la réponse est correcte.
  AttemptClassification classify({
    required bool isCorrect,
    required bool isEmpty,
    bool notEvaluated = false,
    bool abandoned = false,
  }) {
    if (abandoned || isEmpty || notEvaluated) {
      return AttemptClassification.incomplete;
    }
    if (isCorrect) {
      return hasHints
          ? AttemptClassification.assistedSuccess
          : AttemptClassification.autonomousSuccess;
    }
    return hasHints
        ? AttemptClassification.assistedIncorrect
        : AttemptClassification.incorrect;
  }

  @override
  String toString() =>
      'HintTrajectory(count=$length, orders=$consumedOrders)';
}
