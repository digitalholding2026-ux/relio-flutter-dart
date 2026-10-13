/// Test d'entree — persistance des reponses.
///
/// S'appuie sur `LearningEventRepository`, qui est deja transactionnel,
/// append-only et deduplique par identifiant. Aucune table, aucune migration,
/// aucun modele d'evenement modifie.
///
/// STRATEGIE D'IDENTIFIANTS — le point qui garantit l'idempotence :
///
///   LearningEventRepository deduplique sur `learning_events.id`, qui est
///   tire au sort (`newId`, UUID v4). Deux essais de la MEME reponse
///   produiraient donc deux identifiants DIFFERENTS, et la deduplication
///   ne protegerait rien.
///
///   Chaque evenement du test d'entree porte donc un identifiant DETERMINISTE
///   construit a partir de la session et de la question :
///
///       entry-test:<sessionId>:started
///       entry-test:<sessionId>:answer:<questionId>
///       entry-test:<sessionId>:completed
///
///   Rejouer une ecriture produit le MEME identifiant : la deduplication
///   s'applique, rien n'est duplique. Une session ne peut donc pas etre
///   demarree deux fois, ni une reponse enregistree deux fois.
///
/// Ce qui n'est PAS fait, deliberement :
///
///  - aucune liaison avec les lecons du chapitre 1 : `notionIds` reste vide ;
///  - aucun `ExerciseAttempt`, donc aucune `ObservedError` — une reponse non
///    evaluable ne creera jamais de fausse erreur pedagogique ;
///  - aucune note de maitrise, de score ou de niveau.
///
/// Le type d'evenement est une chaine libre, et les metadonnees un JSON
/// libre : le format tient dans `metadata_json`, sans toucher au schema.
library;

import '../../core/clock.dart';
import '../learning/activity_context.dart';
import '../learning/learning_event.dart';
import '../learning/learning_event_repository.dart';
import 'entry_test_correction.dart';
import 'entry_test_question.dart';
import 'entry_test_session.dart';

/// Persistance des reponses au test d'entree.
class EntryTestRepository {
  EntryTestRepository(
    this._events, {
    this._clock = systemClockUtc,
    List<EntryTestQuestion>? questions,
  }) : _questions = List<EntryTestQuestion>.unmodifiable(
          questions ?? EntryTestBank.questions,
        );

  /// Prefix des identifiants deterministes.
  static const String _idPrefix = 'entry-test';

  /// Type d'evenement : la session a ete demarree.
  static const String sessionStartedEventType = 'entry_test_session_started';

  /// Type d'evenement : une reponse a ete enregistree.
  static const String answerEventType = 'entry_test_answer';

  /// Type d'evenement : la session est terminee.
  static const String sessionCompletedEventType = 'entry_test_session_completed';

  /// Valeur d'`activityType` portee par les evenements du test d'entree.
  ///
  /// Renseigne systematiquement, contrairement au chapitre 1 qui laisse le
  /// contexte vide : c'est ce qui permet de relire uniquement les evenements
  /// du test d'entree, et de ne jamais les confondre avec des tentatives du
  /// chapitre 1.
  static const String activityType = 'entry_test';

  final LearningEventRepository _events;
  final Clock _clock;
  final List<EntryTestQuestion> _questions;

  /// Les cinq questions, dans l'ordre.
  List<EntryTestQuestion> get questions => _questions;

  /// Identifiant deterministe d'un evenement de session.
  ///
  /// Expose pour que les tests puissent prouver l'idempotence sans passer
  /// par une ecriture reelle.
  static String eventIdFor(String sessionId, String suffix) =>
      '$_idPrefix:$sessionId:$suffix';

  /// Enregistre le demarrage d'une session.
  ///
  /// Idempotent : deux appels produisent le meme identifiant, le second est
  /// ignore. Une session n'est donc jamais demarree deux fois.
  Future<bool> startSession({
    required String sessionId,
    required DateTime startedAt,
  }) {
    return _events.record(
      LearningEvent(
        id: eventIdFor(sessionId, 'started'),
        type: sessionStartedEventType,
        occurredAt: startedAt,
        context: ActivityContext(
          activityId: sessionId,
          activityType: activityType,
          source: 'app_android',
        ),
        metadata: <String, Object?>{'sessionId': sessionId},
      ),
    );
  }

