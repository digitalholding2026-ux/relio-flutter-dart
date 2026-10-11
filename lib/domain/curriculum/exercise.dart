/// Modèle d'un exercice de la banque pilote.
///
/// Représentation STRUCTURÉE et testable : les 11 exercices du chapitre 1
/// sont décrits par des objets [Exercise], jamais par des conditions
/// dispersées dans l'interface.
///
/// Le contenu (énoncés, réponses attendues, indices) est une transcription
/// du document pédagogique validé : il n'est jamais inventé ici.
library;

/// Leçon du chapitre 1 « Arithmétique ».
///
/// Les intitulés reprennent ceux du document validé. La leçon 2 porte le
/// libellé « PGDC » dans la source, signalé comme transcription à vérifier :
/// il est conservé tel quel, avec [requiresEditorialConfirmation].
enum ArithmeticLesson {
  /// Leçon 1 — PGCD : algorithme des soustractions.
  lesson1Subtractions(
    id: 'lecon-1',
    title: 'PGCD : algorithme des soustractions',
  ),

  /// Leçon 2 — « PGDC » : algorithme d'Euclide.
  ///
  /// Le libellé « PGDC » est conservé comme transcription de la capture à
  /// vérifier (cf. document source, note éditoriale).
  lesson2Euclid(
    id: 'lecon-2',
    title: '« PGDC » : algorithme d’Euclide',
    requiresEditorialConfirmation: true,
  ),

  /// Leçon 3 — Relation entre le PPCM et le PGCD de deux entiers naturels.
  lesson3PpcmPgcdRelation(
    id: 'lecon-3',
    title: 'Relation entre le PPCM et le PGCD de deux entiers naturels',
  );

  const ArithmeticLesson({
    required this.id,
    required this.title,
    this.requiresEditorialConfirmation = false,
  });

  /// Identifiant stable de la leçon.
  final String id;

  /// Intitulé officiel, reproduit du document validé.
  final String title;

  /// Vrai si l'intitulé attend une confirmation éditoriale.
  ///
  /// Aucune correction n'est appliquée automatiquement : modifier un titre
  /// officiel relève d'une décision pédagogique, pas technique.
  final bool requiresEditorialConfirmation;

  @override
  String toString() => 'ArithmeticLesson($id)';
}

/// Nature d'une étape de résolution attendue.
///
/// Décrit ce que l'élève est censé produire, sans l'exiger : ces étapes
/// sont des ATTENDUES, pas des faits observés.
enum SolutionStepKind {
  /// Une opération à effectuer (soustraction, division euclidienne).
  operation,

  /// Un couple de nombres obtenu en cours de route.
  intermediatePair,

  /// Le résultat final.
  finalResult,

  /// Une justification en langage naturel.
  justification,

  /// Un élément de comparaison entre deux méthodes.
  comparison,
}

/// Une étape attendue dans la résolution.
class SolutionStep {
  const SolutionStep({
    required this.kind,
    required this.text,
    this.pair,
    this.value,
  });

  final SolutionStepKind kind;

  /// Formulation lisible de l'étape, transcrit du document.
  final String text;

  /// Couple obtenu, si l'étape en produit un (ex. (12, 6)).
  final (int, int)? pair;

  /// Valeur numérique associée, si l'étape en porte une.
  final int? value;

  @override
  String toString() => 'SolutionStep(${kind.name}: $text)';
}

/// Critère de correction d'une réponse d'élève.
///
/// Sépare nettement :
///  - ce que l'élève SAISIT (fait) ;
///  - ce qui est ATTENDU (référence de correction).
class CorrectionCriterion {
  const CorrectionCriterion({
    this.acceptedValues = const <int>[],
    this.acceptedExpressions = const <String>[],
    this.expectsJustification = false,
    this.expectsComparison = false,
    this.explanation = '',
  });

  /// Valeurs numériques acceptées.
  final List<int> acceptedValues;

  /// Expressions textuelles acceptées (ex. « (8*12)/4 »).
  final List<String> acceptedExpressions;

  /// Une justification en langage naturel est attendue.
  final bool expectsJustification;

  /// Un élément de comparaison entre méthodes est attendu.
  final bool expectsComparison;

  /// Texte expliquant la correction, transcrit du document.
  final String explanation;

  /// Le critère accepte-t-il la valeur [value] ?
  bool accepts(int value) => acceptedValues.contains(value);

  /// Le critère accepte-t-il l'expression normalisée [expression] ?
  bool acceptsExpression(String expression) =>
      acceptedExpressions.contains(expression);

