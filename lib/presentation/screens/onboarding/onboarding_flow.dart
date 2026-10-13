/// Onboarding — routeur du parcours d'entrée.
///
/// Affiche l'un des trois écrans — Prénom, Test, Clôture — selon l'état de
/// l'élève, et décide de la suite.
///
/// LE ROUTEUR NE CONNAIT QUE L'ORCHESTRATEUR. Il ne lit aucun dépôt, aucun
/// marqueur, aucune session : il demande à [EntryTestOnboarding], et suit ce
/// qu'il répond. C'est ce qui garantit qu'aucune décision d'affichage ne
/// dépend d'une lecture directe de la base.
///
/// L'ORDRE DE ROUTAGE est celui validé :
///
///   parcours terminé          → accueil (traité par l'appelant) ;
///   pas de prénom valide      → étape Prénom ;
///   session prête à terminer  → clôture ;
///   question disponible       → question courante ;
///   sinon                     → clôture.
library;

import 'package:flutter/material.dart';

import '../../../domain/entrytest/entry_test_onboarding.dart';
import '../../../domain/entrytest/entry_test_session.dart';
import 'closing_page.dart';
import 'entry_test_page.dart';
import 'name_page.dart';

/// Étape courante du parcours.
enum OnboardingStep {
  /// Demande du prénom.
  name,

  /// Test d'entrée, cinq questions.
  test,

  /// Remerciement et sortie du parcours.
  closing,
}

/// Conduit le parcours d'entrée jusqu'à sa clôture.
class OnboardingFlow extends StatefulWidget {
  /// Crée le parcours.
  const OnboardingFlow({
    super.key,
    required this.onboarding,
    required this.onCompleted,
    this.reduceAnimations = false,
  });

  /// Passage par l'orchestrateur : c'est le seul accès au parcours.
  final EntryTestOnboarding onboarding;

  /// Le parcours est terminé : l'appelant bascule sur l'accueil.
  ///
  /// N'est appelé qu'après l'écriture CONFIRMÉE du marqueur de fin.
  final VoidCallback onCompleted;

  /// L'élève a demandé la réduction des animations.
  final bool reduceAnimations;

  @override
  State<OnboardingFlow> createState() => OnboardingFlowState();
}

class OnboardingFlowState extends State<OnboardingFlow> {
  /// La session de test, une fois ouverte.
  EntryTestSession? _session;

  /// Étape courante.
  OnboardingStep _step = OnboardingStep.name;

  /// Le parcours est-il terminé ? L'écran d'attente disparaît alors.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  /// Détermine l'étape de départ, sans jamais bloquer le parcours.
  ///
  /// Le parcours n'est ouvert QUE si le marqueur de fin n'est pas posé.
  /// Un élève déjà passé par là ne voit jamais ces trois écrans.
  Future<void> _resolve() async {
    var completed = false;
    try {
      completed = await widget.onboarding.hasCompletedFirstLaunch();
    } catch (_) {
      // Lecture en échec : on ne bloque pas l'élève sur une donnée illisible.
      completed = true;
    }
    if (!mounted) return;
    if (completed) {
      // Parcours DÉJÀ terminé : aucun des trois écrans ne doit être montré.
      // Le parcours rend la main sans attendre — l'appelant affiche l'accueil.
      setState(() => _done = true);
      widget.onCompleted();
      return;
    }

    var hasName = false;
    try {
      hasName = await widget.onboarding.hasValidName();
    } catch (_) {
      hasName = false;
    }
    if (!mounted) return;

    EntryTestSession session;
    try {
      session = await widget.onboarding.openSession();
    } catch (_) {
      // Sans session, l'écran Prénom reste affichable : l'élève commence,
      // et l'échec sera visible à l'enregistrement.
      if (mounted) {
        setState(() => _step = OnboardingStep.name);
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _session = session;
      _step = _stepFor(session: session, hasName: hasName);
    });
  }

