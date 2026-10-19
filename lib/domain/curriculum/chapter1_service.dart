/// Service d'intÃ©gration : relie la banque du chapitre 1 aux Ã©vÃ©nements
/// d'apprentissage existants.
///
/// Ce service NE REFAIT PAS la persistance : il utilise
/// [LearningEventRepository] et le modÃ¨le [LearningEvent] du socle. Aucun
/// Ã©tat parallÃ¨le n'est introduit.
///
/// Principe central : **aucun boolÃ©en de maÃ®trise n'est stockÃ©**. La
/// distinction autonome / assistÃ©e est dÃ©rivÃ©e de l'historique rÃ©el des
/// indices au moment de la classification.
// Le service utilise des champs privÃ©s initialisÃ©s depuis des paramÃ¨tres
// optionnels (horloge, moteur, gÃ©nÃ©rateur d'identifiants) : les
// initialising formals ne s'appliquent pas Ã  ce motif.
// ignore_for_file: prefer_initializing_formals
library;

import '../../core/clock.dart';
import 'answer_normalization.dart';
import 'arithmetic_expression.dart';
import '../../core/id.dart';
import '../learning/exercise_attempt.dart';
import '../learning/learning_event.dart';
import '../learning/learning_event_repository.dart';
import '../learning/observed_error.dart';
import '../learning/offered_hint.dart';
import 'chapter1_bank.dart';
import 'diagnostic_case.dart';
import 'diagnostic_engine.dart';
import 'exercise.dart';
import 'hint_trajectory.dart';
import 'rich_hint.dart';
import 'rich_hint_adapter.dart';

/// Type d'Ã©vÃ©nement Â« consultation d'indice Â».
///
/// Chaque indice consultÃ© est un Ã©vÃ©nement DISTINCT : l'ordre rÃ©el de
/// consultation est ainsi conservÃ© dans l'historique immuable.
const String kHintRequestedEventType = 'hint_requested';

/// Type d'Ã©vÃ©nement Â« tentative d'exercice Â».
const String kAttemptEventType = 'exercise_attempt';

/// Vue d'une tentative reconstituÃ©e depuis l'historique.
class AttemptRecord {
  AttemptRecord({
    required this.eventId,
    required this.exerciseId,
    required this.trajectory,
    required this.classification,
    required this.outcome,
    required this.attemptKey,
    this.submittedAt,
  });

  /// Identifiant de l'Ã©vÃ©nement d'apprentissage.
  final String eventId;

  /// ClÃ© reliant les indices consultÃ©s Ã  CETTE tentative.
  ///
  /// Distincte de [eventId] : les indices sont enregistrÃ©s avant la
  /// soumission, donc avant que l'identifiant dÃ©finitif n'existe.
  final String attemptKey;

  /// Exercice tentÃ©.
  final String exerciseId;

  /// Trajectoire des indices, dans l'ordre rÃ©el de consultation.
  final HintTrajectory trajectory;

  /// Classification dÃ©rivÃ©e des faits.
  final AttemptClassification classification;

  /// RÃ©sultat observable de la correction.
  final AnswerOutcome outcome;

  /// Date de soumission.
  final DateTime? submittedAt;

  /// La rÃ©ussite est-elle autonome (aucun indice consultÃ©) ?
  ///
  /// Une rÃ©ussite aprÃ¨s indice n'est JAMAIS autonome.
  bool get isAutonomous => classification == AttemptClassification.autonomousSuccess;

  @override
  String toString() =>
      'AttemptRecord($exerciseId, ${classification.name}, '
      'indices=${trajectory.consumedOrders})';
}

/// Resultat de la correction d'une rÃ©ponse, calculÃ© MÃ‰CANIQUEMENT.
///
/// Ne contient aucun jugement : uniquement l'adÃ©quation Ã  la rÃ©ponse
/// attendue du document validÃ©.
class CorrectionResult {
  const CorrectionResult({
    required this.isCorrect,
    required this.isEvaluated,
    required this.matchedValue,
  });

