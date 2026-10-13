/// Test d'entree — modele de session.
///
/// Une session est UNE passation. Elle porte son identifiant, son etat, et
/// les reponses deja enregistrees, rattachees a leurs questions.
///
/// L'ordre des questions est explicite : il vient de [questions], jamais de
/// l'ordre de lecture des evenements SQLite. Une lecture SQL sans clause
/// `ORDER BY` n'a aucun ordre garanti, et l'en deduire rendrait la reprise
/// dependante d'un detail d'implementation de la base.
library;

import 'entry_test_correction.dart';
import 'entry_test_question.dart';

/// Etat d'une session.
enum EntryTestSessionState {
  /// Au moins une question reste sans reponse enregistree.
  inProgress,

  /// Les cinq questions ont une reponse enregistree.
  completed,
}

/// Une reponse enregistree, liee a sa question.
///
/// IMMUABLE et VERBATIM : la saisie brute est conservee telle quelle, pour
/// l'audit. Le resultat d'evaluation l'est egalement — y compris lorsqu'il
/// n'est pas evaluable, puisque « non evaluable » EST une observation.
class EntryTestAnswer {
  const EntryTestAnswer({
    required this.questionId,
    required this.order,
    required this.rawAnswer,
    required this.normalizedAnswer,
    required this.correction,
    required this.answeredAt,
  });

  /// Question à laquelle cette réponse se rapporte.
  final String questionId;

  /// Rang de la question, recopié depuis la question elle-même.
  ///
  /// Recopié pour que la relecture ne doive pas charger la banque entière
  /// avant de pouvoir ordonner quoi que ce soit.
  final int order;

  /// Saisie de l'élève, telle quelle.
  final String rawAnswer;

  /// Forme normalisée ayant servi à la comparaison.
  final String normalizedAnswer;

  /// Résultat observable de l'évaluation.
  final EntryTestCorrection correction;

  /// Date de la réponse (UTC).
  final DateTime answeredAt;

  @override
  String toString() => 'EntryTestAnswer($questionId, '
      'correct=${correction.isCorrect}, evaluated=${correction.isEvaluated})';
}

/// Une passation du test d'entrée.
class EntryTestSession {
  EntryTestSession({
    required this.sessionId,
    required this.startedAt,
    required List<EntryTestQuestion> questions,
    Map<String, EntryTestAnswer> answers =
        const <String, EntryTestAnswer>{},
    this.completedAt,
  })  : questions = List<EntryTestQuestion>.unmodifiable(questions),
        answers = Map<String, EntryTestAnswer>.unmodifiable(answers);

  /// Identifiant stable de la passation.
  final String sessionId;

  /// Date de début (UTC).
  final DateTime startedAt;

  /// Date de fin (UTC), `null` tant que le test n'est pas terminé.
  final DateTime? completedAt;

  /// Les cinq questions, dans l'ordre de présentation.
  final List<EntryTestQuestion> questions;

  /// Réponses déjà enregistrées, indexées par identifiant de question.
  final Map<String, EntryTestAnswer> answers;

  /// La session est-elle terminée ?
  bool get isCompleted => completedAt != null;

  /// La session est-elle encore en cours ?
  bool get isInProgress => !isCompleted;

  /// État de la session.
  EntryTestSessionState get state => isCompleted
      ? EntryTestSessionState.completed
      : EntryTestSessionState.inProgress;

  /// Nombre de questions ayant une réponse enregistrée.
  int get answeredCount => answers.length;

  /// Nombre de questions restant sans réponse.
  int get remainingCount => questions.length - answers.length;

  /// Cette question a-t-elle déjà une réponse enregistrée ?
  bool hasAnswer(String questionId) => answers.containsKey(questionId);

  /// Réponse enregistrée pour cette question, `null` si aucune.
  EntryTestAnswer? answerFor(String questionId) => answers[questionId];

  /// Questions restant sans réponse, dans l'ordre.
  List<EntryTestQuestion> get remainingQuestions => <EntryTestQuestion>[
        for (final EntryTestQuestion q in questions)
          if (!answers.containsKey(q.id)) q,
      ];

  /// Première question sans réponse, `null` si tout est répondu.
  ///
  /// C'est le point de reprise : il est calculé à partir de [questions],
  /// donc de l'ordre DÉCLARÉ, et non de l'ordre de lecture des événements.
  EntryTestQuestion? get nextQuestion {
    for (final EntryTestQuestion q in questions) {
      if (!answers.containsKey(q.id)) return q;
    }
    return null;
  }

  /// Toutes les questions ont-elles une réponse enregistrée ?
  bool get isReadyToComplete =>
      questions.isNotEmpty && remainingCount == 0;

  /// Progression, dans l'ordre des questions.
  List<EntryTestAnswer> get orderedAnswers {
    final List<EntryTestAnswer> all =
        <EntryTestAnswer>[for (final EntryTestQuestion q in questions) if (answers[q.id] != null) answers[q.id]!];
    all.sort((EntryTestAnswer a, EntryTestAnswer b) => a.order.compareTo(b.order));
    return all;
  }

  /// Copie portant la réponse enregistrée à cette question.
  ///
  /// Une réponse déjà persistée n'est jamais écrasée : l'historique est
  /// append-only, et la première réponse fait foi. Réécrire n'aurait aucun
  ///sens — l'élève n'a pas « corrigé » sa réponse, il en a donné une autre.
  EntryTestSession withAnswer(EntryTestAnswer answer) {
    return EntryTestSession(
      sessionId: sessionId,
      startedAt: startedAt,
      questions: questions,
      answers: <String, EntryTestAnswer>{...answers, answer.questionId: answer},
      completedAt: completedAt,
    );
  }

  /// Copie portée par l'horodatage de fin.
  EntryTestSession asCompleted(DateTime at) {
    return EntryTestSession(
      sessionId: sessionId,
      startedAt: startedAt,
      questions: questions,
      answers: answers,
      completedAt: at,
    );
  }

  @override
  String toString() => 'EntryTestSession($sessionId, ${state.name}, '
      '$answeredCount/${questions.length})';
}