/// Registre unique des banques disponibles.
///
/// L'application ne connaît plus « la banque du chapitre 1 » : elle lit un
/// registre qui assemble les chapitres ouverts. Ajouter un chapitre ne doit
/// pas obliger l'écran, le service ou les règles de navigation à connaître son
/// nom : ils passent tous par ce point.
///
/// L'ORDRE EST CELUI DU PROGRAMME : chapitre 1 puis chapitre 2. Il fixe la
/// numérotation d'affichage des exercices et la continuité de « l'exercice
/// précédent » ; il ne modifie aucune banque existante.
library;

import 'chapter1_bank.dart';
import 'chapter2_bank.dart';
import 'exercise.dart';

/// Banques disponibles, dans l'ordre du programme.
abstract final class CurriculumBank {
  const CurriculumBank._();

  /// Toutes les leçons ouvertes, chapitre par chapitre.
  static const List<CurriculumLesson> lessons = <CurriculumLesson>[
    ...ArithmeticLesson.values,
    ...ThalesLesson.values,
  ];

  /// Tous les éléments (exercices et tâches de vérification), dans l'ordre.
  static const List<Exercise> all = <Exercise>[
    ...Chapter1Bank.exercises,
    ...Chapter2Bank.exercises,
    ...Chapter1Bank.verificationTasks,
    ...Chapter2Bank.verificationTasks,
  ];

  /// Les exercices officiels, dans l'ordre des chapitres.
  static List<Exercise> get exercises => all
      .where((Exercise exercise) => exercise.kind == BankElementKind.exercise)
      .toList();

  /// Les tâches de vérification post-remédiation.
  static List<Exercise> get verificationTasks => all
      .where(
        (Exercise exercise) =>
            exercise.kind == BankElementKind.verificationTask,
      )
      .toList();

  /// Élément par identifiant, exercice ou tâche de vérification.
  static Exercise? findExercise(String id) {
    for (final exercise in all) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  /// Leçons d'un chapitre, dans l'ordre du programme.
  static List<CurriculumLesson> lessonsForChapter(int chapterNumber) => <
      CurriculumLesson>[
    for (final lesson in lessons)
      if (lesson.chapterNumber == chapterNumber) lesson,
  ];

  /// Exercices officiels d'une leçon.
  static List<Exercise> exercisesOfLesson(String lessonId) => exercises
      .where((Exercise exercise) => exercise.lesson.id == lessonId)
      .toList();
}
