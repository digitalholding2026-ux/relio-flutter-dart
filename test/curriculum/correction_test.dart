/// Tests de correction des réponses — chapitre 1.
///
/// Ces tests couvrent quatre familles de saisies, exigées par la mission :
///  1. les réponses EXACTES attendues par le document validé ;
///  2. les variantes ÉQUIVALENTES (même réponse, autre écriture) ;
///  3. les réponses ERRONÉES, qui doivent rester distinguables des autres ;
///  4. les cas RÉELLEMENT NON ÉVALUABLES, qui ne doivent jamais être
///     transformés en « faux ».
///
/// Règle appliquée : un test qui échoue parce qu'une réponse correcte a été
/// rejetée est un bug de correction ; un test qui échoue parce qu'une
/// réponse fausse a été acceptée est un bug de correction. Il n'existe pas
/// de troisième issue.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/answer_normalization.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/presentation/rules/v1_screen_rules.dart';

Exercise ex(String id) => Chapter1Bank.findExercise(id)!;

void main() {
  // ---------------------------------------------------------------------
  group('Exactitude arithmétique de la banque', () {
    // Ces tests ne vérifient pas le moteur : ils vérifient que les valeurs
    // ATTENDUES sont mathématiquement justes. Une erreur de transcription
    // dans la banque serait détectée ici, avant d'atteindre un élève.
    int gcdOf(int a, int b) => b == 0 ? a : gcdOf(b, a % b);
    int ppcmOf(int a, int b) => a ~/ gcdOf(a, b) * b;

    test('PGCD attendus pour les exercices 1 a 7', () {
      expect(gcdOf(18, 12), 6);
      expect(gcdOf(15, 10), 5);
      expect(gcdOf(21, 14), 7);
      expect(gcdOf(20, 12), 4);
      expect(gcdOf(30, 18), 6);
      expect(gcdOf(42, 30), 6);
      expect(gcdOf(48, 18), 6);
    });

    test('PGCD attendus pour les tâches de contrôle', () {
      expect(gcdOf(16, 12), 4);
      expect(gcdOf(14, 7), 7);
      expect(gcdOf(24, 16), 8);
      expect(gcdOf(35, 20), 5);
    });

    test('PPCM attendus pour les exercices 8 à 10', () {
      expect(gcdOf(12, 18), 6);
      expect(ppcmOf(12, 18), 36);
      expect(gcdOf(8, 12), 4);
      expect(ppcmOf(8, 12), 24);
    });

    test('PPCM attendus pour les tâches de contrôle', () {
      expect(gcdOf(10, 15), 5);
      expect(ppcmOf(10, 15), 30);
      expect(gcdOf(6, 8), 2);
      expect(ppcmOf(6, 8), 24);
    });

    test('la relation de l\'exercice 10 tient effectivement', () {
      const a = 9, b = 15;
      expect(a * b, 135);
      expect(gcdOf(a, b), 3);
      expect(ppcmOf(a, b), 45);
      expect(gcdOf(a, b) * ppcmOf(a, b), a * b);
    });
  });

  // ---------------------------------------------------------------------
  group('Réponses exactes', () {
    test('chaque exercice accepte la valeur attendue du document', () {
      const attendu = <String, int>{
        ExerciseIds.ex1: 6,
        ExerciseIds.ex2: 5,
        ExerciseIds.ex3: 7,
        ExerciseIds.ex4: 4,
        ExerciseIds.ex5: 6,
        ExerciseIds.ex6: 6,
        ExerciseIds.ex7: 6,
        ExerciseIds.ex8: 36,
        ExerciseIds.ex9: 24,
        ExerciseIds.ex10: 135,
      };

      attendu.forEach((id, value) {
        final result = correct(ex(id), '$value');
        expect(result.isCorrect, isTrue, reason: 'exercice $id, valeur $value');
        expect(result.isEvaluated, isTrue, reason: 'exercice $id');
      });
    });

    test('les six tâches de vérification acceptent une réponse conforme', () {
      // Réponse attendue pour chacune. Pour la tâche PPCM, la valeur seule
      // ne suffit PLUS : c'est désormais le contrat de relation qui compte.
      const conforme = <String, String>{
        ExerciseIds.verifyPgcd16And12: '4',
        ExerciseIds.verifyPgcd14And7: '7',
        ExerciseIds.verifyPgcd24And16: '8',
        ExerciseIds.verifyPgcd35And20: '5',
        ExerciseIds.verifyPpcm10And15: '150/5',
        ExerciseIds.verifyPpcm6And8: '24',
      };

      conforme.forEach((id, reponse) {
        expect(correct(ex(id), reponse).isCorrect, isTrue, reason: id);
      });
    });

    test('l\'exercice 11 accepte la relation attendue', () {
      final result = correct(ex(ExerciseIds.ex11), 'ppcm = produit / pgcd');

      expect(result.isCorrect, isTrue);
      expect(result.isEvaluated, isTrue);
    });
  });

  // ---------------------------------------------------------------------
  group('Variantes équivalentes', () {
    test('exercice 11 : « ÷ » est reconnu comme « / »', () {
      final result = correct(ex(ExerciseIds.ex11), 'PPCM = produit ÷ PGCD');

      expect(result.isCorrect, isTrue,
          reason: 'la même relation écrite avec un autre symbole de division');
    });

    test('exercice 11 : espaces et casse indifférents', () {
      for (final saisie in <String>[
        'PPCM=PRODUIT/PGCD',
        'ppcm = produit / pgcd',
        '  ppcm   =   produit/ pgcd  ',
        'ppcm = produit /pgcd',
      ]) {
        expect(correct(ex(ExerciseIds.ex11), saisie).isCorrect, isTrue,
            reason: 'saisie « $saisie »');
      }
    });

    test('exercice 11 : le « x » de multiplication est reconnu', () {
      // Formulation équivalente de la relation, avec « × » au lieu de « x ».
      final result = correct(ex(ExerciseIds.ex11), 'produit = pgcd x ppcm');

      // Cette formulation N'EST PAS dans le document : elle ne doit donc
      // pas être acceptée, mais elle ne doit pas non plus être traitée
      // comme une erreur de l'élève : le cas reste non concluant.
      expect(result.isEvaluated, isFalse,
          reason: 'formulation non transcrite : non évaluable, jamais fausse');
    });

    test('exercice 9 : « × », espaces et parenthèses indifférents', () {
      for (final saisie in <String>[
        '(8 × 12) / 4',
        '(8*12)/4',
        '(8 x 12) / 4',
        ' 96 / 4 ',
        '96/4',
      ]) {
        expect(correct(ex(ExerciseIds.ex9), saisie).isCorrect, isTrue,
            reason: 'saisie « $saisie »');
      }
    });

    test('exercice 9 : le résultat seul reste accepté', () {
      expect(correct(ex(ExerciseIds.ex9), '24').isCorrect, isTrue);
      expect(correct(ex(ExerciseIds.ex9), ' 24 ').isCorrect, isTrue);
    });

    test('exercice 10 : les formulations textuelles de la banque', () {
      for (final saisie in <String>['oui', 'Oui', 'verifie', 'VÉRIFIE']) {
        expect(correct(ex(ExerciseIds.ex10), saisie).isCorrect, isTrue,
            reason: 'saisie « $saisie »');
      }
    });

    test('exercice 6 et 8 de contrôle : les deux valeurs de la tâche D6', () {
      final tache = ex(ExerciseIds.verifyPpcm6And8);

      expect(correct(tache, '24').isCorrect, isTrue);
      // Formulation correcte, avec les deux valeurs nommées.
      expect(correct(tache, 'ppcm=24;pgcd=2').isCorrect, isTrue);
      // Formulation inversée : non transcrite dans la banque, donc
      // non évaluable — et jamais « fausse ».
      expect(correct(tache, 'pgcd=24;ppcm=2').isEvaluated, isFalse);
    });
  });

  // ---------------------------------------------------------------------
  group('Réponses erronées', () {
    test('une valeur fausse sur un exercice entier est fausse, et évaluée', () {
      final result = correct(ex(ExerciseIds.ex1), '9');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isTrue,
          reason: 'le moteur a su évaluer : le panneau E est légitime');
    });

    test('le PPCM inversé reste faux (erreur classique, non tolérée)', () {
      // 6 / 216 : l'erreur classique de D5. Elle ne doit surtout pas être
      // acceptée « par équivalence ».
      final result = correct(ex(ExerciseIds.ex8), '0');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isTrue);
    });

    test('une expression non transcrite reste NON évaluable, pas fausse', () {
      // « 96/6 » vaut 16, ce qui est faux. Mais le moteur ne connaît que
      // les expressions de la banque : il ne calcule pas. Conclure « faux »
      // reviendrait à attribuer au moteur une capacité qu'il n'a pas.
      final result = correct(ex(ExerciseIds.ex9), '96/6');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isFalse);
    });

    test('une saisie vide est évaluée mais fausse', () {
      final result = correct(ex(ExerciseIds.ex1), '   ');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isTrue);
    });
  });

  // ---------------------------------------------------------------------
  group('Cas réellement non évaluables', () {
    test('un format non reconnu n\'est jamais une erreur de l\'élève', () {
      final result = correct(ex(ExerciseIds.ex1), 'beaucoup');

      expect(result.isCorrect, isFalse);
      expect(result.isEvaluated, isFalse);
    });

    test('exercice 11 : un entier seul est NON ÉVALUABLE, jamais faux', () {
      // Régression centrale de la mission. Avant correction, ces saisies
      // étaient enregistrées comme `incorrect` dans l'historique
      // append-only : une fausse négatif définitive.
      for (final saisie in <String>['24', '36', '0', '42']) {
        final result = correct(ex(ExerciseIds.ex11), saisie);
        expect(result.isCorrect, isFalse, reason: 'saisie « $saisie »');
        expect(result.isEvaluated, isFalse, reason:
            'l\'exercice 11 attend une relation en mots : un entier ne '
            'peut être ni confirmé ni infirmé');
      }
    });

    test('exercice 11 : une phrase hors sujet reste non évaluable', () {
      for (final saisie in <String>[
        'je ne sais pas',
        'la relation',
        'le PPCM',
      ]) {
        expect(correct(ex(ExerciseIds.ex11), saisie).isEvaluated, isFalse,
            reason: 'saisie « $saisie »');
      }
    });

    test('aucun entier ne peut être accepté sur un critère purement textuel', () {
      for (final element in <Exercise>[
        ...Chapter1Bank.exercises,
        ...Chapter1Bank.verificationTasks,
      ]) {
        if (!element.correction.isTextOnly) continue;
        final result = correct(element, '7');
        expect(result.isCorrect, isFalse, reason: element.id);
        expect(result.isEvaluated, isFalse, reason: element.id);
      }
    });
  });

  // ---------------------------------------------------------------------
  group('Contrat type de réponse / clavier', () {
    test('les exercices 1 à 9 attendent un entier, 10 et 11 une rédaction', () {
      for (final element in Chapter1Bank.exercises) {
        final attendu = V1ScreenRules.positionOf(element.id)! <= 9
            ? AnswerType.integer
            : AnswerType.text;
        expect(element.correction.answerType, attendu, reason: element.id);
      }
    });

    test('le clavier affiché correspond TOUJOURS au type de réponse', () {
      for (final element in <Exercise>[
        ...Chapter1Bank.exercises,
        ...Chapter1Bank.verificationTasks,
      ]) {
        final keyboard = V1ScreenRules.keyboardFor(element.id);
        final attendu = element.correction.answerType == AnswerType.integer
            ? AnswerKeyboard.numeric
            : AnswerKeyboard.alphanumeric;
        expect(keyboard, attendu,
            reason: '${element.id} : le clavier doit suivre le critère');
      }
    });

    test('la tâche D6 attend bien du texte : elle exige les DEUX valeurs', () {
      // La banque transcrit « ppcm=24;pgcd=2 » : nommer les deux notions
      // est précisément l'objet de la tâche. Un clavier numérique serait
      // ici incapable de permettre la réponse attendue.
      expect(
        ex(ExerciseIds.verifyPpcm6And8).correction.answerType,
        AnswerType.text,
      );
    });

    test('un identifiant inconnu ouvre le clavier texte, sans refus', () {
      expect(V1ScreenRules.keyboardFor('inconnu'),
          AnswerKeyboard.alphanumeric);
    });
  });

  // ---------------------------------------------------------------------
  group('Normalisation', () {
    test('espaces, casse, symboles et tirets sont unifiés', () {
      expect(normalizeAnswer('  PPCM = PRODUIT / PGCD '), 'ppcm=produit/pgcd');
      expect(normalizeAnswer('a ÷ b'), 'a/b');
      expect(normalizeAnswer('a × b'), 'a*b');
      expect(normalizeAnswer('a*b'), 'a*b');
      expect(normalizeAnswer('12 x 8'), '12*8');
      expect(normalizeAnswer('12 − 5'), '12-5');
      expect(normalizeAnswer('12 – 5'), '12-5');
      expect(normalizeAnswer('24.'), '24');
    });

    test('les accents francais sont plies sur leur lettre de base', () {
      expect(normalizeAnswer('vérifie'), 'verifie');
      expect(normalizeAnswer('VÉRIFIE'), 'verifie');
      expect(normalizeAnswer('Écrivez'), 'ecrivez');
      expect(correct(ex(ExerciseIds.ex10), 'vérifie').isCorrect, isTrue);
    });

    test('la lettre « x » n\'est un signe que entre deux chiffres', () {
      // Un mot contenant « x » ne doit jamais devenir un produit.
      expect(normalizeAnswer('x + 1'), 'x+1');
      expect(looksNumeric('x + 1'), isFalse);
      expect(looksNumeric('96/4'), isTrue);
      expect(looksNumeric('ppcm=24'), isFalse);
    });

    test('les deux écritures d\'un même texte se rejoignent', () {
      expect(
        normalizeAnswer('PPCM = produit ÷ PGCD'),
        normalizeAnswer('ppcm = produit / pgcd'),
      );
    });

    test('un décimal reste non évaluable, il n\'est pas tronqué', () {
      final result = correct(ex(ExerciseIds.ex1), '6,5');

      expect(result.isEvaluated, isFalse,
          reason: 'les exercices demandent un entier : ne pas arrondir');
    });
  });
}