  /// La rÃ©ponse correspond-elle Ã  la rÃ©ponse attendue ?
  final bool isCorrect;

  /// La rÃ©ponse a-t-elle pu Ãªtre Ã©valuÃ©e ?
  final bool isEvaluated;

  /// Valeur attendue retenue, si la rÃ©ponse Ã©tait numÃ©rique.
  final int? matchedValue;
}

/// Corrige une rÃ©ponse saisie par rapport Ã  un exercice.
///
/// Correction purely FORMELLE : comparaison Ã  la rÃ©ponse attendue.
/// Aucune infÃ©rence pÃ©dagogique n'est faite ici.
CorrectionResult correct(Exercise exercise, String rawInput) {
  final raw = rawInput.trim();
  if (raw.isEmpty) {
    return const CorrectionResult(
      isCorrect: false,
      isEvaluated: true,
      matchedValue: null,
    );
  }

  final criterion = exercise.correction;

  // Contrat « relation appliquée » : la valeur seule ne suffit pas.
  //
  // La tâche exige une DÉMONSTRATION écrite. On évalue donc ce que l'élève a
  // écrit, et rien d'autre : jamais son raisonnement, jamais sa méthode.
  final relation = criterion.ppcmRelation;
  if (relation != null) {
    return _correcterParRelation(relation, raw);
  }

  // Expression textuelle normalisÃ©e (ex. Â« ppcm = produit / pgcd Â»).
  if (criterion.acceptsExpression(raw)) {
    return CorrectionResult(
      isCorrect: true,
      isEvaluated: true,
      matchedValue: criterion.acceptedValues.isEmpty
          ? null
          : criterion.acceptedValues.first,
    );
  }

  // Valeur numÃ©rique.
  final parsed = parseInteger(raw);
  if (parsed == null) {
    // Format non reconnu : distinct d'une rÃ©ponse fausse.
    return const CorrectionResult(
      isCorrect: false,
      isEvaluated: false,
      matchedValue: null,
    );
  }

  // Text-only criterion (exercise 11): no integer value is accepted, a
  // written relation is expected. An integer entered there proves neither
  // right nor wrong. Marking it "false" would be a false NEGATIVE, and the
  // verdict would be written DEFINITIVELY into the append-only history.
  if (criterion.isTextOnly) {
    return const CorrectionResult(
      isCorrect: false,
      isEvaluated: false,
      matchedValue: null,
    );
  }

  final matches = criterion.accepts(parsed);
  return CorrectionResult(
    isCorrect: matches,
    isEvaluated: true,
    matchedValue: matches ? parsed : null,
  );
}

/// Corrige une réponse face à un contrat de relation PPCM–PGCD.
///
/// QUATRE issues, jamais confondues :
///
///  - **réussite** : une division est écrite, elle s'évalue au PPCM attendu
///    et le membre de droite de l'égalité, s'il y en a un, est correct ;
///  - **échec évalvable** : le calcul est écrit et cohérent, mais il donne
///    une autre valeur. L'élève s'est trompé de calcul : c'est un fait ;
///  - **non évaluable** : un nombre seul (`30`), une expression sans
///    division (`6*5`), ou une écriture incompréhensible. Dans ce cas on ne
///    conclut RIEN : conclure « faux » à partir de `30` serait exactement
///    le faux négatif que ce contrat doit éviter.
CorrectionResult _correcterParRelation(PpcmRelation relation, String raw) {
  final evaluation = evaluateArithmetic(raw);

  // Nombre seul : le bon résultat, sans aucune démonstration.
  if (evaluation.isBareNumber) {
    return const CorrectionResult(
      isCorrect: false,
      isEvaluated: false,
      matchedValue: null,
    );
  }

  // Expression incompréhensible : aucune conclusion possible.
  if (!evaluation.isEvaluable) {
    return const CorrectionResult(
      isCorrect: false,
      isEvaluated: false,
      matchedValue: null,
    );
  }

  // Pas de division : le calcul est peut-être juste, mais la relation n'est
  // pas montrée. « 6*5 = 30 » ne dit rien de la relation PPCM–PGCD.
  if (!evaluation.usedDivision) {
    return const CorrectionResult(
      isCorrect: false,
      isEvaluated: false,
      matchedValue: null,
    );
  }

  final correcte = evaluation.equalityHolds &&
      evaluation.value!.round() == relation.result;
  return CorrectionResult(
    isCorrect: correcte,
    isEvaluated: true,
    matchedValue: correcte ? relation.result : null,
  );
}

