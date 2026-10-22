/// Banque pilote du chapitre 1 « Arithmétique » (3e).
///
/// TRANSCRIPTION FIDÈLE du document pédagogique validé
/// (`relio_chapitre1_banque_exercices_diagnostic_v1.md`).
///
/// Règles de transcription :
///  - aucune valeur, énoncé, réponse ou intervention n'est inventé ;
///  - les formules ci-dessous sont vérifiables une à une face au document ;
///  - l'intitulé « PGDC » de la leçon 2 est conservé tel quel, avec un
///    indicateur [ArithmeticLesson.requiresEditorialConfirmation] ;
///  - les 11 exercices et les 8 cas de diagnostic sont intégralement
///    présents (critère de fin de mission).
library;

import 'diagnostic_case.dart';
import 'exercise.dart';
import 'rich_hint.dart';

/// Identifiants stables des 11 exercices.
abstract final class ExerciseIds {
  static const ex1 = 'ch1-ex-1-pgcd-soustractions-guide';
  static const ex2 = 'ch1-ex-2-pgcd-soustractions-autonome';
  static const ex3 = 'ch1-ex-3-pgcd-soustractions-transfert';
  static const ex4 = 'ch1-ex-4-pgcd-soustractions-verification';
  static const ex5 = 'ch1-ex-5-euclide-guide';
  static const ex6 = 'ch1-ex-6-euclide-autonome';
  static const ex7 = 'ch1-ex-7-euclide-transfert-comparaison';
  static const ex8 = 'ch1-ex-8-ppcm-pgcd-application';
  static const ex9 = 'ch1-ex-9-ppcm-isoler-inconnue';
  static const ex10 = 'ch1-ex-10-verification-relation';
  static const ex11 = 'ch1-ex-11-choix-de-methode';

  // Tâches de vérification exigées par la banque pour les cas D1 à D4.
  // Ces couples ne figurent pas parmi les 11 exercices validés : ils sont
  // décrits ici comme tâches de contrôle, sans être réinventés comme
  // exercices officiels.
  static const verifyPgcd16And12 = 'ch1-verify-pgcd-16-12';
  static const verifyPgcd14And7 = 'ch1-verify-pgcd-14-7';
  static const verifyPgcd24And16 = 'ch1-verify-pgcd-24-16';
  static const verifyPgcd35And20 = 'ch1-verify-pgcd-35-20';
  static const verifyPpcm10And15 = 'ch1-verify-ppcm-10-15';
  static const verifyPpcm6And8 = 'ch1-verify-ppcm-6-8';
}

/// La banque du chapitre 1, en lecture seule.
class Chapter1Bank {
  const Chapter1Bank._();

