/// Projection d'affichage de l'avancement de l'élève.
///
/// RIEN N'EST PERSISTÉ ICI. Cette classe ne fait que RELIRE les événements
/// d'apprentissage, qui sont les seuls faits enregistrés, et en tirer des
/// décomptes pour l'interface.
///
/// La règle 5 d'`AGENTS.md` interdit tout champ de maîtrise dans le modèle et
/// le schéma : aucun `maitrise`, `score` ou `niveau` n'existe en base. Les
/// valeurs calculées ici sont donc une PROJECTION, recalculée à chaque
/// lecture, et jamais écrite.
///
/// Définitions retenues, toutes mécaniques :
///
///  - une leçon est **commencée** dès qu'une tentative y a été soumise ;
///  - un exercice est **terminé** dès qu'il a reçu au moins une réponse
///    correcte (une réussite ne se perd pas : l'historique est append-only) ;
///  - une leçon est **maîtrisée** quand tous ses exercices officiels sont
///    terminés.
///
/// Aucune de ces règles n'interprète la manière dont l'élève a répondu : elles
/// ne lisent que des faits observables.
library;

import 'package:flutter/foundation.dart';

import '../curriculum/chapter1_bank.dart';
import '../curriculum/exercise.dart';
import 'exercise_attempt.dart';
import 'learning_event.dart';
import 'learning_event_repository.dart';

/// Type d'événement « tentative d'exercice ».
///
/// Même valeur que `kAttemptEventType` de `chapter1_service.dart`. La
/// constante est répétée ici pour que la projection ne dépende pas du service
/// d'écriture : elle ne lit que l'historique.
const String kLearnerAttemptEventType = 'exercise_attempt';

/// Instantané de l'avancement, calculé depuis les événements.
@immutable
class LearnerProgress {
  /// Crée un instantané.
  const LearnerProgress({
    this.startedLessonIds = const <String>{},
    this.completedExerciseIds = const <String>{},
    this.completedExerciseIdsByLesson = const <String, Set<String>>{},
    this.lessonExerciseTotals = const <String, int>{},
  });

  /// Aucun fait : l'état d'un nouvel élève.
  static const LearnerProgress empty = LearnerProgress();

  /// Leçons pour lesquelles au moins une tentative a été soumise.
  final Set<String> startedLessonIds;

  /// Exercices déjà réussis au moins une fois.
  final Set<String> completedExerciseIds;

  /// Exercices réussis, regroupés par leçon.
  final Map<String, Set<String>> completedExerciseIdsByLesson;

  /// Nombre total d'exercices officiels par leçon.
  ///
  /// Fourni par l'appelant (la banque validée pour le chapitre 1) : la
  /// projection ne recompte jamais un contenu pédagogique.
  final Map<String, int> lessonExerciseTotals;

  /// L'élève a-t-il commencé au moins un exercice ?
  bool get hasStarted => startedLessonIds.isNotEmpty;

  /// Nombre d'exercices terminés, toutes leçons confondues.
  int get completedExercises => completedExerciseIds.length;

  /// Nombre de leçons maîtrisées : tous leurs exercices sont terminés.
  int get masteredNotions {
    var count = 0;
    for (final entry in lessonExerciseTotals.entries) {
      final total = entry.value;
      if (total <= 0) continue;
      if (completedIn(entry.key) >= total) count++;
    }
    return count;
  }

  /// L'élève a-t-il commencé [lessonId] ?
  bool startedLesson(String lessonId) => startedLessonIds.contains(lessonId);

  /// Exercices terminés de [lessonId].
  int completedIn(String lessonId) =>
      completedExerciseIdsByLesson[lessonId]?.length ?? 0;

  /// Total officiel d'exercices de [lessonId], ou 0 si inconnu.
  int totalFor(String lessonId) => lessonExerciseTotals[lessonId] ?? 0;

  /// Construit la projection à partir des événements lus.
  ///
  /// [lessonExerciseTotals] vient de la banque validée : sans lui, aucune
  /// leçon ne peut être déclarée maîtrisée, et le décompte reste à zéro.
  factory LearnerProgress.fromEvents(
    Iterable<LearningEvent> events, {
    Map<String, int>? lessonExerciseTotals,
  }) {
    final started = <String>{};
    final completed = <String>{};
    final byLesson = <String, Set<String>>{};

    for (final event in events) {
      if (event.type != kLearnerAttemptEventType) continue;

      final lessonId = event.metadata['lessonId'];
      if (lessonId is! String || lessonId.isEmpty) continue;

      started.add(lessonId);

      final attempt = event.attempt;
      if (attempt == null) continue;
      if (attempt.outcome != AnswerOutcome.correct) continue;

      completed.add(attempt.exerciseId);
      (byLesson[lessonId] ??= <String>{}).add(attempt.exerciseId);
    }

    return LearnerProgress(
      startedLessonIds: Set<String>.unmodifiable(started),
      completedExerciseIds: Set<String>.unmodifiable(completed),
      completedExerciseIdsByLesson: Map<String, Set<String>>.unmodifiable(
        <String, Set<String>>{
          for (final entry in byLesson.entries)
            entry.key: Set<String>.unmodifiable(entry.value),
        },
      ),
      lessonExerciseTotals: Map<String, int>.unmodifiable(
        lessonExerciseTotals ?? officialChapter1ExerciseTotals(),
      ),
    );
  }

  /// Totaux officiels du chapitre 1, lus dans la banque validée.
  ///
  /// Aucun total n'est saisi à la main : il est compté dans
  /// [Chapter1Bank], donc il ne peut pas diverger du contenu.
  static Map<String, int> officialChapter1ExerciseTotals() {
    final totals = <String, int>{};
    for (final ArithmeticLesson lesson in ArithmeticLesson.values) {
      totals[lesson.id] = Chapter1Bank.exercises
          .where(
            (exercise) =>
                exercise.kind == BankElementKind.exercise &&
                exercise.lesson == lesson,
          )
          .length;
    }
    return totals;
  }
}

/// Charge la projection depuis l'historique persisté.
class LearnerProgressRepository {
  /// Crée le lecteur.
  const LearnerProgressRepository(this._events);

  final LearningEventRepository _events;

  /// Lit tous les événements et en déduit l'avancement.
  ///
  /// V1 : lecture complète de l'historique. Le volume reste faible (une
  /// tentative par exercice) ; une agrégation SQL dédiée prendra le relais
  /// quand l'historique sera long.
  Future<LearnerProgress> load() async {
    final events = await _events.findAll();
    return LearnerProgress.fromEvents(events);
  }
}