// Number parsing and answer normalization now live in
// `answer_normalization.dart`, shared with the exercise model so that the
// keyboard contract and the correction contract cannot diverge.


/// Service d'intÃ©gration de la banque du chapitre 1.
class Chapter1Service {
  Chapter1Service(
    this._repository, {
    Clock clock = systemClockUtc,
    DiagnosticEngine engine = const DiagnosticEngine(),
    String Function()? idGenerator,
  })  : _clock = clock,
        _engine = engine,
        _newId = idGenerator ?? newId;

  final LearningEventRepository _repository;
  final Clock _clock;
  final DiagnosticEngine _engine;
  final String Function() _newId;

  /// Moteur de diagnostic utilisÃ©.
  DiagnosticEngine get engine => _engine;

  // ---------------------------------------------------------------------
  // Lecture de la banque
  // ---------------------------------------------------------------------

  /// Les 11 exercices validÃ©s.
  List<Exercise> get exercises =>
      Chapter1Bank.exercises.where((e) => e.kind == BankElementKind.exercise).toList();

  /// Les tÃ¢ches de vÃ©rification post-rÃ©mediation.
  List<Exercise> get verificationTasks =>
      Chapter1Bank.verificationTasks.toList();

  /// Exercice par identifiant (exercices ET tÃ¢ches de vÃ©rification).
  Exercise? findExercise(String id) => Chapter1Bank.findExercise(id);

  /// Prochain indice Ã  proposer, selon l'ordre de la banque.
  ///
  /// Retourne `null` si tous les indices ont Ã©tÃ© distribuÃ©s : la banque
  /// interdit d'afficher d'emblÃ©e toute la solution, et n'autorise pas
  /// d'inventer une aide supplÃ©mentaire.
  /// Le prochain indice que le budget autorise encore, ou `null`.
  ///
  /// Le budget est la seule autorité : si l'élève a déjà consommé tout ce que
  /// la règle lui accorde, la méthode renvoie `null` même si la banque
  /// possède d'autres fiches. Aucune aide n'est fabriquée au-delà.
  RichHint? nextHint(Exercise exercise, Set<int> consumedOrders) {
    if (hintBudget(exercise, consumedOrders).isExhausted) return null;
    return nextRichHintAfter(exercise, consumedOrders);
  }

  /// Budget d'aide de l'exercice, a l'instant presente.
  ///
  /// LE MOTEUR PORTE LE CALCUL, L'ECRAN NE FAIT QU'LE LIRE.
  ///
  /// L'interface ne decremente jamais le budget elle-meme : apres avoir
  /// enregistre une consultation, elle redemande ce budget et affiche le
  /// nouveau libelle. Cette methode est donc l'unique source du nombre affiche
  /// dans le bouton.
  HintBudget hintBudget(
    Exercise exercise,
    Set<int> consumedOrders, {
    String? previousExerciseId,
  }) =>
      HintBudget(
        maxHintsAllowed: maxHintsFor(exercise),
        hintsConsumed: consumedOrders.length,
        previousExerciseId: previousExerciseId,
      );

