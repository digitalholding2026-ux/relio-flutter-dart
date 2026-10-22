/// Plan de révision : ce que l'onglet Révision propose à l'élève.
///
/// TROIS ENTRÉES, UN SEUL PLAN :
///  - la **date** choisit la séquence du programme en cours
///    (`academic_calendar.dart`) ;
///  - le **programme officiel** fournit les chapitres de cette séquence ;
///  - les **faits d'apprentissage** fournissent les leçons des séquences
///    précédentes où une erreur a été réellement constatée.
///
/// Aucune maîtrise, aucun score : seules des erreurs OBSERVÉES sont comptées
/// (règle 5). Le compteur d'erreurs est un fait (« 2 erreurs relevées »), pas
/// une note.
///
/// CONTENU DISPONIBLE — la banque actuelle ne couvre que le chapitre 1
/// (« Arithmétique »). Les autres chapitres du programme sont affichés, mais
/// n'ont aucun exercice : aucune correspondance n'est inventée. Si la séquence
/// en cours et les faiblesses ne fournissent rien, la préparation retombe sur
/// les exercices réellement disponibles, et l'écran le dit.
///
/// Le plan est immuable et ne touche ni la base ni le réseau : il est prêt à
/// recevoir un autre fournisseur de programme ou d'exercices sans changer
/// l'interface.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../curriculum/academic_calendar.dart';
import '../curriculum/chapter1_bank.dart';
import '../curriculum/curriculum_data.dart';
import '../curriculum/exercise.dart';
import 'exercise_attempt.dart';
import 'learner_progress.dart';
import 'learning_event.dart';

/// Chapitres du programme qui disposent d'exercices dans la banque actuelle.
///
/// La banque ne contient que le chapitre 1. Cette table est le SEUL endroit
/// où un chapitre officiel est relié à des leçons : ajouter un chapitre au
/// programme ne crée donc pas d'exercices par accident.
const Map<String, List<ArithmeticLesson>> lessonsByChapter =
    <String, List<ArithmeticLesson>>{
      'Arithmétique': ArithmeticLesson.values,
    };

/// Numéro de séquence de chaque leçon disponible, calculé depuis le programme.
final Map<ArithmeticLesson, int> _lessonSequenceNumbers =
    <ArithmeticLesson, int>{
      for (final AcademicSequence sequence in officialProgram)
        for (final String chapter in sequence.chapters)
          for (final ArithmeticLesson lesson
              in lessonsByChapter[chapter] ?? const <ArithmeticLesson>[])
            lesson: sequence.number,
    };

/// Une leçon d'une séquence précédente où des erreurs ont été constatées.
@immutable
class RevisionWeakness {
  /// Crée une faiblesse observée.
  const RevisionWeakness({required this.lesson, required this.errorCount});

  /// Leçon concernée, telle que nommée dans la banque validée.
  final ArithmeticLesson lesson;

  /// Nombre d'erreurs réellement observées sur cette leçon.
  ///
  /// C'est un compteur de FAITS, jamais un taux de réussite.
  final int errorCount;
}

/// Ce que l'écran Révision affiche et ce que la préparation peut piocher.
@immutable
class RevisionPlan {
  /// Crée un plan.
  const RevisionPlan({
    required this.sequence,
    required this.weaknesses,
    required this.currentExercises,
    required this.weakExercises,
    required this.fallbackExercises,
  });

  /// Séquence en cours à la date du jour.
  final AcademicSequence sequence;

  /// Leçons des séquences précédentes avec au moins une erreur constatée.
  final List<RevisionWeakness> weaknesses;

  /// Exercices des chapitres de la séquence en cours.
  final List<Exercise> currentExercises;

  /// Exercices des leçons faibles.
  final List<Exercise> weakExercises;

  /// Exercices de secours, quand les deux sections sont vides.
  final List<Exercise> fallbackExercises;

  /// Les deux sections fournissent-elles au moins un exercice ?
  bool get hasSectionExercises =>
      currentExercises.isNotEmpty || weakExercises.isNotEmpty;

  /// La préparation s'appuie-t-elle sur le vivier de secours ?
  bool get usesFallback => !hasSectionExercises && fallbackExercises.isNotEmpty;

  /// Peut-on lancer une préparation ?
  bool get canStart =>
      currentExercises.isNotEmpty ||
      weakExercises.isNotEmpty ||
      fallbackExercises.isNotEmpty;

