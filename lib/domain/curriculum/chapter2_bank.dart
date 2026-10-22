/// Banque du chapitre 2 « Théorème de Thalès » (3e).
///
/// TRANSCRIPTION DU CONTENU VALIDÉ fourni pour cette mission. Aucune valeur,
/// aucun énoncé, aucune réponse et aucune intervention ne sont inventés ici.
///
/// Le chapitre comporte deux leçons, chacune portant un exercice :
///
///  - leçon 1, propriété directe : calculer une longueur (exercice guidé) ;
///  - leçon 2, propriété réciproque : justifier un parallélisme (exercice
///    autonome).
///
/// Les codes d'erreur `D1`, `D2` et `D3` sont ceux du document de référence.
/// Ils sont locaux au chapitre 2 et ne doivent jamais être confondus avec les
/// cas D1–D8 de l'arithmétique : le champ `chapterNumber` d'un cas de
/// diagnostic les sépare. Aucun cas de diagnostic n'est créé ici, faute
/// d'intervention validée à transcrire : la règle 8 interdit de rédiger à la
/// place du document.
library;

import 'exercise.dart';
import 'rich_hint.dart';

/// Identifiants stables des exercices du chapitre 2.
abstract final class Chapter2ExerciseIds {
  /// Exercice guidé de la propriété directe.
  static const ex1 = 'ch2-ex-1-thales-direct-guide';

  /// Exercice autonome de la propriété réciproque.
  static const ex2 = 'ch2-ex-2-thales-reciproque-autonome';
}

/// Leçon du chapitre 2 « Théorème de Thalès ».
enum ThalesLesson implements CurriculumLesson {
  /// Leçon 1 — appliquer la propriété directe pour calculer une longueur.
  lesson1Direct(
    id: 'ch2-lecon-1',
    title: 'Propriété directe (Calculer des longueurs)',
  ),

  /// Leçon 2 — appliquer la réciproque pour justifier un parallélisme.
  lesson2Reciprocal(
    id: 'ch2-lecon-2',
    title: 'Propriété réciproque (Justifier le parallélisme)',
  );

  const ThalesLesson({required this.id, required this.title});

  @override
  final String id;

  @override
  final String title;

  @override
  int get chapterNumber => 2;

  @override
  int get order => index;

  @override
  String toString() => 'ThalesLesson($id)';
}

/// La banque du chapitre 2, en lecture seule.
class Chapter2Bank {
  const Chapter2Bank._();

  /// Les deux leçons, dans l'ordre du programme.
  static const List<ThalesLesson> lessons = ThalesLesson.values;

  /// Les deux exercices, dans l'ordre du document.
  static const List<Exercise> exercises = <Exercise>[
    // ---------------- Leçon 1 — propriété directe ------------------------
    Exercise(
      id: Chapter2ExerciseIds.ex1,
      lesson: ThalesLesson.lesson1Direct,
      statement:
          'Dans un triangle ABC, M est sur [AB] et N est sur [AC]. On sait '
          'que (MN) // (BC). AM = 3 cm, AB = 5 cm, et AN = 4,5 cm. Calcule AC.',
      correction: CorrectionCriterion(
        // La réponse est décimale : elle est acceptée sous ses deux écritures
        // françaises et anglaises. Aucun entier n'est accepté.
        acceptedExpressions: <String>['7.5', '7,5'],
        explanation: 'AC = (4,5 × 5) ÷ 3 = 7,5 cm.',
      ),
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Première étape',
          blocks: <HintBlock>[
            TextBlock(
              'Pour utiliser la propriété directe de Thalès, tu dois d\'abord '
              'reconnaître la configuration : les droites (MN) et (BC) sont '
              'parallèles. Écris l\'égalité des rapports.',
            ),
            MathBlock('AM/AB = AN/AC = MN/BC'),
            HandoffBlock(
              'À toi : remplace les valeurs que tu connais dans l\'égalité.',
            ),
          ],
        ),
        RichHint(
          order: 2,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            TextBlock(
              'Tu as l\'égalité : 3/5 = 4,5/AC. Pour trouver AC, tu dois faire '
              'un produit en croix.',
            ),
            MathBlock('AC = (4,5 × 5) ÷ 3'),
            HighlightBlock('Le résultat est 7,5 cm.'),
          ],
        ),
      ],
      // Correspondances fournies par le document validé :
      //   D1 — l'élève a inversé les rapports AB/AM ;
      //   D2 — l'élève a fait AM/AC.
      errorCases: <String, String>{'6': 'D1', '3.33': 'D2'},
    ),

    // ---------------- Leçon 2 — propriété réciproque ---------------------
    Exercise(
      id: Chapter2ExerciseIds.ex2,
      lesson: ThalesLesson.lesson2Reciprocal,
      statement:
          'Dans un triangle ABC, M est sur [AB] et N est sur [AC]. '
          'AM = 2 cm, AB = 6 cm, AN = 3 cm, AC = 9 cm. Les droites (MN) et '
          '(BC) sont-elles parallèles ?',
      correction: CorrectionCriterion(
        // Deux formulations sont acceptées par le document : « oui » et
        // « vrai ». Aucune valeur entière n'est attendue.
        acceptedExpressions: <String>['oui', 'vrai'],
        explanation:
            'Les deux rapports sont égaux et les points sont alignés dans le '
            'même ordre, donc d\'après la réciproque de Thalès, les droites '
            'sont parallèles.',
      ),
      richHints: <RichHint>[
        RichHint(
          order: 1,
          title: '💡 Première étape',
          blocks: <HintBlock>[
            TextBlock(
              'Pour utiliser la réciproque, tu dois comparer les deux '
              'rapports : AM/AB et AN/AC. Calcule-les séparément.',
            ),
            HandoffBlock('À toi : combien vaut AM/AB ? Et AN/AC ?'),
          ],
        ),
        RichHint(
          order: 2,
          title: '💡 Indice final : Résolution',
          blocks: <HintBlock>[
            MathBlock('AM/AB = 2/6 = 1/3'),
            MathBlock('AN/AC = 3/9 = 1/3'),
            HighlightBlock(
              'Les deux rapports sont égaux et les points sont alignés dans '
              'le même ordre, donc d\'après la réciproque de Thalès, les '
              'droites sont parallèles.',
            ),
          ],
        ),
      ],
      // Correspondance fournie par le document validé :
      //   D3 — l'élève a mal calculé les rapports.
      errorCases: <String, String>{'non': 'D3', 'faux': 'D3'},
    ),
  ];

  /// Aucune tâche de vérification n'est fournie pour ce chapitre.
  static const List<Exercise> verificationTasks = <Exercise>[];

  /// Élément de banque par identifiant, ou `null`.
  static Exercise? findExercise(String id) {
    for (final exercise in exercises) {
      if (exercise.id == id) return exercise;
    }
    for (final task in verificationTasks) {
      if (task.id == id) return task;
    }
    return null;
  }
}