  /// Combien d'indices la REGLE DE BUDGET accorde a cet exercice.
  ///
  /// L'aide se retire progressivement dans la lecon : le premier exercice
  /// d'une lecon peut beneficier de toutes les fiches du premier, le dernier
  /// n'en garde qu'une. Notations :
  ///
  ///  - `N` : nombre d'EXERCICES OFFICIELS de la lecon. Les taches de
  ///    verification ne comptent pas : elles ne sont pas des exercices de la
  ///    lecon et ne recoivent pas d'indice.
  ///  - `M` : nombre d'indices reels du PREMIER exercice de la lecon ;
  ///  - `i` : position de l'exercice dans sa lecon, a partir de 1.
  ///
  /// La formule est une interpolation lineaire de `M` a 1 :
  ///
  ///     budget(i) = max(1, M - (i - 1) * (M - 1) / (N - 1))
  ///
  /// arrondie a l'entier le plus proche. Le plancher de 1 garantit qu'aucun
  /// exercice ne devient muet, et le budget reel ne peut jamais depasser le
  /// nombre de fiches que l'exercice possede reellement.
  ///
  /// Cas limite d'une lecon d'un seul exercice : l'interpolation n'a pas de
  /// sens, on accorde le budget integral.
  int maxHintsFor(Exercise exercise) {
    final siblings = <Exercise>[
      for (final candidate in Chapter1Bank.exercises)
        if (candidate.kind == BankElementKind.exercise &&
            candidate.lesson == exercise.lesson)
          candidate,
    ];

    // La lecon n'existe pas dans la banque, ou n'a qu'un exercice.
    final position = siblings.indexWhere((e) => e.id == exercise.id);
    if (siblings.length < 2 || position < 0) return exercise.hintCount;

    final n = siblings.length;
    final m = siblings.first.hintCount;
    final interpolated = m - (position * (m - 1) / (n - 1));
    final rounded = interpolated.round();
    final granted = rounded < 1 ? 1 : rounded;

    // Jamais plus de fiches que l'exercice n'en possede.
    return granted > exercise.hintCount ? exercise.hintCount : granted;
  }

  // ---------------------------------------------------------------------
  // Enregistrement
  // ---------------------------------------------------------------------

  /// Enregistre la consultation d'un indice comme Ã©vÃ©nement immuable.
  ///
  /// Un indice = un Ã©vÃ©nement : l'ordre de consultation est ainsi conservÃ©
  /// sans aucune colonne d'ordre Ã  maintenir.
  ///
  /// [attemptKey] relie l'indice Ã  la tentative en cours, y compris si
  /// l'application se ferme avant la soumission.
  Future<String> recordHintRequested({
    required String attemptKey,
    required Exercise exercise,
    required int hintOrder,
  }) async {
    final card = richHintsOf(exercise)
        .where((c) => c.order == hintOrder)
        .firstOrNull;
    if (card == null) {
      throw ArgumentError(
        'Indice #$hintOrder inexistant pour ${exercise.id}',
      );
    }

    // Nature et texte d'origine lorsqu'ils existent encore : ce sont les
    // métadonnées de la transcription validée, pas une reconstruction.
    final legacy = exercise.orderedHints
        .where((h) => h.order == hintOrder)
        .firstOrNull;

    final now = _clock();
    final event = LearningEvent(
      id: _newId(),
      type: kHintRequestedEventType,
      occurredAt: now,
      notionIds: _notionsFor(exercise),
      metadata: <String, Object?>{
        'attemptKey': attemptKey,
        'exerciseId': exercise.id,
        'hintOrder': card.order,
        'hintId': card.hintId,
        'hintKind': legacy?.kind,
        'hintText': _plainTextOf(card),
      },
    );

    await _repository.record(event);
    return event.id;
  }

