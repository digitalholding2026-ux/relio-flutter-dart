/// Tests des modèles de l'écran d'accueil.
///
/// Ces modèles sont des DONNÉES FACTICES : les tests vérifient qu'ils restent
/// cohérents avec le document pédagogique validé (intitulés de leçons) et
/// qu'ils ne portent aucune information chiffrée destinée à l'élève.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/exercise.dart';
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

    test('couvre les trois états d’affichage', () {
      final state = HomeState.mock();

      expect(
        state.lessons.map((l) => l.status).toSet(),
        LessonStatus.values.toSet(),
      );
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
      expect(state.resume.positionLabel.contains('%'), isFalse);
      for (final lesson in state.lessons) {
        expect(lesson.statusLabel.contains('%'), isFalse);
        expect(lesson.statusLabel.toLowerCase().contains('score'), isFalse);
      }
    });
  });

  test('un état peut être construit sans le mock — le moteur pourra le remplir',
      () {
    const state = HomeState(
      message: 'Message',
      resume: ResumeTarget(chapterTitle: 'Chapitre', positionLabel: 'Exercice 1 sur 2'),
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
  });
}