  /// Enregistre la reponse a une question.
  ///
  /// Idempotent : rejouer la meme reponse ne cree aucun doublon.
  ///
  /// Ne leve pas d'exception en cas d'echec d'ecriture : l'appelant doit
  /// pouvoir retenter, et surtout ne pas croire que la reponse est partie.
  /// L'echec remonte tel quel de `LearningEventRepository`, qui n'absorbe
  /// rien — c'est volontaire : masquer une erreur d'ecriture produirait un
  /// « succes » alors que rien n'a ete enregistre.
  ///
  /// Renvoie `true` si la reponse a ete reellement ecrite, `false` si elle
  /// etait deja presente.
  Future<bool> recordAnswer({
    required String sessionId,
    required EntryTestQuestion question,
    required String rawAnswer,
    required EntryTestCorrection correction,
    required String normalizedAnswer,
    DateTime? answeredAt,
  }) {
    final DateTime at = answeredAt ?? _clock();
    return _events.record(
      LearningEvent(
        id: eventIdFor(sessionId, 'answer:${question.id}'),
        type: answerEventType,
        occurredAt: at,
        // Aucune notion du chapitre 1 : le test d'entree ne cree aucune
        // fausse association avec une lecon.
        notionIds: const <String>[],
        context: ActivityContext(
          activityId: sessionId,
          activityType: activityType,
          source: 'app_android',
        ),
        metadata: <String, Object?>{
          'sessionId': sessionId,
          'questionId': question.id,
          'order': question.order,
          'raw': rawAnswer,
          'normalized': normalizedAnswer,
          'correct': correction.isCorrect,
          'evaluated': correction.isEvaluated,
        },
      ),
    );
  }

  /// Marque la session comme terminee.
  ///
  /// Idempotent, comme les deux precedents.
  Future<bool> completeSession({
    required String sessionId,
    DateTime? completedAt,
  }) {
    final DateTime at = completedAt ?? _clock();
    return _events.record(
      LearningEvent(
        id: eventIdFor(sessionId, 'completed'),
        type: sessionCompletedEventType,
        occurredAt: at,
        context: ActivityContext(
          activityId: sessionId,
          activityType: activityType,
          source: 'app_android',
        ),
        metadata: <String, Object?>{'sessionId': sessionId},
      ),
    );
  }

  /// Relit une session et ses reponses.
  ///
  /// `null` si cette session n'a jamais ete demarree.
  Future<EntryTestSession?> loadSession(String sessionId) async {
    // PAS de `limit` ici. Le demarrage est recherche pour UNE session
    // donnee, or `findByType` ne filtre pas sur les metadonnees : limiter
    // la liste AVANT de filtrer rendrait introuvable toute session qui
    // n'est pas la plus recente. Le tri par date n'est pas un critere de
    // selection.
    final List<LearningEvent> started =
        await _events.findByType(sessionStartedEventType);

    // Une session inconnue ne doit pas ressembler a une session qui n'a
    // jamais demarre.
    final LearningEvent? start = _firstForSession(started, sessionId);
    if (start == null) return null;

    final List<LearningEvent> answers =
        await _events.findByType(answerEventType);
    final List<LearningEvent> completions =
        await _events.findByType(sessionCompletedEventType);

    final Map<String, EntryTestAnswer> parsed = <String, EntryTestAnswer>{};
    for (final LearningEvent event in _forSession(answers, sessionId)) {
      final EntryTestAnswer? answer = _parseAnswer(event);
      if (answer != null) parsed[answer.questionId] = answer;
    }

    final LearningEvent? completion = _firstForSession(completions, sessionId);

    return EntryTestSession(
      sessionId: sessionId,
      startedAt: start.occurredAt,
      questions: _questions,
      answers: parsed,
      completedAt: completion?.occurredAt,
    );
  }

  /// Identifiant de la DERNIERE session demarree, `null` si aucune.
  ///
  /// Sert a retrouver le test d'entree apres une fermeture de
  /// l'application, quand aucun identifiant de session n'a encore ete
  /// memorise cote parametres.
  Future<String?> findLatestSessionId() async {
    final List<LearningEvent> started =
        await _events.findByType(sessionStartedEventType);
    if (started.isEmpty) return null;

    // `findByType` rend le plus RECENT en premier. La PREMIERE entree est
    // donc la plus recente, et c'est celle qu'on cherche : une session
    // inachevee est par definition la derniere ouverte.
    final LearningEvent latest = started.first;
    final Object? sessionId = latest.metadata['sessionId'];
    if (sessionId is! String || sessionId.isEmpty) return null;
    return sessionId;
  }

  LearningEvent? _firstForSession(List<LearningEvent> events, String sessionId) {
    for (final LearningEvent event in events) {
      if (event.metadata['sessionId'] == sessionId) return event;
    }
    return null;
  }

  List<LearningEvent> _forSession(List<LearningEvent> events, String sessionId) =>
      <LearningEvent>[
        for (final LearningEvent e in events)
          if (e.metadata['sessionId'] == sessionId) e,
      ];

  EntryTestAnswer? _parseAnswer(LearningEvent event) {
    final Object? questionId = event.metadata['questionId'];
    final Object? order = event.metadata['order'];
    if (questionId is! String || order is! int) return null;

    final Object? raw = event.metadata['raw'];
    final Object? normalized = event.metadata['normalized'];
    final Object? correct = event.metadata['correct'];
    final Object? evaluated = event.metadata['evaluated'];

    return EntryTestAnswer(
      questionId: questionId,
      order: order,
      rawAnswer: raw is String ? raw : '',
      normalizedAnswer: normalized is String ? normalized : '',
      correction: EntryTestCorrection(
        isCorrect: correct == true,
        isEvaluated: evaluated == true,
      ),
      answeredAt: event.occurredAt,
    );
  }
}