  /// Étape de départ, dans l'ordre validé.
  ///
  /// L'étape Prénom est SAUTÉE si un prénom valide existe déjà : aucun
  /// affichage, aucune confirmation.
  static OnboardingStep _stepFor({
    required EntryTestSession session,
    required bool hasName,
  }) {
    if (!hasName) return OnboardingStep.name;
    if (session.isReadyToComplete || session.isCompleted) {
      return OnboardingStep.closing;
    }
    if (session.nextQuestion != null) return OnboardingStep.test;
    // Cas théorique : aucune question et session incomplète. On ne fabrique
    // pas de question — on montre la clôture, qui permet de sortir.
    return OnboardingStep.closing;
  }

  Future<void> _onNameSubmitted(String name) async {
    try {
      await widget.onboarding.setName(name);
    } catch (_) {
      // L'écriture du prénom a échoué. L'écran de test affichera une session
      // sans nom : on continue plutôt que de bloquer l'élève sur une erreur
      // qu'il ne peut pas corriger.
    }
    if (!mounted) return;

    final EntryTestSession? session = _session;
    if (session == null) {
      // La session n'a pas pu être ouverte : on retente une fois.
      await _resolve();
      return;
    }
    setState(() => _step = OnboardingStep.test);
  }

  void _onTestFinished() {
    if (!mounted) return;
    setState(() => _step = OnboardingStep.closing);
  }

  /// Sortie du parcours, après écriture CONFIRMÉE du marqueur.
  ///
  /// L'erreur est laissée remonter à l'écran de clôture : il doit rester
  /// affiché et rendre son bouton actif, ce qu'il fait seul en propageant.
  Future<void> _onClosingConfirmed() async {
    await widget.onboarding.markFirstLaunchCompleted();
    if (!mounted) return;
    setState(() => _done = true);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // Le parcours est terminé, ou la session n'a pas pu être ouverte et
    // l'écran affiché décide de la suite : l'appelant prend le relais.
    if (_done) return const SizedBox.shrink();

    return PopScope<Object?>(
      // Le retour Android ne solderait JAMAIS le parcours : il ne réécrit
      // aucun marqueur. Il remonte seulement au premier écran du parcours
      // (Prénom ou Test), ou laisse l'application se fermer si ce parcours
      // est déjà la racine.
      //
      // `canPop: true` n'est PAS une concession : le parcours n'est pas la
      // seule pile, et une session inachevée reste conservée en base —
      // elle sera reprise à la réouverture.
      canPop: _step == OnboardingStep.test,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        if (_step == OnboardingStep.name) return;
        // Depuis le test, on revient au Prénom sans rien écrire.
        setState(() => _step = OnboardingStep.name);
      },
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case OnboardingStep.name:
        return NamePage(
          reduceAnimations: widget.reduceAnimations,
          onSubmit: _onNameSubmitted,
        );

      case OnboardingStep.test:
        final EntryTestSession? session = _session;
        if (session == null) return const SizedBox.shrink();
        return EntryTestPage(
          onboarding: widget.onboarding,
          session: session,
          reduceAnimations: widget.reduceAnimations,
          onFinished: _onTestFinished,
        );

      case OnboardingStep.closing:
        return _ClosingHost(
          onboarding: widget.onboarding,
          reduceAnimations: widget.reduceAnimations,
          onConfirm: _onClosingConfirmed,
        );
    }
  }
}

/// Écran de clôture, alimenté par le prénom enregistré.
///
/// Le prénom vient de l'ORCHESTRATEUR et non de l'étape Prénom : il peut
/// avoir été saisi lors d'une session précédente, et c'est la base qui fait
/// foi, pas l'écran qui vient d'être quitté.
class _ClosingHost extends StatefulWidget {
  const _ClosingHost({
    required this.onboarding,
    required this.onConfirm,
    required this.reduceAnimations,
  });

  final EntryTestOnboarding onboarding;
  final Future<void> Function() onConfirm;
  final bool reduceAnimations;

  @override
  State<_ClosingHost> createState() => _ClosingHostState();
}

class _ClosingHostState extends State<_ClosingHost> {
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    String name = '';
    try {
      name = await widget.onboarding.storedName();
    } catch (_) {
      name = '';
    }
    if (!mounted) return;
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    return ClosingPage(
      name: _name,
      reduceAnimations: widget.reduceAnimations,
      onConfirm: widget.onConfirm,
    );
  }
}