/// Tests des modèles de l'écran d'accueil.
///
/// Ces modèles sont des DONNÉES FACTICES : les tests vérifient qu'ils restent
/// cohérents avec le document pédagogique validé (intitulés de leçons) et
/// qu'ils ne portent aucune information chiffrée destinée à l'élève.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter2_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/presentation/home/home_state.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

void main() {
  group('HomeState.mock', () {
    test('reprend un chapitre et une position lisibles', () {
      final state = HomeState.mock();

      expect(state.message, RelioStrings.relioMessage);
      expect(state.resume.chapterTitle, RelioStrings.chapterArithmetic);
      expect(state.resume.positionLabel, 'Exercice 2 sur 4');
    });

    test('porte l’objectif de séquence en tête', () {
      final state = HomeState.mock();

      expect(state.objective.sequence, 1);
      expect(state.objective.validated, 2);
      expect(state.objective.notions, 5);
      expect(state.objective.label, 'Séquence 1 • 2 notions sur 5 validées');
      expect(state.objective.ratio, closeTo(0.4, 1e-9));
    });

    test('le message par défaut ne parle d’aucun blocage', () {
      expect(HomeState.mock().message, RelioStrings.relioMessage);
      expect(
        HomeState.mock(recentBlock: 'code_inconnu').message,
        RelioStrings.relioMessage,
      );
    });

    test('un blocage récent sur les soustractions change le message', () {
      final state = HomeState.mock(
        recentBlock: RecentBlockCodes.subtractionWrong,
      );

      expect(state.message, RelioStrings.relioMessageSubtraction);
      expect(state.message, contains('soustractions'));
      // Le reste de l'écran ne bouge pas : seule la phrase change.
      expect(state.objective.label, HomeState.mock().objective.label);
      expect(state.resume.positionLabel, HomeState.mock().resume.positionLabel);
      expect(state.lessons.length, HomeState.mock().lessons.length);
    });

    test('liste les trois leçons du chapitre, dans l’ordre validé', () {
      final state = HomeState.mock();

      expect(
        state.lessons.map((l) => l.lessonId),
        ArithmeticLesson.values.map((l) => l.id),
      );
      expect(
        state.lessons.map((l) => l.title),
        ArithmeticLesson.values.map((l) => l.title),
      );
    });

    test('couvre les trois états d’affichage du mock', () {
      final state = HomeState.mock();

      // Le mock n'utilise pas l'état vide : « À commencer » appartient à
      // l'état réel, pas à la démonstration.
      expect(state.lessons.map((l) => l.status).toSet(), <LessonStatus>{
        LessonStatus.inProgress,
        LessonStatus.toReview,
        LessonStatus.mastered,
      });
      expect(state.lessons[0].statusLabel, RelioStrings.statusInProgress);
      expect(state.lessons[1].statusLabel, RelioStrings.statusToReview);
      expect(state.lessons[2].statusLabel, RelioStrings.statusMastered);
    });

    test('les remplissages restent entre 0 et 1', () {
      for (final lesson in HomeState.mock().lessons) {
        expect(lesson.fill, inInclusiveRange(0, 1));
      }
    });

    test('aucun libellé ne porte de pourcentage ni de score', () {
      final state = HomeState.mock();

      expect(state.message.contains('%'), isFalse);
      expect(state.resume.positionLabel!.contains('%'), isFalse);
      for (final lesson in state.lessons) {
        expect(lesson.statusLabel.contains('%'), isFalse);
        expect(lesson.statusLabel.toLowerCase().contains('score'), isFalse);
      }
    });
  });

  test(
    'un état peut être construit sans le mock — le moteur pourra le remplir',
    () {
      const state = HomeState(
        objective: SequenceObjective(sequence: 2, validated: 1, notions: 4),
        message: 'Message',
        resume: ResumeTarget(
          chapterNumber: 1,
          chapterTitle: 'Chapitre',
          positionLabel: 'Exercice 1 sur 2',
        ),
        lessons: <LessonProgress>[
          LessonProgress(
            lessonId: 'x',
            title: 'Leçon',
            status: LessonStatus.mastered,
            fill: 1,
          ),
        ],
      );

      expect(state.lessons, hasLength(1));
      expect(state.lessons.single.statusLabel, RelioStrings.statusMastered);
      expect(state.objective.label, 'Séquence 2 • 1 notion sur 4 validées');
    },
  );

  test('un objectif sans notion ne divise pas par zéro', () {
    const objective = SequenceObjective(sequence: 1, validated: 0, notions: 0);

    expect(objective.ratio, 0);
  });

  group('HomeState.fromProgress', () {
    test('un historique vide donne l’état de premier démarrage', () {
      final DateTime now = DateTime(2026, 9, 10, 10);
      final state = HomeState.fromProgress(LearnerProgress.empty, now: now);

      expect(state.started, isFalse);
      expect(state.message, RelioStrings.relioSeasonMessage(now, 1));
      expect(state.objective.sequence, 1);
      expect(state.resume.positionLabel, isNull);
      expect(state.resume.chapterTitle, RelioStrings.chapter1CardTitle);
      expect(state.objective.validated, 0);
      expect(state.objective.notions, ArithmeticLesson.values.length);
      expect(
        state.lessons.map((lesson) => lesson.status),
        everyElement(LessonStatus.notStarted),
      );
      expect(state.lessons.map((lesson) => lesson.fill), everyElement(0.0));
    });

    test(
      'le soir, le message de Relio situe l’élève et propose une session',
      () {
        final DateTime now = DateTime(2026, 11, 22, 21);
        final state = HomeState.fromProgress(LearnerProgress.empty, now: now);

        expect(state.message, RelioStrings.relioSeasonMessage(now, 2));
        expect(state.message, startsWith('Bonsoir'));
        expect(state.message, contains('ce soir'));
      },
    );

    test('une tentative au chapitre 1 ne fait pas démarrer le chapitre 2', () {
      final lesson = ArithmeticLesson.lesson1Subtractions;
      final progress = LearnerProgress(
        startedLessonIds: <String>{lesson.id},
        lessonExerciseTotals: LearnerProgress.officialChapter1ExerciseTotals(),
      );

      final DateTime now = DateTime(2026, 11, 10, 10);
      final state = HomeState.fromProgress(progress, now: now);

      // En novembre, le chapitre courant est Thalès : la tentative faite sur
      // l'arithmétique n'ouvre donc pas la carte du chapitre 2.
      expect(state.started, isFalse);
      expect(state.message, RelioStrings.relioSeasonMessage(now, 2));
      expect(state.objective.sequence, 2);
      expect(state.resume.chapterNumber, 2);
      expect(state.resume.chapterTitle, RelioStrings.chapter2CardTitle);
      expect(state.resume.positionLabel, isNull);

      // Les deux leçons de Thalès passent en tête, jamais commencées.
      expect(
        state.lessons.take(2).map((l) => l.lessonId),
        ThalesLesson.values.map((l) => l.id),
      );
      expect(
        state.lessons.take(2).map((l) => l.status),
        everyElement(LessonStatus.notStarted),
      );
      // Puis la leçon d'arithmétique commencée, qui reste à revoir.
      expect(state.lessons.last.lessonId, lesson.id);
      expect(state.lessons.last.status, LessonStatus.inProgress);
      expect(state.lessons.last.fill, 0);
    });

    test('un premier exercice réussi annonce la suite et la position', () {
      final lesson = ArithmeticLesson.lesson1Subtractions;
      final first = Chapter1Bank.exercises.firstWhere(
        (exercise) =>
            exercise.kind == BankElementKind.exercise &&
            exercise.lesson == lesson,
      );

      final progress = LearnerProgress(
        startedLessonIds: <String>{lesson.id},
        completedExerciseIds: <String>{first.id},
        completedExerciseIdsByLesson: <String, Set<String>>{
          lesson.id: <String>{first.id},
        },
        lessonExerciseTotals: LearnerProgress.officialChapter1ExerciseTotals(),
      );

      final state = HomeState.fromProgress(
        progress,
        now: DateTime(2026, 9, 10, 10),
      );

      // L'accueil propose de CONTINUER, avec la position réelle.
      expect(state.started, isTrue);
      expect(state.resume.positionLabel, RelioStrings.resumeProgress(2, 4));
      expect(state.message, RelioStrings.relioMessageFirstExerciseDone);
    });

    test('une leçon entièrement réussie devient maîtrisée', () {
      final lesson = ArithmeticLesson.lesson1Subtractions;
      // Les identifiants sont ceux de la banque : la reprise doit pouvoir les
      // reconnaître pour passer à la leçon suivante.
      final completed = Chapter1Bank.exercises
          .where(
            (exercise) =>
                exercise.kind == BankElementKind.exercise &&
                exercise.lesson == lesson,
          )
          .map((exercise) => exercise.id)
          .toSet();
      final progress = LearnerProgress(
        startedLessonIds: <String>{lesson.id},
        completedExerciseIds: completed,
        completedExerciseIdsByLesson: <String, Set<String>>{
          lesson.id: completed,
        },
        lessonExerciseTotals: LearnerProgress.officialChapter1ExerciseTotals(),
      );

      final state = HomeState.fromProgress(
        progress,
        now: DateTime(2026, 9, 10, 10),
      );

      expect(state.objective.validated, 1);
      expect(state.lessons.first.status, LessonStatus.mastered);
      expect(state.lessons.first.fill, 1);
      // La reprise pointe le premier exercice de la leçon suivante.
      expect(state.resume.positionLabel, RelioStrings.resumeProgress(1, 3));
    });

    test('en octobre, le chapitre courant est Théorème de Thalès', () {
      final DateTime now = DateTime(2026, 10, 22, 10);
      final state = HomeState.fromProgress(LearnerProgress.empty, now: now);

      // La séquence 2 ne contient aucun chapitre ouvert : l'accueil garde le
      // dernier chapitre enseigné, Thalès, plutôt qu'une liste vide.
      expect(state.objective.sequence, 2);
      expect(state.currentChapterNumber, 2);
      expect(state.resume.chapterNumber, 2);
      expect(state.resume.chapterTitle, RelioStrings.chapter2CardTitle);
      expect(state.resume.positionLabel, isNull);
      expect(state.started, isFalse);
      expect(state.objective.notions, ThalesLesson.values.length);
      expect(
        state.lessons.map((lesson) => lesson.lessonId),
        ThalesLesson.values.map((lesson) => lesson.id),
      );
      expect(state.message, RelioStrings.relioSeasonMessage(now, 2));
    });

    test('en septembre, le chapitre courant est Arithmétique', () {
      final state = HomeState.fromProgress(
        LearnerProgress.empty,
        now: DateTime(2026, 9, 10, 10),
      );

      expect(state.currentChapterNumber, 1);
      expect(state.resume.chapterTitle, RelioStrings.chapter1CardTitle);
      expect(state.objective.notions, ArithmeticLesson.values.length);
    });

    test('en décembre, aucun chapitre ouvert ne vide l’accueil', () {
      final state = HomeState.fromProgress(
        LearnerProgress.empty,
        now: DateTime(2026, 12, 10, 10),
      );

      expect(state.objective.sequence, 3);
      expect(state.currentChapterNumber, 2);
      expect(state.lessons, isNotEmpty);
    });

    test('un chapitre 2 commencé propose de reprendre', () {
      final lesson = ThalesLesson.lesson1Direct;
      final progress = LearnerProgress(
        startedLessonIds: <String>{lesson.id},
        lessonExerciseTotals: LearnerProgress.officialExerciseTotals(),
      );

      final state = HomeState.fromProgress(
        progress,
        now: DateTime(2026, 10, 22, 10),
      );

      expect(state.started, isTrue);
      expect(state.resume.chapterNumber, 2);
      expect(state.resume.positionLabel, RelioStrings.resumeProgress(1, 1));
    });
  });
}
