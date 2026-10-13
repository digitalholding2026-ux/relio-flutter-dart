/// Test d'entree — orchestration du parcours d'entree.
///
/// Assemble les decisions VALIDÉES du parcours dans un seul endroit :
/// reprise de session, verrouillage apres cloture, et moment de la marque
/// de fin du premier lancement. Aucun ecran, aucun widget : cette classe
/// n'expose que des operations metier.
///
/// Elle ne fait QUE relier des briques existantes — `SettingsRepository`
/// pour le prenom et le drapeau de premier lancement, `EntryTestRepository`
/// pour les reponses. Aucune requete SQL n'y figure.
library;

import '../../core/clock.dart';
import '../../core/id.dart';
import '../settings/learner_settings.dart';
import 'entry_test_correction.dart';
import 'entry_test_question.dart';
import 'entry_test_repository.dart';
import 'entry_test_session.dart';

/// Parcours d'entree : session de test d'entree et fin du premier lancement.
class EntryTestOnboarding {
  EntryTestOnboarding(
    this._entries,
    this._settings, {
    this._evaluator = const EntryTestEvaluator(),
    this._clock = systemClockUtc,
    String Function()? idGenerator,
  }) : _newId = idGenerator ?? newId;

  final EntryTestRepository _entries;
  final SettingsRepository _settings;
  final EntryTestEvaluator _evaluator;
  final Clock _clock;
  final String Function() _newId;

  /// Questions du test, dans l'ordre.
  List<EntryTestQuestion> get questions => _entries.questions;

  /// Un prenom est-il deja disponible ?
  ///
  /// Un prenom « valide » est un prenom non vide apres trim : c'est ce qui
  /// evite de redemander un prenom a l'eleve qui en a deja fourni un.
  Future<bool> hasValidName() async {
    final LearnerSettings settings = await _settings.load();
    return settings.name.trim().isNotEmpty;
  }

  /// Prénom actuellement enregistré, chaîne vide si aucun.
  Future<String> storedName() async {
    final LearnerSettings settings = await _settings.load();
    return settings.name.trim();
  }

  // ---------------------------------------------------------------------
  // Marqueurs du parcours — PURS DELEGATES.
  //
  // Aucune logique métier ici : ces quatre méthodes relaient
  // `SettingsRepository`. Leur seule raison d'être est de donner à
  // l'interface UN SEUL point d'accès au parcours, afin qu'elle ne
  // manipule jamais `SettingsRepository` directement pour l'onboarding.
  //
  // Les deux marqueurs sont INDÉPENDANTS et ne doivent jamais l'être :
  // `entryScreenSeen` dit « l'écran a été vu », `firstLaunchCompleted`
  // dit « le parcours est terminé ». Les confondre ferait perdre un test
  // d'entrée interrompu.
  // ---------------------------------------------------------------------

  /// L'écran d'entrée a-t-il déjà été vu ?
  ///
  /// Vrai dès que l'écran a été présenté, même si le test d'entrée
  /// commencé ensuite a été abandonné. Ne signifie PAS que le parcours
  /// est terminé, et ne dispense jamais de reprendre une session
  /// inachevée.
  Future<bool> hasSeenEntryScreen() => _settings.hasSeenEntryScreen();

  /// Marque l'écran d'entrée comme vu, sans solder le parcours.
  ///
  /// Appelé au tap sur « Commencer ». N'écrit ni session ni
  /// `firstLaunchCompleted`.
  Future<void> markEntryScreenSeen() => _settings.markEntryScreenSeen();

  /// Le parcours d'onboarding a-t-il été mené à son terme ?
  ///
  /// Vrai seulement après la fin RÉELLE du test d'entrée, tel qu'écrit par
  /// [finishSession].
  Future<bool> hasCompletedFirstLaunch() =>
      _settings.hasCompletedFirstLaunch();

  /// Marque le parcours comme terminé.
  ///
  /// ⚠️ N'appelez pas cette méthode au simple passage de l'écran d'entrée :
  /// elle est réservée à la clôture du parcours, déjà écrite par
  /// [finishSession]. L'appeler au tap sur « Commencer » empêcherait
  /// l'élève de reprendre un test interrompu.
  Future<void> markFirstLaunchCompleted() =>
      _settings.markFirstLaunchCompleted();

