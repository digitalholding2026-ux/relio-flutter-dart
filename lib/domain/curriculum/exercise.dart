/// Modèle d'un exercice de la banque pilote.
///
/// Représentation STRUCTURÉE et testable : les 11 exercices du chapitre 1
/// sont décrits par des objets [Exercise], jamais par des conditions
/// dispersées dans l'interface.
///
/// Le contenu (énoncés, réponses attendues, indices) est une transcription
/// du document pédagogique validé : il n'est jamais inventé ici.
library;

import 'answer_normalization.dart';
import 'rich_hint.dart';

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
/// Contrat « la relation PPCM–PGCD a été APPLIQUÉE ».
///
/// Différent d'un simple critère de valeur : ici, une réponse correcte sans
/// trace du calcul ne vaut PAS preuve. `30` seul est le bon résultat, mais il
/// ne démontre rien.
///
/// Ce que le moteur contrôle, et seulement cela : ce que l'élève a ÉCRIT.
/// L'évaluateur vérifie que la réponse contient une division, qu'elle
/// s'évalue au PPCM attendu, et qu'elle n'est pas un nombre seul. Il ne
/// pretend observer ni le raisonnement, ni la méthode employée ailleurs.
class PpcmRelation {
  const PpcmRelation({
    required this.first,
    required this.second,
    required this.divisor,
    required this.result,
  });

  /// Le PGCD réel de [first] et [second].
  ///
  /// Permet de vérifier qu'un contrat n'est pas installé sur des données
  /// fausses — un test le fait sur toute la banque.
  bool get isCoherent =>
      divisor == _pgcd(first, second) && result == first * second ~/ divisor;

  static int _pgcd(int a, int b) => b == 0 ? a : _pgcd(b, a % b);

  /// Premier entier de la relation.
  final int first;

  /// Second entier de la relation.
  final int second;

  /// Le PGCD, qui divise le produit.
  final int divisor;

  /// Le PPCM attendu.
  final int result;

  @override
  String toString() =>
      'PpcmRelation(PPCM($first, $second) = $first*$second/$divisor = $result)';
}

class CorrectionCriterion {
  const CorrectionCriterion({
    this.acceptedValues = const <int>[],
    this.acceptedExpressions = const <String>[],
    this.expectsJustification = false,
    this.expectsComparison = false,
    this.explanation = '',
    this.ppcmRelation,
  });

  /// Contrat de relation PPCM–PGCD, ou `null` si le critère ne porte que
  /// sur la valeur.
  ///
  /// Quand il est présent, une valeur numérique seule N'EST PAS acceptée :
  /// le résultat correct ne prouve pas que la relation a été utilisée.
  final PpcmRelation? ppcmRelation;

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
  ///
  /// Comparaison faite forme normalisée contre forme normalisée : une même
  /// réponse écrite de deux façons ne doit pas être rejetée.
  bool acceptsExpression(String expression) {
    final needle = normalizeAnswer(expression);
    return acceptedExpressions.any((e) => normalizeAnswer(e) == needle);
  }

  /// Nature de la réponse attendue, DÉDUITE des critères ci-dessus.
  ///
  /// Règle, purement structurelle :
  ///  - aucune valeur numérique acceptée → réponse rédigée ;
  ///  - une variante purement textuelle acceptée (« verifie », « oui »)
  ///    → réponse rédigée, car un entier seul ne suffirait pas ;
  ///  - sinon → entier.
  ///
  /// Sur la banque du chapitre 1, cela donne exactement : exercices 1 à 9
  /// `integer`, exercices 10 et 11 `text`. Le test
  /// `answer_type_test.dart` verrouille ce résultat.
  AnswerType get answerType {
    if (acceptedValues.isEmpty) return AnswerType.text;
    final hasTextualForm = acceptedExpressions.any(
      (expression) => !looksNumeric(expression),
    );
    return hasTextualForm ? AnswerType.text : AnswerType.integer;
  }

  /// Le critère ne peut-il juger QUE du texte ?
  ///
  /// Vrai pour l'exercice 11 : aucune valeur entière n'y est acceptée. Une
  /// saisie numérique y est alors **non évaluable**, et ne doit en aucun cas
  /// être enregistrée comme fausse.
  bool get isTextOnly => acceptedValues.isEmpty;

