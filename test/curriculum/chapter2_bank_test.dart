/// Tests de la banque du chapitre 2 « Théorème de Thalès ».
///
/// Le contenu est une transcription : ces tests vérifient qu'il n'a pas dérivé
/// et que les contrats de correction / navigation / diagnostic le prennent en
/// compte sans le confondre avec le chapitre 1.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter2_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/curriculum_bank.dart';
import 'package:relio/domain/curriculum/diagnostic_engine.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/rich_hint.dart';
import 'package:relio/domain/learning/revision_plan.dart';
import 'package:relio/presentation/rules/v1_screen_rules.dart';

void main() {
  group('Chapitre 2 — structure', () {
    test('deux leçons, deux exercices, un par leçon', () {
      expect(ThalesLesson.values, hasLength(2));
      expect(Chapter2Bank.exercises, hasLength(2));

      final ex1 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex1)!;
      final ex2 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex2)!;

      expect(ex1.lesson, ThalesLesson.lesson1Direct);
      expect(ex2.lesson, ThalesLesson.lesson2Reciprocal);
      expect(
        Chapter2Bank.exercises
            .where((e) => e.lesson == ThalesLesson.lesson1Direct),
        hasLength(1),
      );
      expect(
        Chapter2Bank.exercises
            .where((e) => e.lesson == ThalesLesson.lesson2Reciprocal),
        hasLength(1),
      );
    });

    test('les intitulés sont ceux du document', () {
      expect(
        ThalesLesson.lesson1Direct.title,
        'Propriété directe (Calculer des longueurs)',
      );
      expect(
        ThalesLesson.lesson2Reciprocal.title,
        'Propriété réciproque (Justifier le parallélisme)',
      );
      expect(ThalesLesson.values.every((l) => l.chapterNumber == 2), isTrue);
    });

    test('l’intitulé court tient dans l’AppBar', () {
      // L'AppBar de S2 affiche le titre COURT : sans parenthèses, il ne se
      // retrouve plus tronqué (« Propriété directe (Calculer des… »).
      expect(ThalesLesson.lesson1Direct.shortTitle, 'Propriété directe');
      expect(ThalesLesson.lesson2Reciprocal.shortTitle, 'Propriété réciproque');
      for (final lesson in ThalesLesson.values) {
        expect(lesson.shortTitle, isNot(contains('(')));
        expect(lesson.shortTitle.length, lessThan(lesson.title.length));
      }
    });

    test('les identifiants de leçon ne collisionnent pas avec le chapitre 1', () {
      final ids = <String>{
        for (final CurriculumLesson lesson in CurriculumBank.lessons) lesson.id,
      };
      expect(ids, contains(ThalesLesson.lesson1Direct.id));
      expect(ids, contains(ThalesLesson.lesson2Reciprocal.id));
      expect(ids, contains(ArithmeticLesson.lesson1Subtractions.id));
      expect(ids.length, CurriculumBank.lessons.length);
    });
  });

  group('Chapitre 2 — contenu', () {
    test('exercice 1 : énoncé, réponse 7,5 et diagnostics', () {
      final ex1 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex1)!;

      expect(
        ex1.statement,
        'Dans un triangle ABC, M est sur [AB] et N est sur [AC]. On sait '
        'que (MN) // (BC). AM = 3 cm, AB = 5 cm, et AN = 4,5 cm. Calcule AC.',
      );
      expect(ex1.correction.acceptsExpression('7.5'), isTrue);
      expect(ex1.correction.acceptsExpression('7,5'), isTrue);
      expect(ex1.correction.acceptsExpression('6'), isFalse);
      expect(ex1.errorCaseFor('6'), 'D1');
      expect(ex1.errorCaseFor('3.33'), 'D2');
      expect(ex1.correction.explanation, 'AC = (4,5 × 5) ÷ 3 = 7,5 cm.');
    });

    test('exercice 2 : réponse « oui » ou « vrai », diagnostics', () {
      final ex2 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex2)!;

      expect(ex2.correction.acceptsExpression('oui'), isTrue);
      expect(ex2.correction.acceptsExpression('vrai'), isTrue);
      expect(ex2.correction.acceptsExpression('non'), isFalse);
      expect(ex2.errorCaseFor('non'), 'D3');
      expect(ex2.errorCaseFor('faux'), 'D3');
    });

    test('chaque exercice porte deux fiches, dans l’ordre', () {
      for (final exercise in Chapter2Bank.exercises) {
        expect(exercise.orderedRichHints, hasLength(2), reason: exercise.id);
        expect(exercise.orderedRichHints.map((h) => h.order), <int>[1, 2]);
        expect(exercise.hintCount, 2, reason: exercise.id);
      }
    });

    test('les blocs des fiches sont ceux du document', () {
      final ex1h1 =
          Chapter2Bank.findExercise(Chapter2ExerciseIds.ex1)!
              .orderedRichHints[0];
      expect(ex1h1.blocks[0], isA<TextBlock>());
      expect(ex1h1.blocks[1], isA<MathBlock>());
      expect(ex1h1.blocks[2], isA<HandoffBlock>());
      expect(
        (ex1h1.blocks[1] as MathBlock).text,
        'AM/AB = AN/AC = MN/BC',
      );

      final ex1h2 =
          Chapter2Bank.findExercise(Chapter2ExerciseIds.ex1)!
              .orderedRichHints[1];
      expect((ex1h2.blocks[1] as MathBlock).text, 'AC = (4,5 × 5) ÷ 3');
      expect(
        (ex1h2.blocks[2] as HighlightBlock).text,
        'Le résultat est 7,5 cm.',
      );

      final ex2h2 =
          Chapter2Bank.findExercise(Chapter2ExerciseIds.ex2)!
              .orderedRichHints[1];
      expect((ex2h2.blocks[0] as MathBlock).text, 'AM/AB = 2/6 = 1/3');
      expect((ex2h2.blocks[1] as MathBlock).text, 'AN/AC = 3/9 = 1/3');
      expect(ex2h2.blocks[2], isA<HighlightBlock>());
    });
  });

  group('Chapitre 2 — correction', () {
    test('7,5 et 7.5 réussissent, 6 et 3.33 échouent', () {
      final ex1 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex1)!;

      expect(correct(ex1, '7,5').isCorrect, isTrue);
      expect(correct(ex1, '7.5').isCorrect, isTrue);
      expect(correct(ex1, '6').isCorrect, isFalse);
      expect(correct(ex1, '3.33').isCorrect, isFalse);
    });

    test('oui et vrai réussissent, non et faux échouent', () {
      final ex2 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex2)!;

      expect(correct(ex2, 'oui').isCorrect, isTrue);
      expect(correct(ex2, 'vrai').isCorrect, isTrue);
      expect(correct(ex2, 'non').isCorrect, isFalse);
      expect(correct(ex2, 'faux').isCorrect, isFalse);
    });

    test('un code D1 de Thalès n’ouvre jamais le D1 d’arithmétique', () {
      final ex1 = Chapter2Bank.findExercise(Chapter2ExerciseIds.ex1)!;

      // Sans cas de chapitre 2, la correspondance reste sans intervention :
      // elle ne doit pas emprunter le cas D1 du chapitre 1.
      expect(
        const DiagnosticEngine().diagnoseAnswer(
          exercise: ex1,
          rawAnswer: '6',
        ),
        isNull,
      );
    });
  });

  group('Chapitre 2 — navigation', () {
    test('le premier exercice de chaque leçon est retrouvé', () {
      expect(
        V1ScreenRules.firstOfLesson(ThalesLesson.lesson1Direct.id)?.id,
        Chapter2ExerciseIds.ex1,
      );
      expect(
        V1ScreenRules.firstOfLesson(ThalesLesson.lesson2Reciprocal.id)?.id,
        Chapter2ExerciseIds.ex2,
      );
    });

    test('une leçon d’un seul exercice n’a pas de suivant', () {
      for (final exercise in Chapter2Bank.exercises) {
        expect(V1ScreenRules.nextAfter(exercise), isNull);
      }
    });

    test('les positions suivent l’ordre du programme', () {
      expect(
        V1ScreenRules.positionOf(Chapter2ExerciseIds.ex1),
        V1ScreenRules.exercises.length - 1,
      );
      expect(
        V1ScreenRules.positionOf(Chapter2ExerciseIds.ex2),
        V1ScreenRules.exercises.length,
      );
    });

    test('la révision ne sort jamais du chapitre courant', () {
      // Regression signalee : le premier exercice de Thales proposait de
      // reviser le dernier exercice d'arithmetique (PPCM). Un exercice ne
      // peut avoir de precedent que DANS SA LEÇON, donc dans son chapitre.
      for (final exercise in Chapter2Bank.exercises) {
        final previous = V1ScreenRules.previousBefore(exercise);
        expect(previous, isNull, reason: '${exercise.id} est seul dans sa leçon');
      }

      for (final exercise in CurriculumBank.exercises) {
        final previous = V1ScreenRules.previousBefore(exercise);
        if (previous != null) {
          expect(previous.lesson.chapterNumber, exercise.lesson.chapterNumber);
          expect(previous.lesson, exercise.lesson);
        }
      }
    });

    test('le numéro affiché redémarre à 1 dans chaque chapitre', () {
      // « Revoir l'exercice 12 » n'aurait aucun sens pour un eleve de 3e :
      // la numerotation visible est celle du chapitre, pas celle de la banque.
      expect(V1ScreenRules.chapterPositionOf(Chapter2ExerciseIds.ex1), 1);
      expect(V1ScreenRules.chapterPositionOf(Chapter2ExerciseIds.ex2), 2);
      // Le chapitre 1 garde exactement sa numerotation historique.
      expect(
        V1ScreenRules.chapterPositionOf(ExerciseIds.ex1),
        V1ScreenRules.positionOf(ExerciseIds.ex1),
      );
    });
  });

  group('Chapitre 2 — programme', () {
    test('le programme relie la séquence 1 au chapitre 2', () {
      expect(
        lessonsByChapter['Théorème de Thalès'],
        contains(ThalesLesson.lesson1Direct),
      );
      expect(
        lessonsByChapter['Théorème de Thalès'],
        contains(ThalesLesson.lesson2Reciprocal),
      );
    });

    test('les deux exercices entrent dans la séquence 1', () {
      final exercises = CurriculumBank.exercises
          .where(
            (e) =>
                e.lesson.chapterNumber == 2 &&
                e.kind == BankElementKind.exercise,
          )
          .toList();
      expect(exercises, hasLength(2));
    });
  });
}