  /// Ouvre la session de test d'entrée : reprise si elle existe, création
  /// sinon.
  ///
  /// DÉCISION 4 — si une session est inachevée, elle est reprise. Ses
  /// réponses sont relues et la première question sans réponse est
  /// ré-exposée via [EntryTestSession.nextQuestion].
  ///
  /// DÉCISION 5 — si une session est DÉJÀ terminée, elle est renvoyée telle
  /// quelle et n'est JAMAIS rouverte. Aucune nouvelle passation n'est
  /// lancée automatiquement : la passation initiale reste la référence.
  Future<EntryTestSession> openSession() async {
    final String? stored = await _settings.entryTestSessionId();

    // Une session memorisee est la source de verite. Si elle est introuvable
    // — base reinitialisee, identifiant obsolete — on en cherche une autre
    // plutot que d'en creer silencieusement une nouvelle.
    if (stored != null) {
      final EntryTestSession? session = await _entries.loadSession(stored);
      if (session != null) return session;
      final String? latest = await _entries.findLatestSessionId();
      if (latest != null) {
        final EntryTestSession? previous = await _entries.loadSession(latest);
        if (previous != null) return previous;
      }
    }

    final String sessionId = _newId();
    await _entries.startSession(sessionId: sessionId, startedAt: _clock());
    // La cle de reprise n'est ecrite qu'APRÈS l'evenement de demarrage
    // reussi : memoriser un identifiant avant d'avoir reussi a ecrire
    // laisserait un rappel vers une session inexistante.
    await _settings.saveEntryTestSessionId(sessionId);

    return EntryTestSession(
      sessionId: sessionId,
      startedAt: _clock(),
      questions: questions,
    );
  }

  /// Évalue et enregistre la réponse à [question].
  ///
  /// Renvoie le résultat observable. Ne modifie rien d'autre.
  ///
  /// DÉCISION 3 — en cas d'échec d'écriture, l'erreur REMONTE et la session
  /// n'est pas avancée. L'appelant peut rappeler cette méthode : la
  /// réponse porte un identifiant déterministe, donc la seconde tentative
  /// écrira au plus une fois. Aucun doublon ne peut être créé.
  ///
  /// Lève [StateError] si la session est déjà terminée : une passation
  /// terminée ne se poursuit pas, c'est la décision 5.
  Future<EntryTestAnswer> submitAnswer({
    required EntryTestSession session,
    required EntryTestQuestion question,
    required String rawAnswer,
  }) async {
    if (session.isCompleted) {
      throw StateError(
        'La session ${session.sessionId} est terminee : aucune reponse ne peut '
        'y etre ajoutee.',
      );
    }
    if (!session.questions.any((EntryTestQuestion q) => q.id == question.id)) {
      throw StateError(
        'La question ${question.id} n\'appartient pas a cette session.',
      );
    }

    final EntryTestCorrection correction =
        _evaluator.evaluate(question, rawAnswer);
    final String normalized = _evaluator.normalize(question, rawAnswer);
    final DateTime at = _clock();

    // L'echec d'ecriture se propage tel quel. `recordAnswer` n'absorbe
    // rien : c'est ce qui garantit qu'aucune reponse n'est perdue en silence
    // tout en croyant l'avoir enregistree.
    await _entries.recordAnswer(
      sessionId: session.sessionId,
      question: question,
      rawAnswer: rawAnswer,
      correction: correction,
      normalizedAnswer: normalized,
      answeredAt: at,
    );

    return EntryTestAnswer(
      questionId: question.id,
      order: question.order,
      rawAnswer: rawAnswer,
      normalizedAnswer: normalized,
      correction: correction,
      answeredAt: at,
    );
  }

  /// Termine la session et marque la fin du premier lancement.
  ///
  /// DÉCISION 6 — `firstLaunchCompleted` n'est écrit qu'ici, et seulement
  /// quand la session est réellement complète. Un test à moitié fait ne
  /// marque donc PAS la fin du parcours : le drapeau reste faux, et
  /// l'écran d'entrée sera rejoué au prochain lancement, ce qui laisse
  /// l'élève reprendre son test.
  ///
  /// Lève [StateError] si toutes les questions n'ont pas de réponse : on ne
  /// déclare jamais terminé ce qui ne l'est pas.
  Future<EntryTestSession> finishSession(EntryTestSession session) async {
    if (session.isCompleted) return session;
    if (!session.isReadyToComplete) {
      throw StateError(
        'La session ${session.sessionId} comporte encore '
        '${session.remainingCount} question(s) sans reponse : elle ne peut pas '
        'etre terminee.',
      );
    }

    final DateTime at = _clock();
    await _entries.completeSession(
      sessionId: session.sessionId,
      completedAt: at,
    );

    // Le drapeau n'est pose qu'APRES l'evenement de fin reussi. Dans
    // l'autre sens, un echec d'ecriture laisserait « parcours termine » alors
    // que les donnees ne sont pas la — et l'eleve ne pourrait plus
    // reprendre son test.
    await _settings.markFirstLaunchCompleted();

    return session.asCompleted(at);
  }
}