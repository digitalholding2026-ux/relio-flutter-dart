/// Test d'entree — evaluation des reponses.
///
/// FONCTIONS PURES : evaluer n'ecrit rien, ne declenche aucun indice,
/// aucun diagnostic, aucune verification de transfert, aucun evenement. Le
/// chapitre 1 n'est ni appele ni detourne.
///
/// Trois issues, jamais confondues :
///
///  - **correcte** : la reponse correspond a la reponse attendue ;
///  - **incorrecte et evaluable** : la reponse a ete comprise et ne
///    correspond pas. C'est un FAIT, pas une cause d'erreur ;
///  - **non evaluable** : la reponse n'a pas pu etre lue. On ne conclut
///    RIEN.
///
/// La troisieme issue est celle qui compte le plus. Une reponse illisible
/// n'est pas une faute de l'eleve : la classer « fausse » fabriquerait une
/// difficulté qui n'existe pas. C'est exactement la distinction portee par
/// `TransferOutcome.indeterminate` dans le module de verification de
/// transfert ; elle est reprise ici sous une forme propre au test d'entree.
library;

import '../curriculum/answer_normalization.dart';
import 'entry_test_question.dart';

/// Resultat de l'evaluation d'une reponse au test d'entree.
///
/// Meme forme conceptuelle que `CorrectionResult` (deux booleens
/// ORTHOGONAUX, non un enum a trois cas), mais un type distinct.
///
/// Pourquoi ne pas reutiliser `CorrectionResult` ? Ce type est declare dans
/// `chapter1_service.dart`. L'importer creerait un lien de compilation entre
/// le test d'entree et le service du chapitre 1, alors que ce test doit
/// pouvoir evoluer independamment. La forme est reprise, pas le type : deux
/// booleens orthogonaux decrivent les trois issues sans perte.
class EntryTestCorrection {
  const EntryTestCorrection({
    required this.isCorrect,
    required this.isEvaluated,
    this.matchedValue,
  });

  /// La reponse correspond-elle a la reponse attendue ?
  ///
  /// N'est vrai QUE si [isEvaluated] est vrai.
  final bool isCorrect;

  /// La reponse a-t-elle pu etre comprise ?
  ///
  /// Faux signifie « aucune conclusion possible ». Ni juste, ni faux.
  final bool isEvaluated;

  /// Reponse attendue retenue, lorsque la reponse est correcte.
  final String? matchedValue;

  /// Issue « non evaluable », partagee : elle n'a aucun contenu propre.
  static const EntryTestCorrection notEvaluated =
      EntryTestCorrection(isCorrect: false, isEvaluated: false);

  /// Reponse correcte ET evaluable.
  factory EntryTestCorrection.correct(String matched) => EntryTestCorrection(
        isCorrect: true,
        isEvaluated: true,
        matchedValue: matched,
      );

  /// Reponse incorrecte MAIS evaluable : comprise, et fausse.
  factory EntryTestCorrection.incorrect() =>
      const EntryTestCorrection(isCorrect: false, isEvaluated: true);

  /// Aucune conclusion pedagogique n'est possible.
  bool get isIndeterminate => !isEvaluated;

  @override
  String toString() => 'EntryTestCorrection(correct=$isCorrect, '
      'evaluated=$isEvaluated)';
}

/// Evalue les reponses au test d'entree.
///
/// Sans etat, sans effet de bord, sans dependance au chapitre 1.
class EntryTestEvaluator {
  const EntryTestEvaluator();

  /// Evalue [rawAnswer] face a [question].
  ///
  /// [rawAnswer] peut etre `null` ou vide : une reponse absente n'est pas
  /// evaluable, et n'est surtout pas fausse.
  EntryTestCorrection evaluate(EntryTestQuestion question, String? rawAnswer) {
    switch (question.answerType) {
      case EntryTestAnswerType.integer:
        return _evaluateInteger(question, rawAnswer);
      case EntryTestAnswerType.choice:
        return _evaluateChoice(question, rawAnswer);
    }
  }

  /// Forme normalisee d'une reponse, pour la comparaison et la persistance.
  ///
  /// Les regles sont volontairement LIMITES — deux regles, pas plus :
  /// suppression des espaces en debut et fin, reduction des espaces
  /// consecutifs a un seul.
  ///
  /// Aucun calcul, aucune conversion d'unite, aucune tolerance. Une
  /// normalisation plus tolerante transformerait des saisies differentes en
  /// une meme reponse, et masquerait le fait que l'eleve a ecrit autre chose.
  String normalize(EntryTestQuestion question, String? rawAnswer) {
    final String raw = rawAnswer ?? '';
    final String collapsed = raw.trim().replaceAll(_spaces, ' ');
    if (question.answerType == EntryTestAnswerType.integer) {
      // L'entier ne porte pas d'espace interne : « 2 1 » et « 21 » sont la
      // meme saisie, et l'eleve n'a pas voulu ecrire autre chose.
      return collapsed.replaceAll(' ', '');
    }
    return collapsed;
  }

  static final RegExp _spaces = RegExp(r'\s+');

  EntryTestCorrection _evaluateInteger(
    EntryTestQuestion question,
    String? rawAnswer,
  ) {
    final String normalized = normalize(question, rawAnswer);
    if (normalized.isEmpty) return EntryTestCorrection.notEvaluated;

    // La reponse attendue de la BANQUE est elle-meme lisible ? Si non, le
    // defaut est dans le code, pas chez l'eleve : on refuse de conclure
    // plutot que de declaring une reponse correcte fausse.
    final int? expected = parseInteger(question.expectedValue);
    if (expected == null) return EntryTestCorrection.notEvaluated;

    // `parseInteger` est la normalisation d'entier du depot. Elle ne leve
    // jamais : une saisie illisible rend `null`, ce qui produit exactement
    // l'issue « non evaluable » voulue.
    final int? given = parseInteger(normalized);
    if (given == null) return EntryTestCorrection.notEvaluated;

    return given == expected
        ? EntryTestCorrection.correct(question.expectedValue)
        : EntryTestCorrection.incorrect();
  }

  EntryTestCorrection _evaluateChoice(
    EntryTestQuestion question,
    String? rawAnswer,
  ) {
    final String normalized = normalize(question, rawAnswer);
    if (normalized.isEmpty) return EntryTestCorrection.notEvaluated;

    // Comparaison sur les formes NORMALISEES des choix : la regle de
    // normalisation s'applique des deux cotes, sinon un espace parasite d'un
    // cote seulement rendrait la comparaison injuste.
    final List<String> allowed =
        <String>[for (final String c in question.choices) normalize(question, c)];

    if (!allowed.contains(normalized)) {
      // Choix inconnu : hors contrat. Ce n'est PAS une erreur de l'eleve,
      // c'est une saisie qui ne correspond a rien de propose.
      return EntryTestCorrection.notEvaluated;
    }

    // Choix connu : il est soit correct, soit evaluable et incorrect.
    return normalize(question, question.expectedValue) == normalized
        ? EntryTestCorrection.correct(question.expectedValue)
        : EntryTestCorrection.incorrect();
  }
}