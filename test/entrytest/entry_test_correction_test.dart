/// Test d'entree — evaluation des reponses.
///
/// Verifie les TROIS issues, et surtout qu'elles ne se confondent pas :
/// une reponse fausse reste « evaluable », une reponse illisible reste
/// « non evaluable ». Confondre les deux fabriquerait une difficulty qui
/// n'existe pas.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/entrytest/entry_test_correction.dart';
import 'package:relio/domain/entrytest/entry_test_question.dart';

void main() {
  const EntryTestEvaluator evaluator = EntryTestEvaluator();

  /// Correcte ET evaluable.
  void expectCorrect(EntryTestCorrection c) {
    expect(c.isCorrect, isTrue, reason: 'la reponse doit etre correcte');
    expect(c.isEvaluated, isTrue, reason: 'elle doit etre evaluable');
  }

  /// Incorrecte MAIS evaluable.
  void expectEvaluableIncorrect(EntryTestCorrection c) {
    expect(c.isCorrect, isFalse, reason: 'la reponse doit etre fausse');
    expect(c.isEvaluated, isTrue, reason: 'elle doit rester EVALUABLE');
  }

  /// Aucune conclusion possible.
  void expectNotEvaluated(EntryTestCorrection c) {
    expect(c.isCorrect, isFalse);
    expect(c.isEvaluated, isFalse, reason: 'elle ne doit etre ni juste ni fausse');
    expect(c.isIndeterminate, isTrue);
  }

  group('Banque', () {
    test('contient exactement cinq questions', () {
      expect(EntryTestBank.questions.length, 5);
    });

    test('l\'ordre est 1, 2, 3, 4, 5 et n\'est pas suppose', () {
      expect(EntryTestBank.questions.map((EntryTestQuestion q) => q.order),
          <int>[1, 2, 3, 4, 5]);
    });

    test('les identifiants sont uniques et stables', () {
      expect(EntryTestBank.questionIds.toSet().length, 5);
      expect(EntryTestBank.questionIds,
          <String>['entry-q1', 'entry-q2', 'entry-q3', 'entry-q4', 'entry-q5']);
    });

    test('seule la question 2 est a choix multiple', () {
      final Iterable<EntryTestQuestion> choices = EntryTestBank.questions
          .where((EntryTestQuestion q) => q.isChoice);
      expect(choices.map((EntryTestQuestion q) => q.id), <String>['entry-q2']);
    });

    test('les reponses attendues correspondent au contenu valide', () {
      expect(EntryTestBank.q1.expectedValue, '7');
      expect(EntryTestBank.q2.expectedValue, '2/4');
      expect(EntryTestBank.q2.choices, <String>['2/3', '2/4', '3/4']);
      expect(EntryTestBank.q3.expectedValue, '2');
      expect(EntryTestBank.q4.expectedValue, '7');
      expect(EntryTestBank.q5.expectedValue, '5');
    });

    test('une question introuvable rend null, pas une exception', () {
      expect(EntryTestBank.find('inexistant'), isNull);
      expect(EntryTestBank.find('entry-q3')?.order, 3);
    });
  });

  group('Q1 — 24 ÷ 6 + 3, reponse attendue 7', () {
    const EntryTestQuestion q = EntryTestBank.q1;

    test('la reponse attendue est correcte et evaluable', () {
      expectCorrect(evaluator.evaluate(q, '7'));
    });

    test('une reponse fausse mais lisible est evaluable', () {
      expectEvaluableIncorrect(evaluator.evaluate(q, '6'));
      expectEvaluableIncorrect(evaluator.evaluate(q, '27'));
    });

    test('une saisie illisible n\'est PAS une erreur mathematique', () {
      expectNotEvaluated(evaluator.evaluate(q, 'sept'));
      expectNotEvaluated(evaluator.evaluate(q, '7/0'));
      expectNotEvaluated(evaluator.evaluate(q, ''));
      expectNotEvaluated(evaluator.evaluate(q, '   '));
      expectNotEvaluated(evaluator.evaluate(q, null));
    });
  });

  group('Q2 — fractions, reponse attendue 2/4', () {
    const EntryTestQuestion q = EntryTestBank.q2;

    test('2/4 est correcte', () {
      expectCorrect(evaluator.evaluate(q, '2/4'));
    });

    test('les autres choix sont evaluables et incorrects', () {
      expectEvaluableIncorrect(evaluator.evaluate(q, '2/3'));
      expectEvaluableIncorrect(evaluator.evaluate(q, '3/4'));
    });

    test('un choix ABSENT de la liste n\'est pas evaluable', () {
      // Point central : un choix hors contrat n'est pas une faute de l'eleve,
      // c'est une saisie qui ne correspond a rien de propose.
      expectNotEvaluated(evaluator.evaluate(q, '1/2'));
      expectNotEvaluated(evaluator.evaluate(q, '4/8'));
      expectNotEvaluated(evaluator.evaluate(q, 'peut-etre'));
    });

    test('une valeur absente n\'est pas evaluable', () {
      expectNotEvaluated(evaluator.evaluate(q, ''));
      expectNotEvaluated(evaluator.evaluate(q, null));
    });

    test('le choix correct reste correct avec des espaces parasite', () {
      expectCorrect(evaluator.evaluate(q, '  2/4  '));
    });
  });

  group('Q3 — (-3) + 5, reponse attendue 2', () {
    const EntryTestQuestion q = EntryTestBank.q3;

    test('la reponse attendue est correcte', () {
      expectCorrect(evaluator.evaluate(q, '2'));
    });

    test('une reponse fausse mais lisible reste evaluable', () {
      // -8 est ce qu'on obtient si l'on fait 3 + 5 : c'est une erreur
      // d'interet PRECIS, et le moteur peut le constater factuellement.
      expectEvaluableIncorrect(evaluator.evaluate(q, '8'));
      expectEvaluableIncorrect(evaluator.evaluate(q, '-8'));
      expectEvaluableIncorrect(evaluator.evaluate(q, '0'));
    });

    test('l\'expression elle-meme n\'est pas ce qui est attendu', () {
      // Le moteur compare une VALEUR, il n'evalue pas (-3)+5. C'est
      // volontaire : il n'a pas a savoir calculer pour verifier la reponse.
      expectNotEvaluated(evaluator.evaluate(q, '(-3)+5'));
      expectNotEvaluated(evaluator.evaluate(q, '-3+5'));
    });
  });

  group('Q4 — 2x+1 avec x=3, reponse attendue 7', () {
    const EntryTestQuestion q = EntryTestBank.q4;

    test('la reponse attendue est correcte', () {
      expectCorrect(evaluator.evaluate(q, '7'));
    });

    test('une reponse fausse mais lisible reste evaluable', () {
      // 9 correspond au calcul « on a pose x=1 ».
      expectEvaluableIncorrect(evaluator.evaluate(q, '9'));
      expectEvaluableIncorrect(evaluator.evaluate(q, '6'));
    });

    test('une saisie illisible n\'est pas evaluable', () {
      expectNotEvaluated(evaluator.evaluate(q, '2x+1'));
      expectNotEvaluated(evaluator.evaluate(q, 'sept'));
    });
  });

  group('Q5 — x+4=9, reponse attendue 5', () {
    const EntryTestQuestion q = EntryTestBank.q5;

    test('la reponse attendue est correcte', () {
      expectCorrect(evaluator.evaluate(q, '5'));
    });

    test('une reponse fausse mais lisible reste evaluable', () {
      // 13 correspond au calcul « 9 + 4 ».
      expectEvaluableIncorrect(evaluator.evaluate(q, '13'));
      expectEvaluableIncorrect(evaluator.evaluate(q, '4'));
    });

    test('l\'equation n\'est pas evaluee, seulement la valeur', () {
      expectNotEvaluated(evaluator.evaluate(q, 'x+4=9'));
      expectNotEvaluated(evaluator.evaluate(q, 'x'));
    });
  });

  group('Normalisation', () {
    const EntryTestQuestion q = EntryTestBank.q1;

    test('les espaces en trop sont ignores sur un entier', () {
      expect(evaluator.normalize(q, '  7 '), '7');
      expect(evaluator.normalize(q, ' 7 '), '7');
      expectCorrect(evaluator.evaluate(q, ' 7 '));
    });

    test('un entier separe par des espaces reste un entier', () {
      // « 2 1 » et « 21 » sont la meme saisie.
      expect(evaluator.normalize(q, '21'), '21');
      expectEvaluableIncorrect(evaluator.evaluate(q, '2 1'));
    });

    test('la normalisation ne resout rien par elle-meme', () {
      // Une regle de normalisation plus tolerante fusionnerait des saisies
      // differentes et masquerait le fait que l'eleve a ecrit autre chose.
      expectNotEvaluated(evaluator.evaluate(q, '7 km'));
      expectNotEvaluated(evaluator.evaluate(q, 'sept'));
    });

    test('une reponse nulle se normalise en chaine vide', () {
      expect(evaluator.normalize(q, null), '');
    });
  });

  group('Isolation pedagogique', () {
    test('l\'evaluation ne leve aucun effet de bord observable', () {
      // L'evaluation est une fonction PURE : aucun evenement, aucune
      // relecture, aucun service du chapitre 1 n'est sollicite. Elle peut
      // donc etre appelee autant de fois que voulu sans rien produire.
      for (int i = 0; i < 100; i++) {
        final EntryTestCorrection a = evaluator.evaluate(EntryTestBank.q1, '7');
        final EntryTestCorrection b = evaluator.evaluate(EntryTestBank.q1, '7');
        expect(a.isCorrect, b.isCorrect);
        expect(a.isEvaluated, b.isEvaluated);
      }
    });

    test('le resultat est un fait, pas une classification pedagogique', () {
      // Le chapitre 1 classe une tentative en `AttemptClassification`
      // (reussite autonome, assistee, incomplete...). Ce type n'apparait
      // RIEN ici : le test d'entree n'a ni succes autonome ni succes
      // assiste a distinguer, puisqu'il n'y a ni indice ni rejeu.
      final EntryTestCorrection c = evaluator.evaluate(EntryTestBank.q1, '7');
      expect(c.runtimeType, EntryTestCorrection);
      expect(c.isIndeterminate, isFalse);
    });

    test('une reponse non evaluable ne contient aucun code d\'erreur', () {
      final EntryTestCorrection c = evaluator.evaluate(EntryTestBank.q1, 'sept');
      expect(c.isIndeterminate, isTrue);
      expect(c.matchedValue, isNull,
          reason: 'une reponse non evaluable ne retient aucune valeur');
    });
  });

  group('Coherence sur les cinq questions', () {
    test('exactement une reponse attendue par question est correcte', () {
      for (final EntryTestQuestion q in EntryTestBank.questions) {
        expectCorrect(evaluator.evaluate(q, q.expectedValue));
      }
    });

    test('une valeur hors liste n\'est jamais traitee comme fausse', () {
      for (final EntryTestQuestion q in EntryTestBank.questions) {
        expectNotEvaluated(evaluator.evaluate(q, '???'));
      }
    });
  });
}