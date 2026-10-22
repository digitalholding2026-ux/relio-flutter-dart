/// Séances courtes proposées depuis l'accueil.
///
/// DEUX RACCOURCIS, UNE SEULE RÈGLE DE PIOCHE :
///  - l'échauffement tire UN exercice au hasard ;
///  - « J'ai 5 minutes » prépare une file de TROIS exercices distincts.
///
/// La pioche est un MOCK assumé : elle ne consulte ni maîtrise, ni score
/// (interdits par la règle 5) — seulement les leçons déjà commencées et non
/// terminées, lues dans les faits d'apprentissage. Sans aucune leçon « en
/// cours » (nouvel élève), le chapitre 1 entier sert de vivier : l'élève a
/// toujours quelque chose à faire.
///
/// Aucun contenu pédagogique n'est créé ici : les exercices viennent de la
/// banque validée ([Chapter1Bank]).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../curriculum/chapter1_bank.dart';
import '../curriculum/exercise.dart';
import 'learner_progress.dart';

/// Nature d'une séance courte.
enum QuickPracticeKind {
  /// Un seul exercice, pour se mettre en route.
  warmup,

  /// Trois exercices, pour cinq minutes.
  fiveMinutes,
}

/// File d'exercices d'une séance courte.
///
/// Immuable : avancer produit une nouvelle séance. La page d'exercice reçoit
/// sa position et n'a donc jamais à compter elle-même.
@immutable
class QuickSession {
  /// Crée une séance à partir d'une liste déjà piochée.
  QuickSession({
    required this.kind,
    required this.exercises,
    this.index = 0,
  }) : assert(exercises.isEmpty || index < exercises.length);

  /// Nature de la séance.
  final QuickPracticeKind kind;

  /// Exercices de la file, dans l'ordre de passage.
  final List<Exercise> exercises;

  /// Index courant, base 0.
  final int index;

  /// Aucun exercice disponible.
  bool get isEmpty => exercises.isEmpty;

  /// Exercice à présenter.
  Exercise get current => exercises[index];

  /// Position affichée, base 1 : « Question 1 sur 3 ».
  int get position => index + 1;

  /// Nombre d'exercices de la séance.
  int get length => exercises.length;

  /// Reste-t-il un exercice après celui-ci ?
  bool get hasNext => index + 1 < exercises.length;

  /// Part de séance accomplie, pour la barre de progression.
  double get ratio => length == 0 ? 0 : position / length;

  /// Séance avancée d'un cran, ou elle-même après le dernier exercice.
  QuickSession next() => hasNext
      ? QuickSession(kind: kind, exercises: exercises, index: index + 1)
      : this;
}

/// Pioche des exercices pour les séances courtes.
class QuickPracticePicker {
  /// Crée le piocheur.
  ///
  /// [random] permet de rendre les tests déterministes ; [catalogue] remplace
  /// le vivier du chapitre 1, pour un test isolé.
  QuickPracticePicker({Random? random, this.catalogue})
    : _random = random ?? Random();

  final Random _random;

  /// Vivier de remplacement, ou `null` pour la banque du chapitre 1.
  final List<Exercise>? catalogue;

  /// Tous les exercices proposables, dans l'ordre de la banque.
  List<Exercise> get _all {
    final provided = catalogue;
    if (provided != null) return provided;
    return Chapter1Bank.exercises
        .where((exercise) => exercise.kind == BankElementKind.exercise)
        .toList();
  }

  /// Leçons « en cours » : commencées et non terminées.
  Set<String> _lessonsInProgress(LearnerProgress progress) {
    return <String>{
      for (final lesson in ArithmeticLesson.values)
        if (progress.startedLesson(lesson.id) &&
            !progress.isLessonMastered(lesson.id))
          lesson.id,
    };
  }

  /// Vivier de la pioche : les leçons en cours, sinon le chapitre entier.
  List<Exercise> _pool(LearnerProgress progress) {
    final inProgress = _lessonsInProgress(progress);
    if (inProgress.isEmpty) return _all;
    final pool = _all
        .where((exercise) => inProgress.contains(exercise.lesson.id))
        .toList();
    return pool.isEmpty ? _all : pool;
  }

  /// Tire [count] exercices distincts, en évitant d'abord ceux déjà réussis.
  List<Exercise> _draw(LearnerProgress progress, int count) {
    final completed = progress.completedExerciseIds;
    final pool = _pool(progress);

    final preferred = pool
        .where((exercise) => !completed.contains(exercise.id))
        .toList()
      ..shuffle(_random);

    final remaining = _all
        .where((exercise) => !preferred.contains(exercise))
        .toList()
      ..shuffle(_random);

    final ordered = <Exercise>[...preferred, ...remaining];
    return ordered.take(count).toList(growable: false);
  }

  /// Échauffement : UN exercice de la leçon en cours.
  QuickSession warmup(LearnerProgress progress) {
    final drawn = _draw(progress, 1);
    return QuickSession(kind: QuickPracticeKind.warmup, exercises: drawn);
  }

  /// Session rapide : TROIS exercices distincts.
  QuickSession fiveMinutes(LearnerProgress progress) {
    final drawn = _draw(progress, 3);
    return QuickSession(kind: QuickPracticeKind.fiveMinutes, exercises: drawn);
  }
}
