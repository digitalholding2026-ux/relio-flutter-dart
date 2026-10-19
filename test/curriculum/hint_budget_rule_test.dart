/// La règle de budget progressif — le cœur du système d'indices.
///
/// Ce test verrouille une DÉCISION PÉDAGOGIQUE, pas un détail d'implémentation :
/// l'aide se retire progressivement dans la leçon. Si la formule change, la
/// suite doit échouer : c'est le but.
///
/// Rappel de la règle :
///
///     N = nombre d'EXERCICES OFFICIELS de la leçon (les tâches de vérification
///         ne comptent pas : ce ne sont pas des exercices de la leçon) ;
///     M = nombre d'indices réels du PREMIER exercice de la leçon ;
///     budget(i) = max(1, M - (i - 1) * (M - 1) / (N - 1)), arrondi.
///
/// Le budget réel ne peut jamais dépasser le nombre de fiches que l'exercice
/// possède réellement.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/rich_hint.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late Chapter1Service service;

  setUp(() async {
    final db = await openTestDatabase();
    registerTestDatabase(db);
    service = Chapter1Service(LearningEventRepository(db));
  });

  /// Budget du moteur pour l'exercice [id].
  int budgetOf(String id) =>
      service.maxHintsFor(Chapter1Bank.findExercise(id)!);

  group('La formule produit le retrait attendu', () {
    test('leçon 1 — 4 exercices, premier à 3 fiches : 3, 2, 1, 1', () {
      // Exemple de référence de la spécification.
      expect(budgetOf(ExerciseIds.ex1), 3);
      expect(budgetOf(ExerciseIds.ex2), 2);
      // L'exercice 3 ne possède qu'UNE fiche : le budget calculé de 2 est
      // ramené à ce qu'il peut réellement ouvrir.
      expect(budgetOf(ExerciseIds.ex3), 1);
      expect(budgetOf(ExerciseIds.ex4), 1);
    });

    test('leçon 2 — 3 exercices, premier à 3 fiches : 3, 2, 1', () {
      expect(budgetOf(ExerciseIds.ex5), 3);
      expect(budgetOf(ExerciseIds.ex6), 2);
      expect(budgetOf(ExerciseIds.ex7), 1);
    });

    test('leçon 3 — aucun contenu rédigé : budget nul', () {
      expect(budgetOf(ExerciseIds.ex8), 0);
      expect(budgetOf(ExerciseIds.ex9), 0);
      expect(budgetOf(ExerciseIds.ex10), 0);
      expect(budgetOf(ExerciseIds.ex11), 0);
    });
  });

  group('Les invariants de la règle', () {
    test('le budget ne dépasse jamais le nombre de fiches réelles', () {
      for (final exercise in Chapter1Bank.exercises) {
        expect(
          service.maxHintsFor(exercise),
          lessThanOrEqualTo(exercise.hintCount),
          reason: exercise.id,
        );
      }
    });

    test('le budget décroît ou reste égal en avançant dans la leçon', () {
      for (final lesson in ArithmeticLesson.values) {
        final siblings = Chapter1Bank.exercises
            .where((e) =>
                e.kind == BankElementKind.exercise && e.lesson == lesson)
            .toList();
        for (var i = 1; i < siblings.length; i++) {
          expect(
            service.maxHintsFor(siblings[i]),
            lessThanOrEqualTo(service.maxHintsFor(siblings[i - 1])),
            reason: '${lesson.id} : position ${i + 1}',
          );
        }
      }
    });

    test('les tâches de vérification ne comptent pas dans N', () {
      // La leçon 1 porte 3 tâches de vérification. Si elles entraient dans le
      // calcul de N, le premier exercice verrait son budget tomber à 2.
      final inLesson1 = Chapter1Bank.exercises
          .where((e) => e.lesson == ArithmeticLesson.lesson1Subtractions);
      final official = inLesson1
          .where((e) => e.kind == BankElementKind.exercise)
          .length;
      expect(official, 4);
      expect(budgetOf(ExerciseIds.ex1), 3);
    });
  });

  group('Le budget commande le bouton', () {
    HintBudget budgetAt(String id, Set<int> consumed) =>
        service.hintBudget(Chapter1Bank.findExercise(id)!, consumed);

    test('premier indice demandé, budget intact', () {
      final budget = budgetAt(ExerciseIds.ex1, <int>{});
      expect(budget.maxHintsAllowed, 3);
      expect(budget.remaining, 3);
      expect(budget.cta, HintCta.askFirst);
    });

    test('le libellé se retire à mesure que le budget fond', () {
      expect(budgetAt(ExerciseIds.ex1, <int>{1}).cta, HintCta.next);
      expect(budgetAt(ExerciseIds.ex1, <int>{1, 2}).cta, HintCta.finalOne);
      expect(budgetAt(ExerciseIds.ex1, <int>{1, 2, 3}).isExhausted, isTrue);
    });

    test('un exercice sans fiche n’offre rien du tout', () {
      final budget = budgetAt(ExerciseIds.ex8, <int>{});
      expect(budget.maxHintsAllowed, 0);
      expect(budget.isExhausted, isTrue);
      expect(budget.cta, HintCta.none);
    });

    test('le moteur ne sert aucun indice au-delà du budget', () {
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;
      expect(service.nextHint(ex1, <int>{})!.order, 1);
      expect(service.nextHint(ex1, <int>{1})!.order, 2);
      expect(service.nextHint(ex1, <int>{1, 2})!.order, 3);
      // Budget épuisé : aucune fiche supplémentaire, même si la banque en
      // possédait davantage.
      expect(service.nextHint(ex1, <int>{1, 2, 3}), isNull);
    });
  });

  group('Le contenu est bien celui de la banque', () {
    test('les sept premiers exercices portent des fiches définitives', () {
      final withCards = Chapter1Bank.exercises
          .where((e) => e.orderedRichHints.isNotEmpty)
          .length;
      expect(withCards, 7);
    });

    test('aucune fiche n’est vide : une fiche muette ne lirait rien', () {
      for (final exercise in Chapter1Bank.exercises) {
        for (final hint in exercise.orderedRichHints) {
          expect(hint.blocks, isNotEmpty, reason: '${exercise.id} #${hint.order}');
          for (final block in hint.blocks) {
            expect(block.text.trim(), isNotEmpty,
                reason: '${exercise.id} #${hint.order}');
          }
        }
      }
    });

    test('les rangs sont 1..n, sans trou ni doublon', () {
      for (final exercise in Chapter1Bank.exercises) {
        final orders = exercise.orderedRichHints.map((h) => h.order).toList();
        for (var i = 0; i < orders.length; i++) {
          expect(orders[i], i + 1, reason: exercise.id);
        }
      }
    });

    test('les glyphes mathématiques sont ceux attendus', () {
      // Un tiret ASCII à la place de − trahirait une copie manuelle : c'est
      // le signe que la transcription a bien été faite depuis la source.
      final texts = Chapter1Bank.exercises
          .expand((e) => e.orderedRichHints)
          .expand((h) => h.blocks)
          .map((b) => b.text)
          .toList();

      expect(texts.any((t) => t.contains('−')), isTrue, reason: 'moins');
      expect(texts.any((t) => t.contains('×')), isTrue, reason: 'multiplier');
      expect(texts.any((t) => t.contains('÷')), isTrue, reason: 'diviser');
      expect(
        texts.any((t) => t.contains('18 − 12 = 6')),
        isTrue,
        reason: 'première soustraction du chapitre',
      );
      expect(
        texts.any((t) => t.contains('30 ÷ 18 = 1')),
        isTrue,
        reason: 'première division euclidienne',
      );
    });
  });

  group('Règle 8 — chaque valeur est vérifiée arithmétiquement', () {
    /// PGCD, recalculé par l'algorithme d'Euclide : la valeur attendue est
    /// donc confrontée à un calcul, jamais à un commentaire.
    int pgcd(int a, int b) => b == 0 ? a : pgcd(b, a % b);

    /// Les couples soumis dans les énoncés des sept premiers exercices.
    const couples = <String, (int, int)>{
      ExerciseIds.ex1: (18, 12),
      ExerciseIds.ex2: (15, 10),
      ExerciseIds.ex3: (21, 14),
      ExerciseIds.ex4: (20, 12),
      ExerciseIds.ex5: (30, 18),
      ExerciseIds.ex6: (42, 30),
      ExerciseIds.ex7: (48, 18),
    };

    test('la réponse attendue de chaque exercice est le vrai PGCD', () {
      couples.forEach((id, pair) {
        final exercise = Chapter1Bank.findExercise(id)!;
        expect(
          exercise.correction.acceptedValues.single,
          pgcd(pair.$1, pair.$2),
          reason: id,
        );
      });
    });

    test('chaque énoncé annonce bien le couple qu’il pose', () {
      couples.forEach((id, pair) {
        final statement = Chapter1Bank.findExercise(id)!.statement;
        expect(statement.contains('${pair.$1}'), isTrue, reason: id);
        expect(statement.contains('${pair.$2}'), isTrue, reason: id);
      });
    });

    test('le contenu de la fiche annonce le bon résultat', () {
      couples.forEach((id, pair) {
        final expected = pgcd(pair.$1, pair.$2);
        final texte = Chapter1Bank.findExercise(id)!
            .orderedRichHints
            .expand((h) => h.blocks)
            .map((b) => b.text)
            .join(' ');
        expect(
          texte.contains('$expected'),
          isTrue,
          reason: '$id : la fiche doit conclure par $expected',
        );
      });
    });

    test('les bilans d’Euclide sont arithmétiquement exacts', () {
      // Chaque ligne « a = b × q + r » du contenu doit être VRAIE, et non
      // seulement bien écrite. On balaie toute la leçon 2 : la méthode
      // d'Euclide s'y exprime par des bilans.
      final lignes = <String>[
        for (final id in <String>[
          ExerciseIds.ex5,
          ExerciseIds.ex6,
          ExerciseIds.ex7,
        ])
          ...Chapter1Bank.findExercise(id)!
              .orderedRichHints
              .expand((h) => h.blocks)
              .map((b) => b.text),
      ];

      var verifiees = 0;
      for (final ligne in lignes) {
        final m = RegExp(r'(\d+)\s*=\s*\(?(\d+)\s*×\s*(\d+)\)?\s*\+\s*(\d+)')
            .firstMatch(ligne);
        if (m == null) continue;
        final a = int.parse(m.group(1)!);
        final b = int.parse(m.group(2)!);
        final q = int.parse(m.group(3)!);
        final r = int.parse(m.group(4)!);
        expect(a, b * q + r, reason: ligne);
        expect(r, lessThan(b), reason: 'un reste est plus petit que son '
            'diviseur : $ligne');
        verifiees++;
      }
      expect(verifiees, greaterThanOrEqualTo(8),
          reason: 'les bilans de la leçon 2 doivent tous etre verifies');
    });
  });
}