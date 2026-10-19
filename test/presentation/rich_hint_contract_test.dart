/// Budget d'aide et dérivation mécanique des fiches.
///
/// Ces tests verrouillent deux contrats :
///
///  1. le libellé du bouton est une consequence UNIQUE du budget ;
///  2. la dérivation `ExerciseHint` → `RichHint` ne modifie AUCUN mot.
///
/// Les fiches de test sont des MOCKS explicites : elles vérifient la forme,
/// jamais un contenu pedagogique. La banque de production n'est pas touchee.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/rich_hint.dart';
import 'package:relio/domain/curriculum/rich_hint_adapter.dart';

void main() {
  group('HintBudget — le libellé est univoque', () {
    test('budget intact : premier libellé', () {
      const budget = HintBudget(maxHintsAllowed: 3, hintsConsumed: 0);
      expect(budget.cta, HintCta.askFirst);
      expect(budget.remaining, 3);
      expect(budget.isExhausted, isFalse);
    });

    test('milieu de budget : « Indice suivant »', () {
      const budget = HintBudget(maxHintsAllowed: 3, hintsConsumed: 1);
      expect(budget.cta, HintCta.next);
      expect(budget.remaining, 2);
    });

    test('il reste exactement une fiche : « Indice final »', () {
      const budget = HintBudget(maxHintsAllowed: 3, hintsConsumed: 2);
      expect(budget.cta, HintCta.finalOne);
      expect(budget.remaining, 1);
      expect(budget.isExhausted, isFalse);
    });

    test('budget épuisé, exercice précédent : relecture', () {
      const budget = HintBudget(
        maxHintsAllowed: 3,
        hintsConsumed: 3,
        previousExerciseId: 'D1',
      );
      expect(budget.cta, HintCta.reviewPrevious);
      expect(budget.isExhausted, isTrue);
    });

    test('budget épuisé SANS précédent : le bouton disparaît', () {
      const budget = HintBudget(maxHintsAllowed: 2, hintsConsumed: 2);
      expect(budget.cta, HintCta.none);
    });

    test('budget de 1 fiche : le premier clic est déjà le final', () {
      // Cas limite : avec une seule fiche, `hintsConsumed == 0` ET il ne reste
      // qu'une. Le premier libellé doit primer, sinon l'élève ne verrait jamais
      // « Demander un indice ».
      const budget = HintBudget(maxHintsAllowed: 1, hintsConsumed: 0);
      expect(budget.cta, HintCta.askFirst);
      expect(budget.remaining, 1);
    });

    test('budget dépassé : épuisé, jamais négatif', () {
      const budget = HintBudget(maxHintsAllowed: 2, hintsConsumed: 5);
      expect(budget.isExhausted, isTrue);
      expect(budget.remaining, 0);
    });

    test('les quatre cas couvrent tout l’espace, sans recouvrement', () {
      // Propriété de couverture : pour tout couple (max, consommé), un seul
      // état s'applique, et l'état est bien celui qu'on attend.
      for (var max = 0; max <= 4; max++) {
        for (var consumed = 0; consumed <= 5; consumed++) {
          final budget = HintBudget(
            maxHintsAllowed: max,
            hintsConsumed: consumed,
            previousExerciseId: 'D1',
          );
          final expected = switch (true) {
            _ when consumed >= max => HintCta.reviewPrevious,
            _ when consumed == 0 => HintCta.askFirst,
            _ when max - consumed == 1 => HintCta.finalOne,
            _ => HintCta.next,
          };
          expect(budget.cta, expected,
              reason: 'max=$max consommé=$consumed');
        }
      }
    });
  });

  group('Dérivation — aucun mot n’est inventé', () {
    test('le texte de l’indice est repris tel quel', () {
      const hint = ExerciseHint(
        order: 1,
        text: 'Soustrais le plus petit nombre du plus grand.',
        kind: 'methode',
      );

      final rich = hint.asRichHint();

      expect(rich.order, 1);
      expect(rich.blocks, hasLength(1));
      // Le texte EST celui de la source, pas une reformulation.
      expect(rich.blocks.single.text,
          'Soustrais le plus petit nombre du plus grand.');
    });

    test('le rang et l’identifiant restent ceux de la banque', () {
      const hint = ExerciseHint(order: 2, text: 'Travaille avec 12 et 6.');
      final rich = hint.asRichHint();
      expect(rich.order, 2);
      // Même convention que `ExerciseHint.hintId` : les deux représentations
      // d'un même indice restent joignables dans l'historique.
      expect(rich.hintId, hint.hintId);
      expect(rich.hintId, 'h2');
    });

    test('un texte sans notation mathématique devient un TextBlock', () {
      expect(
        blockFor('Soustrais le plus petit nombre du plus grand.'),
        isA<TextBlock>(),
      );
    });

    test('un texte avec opérateur devient un MathBlock', () {
      expect(blockFor('18 − 12 = 6'), isA<MathBlock>());
      expect(blockFor('PGCD(12, 18) = 6'), isA<MathBlock>());
    });

    test('un nombre seul n’est PAS une formule', () {
      // « prends 18 » porte une DONNÉE, pas un calcul : l'encadré mathématique
      // dirait à tort « voici la formule ».
      expect(blockFor('Prends 18.'), isA<TextBlock>());
    });

    test('le dérivateur ne complète jamais une fiche vide', () {
      const hint = ExerciseHint(order: 1, text: '');
      final rich = hint.asRichHint();
      expect(rich.blocks, hasLength(1));
      expect(rich.blocks.single.text, isEmpty);
    });
  });

  group('Dérivation sur la banque de production', () {
    test('les 11 exercices dérivent sans erreur ni contenu ajouté', () {
      final exercises = Chapter1Bank.exercises
          .where((e) => e.kind == BankElementKind.exercise)
          .toList();
      expect(exercises, isNotEmpty);

      for (final exercise in exercises) {
        for (final hint in exercise.orderedHints) {
          final rich = hint.asRichHint();
          // AUCUNE réécriture : le texte rendu est exactement celui de la
          // source pédagogique.
          expect(rich.blocks.map((b) => b.text), contains(hint.text),
              reason: '${exercise.id} #${hint.order}');
        }
      }
    });

    test('le dernier indice d’un exercice est marqué « final »', () {
      final exercises = Chapter1Bank.exercises
          .where((e) => e.kind == BankElementKind.exercise)
          .toList();

      for (final exercise in exercises) {
        final rich = richHintsOf(exercise);
        if (rich.isEmpty) continue;
        expect(rich.last.isFinal, isTrue, reason: exercise.id);
        // Une fiche unique est à la fois la première et la dernière : il n'y a
        // alors aucune fiche « précédente » à ne pas marquer finale.
        if (rich.length > 1) {
          expect(rich.first.isFinal, isFalse, reason: exercise.id);
        }
      }
    });

    test('la dérivation partielle ne retient que les indices consommés', () {
      final exercise = Chapter1Bank.exercises
          .firstWhere((e) => e.orderedHints.length >= 2);

      final rich = richHintsOf(exercise, consumedOrders: <int>{1});
      expect(rich, hasLength(1));
      expect(rich.single.order, 1);
    });

    test('un exercice sans indice ne produit aucune fiche', () {
      // `hintCount` et non `orderedHints` : un exercice peut n'avoir aucune
      // fiche définitive tout en gardant des indices hérités, et l'inverse
      // aussi. C'est le nombre RÉEL d'indices qui décide.
      final exercise = Chapter1Bank.exercises
          .firstWhere((e) => e.hintCount == 0, orElse: () => const Exercise(
                id: 'vide',
                lesson: ArithmeticLesson.lesson1Subtractions,
                statement: '',
                correction: CorrectionCriterion(),
              ));
      expect(richHintsOf(exercise), isEmpty);
    });
  });
}