  /// Enregistre une tentative d'exercice avec sa correction et son
  /// erreur constatÃ©e.
  ///
  /// [attemptKey] identifie la tentative EN COURS, avant soumission : c'est
  /// lui qui relie les Ã©vÃ©nements d'indices Ã  la tentative, et non
  /// l'identifiant dÃ©finitif de l'Ã©vÃ©nement de soumission.
  ///
  /// [hintOrders] est l'ENSEMBLE des indices consultÃ©s AVANT cette
  /// soumission : c'est ce qui permet de dÃ©river une rÃ©ussite assistÃ©e
  /// sans stocker d'Ã©tat supplÃ©mentaire.
  Future<AttemptRecord> recordAttempt({
    required Exercise exercise,
    required String rawAnswer,
    String? attemptKey,
    Set<int> hintOrders = const <int>{},
    String? errorType,
    bool showSteps = true,
  }) async {
    final correction = correct(exercise, rawAnswer);
    final now = _clock();
    final resolvedKey = attemptKey ?? 'attempt-${_newId()}';

    final trajectory = HintTrajectory(<ConsumedHint>[
      for (final order in hintOrders)
        ConsumedHint(order: order, consumedAt: now, hintId: _hintId(exercise, order)),
    ]);

    final classification = trajectory.classify(
      isCorrect: correction.isCorrect,
      isEmpty: rawAnswer.trim().isEmpty,
      notEvaluated: !correction.isEvaluated,
    );

    final attempt = ExerciseAttempt(
      exerciseId: exercise.id,
      startedAt: now,
      submittedAt: now,
      outcome: correction.isCorrect
          ? AnswerOutcome.correct
          : (correction.isEvaluated ? AnswerOutcome.incorrect : AnswerOutcome.notEvaluated),
      answer: StudentAnswer(
        answerId: 'a-${exercise.id}',
        rawText: rawAnswer,
        normalizedValue: rawAnswer.trim(),
        isEmpty: rawAnswer.trim().isEmpty,
      ),
      // Une erreur constatÃ©e n'est dÃ©crite que si elle est identifiable :
      // `errorType` reste NULL sinon, jamais devinÃ©.
      error: ObservedError(
        id: _newId(),
        occurredAt: now,
        errorType: errorType,
        description: errorType == null && !correction.isCorrect
            ? 'RÃ©ponse non conforme Ã  la rÃ©ponse attendue.'
            : null,
      ),
      // Le dernier indice consultÃ© est conservÃ© pour l'affichage ; la
      // trajectoire complÃ¨te reste dans les Ã©vÃ©nements `hint_requested`.
      hint: hintOrders.isEmpty
          ? null
          : OfferedHint(
              id: _newId(),
              offeredAt: now,
              hintId: _hintId(exercise, hintOrders.last),
              kind: 'methode',
            ),
      context: null,
    );

    final event = LearningEvent(
      id: _newId(),
      type: kAttemptEventType,
      occurredAt: now,
      notionIds: _notionsFor(exercise),
      attempt: attempt,
      metadata: <String, Object?>{
        'exerciseId': exercise.id,
        'lessonId': exercise.lesson.id,
        // ClÃ© de tentative reliant les indices consultÃ©s Ã  cette soumission.
        'attemptKey': resolvedKey,
        // Ordre rÃ©el de consultation : conservÃ© comme FAIT.
        'hintOrders': hintOrders.toList()..sort(),
        'classification': classification.name,
        'stepsShown': showSteps,
      },
    );

    await _repository.record(event);

    return AttemptRecord(
      eventId: event.id,
      attemptKey: resolvedKey,
      exerciseId: exercise.id,
      trajectory: trajectory,
      classification: classification,
      outcome: attempt.outcome,
      submittedAt: now,
    );
  }

  // ---------------------------------------------------------------------
  // Reconstruction depuis l'historique
  // ---------------------------------------------------------------------

