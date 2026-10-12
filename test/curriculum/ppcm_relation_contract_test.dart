/// Tests du contrat « la relation PPCM–PGCD a été APPLIQUÉE ».
///
/// Cible : la tâche `ch1-verify-ppcm-10-15`.
///
/// Ce qui est vérifié ici, et qui est le cœur de la mission :
///  - la valeur `30` seule ne vaut PLUS preuve ;
///  - une écriture montrant réellement la division produit ÷ PGCD est
///    acceptée, y compris sous des formes que la banque n'énumère pas ;
///  - une erreur de calcul écrite reste un ÉCHEC évaluable ;
///  - une écriture non comprise ne devient jamais une difficulté.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/arithmetic_expression.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/curriculum/transfer_verification.dart';

Exercise tache() => Chapter1Bank.findExercise(ExerciseIds.verifyPpcm10And15)!;

void main() {
  // =====================================================================
  group('1. La valeur seule ne suffit PLUS', () {
    test('`30` seul n\'est pas accepté', () {
      final resultat = correct(tache(), '30');

      expect(resultat.isCorrect, isFalse);
    });

    test('`30` seul n\'est même pas déclaré FAUX', () {
      final resultat = correct(tache(), '30');

      // Ni juste ni faux : on ne peut pas conclure. C'est la différence
      // essentielle avec l'ancien contrat.
      expect(resultat.isEvaluated, isFalse,
          reason: 'le bon résultat sans démonstration ne prouve rien, mais '
              'ce n\'est pas une erreur de l\'élève');
    });

    test('aucune variante en clair du résultat seul n\'est acceptée', () {
      for (final reponse in <String>['30', ' 30 ', '030']) {
        expect(correct(tache(), reponse).isCorrect, isFalse, reason: reponse);
        expect(correct(tache(), reponse).isEvaluated, isFalse,
            reason: reponse);
      }
    });

    test('le critère n\'accepte plus aucune valeur entière', () {
      expect(tache().correction.acceptedValues, isEmpty);
    });
  });

  // =====================================================================
  group('2. Une réponse démontrant la relation est acceptée', () {
    test('les écritures canoniques', () {
      const reponses = <String>[
        '10*15/5',
        '(10*15)/5',
        '150/5',
        '10*15÷5',
        '150 ÷ 5',
        '10 × 15 / 5',
        '10*15/5 = 30',
        '150/5 = 30',
      ];

      for (final reponse in reponses) {
        final resultat = correct(tache(), reponse);
        expect(resultat.isCorrect, isTrue, reason: reponse);
        expect(resultat.isEvaluated, isTrue, reason: reponse);
        expect(resultat.matchedValue, 30, reason: reponse);
      }
    });

    test('la valeur attendue est bien PPCM(10, 15)', () {
      final relation = tache().correction.ppcmRelation!;

      expect(relation.first, 10);
      expect(relation.second, 15);
      expect(relation.divisor, 5);
      expect(relation.result, 30);
      expect(relation.isCoherent, isTrue,
          reason: '5 est bien le PGCD(10, 15), et 10*15/5 = 30');
    });
  });

  // =====================================================================
  group('3. Une formule incorrecte est refusée', () {
    test('une division qui donne autre chose', () {
      final resultat = correct(tache(), '10*15/6');

      expect(resultat.isCorrect, isFalse);
      expect(resultat.isEvaluated, isTrue,
          reason: 'le calcul est écrit et cohérent : un calcul faux est un '
              'fait, pas une incertitude');
    });

    test('la division inversée — erreur classique de D5', () {
      // 5/(10*15) : la confusion même que D5 traque.
      final resultat = correct(tache(), '5/(10*15)');

      expect(resultat.isCorrect, isFalse);
      expect(resultat.isEvaluated, isTrue);
    });

    test('une égalité dont le membre de droite est faux', () {
      final resultat = correct(tache(), '10*15/5 = 25');

      expect(resultat.isCorrect, isFalse);
      expect(resultat.isEvaluated, isTrue);
    });
  });

  // =====================================================================
  group('4. Formule correcte, résultat final incorrect', () {
    test('le membre de gauche juste ne rachète pas un membre droit faux', () {
      // C'est le piège classique : l'élève écrit le bon calcul, puis annonce
      // un mauvais résultat. La réussite ne doit pas être déclarée.
      final resultat = correct(tache(), '10*15/5 = 25');

      expect(resultat.isEvaluated, isTrue);
      expect(resultat.isCorrect, isFalse);
      expect(resultat.matchedValue, isNull);
    });

    test('un produit faux divisé par le bon PGCD est un échec', () {
      final resultat = correct(tache(), '15*10/5');

      // 15*10/5 = 30 : le compte est bon, la multiplication aussi. Ce n'est
      // PAS un échec — la relation est bien appliquée.
      expect(resultat.isCorrect, isTrue);
    });

    test('un produit faux donne bien un échec', () {
      final resultat = correct(tache(), '20*15/5'); // = 60

      expect(resultat.isEvaluated, isTrue);
      expect(resultat.isCorrect, isFalse);
    });
  });

  // =====================================================================
  group('5. Formes équivalentes : documentées et testées', () {
    test('le calcul est ÉVALUÉ, pas comparé à une liste', () {
      // Aucune de ces formes n'est énumérée dans la banque : elles sont
      // acceptées parce que l'évaluateur les calcule.
      const equivalentes = <String>[
        '10*15/5',
        '15*10/5',
        '150/5',
        '((10*15))/5',
        '300/10',
        '(10*15)/5*1',
      ];

      for (final reponse in equivalentes) {
        expect(correct(tache(), reponse).isCorrect, isTrue, reason: reponse);
      }
    });

    test('le facteur « x » n\'est PAS un signe : il rend l\'écriture non évaluable',
        () {
      // `10x15/5` contient une lettre : le formateur ne devine pas. Mieux
      // vaut non évaluable qu'un risque de confusion avec une lettre.
      final resultat = correct(tache(), '10x15/5');

      expect(resultat.isEvaluated, isFalse);
      expect(resultat.isCorrect, isFalse);
    });

    test('l\'évaluateur d\'expressions se comporte seul correctement', () {
      expect(evaluateArithmetic('10*15/5').value, 30);
      expect(evaluateArithmetic('10*15/5').usedDivision, isTrue);
      expect(evaluateArithmetic('6*5').usedDivision, isFalse);
      expect(evaluateArithmetic('30').isBareNumber, isTrue);
      expect(evaluateArithmetic('30').isEvaluable, isTrue);
    });

    test('l\'évaluateur ne lève jamais d\'exception', () {
      const casPathologiques = <String>[
        '',
        '   ',
        '(',
        ')',
        '()',
        '1/',
        '/5',
        '10**15',
        'abc',
        '10;15',
        '2^3',
        '1,5',
        '===',
        '(((10)',
      ];

      for (final cas in casPathologiques) {
        final resultat = evaluateArithmetic(cas);
        expect(resultat.isEvaluable, isFalse,
            reason: '« $cas » ne doit pas être évalué');
      }
    });

    test('une division par zéro n\'est pas évaluée', () {
      expect(evaluateArithmetic('10*15/0').isEvaluable, isFalse);
    });
  });

  // =====================================================================
  group('6. Une écriture mal formée ne devient PAS une difficulté', () {
    test('les réponses non évaluables restent non évaluables', () {
      for (final reponse in <String>[
        'je ne sais pas',
        'le PPCM',
        '??',
        'abc',
      ]) {
        final resultat = correct(tache(), reponse);
        expect(resultat.isCorrect, isFalse, reason: reponse);
        expect(resultat.isEvaluated, isFalse, reason: reponse);
      }
    });

    test('une expression sans division n\'est pas un échec : la relation n\'est pas montrée',
        () {
      // 6*5 = 30 : juste arithmétiquement, mais cela ne prouve rien sur la
      // relation PPCM–PGCD.
      final resultat = correct(tache(), '6*5');

      expect(resultat.isEvaluated, isFalse);
      expect(resultat.isCorrect, isFalse);
    });

    test('une multiplication seule correcte reste non évaluée', () {
      final resultat = correct(tache(), '5*6');

      expect(resultat.isEvaluated, isFalse);
    });
  });

  // =====================================================================
  group('7. Aucune régression sur le reste du chapitre', () {
    test('les cinq autres tâches acceptent toujours leur valeur', () {
      const attendu = <String, String>{
        ExerciseIds.verifyPgcd16And12: '4',
        ExerciseIds.verifyPgcd14And7: '7',
        ExerciseIds.verifyPgcd24And16: '8',
        ExerciseIds.verifyPgcd35And20: '5',
        ExerciseIds.verifyPpcm6And8: '24',
      };

      attendu.forEach((id, reponse) {
        expect(
          correct(Chapter1Bank.findExercise(id)!, reponse).isCorrect,
          isTrue,
          reason: id,
        );
      });
    });

    test('aucun des 11 exercices ne porte de contrat de relation', () {
      for (final exercise in Chapter1Bank.exercises) {
        expect(exercise.correction.ppcmRelation, isNull, reason: exercise.id);
      }
    });

    test('une seule tâche porte le contrat', () {
      final porteuses = Chapter1Bank.verificationTasks
          .where((t) => t.correction.ppcmRelation != null)
          .toList();

      expect(porteuses, hasLength(1));
      expect(porteuses.single.id, ExerciseIds.verifyPpcm10And15);
    });

    test('le contenu mathématique de la tâche est inchangé', () {
      expect(tache().statement, 'PPCM de 10 et 15, avec PGCD 5.');
      expect(tache().correction.explanation, 'PPCM = (10 × 15) ÷ 5 = 30.');
      expect(tache().kind, BankElementKind.verificationTask);
      expect(Chapter1Bank.verificationTasks, hasLength(6));
      expect(Chapter1Bank.exercises, hasLength(11));
    });

    test('le lien D5 vers cette tâche est préservé', () {
      expect(
        Chapter1Bank.findCase('D5')!.followUp.exerciseId,
        ExerciseIds.verifyPpcm10And15,
      );
    });
  });

  // =====================================================================
  group('8. Association de transfert : condition technique remplie', () {
    test('le profil confirme que la relation est réellement contrôlée', () {
      final profile =
          TransferVerification.profileOf(ExerciseIds.verifyPpcm10And15);

      expect(profile.scope, TransferEvidence.relationApplied);
      expect(profile.provesRelation, isTrue);
    });

    test('l\'association reste INACTIVE : décision pédagogique en attente', () {
      expect(Chapter1Bank.findExercise(ExerciseIds.ex8)!.followUpTask, isNull);
      expect(TransferVerification.taskFor(ExerciseIds.ex8), isNull);
    });

    test('une réussite sur cette tâche ne vaut PAS maîtrise de méthode', () {
      final profile =
          TransferVerification.profileOf(ExerciseIds.verifyPpcm10And15);

      // La relation est contrôlée, la MÉTHODE ne l'est toujours pas.
      expect(profile.provesRelation, isTrue);
      expect(profile.provesMethod, isFalse);
      expect(kTransferMethodIsEvaluable, isFalse);
    });

    test('l\'association de l\'exercice 1 reste la seule active', () {
      final avecTache = Chapter1Bank.exercises
          .where((e) => TransferVerification.taskFor(e.id) != null)
          .map((e) => e.id)
          .toSet();

      expect(avecTache, <String>{ExerciseIds.ex1});
    });

    test('l\'association de l\'exercice 5 reste inactive', () {
      // La méthode d'Euclide n'est toujours pas vérifiable.
      expect(Chapter1Bank.findExercise(ExerciseIds.ex5)!.followUpTask, isNull);
      expect(
        TransferVerification.profileOf(ExerciseIds.verifyPgcd35And20)
            .provesMethod,
        isFalse,
      );
    });
  });
}