/// Enregistrement d'une réussite → projection d'avancement → écrans.
///
/// Ce test passe par l'API RÉELLE du moteur (`Chapter1Service.recordAttempt`)
/// puis relit l'historique persité, comme le fait la coquille. Il vérifie la
/// chaîne complète, et non une projection fabriquée à la main :
///
///  - une réussite termine l'exercice et compte 1/4 ;
///  - la leçon passe de « À commencer » à « En cours » ;
///  - une réponse fausse commence la leçon sans incrémenter le décompte ;
///  - les quatre réussites de la leçon la font passer à « Maîtrisé ».
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/home/home_state.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LearningEventRepository repository;
  late Chapter1Service service;
  late LearnerProgressRepository progressRepository;

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    repository = LearningEventRepository(db);
    service = Chapter1Service(repository);
    progressRepository = LearnerProgressRepository(repository);
  });

  final lesson = ArithmeticLesson.lesson1Subtractions;

  /// Exercices officiels de la leçon 1, dans l'ordre du programme.
  final exercises = Chapter1Bank.exercises
      .where(
        (exercise) =>
            exercise.kind == BankElementKind.exercise &&
            exercise.lesson == lesson,
      )
      .toList();

  test('une réussite compte 1/4 et passe la leçon en « En cours »', () async {
    final record = await service.recordAttempt(
      exercise: exercises[0],
      rawAnswer: '6',
    );
    expect(record.outcome, AnswerOutcome.correct);

    final progress = await progressRepository.load();
    final LessonProgress shown = HomeState.lessonProgress(lesson, progress);

    expect(progress.startedLesson(lesson.id), isTrue);
    expect(progress.completedIn(lesson.id), 1);
    expect(shown.completedExercises, 1);
    expect(shown.totalExercises, 4);
    expect(shown.exerciseProgressLabel, RelioStrings.lessonExerciseProgress(1, 4));
    expect(shown.status, LessonStatus.inProgress);
    expect(shown.fill, closeTo(0.25, 1e-9));

    // L'accueil propose la suite immédiate, au bon rang.
    final home = HomeState.fromProgress(progress);
    expect(home.started, isTrue);
    expect(home.resume.chapterTitle, RelioStrings.chapterArithmetic);
    expect(home.resume.positionLabel, RelioStrings.resumeProgress(2, 4));
  });

  test('une réponse fausse commence la leçon sans incrémenter', () async {
    final record = await service.recordAttempt(
      exercise: exercises[0],
      rawAnswer: '7',
    );
    expect(record.outcome, AnswerOutcome.incorrect);

    final progress = await progressRepository.load();
    final LessonProgress shown = HomeState.lessonProgress(lesson, progress);

    expect(progress.startedLesson(lesson.id), isTrue);
    expect(progress.completedIn(lesson.id), 0);
    expect(shown.status, LessonStatus.inProgress);
    expect(shown.exerciseProgressLabel, RelioStrings.lessonExerciseProgress(0, 4));
    expect(shown.fill, 0);

    final home = HomeState.fromProgress(progress);
    expect(home.started, isTrue);
    expect(home.resume.positionLabel, RelioStrings.resumeProgress(1, 4));
  });

  test('les quatre réussites de la leçon la rendent « Maîtrisé »', () async {
    // Réponses attendues lues dans la banque : aucune valeur n'est saisie ici.
    for (final exercise in exercises) {
      final expected = exercise.correction.acceptedValues.first;
      final record = await service.recordAttempt(
        exercise: exercise,
        rawAnswer: '$expected',
      );
      expect(record.outcome, AnswerOutcome.correct, reason: exercise.id);
    }

    final progress = await progressRepository.load();
    final LessonProgress shown = HomeState.lessonProgress(lesson, progress);

    expect(progress.completedIn(lesson.id), 4);
    expect(shown.exerciseProgressLabel, RelioStrings.lessonExerciseProgress(4, 4));
    expect(shown.fill, 1);
    expect(shown.status, LessonStatus.mastered);
    expect(shown.statusLabel, RelioStrings.statusMastered);

    expect(HomeState.fromProgress(progress).objective.validated, 1);
  });

  test('rejouer une réussite ne double pas le décompte', () async {
    for (var i = 0; i < 3; i++) {
      await service.recordAttempt(exercise: exercises[0], rawAnswer: '6');
    }

    final progress = await progressRepository.load();
    expect(progress.completedIn(lesson.id), 1);
  });
}