  /// Les 11 exercices, dans l'ordre du document.
  static const List<Exercise> exercises = <Exercise>[
    // ---------------- Leçon 1 — PGCD : algorithme des soustractions --------
    Exercise(
      id: ExerciseIds.ex1,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement:
          'Calcule le PGCD de 18 et 12 avec des soustractions successives.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[6],
        acceptedExpressions: <String>['6'],
        explanation: 'PGCD(18, 12) = 6',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '18 − 12 = 6',
          pair: (12, 6),
          value: 6,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '12 − 6 = 6',
          pair: (6, 6),
          value: 6,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD(18, 12) = 6',
          value: 6,
        ),
      ],
      hints: <ExerciseHint>[
        ExerciseHint(
          order: 1,
          text: 'Soustrais le plus petit nombre du plus grand.',
          kind: 'methode',
        ),
        ExerciseHint(
          order: 2,
          text: 'Après 18 − 12, travaille avec 12 et 6.',
          kind: 'methode',
        ),
      ],
      // FICHES DÉFINITIVES — règle 8.
      //
      // Transcription du document pédagogique validé, jamais une rédaction
      // libre. Les [ExerciseHint] ci-dessus restent la trace de la version
      // courte : elles ne sont plus ce que l'élève voit, mais elles ne sont
      // pas effacées.
      //
      // Glyphes volontairement conservés tels quels : − (moins mathématique),
      // × (multiplier), ÷ (diviser). Le formateur mathématique les reconnaît.
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Première étape',
          blocks: <HintBlock>[
            TextBlock(
              'Pour trouver le PGCD avec des soustractions, on commence '
              'toujours par le plus grand nombre.',
            ),
            TextBlock(
              'Prends le plus grand (18) et soustrais-lui le plus petit (12).',
            ),
            MathBlock('18 − 12 = 6'),
            HandoffBlock(
              'À toi : Maintenant, quels sont les deux nouveaux nombres avec '
              'lesquels tu vas travailler ?',
            ),
          ],
        ),
        RichHint(
          order: 2,
          title: '💡 Deuxième étape',
          blocks: <HintBlock>[
            TextBlock(
              'Tu as trouvé 6. Les deux nombres pour la suite sont donc '
              '12 et 6.',
            ),
            TextBlock('Soustrais à nouveau le plus petit du plus grand.'),
            MathBlock('12 − 6 = 6'),
            HighlightBlock(
              'Règle d\'or : On s\'arrête dès que le résultat de la soustraction '
              'donne le même nombre que le plus petit.',
            ),
            HandoffBlock(
              'À toi : Que remarques-tu sur les deux derniers nombres trouvés '
              '(6 et 6) ?',
            ),
          ],
        ),
        RichHint(
          order: 3,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock(
              'On s\'arrête quand les deux nombres sont égaux. Ce nombre est '
              'le PGCD.',
            ),
            MathBlock('PGCD(18, 12) = 6'),
            HighlightBlock('Le PGCD est 6. Écris 6 dans ta réponse.'),
          ],
        ),
      ],
      comprehension: ComprehensionQuestion(
        question: 'À quel moment t’arrêtes-tu ?',
        expectedAnswer:
            'Lorsque les deux nombres sont égaux ; cette valeur est le PGCD.',
      ),
      // Association de transfert VALIDEE par le fondateur : verifier le
      // calcul du PGCD sur un couple different (18,12) -> (16,12).
      // La tache cible se trouve dans la section verificationTasks plus bas :
      // meme nature, et sa correction ne compare QUE la valeur finale.
      followUpTask: ExerciseIds.verifyPgcd16And12,
      // Correspondances fournies par la specification de correction. Elles
      // ne creent aucun contenu : chaque identifiant renvoie a un cas deja
      // valide dans `diagnosticCases`.
      errorCases: <String, String>{'5': 'D1', '0': 'D2', '3': 'D3'},
    ),
    Exercise(
      id: ExerciseIds.ex2,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement: 'Calcule le PGCD de 15 et 10 par soustractions successives.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[5],
        acceptedExpressions: <String>['5'],
        explanation: '(15,10) → (10,5) → (5,5), donc PGCD = 5.',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.intermediatePair,
          text: '(15, 10) → (10, 5)',
          pair: (10, 5),
          value: 5,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD = 5',
          value: 5,
        ),
      ],
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Rappel de la méthode',
          blocks: <HintBlock>[
            TextBlock(
              'Comme pour le premier exercice, commence par la première '
              'soustraction entre tes deux nombres : 15 et 10.',
            ),
            HandoffBlock(
              'À toi : Pose ta première soustraction et regarde bien le résultat.',
            ),
          ],
        ),
        RichHint(
          order: 2,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock('Voici les étapes :'),
            MathBlock('15 − 10 = 5'),
            MathBlock('10 − 5 = 5'),
            HighlightBlock(
              'Les deux nombres sont égaux à 5. Le PGCD est donc 5.',
            ),
          ],
        ),
      ],
      // Suivi prévu par la banque : PGCD(16, 12) par soustractions (cas D1).
      followUpTask: ExerciseIds.ex4,
      diagnosticCaseIds: <String>['D1', 'D2'],
      // Memes faits que le collecteur, mais explicitement rattaches a la
      // reponse : la carte reste la source de verite de la correction.
      errorCases: <String, String>{'0': 'D2', '-5': 'D1'},
    ),
    Exercise(
      id: ExerciseIds.ex3,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement:
          'Calcule le PGCD de 21 et 14 avec la même méthode, puis explique '
          'comment tu sais que tu peux t’arrêter.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[7],
        acceptedExpressions: <String>['7'],
        expectsJustification: true,
        explanation: '(21,14) → (14,7) → (7,7), donc PGCD = 7.',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.intermediatePair,
          text: '(21, 14) → (14, 7)',
          pair: (14, 7),
          value: 7,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD = 7',
          value: 7,
        ),
      ],
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock(
              'Tu dois appliquer exactement la même méthode qu\'avant.',
            ),
            MathBlock('21 − 14 = 7'),
            MathBlock('14 − 7 = 7'),
            TextBlock(
              'Pour justifier ton arrêt, tu dois dire que tu t\'arrêtes parce '
              'que les deux nombres sont devenus égaux.',
            ),
            HighlightBlock('Le PGCD est 7.'),
          ],
        ),
      ],
    ),
    Exercise(
      id: ExerciseIds.ex4,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement:
          'Quelques exercices plus tard, calcule le PGCD de 20 et 12 par '
          'soustractions successives.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[4],
        acceptedExpressions: <String>['4'],
        explanation: '(20,12) → (12,8) → (8,4) → (4,4), donc PGCD = 4.',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.intermediatePair,
          text: '(20, 12) → (12, 8)',
          pair: (12, 8),
        ),
        SolutionStep(
          kind: SolutionStepKind.intermediatePair,
          text: '(12, 8) → (8, 4)',
          pair: (8, 4),
          value: 4,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD = 4',
          value: 4,
        ),
      ],
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock('Applique la méthode pas à pas :'),
            MathBlock('20 − 12 = 8'),
            MathBlock('12 − 8 = 4'),
            MathBlock('8 − 4 = 4'),
            HighlightBlock('Les deux nombres sont égaux à 4. Le PGCD est 4.'),
          ],
        ),
      ],
    ),

    // ---------------- Leçon 2 — algorithme d'Euclide ---------------------
    Exercise(
      id: ExerciseIds.ex5,
      lesson: ArithmeticLesson.lesson2Euclid,
      statement: 'Calcule le PGCD de 30 et 18 avec l’algorithme d’Euclide.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[6],
        acceptedExpressions: <String>['6'],
        explanation: 'PGCD = 6',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '30 = 18 × 1 + 12',
          value: 12,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '18 = 12 × 1 + 6',
          value: 6,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '12 = 6 × 2 + 0',
          value: 0,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD = 6',
          value: 6,
        ),
      ],
      hints: <ExerciseHint>[
        ExerciseHint(
          order: 1,
          text:
              'Divise le plus grand nombre par le plus petit et note le reste.',
          kind: 'methode',
        ),
        ExerciseHint(
          order: 2,
          text: 'Le nouveau couple est le diviseur et le reste.',
          kind: 'methode',
        ),
      ],
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Comprendre la première division',
          blocks: <HintBlock>[
            TextBlock(
              'On prend le plus grand nombre (30) et on le divise par le plus '
              'petit (18).',
            ),
            MathBlock('30 ÷ 18 = 1'),
            TextBlock(
              'Pourquoi 1 ? Parce que 18 × 1 = 18. Si on faisait 18 × 2, cela '
              'donnerait 36, ce qui est trop grand.',
            ),
            TextBlock('On cherche maintenant le reste de la division :'),
            MathBlock('30 − 18 = 12'),
            HighlightBlock('Bilan : 30 = (18 × 1) + 12'),
            HandoffBlock(
              'À toi : avec les nombres 18 et 12, quelle est la prochaine '
              'division à poser ?',
            ),
          ],
        ),
        RichHint(
          order: 2,
          title: '💡 Comprendre la deuxième division',
          blocks: <HintBlock>[
            TextBlock(
              'On reprend les deux derniers nombres : le diviseur (18) et le '
              'reste (12).',
            ),
            MathBlock('18 ÷ 12 = 1'),
            TextBlock('Le reste est :'),
            MathBlock('18 − 12 = 6'),
            HighlightBlock('Bilan : 18 = (12 × 1) + 6'),
            HandoffBlock('À toi : Peux-tu continuer avec 12 et 6 ?'),
          ],
        ),
        RichHint(
          order: 3,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock('On continue encore une fois :'),
            MathBlock('12 ÷ 6 = 2'),
            MathBlock('12 − (6 × 2) = 0'),
            TextBlock('Le reste est 0. L\'algorithme s\'arrête.'),
            HighlightBlock(
              'Le dernier reste non nul est 6. Donc PGCD(30, 18) = 6.',
            ),
          ],
        ),
      ],
      comprehension: ComprehensionQuestion(
        question: 'Quand l’algorithme s’arrête-t-il ?',
        expectedAnswer:
            'Quand le reste est nul ; le dernier reste non nul est le PGCD.',
      ),
    ),
    Exercise(
      id: ExerciseIds.ex6,
      lesson: ArithmeticLesson.lesson2Euclid,
      statement: 'Calcule le PGCD de 42 et 30 avec l’algorithme d’Euclide.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[6],
        acceptedExpressions: <String>['6'],
        explanation: 'PGCD = 6',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '42 = 30 × 1 + 12',
          value: 12,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '30 = 12 × 2 + 6',
          value: 6,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '12 = 6 × 2 + 0',
          value: 0,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD = 6',
          value: 6,
        ),
      ],
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Rappel de la méthode',
          blocks: <HintBlock>[
            TextBlock(
              'Commence par diviser le plus grand par le plus petit, et note le '
              'reste.',
            ),
            MathBlock('42 ÷ 30 = 1'),
            TextBlock('Trouve le reste en faisant 42 − 30.'),
            HandoffBlock(
              'À toi : Quel est le bilan de cette première division ?',
            ),
          ],
        ),
        RichHint(
          order: 2,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock('Voici les étapes complètes :'),
            MathBlock('42 = 30 × 1 + 12'),
            MathBlock('30 = 12 × 2 + 6'),
            MathBlock('12 = 6 × 2 + 0'),
            HighlightBlock('Le dernier reste non nul est 6. PGCD = 6.'),
          ],
        ),
      ],
      diagnosticCaseIds: <String>['D3', 'D4'],
      // Le reste intermediaire de la premiere division est un arret
      // observable : il correspond au cas D4 valide.
      errorCases: <String, String>{'12': 'D4'},
    ),
    Exercise(
      id: ExerciseIds.ex7,
      lesson: ArithmeticLesson.lesson2Euclid,
      statement:
          'Calcule le PGCD de 48 et 18 avec l’algorithme d’Euclide. Puis '
          'indique une différence entre cette méthode et celle des '
          'soustractions successives.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[6],
        acceptedExpressions: <String>['6'],
        expectsComparison: true,
        explanation: 'PGCD = 6',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '48 = 18 × 2 + 12',
          value: 12,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '18 = 12 × 1 + 6',
          value: 6,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '12 = 6 × 2 + 0',
          value: 0,
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PGCD = 6',
          value: 6,
        ),
        SolutionStep(
          kind: SolutionStepKind.comparison,
          text:
              'L’algorithme d’Euclide utilise les divisions euclidiennes et '
              'peut réduire le nombre d’étapes.',
        ),
      ],
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock('Voici la démarche pour 48 et 18 :'),
            MathBlock('48 = 18 × 2 + 12'),
            MathBlock('18 = 12 × 1 + 6'),
            MathBlock('12 = 6 × 2 + 0'),
            HighlightBlock('Le PGCD est 6.'),
            TextBlock(
              'Pour la comparaison : l\'algorithme d\'Euclide utilise les '
              'divisions euclidiennes, ce qui permet d\'aller plus vite que les '
              'soustractions successives.',
            ),
          ],
        ),
      ],
      // Élément de comparaison accepté par la banque, à contrôler aussi
      // dans la correction textuelle de l'exercice.
      followUpTask: ExerciseIds.ex4,
    ),

    // ---------------- Leçon 3 — relation PPCM / PGCD ----------------------
    Exercise(
      id: ExerciseIds.ex8,
      lesson: ArithmeticLesson.lesson3PpcmPgcdRelation,
      statement:
          'On sait que PGCD(12,18) = 6. Calcule PPCM(12,18) à l’aide de la '
          'relation entre PGCD et PPCM.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[36],
        acceptedExpressions: <String>['36'],
        explanation: '12 × 18 = 6 × PPCM(12,18) ; PPCM = 216 ÷ 6 = 36.',
      ),
      // PGCD donné par l'énoncé : seule la valeur du PPCM est calculée.
      givenPgcd: 6,
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '12 × 18 = 6 × PPCM(12,18)',
        ),
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PPCM(12,18) = 216 ÷ 6 = 36',
          value: 36,
        ),
      ],
      diagnosticCaseIds: <String>['D5', 'D6'],
      // Zero n'est pas le PGCD donne : c'est une erreur de calcul, sans
      // confusion observable entre PGCD et PPCM. Le cas D5 est donc seul.
      errorCases: <String, String>{'0': 'D5'},
    ),
    Exercise(
      id: ExerciseIds.ex9,
      lesson: ArithmeticLesson.lesson3PpcmPgcdRelation,
      statement:
          'Pour deux entiers positifs a = 8 et b = 12, on sait que leur '
          'PGCD vaut 4. Calcule leur PPCM.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[24],
        acceptedExpressions: <String>['24', '(8*12)/4', '96/4'],
        explanation: 'PPCM = (8 × 12) ÷ 4 = 24.',
      ),
      // PGCD donné par l'énoncé : seule la valeur du PPCM est calculée.
      givenPgcd: 4,
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.finalResult,
          text: 'PPCM = (8 × 12) ÷ 4 = 24',
          value: 24,
        ),
      ],
      // Le suivi vérifie le PPCM de 10 et 15 avec PGCD 5 (cas D5) :
      // tâche DIFFÉRENTE de celle qui vient d'échouer.
      followUpTask: ExerciseIds.ex8,
      diagnosticCaseIds: <String>['D5', 'D6'],
    ),
    Exercise(
      id: ExerciseIds.ex10,
      lesson: ArithmeticLesson.lesson3PpcmPgcdRelation,
      statement:
          'On propose PGCD(9,15) = 3 et PPCM(9,15) = 45. Vérifie ces deux '
          'valeurs avec la relation.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[135],
        acceptedExpressions: <String>['135', 'verifie', 'oui'],
        explanation:
            '9 × 15 = 135 et 3 × 45 = 135 ; la relation est vérifiée. '
            'La vérification de la relation seule ne prouve pas toujours '
            'séparément chaque valeur.',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '9 × 15 = 135',
          value: 135,
        ),
        SolutionStep(
          kind: SolutionStepKind.operation,
          text: '3 × 45 = 135',
          value: 135,
        ),
        SolutionStep(
          kind: SolutionStepKind.justification,
          text: 'La relation est vérifiée.',
        ),
      ],
    ),
    Exercise(
      id: ExerciseIds.ex11,
      lesson: ArithmeticLesson.lesson3PpcmPgcdRelation,
      statement:
          'Pour deux entiers positifs, tu connais leur produit et leur PGCD. '
          'Quelle relation peux-tu utiliser pour retrouver leur PPCM ? '
          'Explique en une phrase.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[],
        acceptedExpressions: <String>['ppcm = produit / pgcd'],
        expectsJustification: true,
        explanation:
            'Produit des deux entiers = PGCD × PPCM ; donc '
            'PPCM = produit ÷ PGCD.',
      ),
      expectedSteps: <SolutionStep>[
        SolutionStep(
          kind: SolutionStepKind.justification,
          text: 'produit des deux entiers = PGCD × PPCM',
        ),
        SolutionStep(
          kind: SolutionStepKind.justification,
          text: 'PPCM = produit ÷ PGCD',
        ),
      ],
    ),
  ];

  /// Tâches de vérification exigées par la banque pour contrôler une
  /// remédiation (couples cités dans les cas D1 à D6).
  ///
  /// Elles ne sont PAS des exercices validés : elles portent
  /// [BankElementKind.verificationTask] et ne sont jamais proposées dans
  /// le parcours normal.
  static const List<Exercise> verificationTasks = <Exercise>[
    Exercise(
      id: ExerciseIds.verifyPgcd16And12,
      kind: BankElementKind.verificationTask,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement: 'PGCD(16, 12) par soustractions successives.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[4],
        acceptedExpressions: <String>['4'],
        explanation: '(16,12) → (12,4) → (8,4) → (4,4), donc PGCD = 4.',
      ),
    ),
    Exercise(
      id: ExerciseIds.verifyPgcd14And7,
      kind: BankElementKind.verificationTask,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement: 'PGCD(14, 7).',
      correction: CorrectionCriterion(
        acceptedValues: <int>[7],
        acceptedExpressions: <String>['7'],
        explanation: '(14,7) → (7,7), donc PGCD = 7.',
      ),
    ),
    Exercise(
      id: ExerciseIds.verifyPgcd24And16,
      kind: BankElementKind.verificationTask,
      lesson: ArithmeticLesson.lesson1Subtractions,
      statement: 'PGCD(24, 16).',
      correction: CorrectionCriterion(
        acceptedValues: <int>[8],
        acceptedExpressions: <String>['8'],
        explanation: '(24,16) → (16,8) → (8,8), donc PGCD = 8.',
      ),
    ),
    Exercise(
      id: ExerciseIds.verifyPgcd35And20,
      kind: BankElementKind.verificationTask,
      lesson: ArithmeticLesson.lesson2Euclid,
      statement: 'PGCD(35, 20).',
      correction: CorrectionCriterion(
        acceptedValues: <int>[5],
        acceptedExpressions: <String>['5'],
        explanation:
            '35 = 20 × 1 + 15 ; 20 = 15 × 1 + 5 ; 15 = 5 × 3 + 0 ; '
            'PGCD = 5.',
      ),
    ),
    Exercise(
      id: ExerciseIds.verifyPpcm10And15,
      kind: BankElementKind.verificationTask,
      lesson: ArithmeticLesson.lesson3PpcmPgcdRelation,
      statement: 'PPCM de 10 et 15, avec PGCD 5.',
      correction: CorrectionCriterion(
        // CONTRAT « RELATION APPLIQUÉE ».
        //
        // Auparavant, `acceptedValues: [30]` suffisait : l'élève pouvait
        // écrire 30, obtenir le bon résultat, et l'application retirer que
        // la relation avait été comprise. C'était une sur-promission.
        //
        // `acceptedValues` est donc VIDE : une valeur numérique seule n'est
        // plus acceptée. Seule une écriture montrant la division
        // produit ÷ PGCD est évaluée.
        //
        // `acceptedExpressions` reste vide : l'évaluateur ne compare plus à
        // une liste de chaînes, il ÉVALUE le calcul écrit. C'est ce qui
        // permet d'accepter 10*15/5, (10*15)/5, 150/5, 150 ÷ 5 et
        // 10*15/5 = 30 sans les énumérer.
        ppcmRelation: PpcmRelation(
          first: 10,
          second: 15,
          divisor: 5,
          result: 30,
        ),
        explanation: 'PPCM = (10 × 15) ÷ 5 = 30.',
      ),
    ),
    Exercise(
      id: ExerciseIds.verifyPpcm6And8,
      kind: BankElementKind.verificationTask,
      lesson: ArithmeticLesson.lesson3PpcmPgcdRelation,
      statement: 'Distinguer PGCD et PPCM de 6 et 8.',
      correction: CorrectionCriterion(
        acceptedValues: <int>[24],
        // PGCD(6, 8) = 2 ET PPCM(6, 8) = 24 : les deux valeurs doivent
        // être distinguées, c'est tout l'objet de la tâche de D6.
        acceptedExpressions: <String>['24', 'ppcm=24;pgcd=2', 'pgcd=2;ppcm=24'],
        explanation:
            'PGCD(6, 8) = 2 et PPCM(6, 8) = 24 : la confusion des deux '
            'notions est levée en les nommant explicitement.',
      ),
    ),
  ];

  /// Les 8 cas de diagnostic D1 à D8.
  ///
  /// Chaque cas porte des HYPOTHÈSES multiples : le document source impose
  /// de ne pas conclure à une cause unique.
  static const List<DiagnosticCase> diagnosticCases = <DiagnosticCase>[
    DiagnosticCase(
      id: 'D1',
      title: 'Soustraction fausse',
      observations: <String>{'soustraction_fausse'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Erreur de calcul ou de procédure',
          confidence: HypothesisConfidence.possible,
          evidence: <String>{'soustraction_fausse'},
        ),
      ],
      intervention: Intervention(
        question: 'Quelle opération as-tu faite ici ?',
      ),
      // Tâche différente : PGCD(16, 12) par soustractions.
      followUp: FollowUpTask(
        label: 'PGCD(16, 12) par soustractions',
        exerciseId: ExerciseIds.verifyPgcd16And12,
      ),
    ),
    DiagnosticCase(
      id: 'D2',
      title: 'Poursuite après deux valeurs égales',
      observations: <String>{'poursuit_apres_valeurs_egales'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Critère d’arrêt mal compris',
          confidence: HypothesisConfidence.possible,
          evidence: <String>{'poursuit_apres_valeurs_egales'},
        ),
      ],
      intervention: Intervention(
        question: 'Que remarques-tu sur les deux nombres ?',
      ),
      followUp: FollowUpTask(
        label: 'PGCD(14, 7)',
        exerciseId: ExerciseIds.verifyPgcd14And7,
      ),
    ),
    DiagnosticCase(
      id: 'D3',
      title: 'Rôle du reste mal compris',
      observations: <String>{'mauvais_couple_repris'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Rôle du reste mal compris',
          confidence: HypothesisConfidence.likely,
          evidence: <String>{'mauvais_couple_repris'},
        ),
      ],
      intervention: Intervention(
        question: 'Quels sont le diviseur et le reste ?',
      ),
      followUp: FollowUpTask(
        label: 'PGCD(24, 16)',
        exerciseId: ExerciseIds.verifyPgcd24And16,
      ),
    ),
    DiagnosticCase(
      id: 'D4',
      title: 'Arrêt sur reste non nul',
      observations: <String>{'arret_avec_reste_non_nul'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Critère d’arrêt de l’algorithme incertain',
          confidence: HypothesisConfidence.likely,
          evidence: <String>{'arret_avec_reste_non_nul'},
        ),
      ],
      intervention: Intervention(question: 'Le reste est-il nul ?'),
      followUp: FollowUpTask(
        label: 'PGCD(35, 20)',
        exerciseId: ExerciseIds.verifyPgcd35And20,
      ),
    ),
    DiagnosticCase(
      id: 'D5',
      title: 'PGCD correct, PPCM faux par division inversée',
      observations: <String>{'pgcd_correct_ppcm_faux'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Isolement de l’inconnue ou calcul',
          confidence: HypothesisConfidence.possible,
          evidence: <String>{'pgcd_correct_ppcm_faux'},
        ),
      ],
      intervention: Intervention(
        question: 'Dans la relation, que dois-tu diviser par quoi ?',
      ),
      followUp: FollowUpTask(
        label: 'PPCM de 10 et 15, avec PGCD 5',
        exerciseId: ExerciseIds.verifyPpcm10And15,
      ),
      // D5 exige de NE PAS confondre avec D6 : les deux causes
      // (isolement algébrique vs confusion conceptuelle) doivent rester
      // distinguables. La question de clarification porte sur le test
      // séparé des deux compétences.
      priorityTest: true,
      clarificationQuestion:
          'Peux-tu calculer le PGCD seul, puis le PPCM seul ?',
    ),
    DiagnosticCase(
      id: 'D6',
      title: 'Confusion entre PGCD et PPCM',
      observations: <String>{'confusion_pgcd_ppcm'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Distinction conceptuelle fragile',
          confidence: HypothesisConfidence.possible,
          evidence: <String>{'confusion_pgcd_ppcm'},
        ),
        // Cause alternative maintenue ouverte : le document source
        // interdit de conclure sur une seule erreur.
        DiagnosticHypothesis(
          label: 'Erreur de saisie du résultat',
          confidence: HypothesisConfidence.possible,
          evidence: <String>{'confusion_pgcd_ppcm'},
        ),
      ],
      intervention: Intervention(
        question: 'Cherches-tu un diviseur commun ou un multiple commun ?',
      ),
      followUp: FollowUpTask(
        label: 'Distinguer PGCD et PPCM de 6 et 8',
        exerciseId: ExerciseIds.verifyPpcm6And8,
      ),
      priorityTest: true,
    ),
    DiagnosticCase(
      id: 'D7',
      title: 'Réussite seulement après indice',
      observations: <String>{'reussite_apres_indice'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Procédure en cours d’acquisition',
          confidence: HypothesisConfidence.likely,
          evidence: <String>{'reussite_apres_indice'},
        ),
      ],
      intervention: Intervention(question: '', reassuresProgress: true),
      // Vérification par un nouvel exercice SANS indice.
      followUp: FollowUpTask(
        label: 'Nouvel exercice sans indice',
        exerciseId: ExerciseIds.ex3,
        withHints: false,
      ),
    ),
    DiagnosticCase(
      id: 'D8',
      title: 'Bonne réponse sans démarche visible',
      observations: <String>{'reponse_correcte_sans_demarche'},
      hypothesis: <DiagnosticHypothesis>[
        DiagnosticHypothesis(
          label: 'Stratégie inconnue',
          confidence: HypothesisConfidence.possible,
          evidence: <String>{'reponse_correcte_sans_demarche'},
        ),
      ],
      intervention: Intervention(question: 'Montre une étape de ton calcul.'),
      // Couplet différent, sans aide.
      followUp: FollowUpTask(
        label: 'Couple différent, sans aide',
        exerciseId: ExerciseIds.ex6,
        withHints: false,
      ),
    ),
  ];

  /// Élément de banque par identifiant (exercice OU tâche de vérification).
  ///
  /// `null` si l'identifiant n'existe pas : un exercice référencé par
  /// erreur ne doit jamais faire planter le moteur.
  static Exercise? findExercise(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    for (final task in verificationTasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Cas de diagnostic par identifiant.
  static DiagnosticCase? findCase(String id) {
    for (final diagnostic in diagnosticCases) {
      if (diagnostic.id == id) return diagnostic;
    }
    return null;
  }

  /// Observations rattachées à l'exercice [exerciseId].
  static Set<String> observationsFor(String exerciseId) =>
      findExercise(exerciseId)?.diagnosticCaseIds.toSet() ?? <String>{};
}
