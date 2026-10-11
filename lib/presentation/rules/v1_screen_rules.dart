/// Regles d'ecran propres a la version V1 du parcours.
///
/// Ces regles sont des choix d'INTERFACE, pas des regles pedagogiques :
/// elles vivent dans la couche de presentation et ne modifient ni le moteur
/// ni le contenu valide.
library;

import '../../domain/curriculum/chapter1_bank.dart';
import '../../domain/curriculum/exercise.dart';
import '../strings/relio_strings.dart';

/// Type de clavier a utiliser pour un exercice.
///
/// REGLE V1 : les exercices 1 a 9 attendent un entier, les exercices 10 et 11
/// une reponse redigee. Cette repartition est une decision d'interface
/// transmise par la specification ; elle ne provient d'aucune donnee du
/// moteur, qui n'expose pas de type de reponse.
enum AnswerKeyboard {
  /// Clavier numerique : chiffres uniquement.
  numeric,

  /// Clavier alphanumerique : texte court.
  alphanumeric,
}

/// Exercice 11 — le seul dont la redaction n'est pas evaluee de facon fiable.
///
/// REGLE PROVISOIRE, a retirer des que le moteur saura reconnaitre les
/// formulations alternatives.
const String kRedactionExerciseId = ExerciseIds.ex11;

/// Regles d'ecran V1.
abstract final class V1ScreenRules {
  const V1ScreenRules._();

  /// Les 11 exercices, dans l'ordre du document valide.
  static List<Exercise> get exercises =>
      Chapter1Bank.exercises
          .where((e) => e.kind == BankElementKind.exercise)
          .toList();

  /// Index (base 1) d'un exercice dans la banque, ou `null`.
  static int? positionOf(String exerciseId) {
    final index = exercises.indexWhere((e) => e.id == exerciseId);
    return index >= 0 ? index + 1 : null;
  }

  /// Exercice suivant dans la leçon, ou `null` si c'est le dernier.
  static Exercise? nextAfter(Exercise exercise) {
    final list = exercises;
    final index = list.indexWhere((e) => e.id == exercise.id);
    if (index < 0 || index + 1 >= list.length) return null;
    return list[index + 1];
  }

  /// Premier exercice d'une lecon.
  ///
  /// S2 s'ouvre toujours sur le premier exercice de la lecon.
  static Exercise? firstOfLesson(String lessonId) {
    for (final exercise in exercises) {
      if (exercise.lesson.id == lessonId) return exercise;
    }
    return null;
  }

  /// Clavier a afficher pour [exerciseId].
  ///
  /// REGLE V1 : positions 1 a 9 → numerique, 10 et 11 → alphanumerique.
  static AnswerKeyboard keyboardFor(String exerciseId) {
    final position = positionOf(exerciseId);
    if (position == null) return AnswerKeyboard.alphanumeric;
    return position <= 9 ? AnswerKeyboard.numeric : AnswerKeyboard.alphanumeric;
  }

  /// L'exercice attend-il une redaction non evaluee de facon fiable ?
  ///
  /// today : seul l'exercice 11.
  static bool expectsUnconclusiveHandling(String exerciseId) =>
      exerciseId == kRedactionExerciseId;

  /// Mention de transparence a afficher sous l'enonce, ou `null`.
  ///
  /// Affichee UNIQUEMENT sur les exercices 3, 7 et 11, avec un texte
  /// propre a chacun. Aucun autre exercice n'en porte.
  ///
  /// Les libelles viennent de [RelioStrings] : source unique, pour eviter
  /// toute divergence entre la regle et l'affichage.
  static String? transparencyNote(String exerciseId) {
    switch (exerciseId) {
      case ExerciseIds.ex3:
        return RelioStrings.transparencyJustification;
      case ExerciseIds.ex7:
        return RelioStrings.transparencyComparison;
      case ExerciseIds.ex11:
        return RelioStrings.transparencyRedaction;
      default:
        return null;
    }
  }
}