  /// Tire jusqu'à [count] exercices, en puisant DANS LES DEUX sections.
  ///
  /// Quand les deux sections sont pourvues, le tirage garantit au moins un
  /// exercice de chacune : la préparation ne peut pas ignorer les faiblesses.
  /// Le tirage est aléatoire mais reproductible dès que [random] est fourni.
  List<Exercise> pickPreparation({Random? random, int count = 3}) {
    if (count <= 0 || !canStart) return const <Exercise>[];

    final Random rng = random ?? Random();
    final bool useSections = hasSectionExercises;

    final List<Exercise> current = <Exercise>[
      ...(useSections ? currentExercises : fallbackExercises),
    ]..shuffle(rng);
    final List<Exercise> weak = <Exercise>[
      ...(useSections ? weakExercises : const <Exercise>[]),
    ]..shuffle(rng);

    final List<Exercise> chosen = <Exercise>[];
    final Set<String> seen = <String>{};

    void add(Exercise exercise) {
      if (seen.add(exercise.id)) chosen.add(exercise);
    }

    // Un exercice de chaque section d'abord : « les deux sections » est une
    // promesse de l'écran, pas un effet du hasard.
    if (count >= 2 && weak.isNotEmpty && current.isNotEmpty) {
      add(weak.removeAt(0));
      add(current.removeAt(0));
    }

    final List<Exercise> rest = <Exercise>[...weak, ...current]..shuffle(rng);
    for (final Exercise exercise in rest) {
      if (chosen.length >= count) break;
      add(exercise);
    }

    return List<Exercise>.unmodifiable(chosen.take(count));
  }
}

/// Construit le plan depuis la date et l'historique.
class RevisionPlanBuilder {
  /// Crée un constructeur de plan.
  const RevisionPlanBuilder();

  /// Calcule le plan pour [date] à partir des [events] persistés.
  ///
  /// [events] peut être vide (nouvel élève, historique illisible) : le
  /// programme reste affichable, seules les faiblesses sont absentes.
  RevisionPlan build({
    required DateTime date,
    required Iterable<LearningEvent> events,
  }) {
    final AcademicSequence current = sequenceForDate(date);
    final List<RevisionWeakness> weaknesses = _weaknesses(events, current);
    final List<Exercise> currentExercises = _exercisesOfChapters(
      current.chapters,
    );
    final List<Exercise> weakExercises = <Exercise>[
      for (final RevisionWeakness weakness in weaknesses)
        ..._exercisesOfLessons(<ArithmeticLesson>[weakness.lesson]),
    ];

    final bool empty = currentExercises.isEmpty && weakExercises.isEmpty;

    return RevisionPlan(
      sequence: current,
      weaknesses: weaknesses,
      currentExercises: currentExercises,
      weakExercises: weakExercises,
      fallbackExercises: empty
          ? _exercisesOfLessons(ArithmeticLesson.values)
          : const <Exercise>[],
    );
  }

  /// Leçons des séquences précédentes ayant au moins une erreur constatée.
  ///
  /// Une erreur n'est retenue que si elle a été OBSERVÉE sur une tentative
  /// réellement corrigée comme fausse. Une tentative non évaluée (exercice
  /// rédigé) ou réussie n'entre jamais dans le compte.
  List<RevisionWeakness> _weaknesses(
    Iterable<LearningEvent> events,
    AcademicSequence current,
  ) {
    final Map<ArithmeticLesson, int> counts = <ArithmeticLesson, int>{};

    for (final LearningEvent event in events) {
      if (event.type != kLearnerAttemptEventType) continue;

      final Object? lessonId = event.metadata['lessonId'];
      if (lessonId is! String) continue;

      final ExerciseAttempt? attempt = event.attempt;
      if (attempt == null) continue;
      if (attempt.outcome != AnswerOutcome.incorrect) continue;
      if (attempt.error == null) continue;

      final ArithmeticLesson? lesson = _lessonById(lessonId);
      if (lesson == null) continue;

      final int? sequenceNumber = _lessonSequenceNumbers[lesson];
      if (sequenceNumber == null || sequenceNumber >= current.number) continue;

      counts.update(lesson, (int value) => value + 1, ifAbsent: () => 1);
    }

    final List<RevisionWeakness> result = <RevisionWeakness>[
      for (final MapEntry<ArithmeticLesson, int> entry in counts.entries)
        RevisionWeakness(lesson: entry.key, errorCount: entry.value),
    ];

    result.sort((RevisionWeakness a, RevisionWeakness b) {
      final int byCount = b.errorCount.compareTo(a.errorCount);
      if (byCount != 0) return byCount;
      return a.lesson.index.compareTo(b.lesson.index);
    });

    return List<RevisionWeakness>.unmodifiable(result);
  }

  /// Exercices des leçons rattachées à [chapters].
  List<Exercise> _exercisesOfChapters(List<String> chapters) {
    final Set<ArithmeticLesson> lessons = <ArithmeticLesson>{
      for (final String chapter in chapters)
        ...?lessonsByChapter[chapter],
    };
    return _exercisesOfLessons(lessons);
  }

  /// Exercices de la banque pour [lessons], dans l'ordre de la banque.
  List<Exercise> _exercisesOfLessons(Iterable<ArithmeticLesson> lessons) {
    final Set<ArithmeticLesson> wanted = lessons.toSet();
    return List<Exercise>.unmodifiable(<Exercise>[
      for (final Exercise exercise in Chapter1Bank.exercises)
        if (exercise.kind == BankElementKind.exercise &&
            wanted.contains(exercise.lesson))
          exercise,
    ]);
  }

  /// Retrouve une leçon par son identifiant persisté.
  ArithmeticLesson? _lessonById(String id) {
    for (final ArithmeticLesson lesson in ArithmeticLesson.values) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }
}
