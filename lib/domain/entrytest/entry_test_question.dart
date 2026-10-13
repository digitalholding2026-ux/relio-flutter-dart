/// Test d'entree — definition des questions.
///
/// Banque DEDIEE, volontairement separee de `Chapter1Bank` :
///
///  - le chapitre 1 parle de PGCD et de PPCM, le test d'entree non ;
///  - `Chapter1Bank` est verrouillee par des tests qui verifient son contenu
///    (voir `test/curriculum/correction_test.dart`) ;
///  - un test d'entree ne doit creer aucune association avec une lecon.
///
/// Les identifiants et l'ordre sont FIGES : ils voyagent dans la
/// persistance et doivent rester stables au fil des versions compatibles.
/// Les renommer orphelinerait les sessions deja enregistrees.
library;

/// Nature de la reponse attendue par une question.
enum EntryTestAnswerType {
  /// Un entier. L'eleve saisit un nombre.
  integer,

  /// Un choix parmi une liste fermee et connue.
  choice,
}

/// Une question du test d'entree.
///
/// Les criteres de correction NE SONT PAS ici : ils appartiennent a
/// `EntryTestEvaluator`. Cette classe ne porte que l'IDENTITE et le
/// CONTENU de la question, jamais la facon de juger une reponse.
class EntryTestQuestion {
  const EntryTestQuestion({
    required this.id,
    required this.order,
    required this.statement,
    required this.answerType,
    required this.expectedValue,
    this.choices = const <String>[],
  });

  /// Identifiant stable, versionne avec la banque.
  final String id;

  /// Rang dans le test, a partir de 1.
  ///
  /// EXPLICITE, et jamais deduit de l'ordre de lecture des evenements : la
  /// lecture SQL ne garantit aucun ordre, et le deduire rendrait la reprise
  /// dependante d'un detail de la base.
  final int order;

  /// Enonce affiche a l'eleve.
  final String statement;

  /// Nature de la reponse attendue.
  final EntryTestAnswerType answerType;

  /// Reponse attendue, sous sa forme textuelle.
  ///
  /// Un entier pour [EntryTestAnswerType.integer], un des [choices] pour
  /// [EntryTestAnswerType.choice].
  final String expectedValue;

  /// Choix proposes, dans l'ordre d'affichage.
  ///
  /// Vide sauf pour [EntryTestAnswerType.choice]. Une liste fermee est ce qui
  /// permet de distinguer « choix errone » de « choix inconnu » : un choix
  /// absent d'ici n'est pas evaluable.
  final List<String> choices;

  /// Cette question est-elle a choix multiple ?
  bool get isChoice => answerType == EntryTestAnswerType.choice;

  @override
  String toString() =>
      'EntryTestQuestion($id, ordre=$order, type=${answerType.name})';
}

/// Les cinq questions du test d'entree, dans l'ordre.
///
/// Contenu transcrit du document pedagogique valide. Il n'est pas modifie,
/// ni complete, ni interprete : les seules decisions portent sur les
/// criteres de correction, dans `EntryTestEvaluator`.
abstract final class EntryTestBank {
  const EntryTestBank._();

  /// Question 1 — calcul numerique.
  static const EntryTestQuestion q1 = EntryTestQuestion(
    id: 'entry-q1',
    order: 1,
    statement: '24 ÷ 6 + 3',
    answerType: EntryTestAnswerType.integer,
    expectedValue: '7',
  );

  /// Question 2 — fractions, a choix multiple.
  static const EntryTestQuestion q2 = EntryTestQuestion(
    id: 'entry-q2',
    order: 2,
    statement: 'Quelle fraction est égale à 1/2 ?',
    answerType: EntryTestAnswerType.choice,
    expectedValue: '2/4',
    choices: <String>['2/3', '2/4', '3/4'],
  );

  /// Question 3 — nombres relatifs.
  static const EntryTestQuestion q3 = EntryTestQuestion(
    id: 'entry-q3',
    order: 3,
    statement: '(-3) + 5',
    answerType: EntryTestAnswerType.integer,
    expectedValue: '2',
  );

  /// Question 4 — substitution algebrique.
  static const EntryTestQuestion q4 = EntryTestQuestion(
    id: 'entry-q4',
    order: 4,
    statement: 'Si x=3, quelle est la valeur de 2x+1 ?',
    answerType: EntryTestAnswerType.integer,
    expectedValue: '7',
  );

  /// Question 5 — equation.
  static const EntryTestQuestion q5 = EntryTestQuestion(
    id: 'entry-q5',
    order: 5,
    statement: 'Trouve le nombre x tel que x+4=9',
    answerType: EntryTestAnswerType.integer,
    expectedValue: '5',
  );

  /// Les cinq questions, dans l'ordre de presentation.
  ///
  /// La liste est explicitement ordonnee par [EntryTestQuestion.order], et
  /// non supposee : ajouter une question ne peut pas la deplacer par effet
  /// de bord de l'ecriture du fichier.
  static List<EntryTestQuestion> get questions {
    final List<EntryTestQuestion> all = <EntryTestQuestion>[q1, q2, q3, q4, q5];
    all.sort(
      (EntryTestQuestion a, EntryTestQuestion b) => a.order.compareTo(b.order),
    );
    return List<EntryTestQuestion>.unmodifiable(all);
  }

  /// Identifiants de toutes les questions, dans l'ordre.
  static List<String> get questionIds =>
      <String>[for (final EntryTestQuestion q in questions) q.id];

  /// Question portant cet identifiant, `null` si inconnue.
  static EntryTestQuestion? find(String id) {
    for (final EntryTestQuestion q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }
}