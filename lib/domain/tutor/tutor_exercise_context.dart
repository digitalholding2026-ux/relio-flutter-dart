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

  /// Protocole technique de signalement d'une erreur.
  ///
  /// Ce bloc ne fait pas partie du cerveau pédagogique validé : il décrit
  /// seulement un canal machine. Le modèle reste libre de ne rien signaler ;
  /// s'il le fait, il choisit un code dans la liste fermée, et
  /// [parseTutorErrorSignal] ignore tout le reste.
  static const String errorSignalBlock =
      '## Signalement technique\n'
      'Si l’élève écrit explicitement une erreur que tu identifies avec '
      'certitude, termine ta réponse par un seul marqueur, seul sur la '
      'dernière ligne : [[relio-erreur:CODE]].\n'
      'Codes autorisés :\n'
      '- soustraction_fausse : une soustraction est fausse ;\n'
      '- poursuit_apres_valeurs_egales : l’élève continue alors que les '
      'deux nombres sont égaux ;\n'
      '- mauvais_couple_repris : le mauvais couple est réutilisé dans '
      'l’algorithme d’Euclide ;\n'
      '- arret_avec_reste_non_nul : l’élève s’arrête sur un reste non nul ;\n'
      '- pgcd_correct_ppcm_faux : le PGCD est juste mais le PPCM est faux ;\n'
      '- confusion_pgcd_ppcm : l’élève confond le PGCD et le PPCM.\n'
      'N’utilise aucun autre code. Ne commente jamais ce marqueur et ne '
      'l’explique pas à l’élève. Sans erreur clairement identifiée, ne '
      'mets aucun marqueur.';
}

/// Prompt système complet : cerveau officiel + exercice courant.
String systemPromptFor(TutorExerciseContext exercise) {
  return '$kTutorSystemPrompt\n\n${exercise.promptBlock}'
      '\n\n${TutorExerciseContext.errorSignalBlock}';
}