  @override
  String toString() =>
      'CorrectionCriterion($acceptedValues, expr=$acceptedExpressions)';
}

/// Nature de la réponse attendue par un exercice.
///
/// CONTRAT TECHNIQUE, déduit des critères de correction, jamais posé à la
/// main : le risque d'une divergence entre le clavier affiché et la correction
/// devient nul, puisque les deux lisent la même donnée.
enum AnswerType {
  /// Un entier : le clavier numérique suffit.
  integer,

  /// Une rédaction ou une expression en mots : le clavier alphanumérique est
  /// nécessaire.
  text,
}

/// Un indice consultable, proposé progressivement.
///
/// L'ORDRE est significatif : l'indice 1 est proposé avant l'indice 2, et
/// la banque interdit d'afficher d'emblée toute la solution.
class ExerciseHint {
  const ExerciseHint({required this.order, required this.text, this.kind});

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
    this.richHints = const <RichHint>[],
    this.comprehension,
    this.followUpTask,
    this.diagnosticCaseIds = const <String>[],
    this.errorCases = const <String, String>{},
    this.givenPgcd,
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

  /// Fiches d'aide DÉFINITIVES, par rang croissant.
  ///
  /// Quand cette liste est renseignée, elle fait autorité : le nombre
  /// d'indices ouvrables, le contenu affiché et le budget en découlent. Les
  /// [hints] héritées ne sont alors plus qu'une trace de la transcription
  /// d'origine, conservée telle quelle pour l'historique.
  ///
  /// Elle est vide tant que le contenu pédagogique définitif n'a pas été
  /// fourni (règle 8) : les exercices sans fiches restent pilotés par [hints].
  final List<RichHint> richHints;

  /// Fiches définitives, triées par rang croissant.
  List<RichHint> get orderedRichHints {
    final sorted = List<RichHint>.of(richHints);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Combien d'indices l'élève peut réellement ouvrir sur cet exercice.
  ///
  /// Les fiches définitives priment : si la banque en fournit, elles seules
  /// comptent. C'est CETTE valeur que la règle de budget consomme comme «
  /// nombre d'indices réels de l'exercice ».
  int get hintCount =>
      orderedRichHints.isNotEmpty ? orderedRichHints.length : hints.length;

  /// Question de compréhension éventuelle.
  final ComprehensionQuestion? comprehension;

  /// Exercice de suivi à proposer, pour vérifier le transfert.
  ///
  /// Renvoie l'identifiant d'un AUTRE exercice de la banque ; la
  /// vérification post-rémediation doit porter sur une tâche différente.
  final String? followUpTask;

  /// Cas de diagnostic éventuellement associés à cet exercice.
  final List<String> diagnosticCaseIds;

  /// Réponses saisies associées explicitement à un cas de diagnostic.
  ///
  /// La clé est la réponse normalisée (voir [normalizeAnswer]), la valeur un
  /// identifiant de [Chapter1Bank.diagnosticCases]. Une correspondance ici est
  /// une décision de la banque : elle ouvre le panneau C avec l'intervention
  /// du cas, avant toute observation déduite de la réponse.
  ///
  /// Vide par défaut : une réponse non mappée suit le chemin habituel
  /// (observations, puis panneau E si rien n'est lisible).
  final Map<String, String> errorCases;

  /// Cas de diagnostic associé à [rawAnswer], ou `null`.
  ///
  /// La comparaison est normalisée : « 5 », « 5 » entouré d'espaces et une
  /// variante typographique de la même écriture désignent la même réponse.
  String? errorCaseFor(String rawAnswer) =>
      errorCases[normalizeAnswer(rawAnswer)];

  /// PGCD fourni par l'énoncé, quand la tâche ne demande QUE le PPCM.
  ///
  /// Ce n'est pas une réponse attendue : c'est une donnée LUE dans l'énoncé
  /// validé. Elle permet un fait strictement observable : si la réponse est
  /// fausse, le PGCD était juste (il était donné), donc le PPCM est faux.
  ///
  /// `null` partout ailleurs : aucun exercice ne reçoit cette donnée par
  /// déduction.
  final int? givenPgcd;

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