  @override
  String toString() =>
      'CorrectionCriterion($acceptedValues, expr=$acceptedExpressions)';
}

/// Un indice consultable, proposé progressivement.
///
/// L'ORDRE est significatif : l'indice 1 est proposé avant l'indice 2, et
/// la banque interdit d'afficher d'emblée toute la solution.
class ExerciseHint {
  const ExerciseHint({
    required this.order,
    required this.text,
    this.kind,
  });

  /// Rang de l'indice, à partir de 1.
  ///
  /// Ne jamais réattribuer ces rangs : ils sont référencés par
  /// l'historique d'apprentissage.
  final int order;

  /// Texte de l'indice, transcrit du document validé.
  final String text;

  /// Nature de l'aide (ex. « methode », « exemple »).
  final String? kind;

  /// Identifiant stable du contenu d'indice, dérivé de son rang.
  ///
  /// L'ordre ne changeant jamais, cet identifiant reste valide dans
  /// l'historique d'apprentissage.
  String get hintId => 'h$order';

  @override
  String toString() => 'ExerciseHint(#$order)';
}

/// Question de compréhension associée à un exercice.
class ComprehensionQuestion {
  const ComprehensionQuestion({
    required this.question,
    required this.expectedAnswer,
  });

  /// Question brève, destinée à l'oral (cf. règle du document source).
  final String question;

  /// Réponse attendue, transcrite du document.
  final String expectedAnswer;

  @override
  String toString() => 'ComprehensionQuestion($question)';
}

/// Nature d'un élément de la banque.
///
/// Distingue les EXERCICES validés par le responsable pédagogique, des
/// TÂCHES DE VÉRIFICATION exigées par la banque pour contrôler une
/// remédiation. Les deux sont fidelity-transcrits, mais seuls les
/// exercices portent une numérotation officielle.
enum BankElementKind {
  /// Exercice de la banque pilote, numéroté de 1 à 11.
  exercise,

  /// Tâche de vérification post-rémediation.
  ///
  /// Les couples demandés par les cas de diagnostic (PGCD(16,12),
  /// PGCD(14,7), PGCD(24,16), PGCD(35,20)…) ne figurent pas parmi les
  /// 11 exercices validés : ils sont décrits ici comme tâches de contrôle,
  /// sans être réinventés comme exercices officiels.
  verificationTask,
}

/// Un élément de la banque : exercice officiel ou tâche de vérification.
class Exercise {
  const Exercise({
    required this.id,
    required this.lesson,
    required this.statement,
    required this.correction,
    this.kind = BankElementKind.exercise,
    this.expectedSteps = const <SolutionStep>[],
    this.hints = const <ExerciseHint>[],
    this.comprehension,
    this.followUpTask,
    this.diagnosticCaseIds = const <String>[],
  });

  /// Identifiant stable et unique. Jamais régénéré.
  final String id;

  /// Nature de l'élément : exercice officiel ou tâche de vérification.
  final BankElementKind kind;

  /// Leçon concernée.
  final ArithmeticLesson lesson;

  /// Énoncé présenté à l'élève, transcrit du document validé.
  final String statement;

  /// Critères de correction.
  final CorrectionCriterion correction;

  /// Étapes de résolution attendues.
  final List<SolutionStep> expectedSteps;

  /// Indices disponibles, par ordre croissant de [ExerciseHint.order].
  final List<ExerciseHint> hints;

  /// Question de compréhension éventuelle.
  final ComprehensionQuestion? comprehension;

  /// Exercice de suivi à proposer, pour vérifier le transfert.
  ///
  /// Renvoie l'identifiant d'un AUTRE exercice de la banque ; la
  /// vérification post-rémediation doit porter sur une tâche différente.
  final String? followUpTask;

  /// Cas de diagnostic éventuellement associés à cet exercice.
  final List<String> diagnosticCaseIds;

  /// Indices triés par ordre croissant.
  ///
  /// L'ordre est garanti : la banque exige une révélation progressive.
  List<ExerciseHint> get orderedHints {
    final sorted = List<ExerciseHint>.of(hints);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// L'indice suivant celui déjà consulté jusqu'à [consumedOrders].
  ///
  /// Retourne `null` si tous les indices ont été distribués : la banque
  /// interdit d'inventer une aide supplémentaire.
  ExerciseHint? nextHintAfter(Set<int> consumedOrders) {
    for (final hint in orderedHints) {
      if (!consumedOrders.contains(hint.order)) return hint;
    }
    return null;
  }

  @override
  String toString() => 'Exercise($id)';
}
