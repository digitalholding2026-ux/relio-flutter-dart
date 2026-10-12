/// Tests de la banque pilote du chapitre 1 « Arithmétique ».
///
/// Couvre les points 1, 2, 3 et 4 des tests obligatoires :
///  1. chargement des 11 exercices ;
///  2. cohérence des identifiants et des réponses attendues ;
///  3. consultation et enregistrement des indices ;
///  4. distinction réussite autonome / assistée.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/hint_trajectory.dart';

void main() {
  group('1. Chargement des 11 exercices', () {
    test('la banque contient exactement 11 exercices validés', () {
      final exercises = Chapter1Bank.exercises
          .where((e) => e.kind == BankElementKind.exercise)
          .toList();

      expect(exercises, hasLength(11));
    });

    test('les 11 exercices couvrent les trois leçons', () {
      final byLesson = <String, int>{};
      for (final exercise in Chapter1Bank.exercises) {
        byLesson[exercise.lesson.id] = (byLesson[exercise.lesson.id] ?? 0) + 1;
      }

      expect(byLesson[ArithmeticLesson.lesson1Subtractions.id], 4,
          reason: 'leçon 1 : exercices 1 à 4');
      expect(byLesson[ArithmeticLesson.lesson2Euclid.id], 3,
          reason: 'leçon 2 : exercices 5 à 7');
      expect(byLesson[ArithmeticLesson.lesson3PpcmPgcdRelation.id], 4,
          reason: 'leçon 3 : exercices 8 à 11');
    });

    test('chaque exercice a un énoncé non vide', () {
      for (final exercise in Chapter1Bank.exercises) {
        expect(exercise.statement.trim(), isNotEmpty,
            reason: 'exercice ${exercise.id}');
      }
    });

    test('les intitulés de leçon ne sont pas modifiés', () {
      expect(
        ArithmeticLesson.lesson1Subtractions.title,
        'PGCD : algorithme des soustractions',
      );
      // La leçon 2 conserve le libellé « PGDC » de la capture, signalé
      // comme à confirmer éditorialement.
      expect(ArithmeticLesson.lesson2Euclid.title, '« PGDC » : algorithme d’Euclide');
      expect(ArithmeticLesson.lesson2Euclid.requiresEditorialConfirmation, isTrue);
      expect(
        ArithmeticLesson.lesson3PpcmPgcdRelation.title,
        'Relation entre le PPCM et le PGCD de deux entiers naturels',
      );
    });
  });

  group('2. Cohérence des identifiants et réponses attendues', () {
    test('les identifiants sont uniques', () {
      final ids = Chapter1Bank.exercises.map((e) => e.id).toSet();

      expect(ids, hasLength(Chapter1Bank.exercises.length));
    });

    test('findExercise retrouve chaque exercice par son identifiant', () {
      for (final exercise in Chapter1Bank.exercises) {
        expect(Chapter1Bank.findExercise(exercise.id), isNotNull);
      }
    });

    test('findExercise renvoie null pour un identifiant inconnu', () {
      expect(Chapter1Bank.findExercise('inexistant'), isNull);
    });

    test('les réponses attendues correspondent aux calculs du document', () {
      // Valeurs vérifiées arithmétiquement face au document source.
      const expected = <String, int>{
        ExerciseIds.ex1: 6, //  PGCD(18, 12)
        ExerciseIds.ex2: 5, //  PGCD(15, 10)
        ExerciseIds.ex3: 7, //  PGCD(21, 14)
        ExerciseIds.ex4: 4, //  PGCD(20, 12)
        ExerciseIds.ex5: 6, //  PGCD(30, 18)
        ExerciseIds.ex6: 6, //  PGCD(42, 30)
        ExerciseIds.ex7: 6, //  PGCD(48, 18)
        ExerciseIds.ex8: 36, // PPCM(12, 18)
        ExerciseIds.ex9: 24, // PPCM(8, 12)
        ExerciseIds.ex10: 135, // 9 × 15 = 3 × 45
      };

      expected.forEach((id, value) {
        final exercise = Chapter1Bank.findExercise(id);
        expect(exercise, isNotNull, reason: 'exercice $id absent');
        expect(
          exercise!.correction.accepts(value),
          isTrue,
          reason: '$id doit accepter $value',
        );
      });
    });

    test('une valeur fausse est refusée', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(ex1.correction.accepts(7), isFalse);
      expect(ex1.correction.accepts(5), isFalse);
    });

    test('les tâches de vérification portent des valeurs exactes', () {
      // La valeur ATTENDUE de chaque tâche. Elle n'est pas forcément
      // ACCEPTÉE telle quelle : la tâche PPCM exige désormais une
      // démonstration de la relation, pas le seul résultat.
      const attendu = <String, int>{
        ExerciseIds.verifyPgcd16And12: 4, // PGCD(16, 12)
        ExerciseIds.verifyPgcd14And7: 7, //  PGCD(14, 7)
        ExerciseIds.verifyPgcd24And16: 8, // PGCD(24, 16)
        ExerciseIds.verifyPgcd35And20: 5, // PGCD(35, 20)
        ExerciseIds.verifyPpcm10And15: 30, // PPCM(10, 15)
        ExerciseIds.verifyPpcm6And8: 24, //   PPCM(6, 8)
      };

      attendu.forEach((id, value) {
        final tache = Chapter1Bank.findExercise(id);
        expect(tache, isNotNull, reason: 'tâche $id absente');
        expect(tache!.kind, BankElementKind.verificationTask);

        final relation = tache.correction.ppcmRelation;
        if (relation != null) {
          expect(relation.result, value, reason: '$id : résultat du contrat');
          expect(relation.isCoherent, isTrue, reason: '$id : contrat cohérent');
        } else {
          expect(tache.correction.accepts(value), isTrue, reason: '$id / $value');
        }
      });
    });

    test('aucune tâche de vérification ne se déguise en exercice validé', () {
      for (final task in Chapter1Bank.verificationTasks) {
        expect(task.kind, BankElementKind.verificationTask);
      }
      final officialIds = Chapter1Bank.exercises
          .where((e) => e.kind == BankElementKind.exercise)
          .map((e) => e.id)
          .toSet();
      for (final task in Chapter1Bank.verificationTasks) {
        expect(officialIds, isNot(contains(task.id)));
      }
    });
  });

  group('3. Consultation et enregistrement des indices', () {
    test('les indices sont ordonnés et progressifs', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(ex1.orderedHints.map((h) => h.order), <int>[1, 2]);
      expect(ex1.orderedHints.first.text,
          'Soustrais le plus petit nombre du plus grand.');
    });

    test('nextHintAfter propose l’indice suivant dans l’ordre', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(ex1.nextHintAfter(<int>{})!.order, 1);
      expect(ex1.nextHintAfter(<int>{1})!.order, 2);
      expect(ex1.nextHintAfter(<int>{1, 2}), isNull,
          reason: 'aucun indice inventé au-delà de ceux de la banque');
    });

    test('un ordre déjà consommé n’est jamais reproposé', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(ex1.nextHintAfter(<int>{2})!.order, 1,
          reason: 'l’indice 1 reste disponible si seul le 2 a été vu');
      expect(ex1.nextHintAfter(<int>{1, 2}), isNull);
    });

    test('un exercice sans indice n’en propose aucun', () {
      final ex2 = Chapter1Bank.findExercise(ExerciseIds.ex2)!;

      expect(ex2.hints, isEmpty);
      expect(ex2.nextHintAfter(<int>{}), isNull);
    });

    test('les indices de l’exercice 5 respectent le document', () {
      final ex5 = Chapter1Bank.findExercise(ExerciseIds.ex5)!;

      expect(ex5.orderedHints.map((h) => h.text), <String>[
        'Divise le plus grand nombre par le plus petit et note le reste.',
        'Le nouveau couple est le diviseur et le reste.',
      ]);
    });
  });

  group('4. Réussite autonome vs assistée', () {
    HintTrajectory trajectoryOf(List<int> orders) => HintTrajectory(<ConsumedHint>[
          for (final order in orders)
            ConsumedHint(order: order, consumedAt: DateTime.utc(2026, 3, 15, 9, order)),
        ]);

    test('réussite sans indice = autonome', () {
      final classification = trajectoryOf(<int>[]).classify(
        isCorrect: true,
        isEmpty: false,
      );

      expect(classification, AttemptClassification.autonomousSuccess);
    });

    test('réussite AVEC indice = assistée, jamais autonome', () {
      final classification = trajectoryOf(<int>[1]).classify(
        isCorrect: true,
        isEmpty: false,
      );

      expect(classification, AttemptClassification.assistedSuccess);
      expect(classification, isNot(AttemptClassification.autonomousSuccess),
          reason: 'règle centrale du document source');
    });

    test('réussite après deux indices reste assistée', () {
      final classification = trajectoryOf(<int>[1, 2]).classify(
        isCorrect: true,
        isEmpty: false,
      );

      expect(classification, AttemptClassification.assistedSuccess);
    });

    test('échec sans indice', () {
      expect(
        trajectoryOf(<int>[]).classify(isCorrect: false, isEmpty: false),
        AttemptClassification.incorrect,
      );
    });

    test('échec avec indice', () {
      expect(
        trajectoryOf(<int>[1]).classify(isCorrect: false, isEmpty: false),
        AttemptClassification.assistedIncorrect,
      );
    });

    test('réponse vide = incomplète, quel que soit le nombre d’indices', () {
      expect(
        trajectoryOf(<int>[]).classify(isCorrect: false, isEmpty: true),
        AttemptClassification.incomplete,
      );
      expect(
        trajectoryOf(<int>[1, 2]).classify(isCorrect: false, isEmpty: true),
        AttemptClassification.incomplete,
      );
    });

    test('réponse non évaluable = incomplète', () {
      expect(
        trajectoryOf(<int>[]).classify(
          isCorrect: false,
          isEmpty: false,
          notEvaluated: true,
        ),
        AttemptClassification.incomplete,
      );
    });

    test('abandon = incomplet', () {
      expect(
        trajectoryOf(<int>[]).classify(
          isCorrect: false,
          isEmpty: false,
          abandoned: true,
        ),
        AttemptClassification.incomplete,
      );
    });
  });

  group('5. Conservation de l’historique des indices par tentative', () {
    test('la trajectoire conserve l’ordre RÉEL de consultation', () {
      // L'élève peut consulter l'indice 2 avant le 1 : l'ordre réel fait
      // foi, pas l'ordre de la banque.
      final trajectory = HintTrajectory(<ConsumedHint>[
        ConsumedHint(order: 2, consumedAt: DateTime.utc(2026, 3, 15, 10)),
        ConsumedHint(order: 1, consumedAt: DateTime.utc(2026, 3, 15, 9)),
      ]);

      expect(trajectory.hints.map((h) => h.order), <int>[1, 2]);
      expect(trajectory.consumedOrders, <int>{1, 2});
      expect(trajectory.length, 2);
      expect(trajectory.hasHints, isTrue);
    });

    test('à horodatage égal, l’ordre de la banque départage', () {
      final same = DateTime.utc(2026, 3, 15, 9);
      final trajectory = HintTrajectory(<ConsumedHint>[
        ConsumedHint(order: 2, consumedAt: same),
        ConsumedHint(order: 1, consumedAt: same),
      ]);

      expect(trajectory.hints.map((h) => h.order), <int>[1, 2]);
    });

    test('une trajectoire vide n’a aucun indice', () {
      final trajectory = HintTrajectory(const <ConsumedHint>[]);

      expect(trajectory.length, 0);
      expect(trajectory.hasHints, isFalse);
    });

    test('nextAvailable tient compte de la consommation réelle', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;
      final trajectory = HintTrajectory(<ConsumedHint>[
        ConsumedHint(order: 1, consumedAt: DateTime.utc(2026, 3, 15, 9)),
      ]);

      expect(trajectory.nextAvailable(ex1)!.order, 2);
      expect(
        HintTrajectory(const <ConsumedHint>[]).nextAvailable(ex1)!.order,
        1,
      );
    });
  });
}