  /// Reconstitue une tentative depuis les Ã©vÃ©nements persistÃ©s.
  ///
  /// La classification est RECALCULÃ‰E depuis les Ã©vÃ©nements d'indices : elle
  /// ne dÃ©pend d'aucun Ã©tat stockÃ©, donc ne peut pas devenir incohÃ©rente.
  Future<AttemptRecord?> findAttempt(String eventId) async {
    final event = await _repository.findById(eventId);
    if (event == null) return null;

    // Les indices sont rattachÃ©s Ã  la CLÃ‰ de tentative, pas Ã  l'identifiant
    // de l'Ã©vÃ©nement : ils sont enregistrÃ©s avant la soumission.
    final key = (event.metadata['attemptKey'] as String?) ?? event.id;
    final hintEvents = await _repository.findByType(kHintRequestedEventType);
    final consumed = <ConsumedHint>[
      for (final hintEvent in hintEvents)
        if (hintEvent.metadata['attemptKey'] == key)
          if (hintEvent.metadata['hintOrder'] case final int order)
            ConsumedHint(order: order, consumedAt: hintEvent.occurredAt),
    ];

    final trajectory = HintTrajectory(consumed);

    final outcome = event.attempt?.outcome ?? AnswerOutcome.notEvaluated;
    final isCorrect = outcome == AnswerOutcome.correct;
    final isEmpty = event.attempt?.answer?.isEmpty ?? false;

    return AttemptRecord(
      eventId: event.id,
      attemptKey: (event.metadata['attemptKey'] as String?) ?? event.id,
      exerciseId: event.attempt?.exerciseId ?? '',
      trajectory: trajectory,
      classification: trajectory.classify(
        isCorrect: isCorrect,
        isEmpty: isEmpty,
        notEvaluated: outcome == AnswerOutcome.notEvaluated,
        abandoned: outcome == AnswerOutcome.abandoned,
      ),
      outcome: outcome,
      submittedAt: event.attempt?.submittedAt,
    );
  }

  /// Historique des indices d'une tentative, dans l'ordre rÃ©el.
  ///
  /// [attemptKey] est la clÃ© de tentative, pas l'identifiant de
  /// l'Ã©vÃ©nement de soumission.
  Future<List<ConsumedHint>> hintHistoryOf(String attemptKey) async {
    final hintEvents = await _repository.findByType(kHintRequestedEventType);
    return <ConsumedHint>[
      for (final hintEvent in hintEvents)
        if (hintEvent.metadata['attemptKey'] == attemptKey)
          if (hintEvent.metadata['hintOrder'] case final int order)
            ConsumedHint(order: order, consumedAt: hintEvent.occurredAt),
    ]..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
  }

  /// Lance un diagnostic sur une tentative observÃ©e.
  ///
  /// Les FAITS sont fournis par l'appelant ; le moteur ne produit que des
  /// hypothÃ¨ses.
  DiagnosisOutcome diagnose({
    required AttemptObservation observation,
    required String failedExerciseId,
    int clarificationAlreadyAsked = 0,
  }) {
    return _engine.diagnose(
      DiagnosticContext(
        observation: observation,
        failedExerciseId: failedExerciseId,
        clarificationAlreadyAsked: clarificationAlreadyAsked,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Interne
  // ---------------------------------------------------------------------

  String? _hintId(Exercise exercise, int order) {
    for (final hint in richHintsOf(exercise)) {
      if (hint.order == order) return hint.hintId;
    }
    return null;
  }

  /// Texte plat d'une fiche : ses blocs concaténés, dans l'ordre de lecture.
  ///
  /// Sert uniquement à l'historique. AUCUN mot n'est ajouté ni reformulé :
  /// l'événement enregistre ce que l'élève a réellement lu.
  static String _plainTextOf(RichHint card) =>
      card.blocks.map((block) => block.text).join(' ').trim();

  /// Notions concernÃ©es par un exercice.
  ///
  /// Aucun contenu pÃ©dagogique n'est inventÃ© : les identifiants sont
  /// dÃ©rivÃ©s de la leÃ§on, ce sont des clÃ©s structurelles.
  List<String> _notionsFor(Exercise exercise) => <String>['lecon-${exercise.lesson.id}'];
}

