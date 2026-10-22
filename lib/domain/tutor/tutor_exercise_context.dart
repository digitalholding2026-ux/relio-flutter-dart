/// Ce que le tuteur sait de l'exercice en cours.
///
/// L'énoncé et la correction viennent de la banque VALIDÉE (règle 8) : le
/// tuteur ne reçoit aucun contenu inventé, et rien d'autre que l'exercice
/// affiché.
///
/// La réponse attendue est transmise au modèle pour qu'il puisse guider sans
/// se tromper. Le prompt système lui interdit explicitement de la révéler.
library;

import 'package:flutter/foundation.dart';

import '../curriculum/exercise.dart';
import 'tutor_prompt.dart';

/// Exercice transmis au modèle, sous forme de texte.
@immutable
class TutorExerciseContext {
  /// Crée le contexte.
  const TutorExerciseContext({
    required this.statement,
    required this.expectedAnswer,
  });

  /// Énoncé affiché à l'élève, transcrit du document validé.
  final String statement;

  /// Réponse attendue et critères de correction, à NE JAMAIS révéler.
  final String expectedAnswer;

  /// Construit le contexte depuis l'exercice réellement ouvert.
  ///
  /// Aucune valeur n'est recalculée : on reprend la correction validée.
  factory TutorExerciseContext.fromExercise(Exercise exercise) {
    return TutorExerciseContext(
      statement: exercise.statement,
      expectedAnswer: describeCorrection(exercise.correction),
    );
  }

  /// Décrit la correction en clair, pour le seul usage du modèle.
  static String describeCorrection(CorrectionCriterion correction) {
    final parts = <String>[
      if (correction.acceptedValues.isNotEmpty)
        'Valeurs acceptées : ${correction.acceptedValues.join(', ')}.',
      if (correction.acceptedExpressions.isNotEmpty)
        'Expressions acceptées : ${correction.acceptedExpressions.join(', ')}.',
      if (correction.explanation.trim().isNotEmpty)
        correction.explanation.trim(),
    ];

    if (parts.isEmpty) return 'Aucune correction explicite fournie.';
    return parts.join(' ');
  }

  /// Bloc interne ajouté après le prompt système.
  String get promptBlock {
    return '## Exercice en cours\n'
        'Énoncé : $statement\n'
        'Réponse attendue (à ne jamais révéler) : $expectedAnswer';
  }
}

/// Prompt système complet : cerveau officiel + exercice courant.
String systemPromptFor(TutorExerciseContext exercise) {
  return '$kTutorSystemPrompt\n\n${exercise.promptBlock}';
}
