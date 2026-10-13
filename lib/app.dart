/// Application Relio — racine de l'interface.
///
/// NAVIGATION : trois onglets permanents (Accueil, Apprendre, Profil) portés
/// par [AppShell]. L'application ouvre sur ACCUEIL, plus sur S1.
///
/// S1 (accès aux leçons du chapitre 1) est désormais atteint depuis
/// Apprendre, via la carte du chapitre 1. Sa flèche de retour est donc active,
/// et ramène à l'écran Apprendre.
///
/// Les écrans ne connaissent que les événements qu'ils émettent : jamais la
/// suite du parcours.
library;

import 'package:flutter/material.dart';

import 'data/db/app_database.dart';
import 'domain/curriculum/chapter1_service.dart';
import 'domain/curriculum/exercise.dart';
import 'domain/learning/learning_event_repository.dart';
import 'domain/settings/learner_settings.dart';
import 'presentation/rules/v1_screen_rules.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/app_shell_nav.dart';
import 'presentation/screens/chapter_access_page.dart';
import 'presentation/screens/exercise_page.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/intro/intro_page.dart';
import 'presentation/screens/intro/intro_preloader.dart';
import 'presentation/screens/learn_page.dart';
import 'presentation/screens/profile_page.dart';
import 'presentation/theme/relio_theme.dart';

class RelioApp extends StatefulWidget {
  const RelioApp({
    super.key,
    required this.database,
    this.settingsController,
    this.showIntro = true,
  });

  final AppDatabase database;

  /// Préférences de l'élève.
  ///
  /// Optionnel pour les tests : à défaut, l'application crée son propre
  /// contrôleur et lit les préférences depuis la base.
  final SettingsController? settingsController;

  /// L'écran d'entrée doit-il être proposé ?
  ///
  /// `false` pour les tests qui portent sur l'interface : sinon chaque test
  /// d'écran devrait attendre 5,3 s de séquence. La décision
  /// première-ouverture / ouvertures suivantes est prise par ailleurs, dans
  /// [_RelioAppState], à partir du drapeau persisté.
  final bool showIntro;

  @override
  State<RelioApp> createState() => _RelioAppState();
}

class _RelioAppState extends State<RelioApp> {
  late final SettingsController _controller;
  late final bool _ownsController;

  late final SettingsRepository _repository;

  /// L'écran d'entrée doit-il s'afficher ?
  ///
  /// `null` tant que la question n'est pas tranchée. On ne suppose jamais
  /// « première ouverture » par defaut : afficher par erreur l'écran d'entrée a
  /// un élève déjà habitué serait une faute, et le cacher a un nouvel élève en
  /// serait une autre.
  bool? _showIntro;

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(widget.database);

    final provided = widget.settingsController;
    _ownsController = provided == null;
    _controller = provided ?? SettingsController(_repository);
    if (_ownsController) _controller.load();

    if (!widget.showIntro) {
      _showIntro = false;
    } else {
      _resolveFirstLaunch();
    }
  }

  /// Tranche : premiere ouverture, ou retour ?
  ///
  /// Une lecture en echec vaut « pas première ouverture » : mieux vaut laisser
  /// l'eleve directement a l'accueil que bloquer l'application sur une
  /// preference illisible.
  Future<void> _resolveFirstLaunch() async {
    var completed = true;
    try {
      completed = await _repository.hasCompletedFirstLaunch();
    } catch (_) {
      completed = true;
    }
    if (mounted) setState(() => _showIntro = !completed);
  }

  @override
  void dispose() {
    // Seul un contrôleur créé ici est détruit : un contrôleur fourni par un
    // parent reste la responsabilité de son propriétaire.
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// L'écran d'entrée est terminé : on passe à l'étape suivante.
  ///
  /// Appelé par le bouton « Commencer » ET par le bouton retour Android.
  ///
  /// ⚠️ AUCUN marqueur de fin de parcours n'est écrit ici. Le tap sur
  /// « Commencer » signifie « j'ai vu l'écran d'entrée », rien de plus.
  ///
  /// `firstLaunchCompleted` n'est écrit QUE par la fin RÉELLE du parcours
  /// d'onboarding, via `EntryTestOnboarding.finishSession()`. L'écrire ici
  /// empêcherait la reprise : un élève ayant fermé l'application au milieu
  /// du test d'entrée verrait son parcours définitivement soldé, et le test
  /// ne pourrait plus être repris.
  ///
  /// L'écriture de `entryScreenSeen` est une simple bascule d'affichage et
  /// appartient à la mission d'intégration UX/UI : cette classe ne dépend
  /// que de `SettingsRepository`, pas de l'orchestrateur d'onboarding.
  Future<void> _completeFirstLaunch() async {
    if (mounted) setState(() => _showIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final settings = _controller.settings;
        final palette = RelioPalette.of(highContrast: settings.highContrast);

        return RelioPaletteScope(
          palette: palette,
          child: MediaQuery.withClampedTextScaling(
            // La taille de texte choisie s'applique à TOUTE l'application :
            // barre basse comprise.
            //
            // Elle sert de PLANCHER, jamais de plafond : le réglage
            // d'accessibilité du système reste respecté. Un élève qui a
            // agrandi la police de son téléphone doit le sentir aussi dans
            // Relio — verrouiller l'échelle l'annulerait.
            minScaleFactor: settings.textScale.factor,
            maxScaleFactor: switch (MediaQuery.maybeTextScalerOf(context)) {
              final scaler? =>
                scaler.scale(10) > settings.textScale.factor * 10
                    ? scaler.scale(10) / 10
                    : settings.textScale.factor,
              null => settings.textScale.factor,
            },
            child: MaterialApp(
              title: 'Relio',
              debugShowCheckedModeBanner: false,
              theme: RelioTheme.build(settings: settings),
              // Tant que la question premiere-ouverture n'est pas tranchee,
              // on n'affiche ni l'accueil ni l'ecran d'entree : afficher un
              // ecran puis le remplacer ferait un clignotement.
              home: _showIntro == null
                  ? const _SplashGate()
                  : _showIntro!
                      ? IntroPage(
                          reduceAnimations: settings.reduceAnimations,
                          preload: IntroPreloader(widget.database).run,
                          onFinished: _completeFirstLaunch,
                        )
                      : _RelioShell(
                          database: widget.database,
                          settings: settings,
                          controller: _controller,
                        ),
            ),
          ),
        );
      },
    );
  }
}

/// Ecran de garde, affiche le temps de lire le drapeau.
///
/// Blanc, sans rien : ce n'est pas un chargement annonce, c'est le temps d'une
/// lecture de base qui prend quelques millisecondes.
class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
      );
}

/// Coquille des trois onglets, avec la navigation du chapitre.
class _RelioShell extends StatefulWidget {
  const _RelioShell({
    required this.database,
    required this.settings,
    required this.controller,
  });

  final AppDatabase database;
  final LearnerSettings settings;
  final SettingsController controller;

  @override
  State<_RelioShell> createState() => _RelioShellState();
}

class _RelioShellState extends State<_RelioShell> {
  /// Brouillons par identifiant d'exercice — mémoire de session uniquement.
  ///
  /// V1 : aucune persistance. Une fermeture forcée de l'application perd la
  /// saisie ; limite ACCEPTÉE et non masquée.
  final Map<String, ExerciseDraft> _drafts = <String, ExerciseDraft>{};

  late final Chapter1Service _service =
      Chapter1Service(LearningEventRepository(widget.database));

  final GlobalKey<AppShellState> _shellKey = GlobalKey<AppShellState>();
  final GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _learnKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileKey = GlobalKey<NavigatorState>();

  /// Signal de masquage de la barre basse.
  ///
  /// Levé par S2 seul : sur S1 la barre reste visible, sur S2 elle disparaît
  /// pour laisser la place à la barre d'action fixe (champ + « Valider »).
  final ValueNotifier<bool> _hideBottomBar = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hideBottomBar.dispose();
    super.dispose();
  }

  NavigatorState? get _learnNavigator => _learnKey.currentState;

  /// Ouvre S1, puis S2, dans la pile de l'onglet Apprendre.
  ///
  /// « Commence ici » (Accueil) et le chapitre 1 (Apprendre) convergent donc
  /// vers le MÊME parcours, sans dupliquer la pile.
  ///
  /// Bascule AUSSI sur l'onglet Apprendre : pousser une page dans la pile d'un
  /// onglet sans l'afficher laisserait S1 invisible.
  void _openChapter1() {
    _shellKey.currentState?.selectTab(RelioTab.learn);

    final navigator = _learnNavigator;
    if (navigator == null) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChapterAccessPage(onOpenLesson: _openLesson),
      ),
    );
  }

  /// Ouvre S2 sur le premier exercice de la leçon.
  Future<void> _openLesson(String lessonId) async {
    final exercise = V1ScreenRules.firstOfLesson(lessonId);
    // Leçon inconnue : ne rien ouvrir plutôt qu'afficher un écran vide.
    if (exercise == null) return;

    final navigator = _learnNavigator;
    if (navigator == null) return;

    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExercisePage(
          service: _service,
          exercise: exercise,
          drafts: _drafts,
          // S1 est désormais empilé : son retour ramène à l'écran précédent.
          onExit: () => navigator.pop(),
          onGoToNext: () => _goToNext(exercise),
          onFullscreenChanged: _setFullscreen,
        ),
      ),
    );
  }

  /// Passe à l'exercice suivant, ou revient à S1 après le dernier.
  Future<void> _goToNext(Exercise exercise) async {
    final navigator = _learnNavigator;
    if (navigator == null || !navigator.mounted) return;

    final next = V1ScreenRules.nextAfter(exercise);
    if (next == null) {
      // Dernier exercice du chapitre : retour à S1.
      navigator.pop();
      return;
    }

    // Remplace S2 par l'exercice suivant : la pile ne s'empile pas.
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ExercisePage(
          service: _service,
          exercise: next,
          drafts: _drafts,
          onExit: () => navigator.pop(),
          onGoToNext: () => _goToNext(next),
          onFullscreenChanged: _setFullscreen,
          // L'élève enchaîne : le champ doit être prêt à écrire sans qu'il
          // ait à le toucher.
          requestFocusOnOpen: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      key: _shellKey,
      hideBottomBar: _hideBottomBar,
      navigatorKeys: <GlobalKey<NavigatorState>>[
        _homeKey,
        _learnKey,
        _profileKey,
      ],
      tabs: <Widget Function(BuildContext, GlobalKey<NavigatorState>)>[
        (context, _) => HomePage(
              name: widget.settings.name,
              onStartHere: _openChapter1,
              // « Programme de 3e » bascule sur l'onglet Apprendre, sans
              // y pousser d'écran : il en est déjà la racine.
              onOpenProgram: () => _shellKey.currentState?.selectTab(RelioTab.learn),
            ),
        (context, _) => LearnPage(onOpenChapter1: _openChapter1),
        (context, _) => ProfilePage(
              settings: widget.settings,
              onChanged: _onSettingsChanged,
            ),
      ],
    );
  }

  void _onSettingsChanged(LearnerSettings next) {
    widget.controller.apply(next);
  }

  /// S2 réclame (ou rend) toute la hauteur disponible.
  ///
  /// S2 signale son propre état, et non l'inverse : la règle « la barre basse
  /// disparaît sur l'exercice » appartient à l'écran d'exercice, pas à la
  /// coquille qui ne fait qu'exécuter.
  void _setFullscreen(bool fullscreen) {
    // `dispose` peut être atteint alors que la notification différée d'un
    // exercice vient d'être planifiée : écrire dans un notifier déjà détruit
    // lève une assertion. Le garde-fou `mounted` l'évite.
    if (!mounted) return;
    if (_hideBottomBar.value != fullscreen) _hideBottomBar.value = fullscreen;
  }
}

/// Contrôleur des préférences, notifiant l'interface.
///
/// Les écritures vont d'abord en mémoire — l'interface reflète immédiatement le
/// choix — puis en base.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  LearnerSettings _settings = LearnerSettings.defaults;

  /// Préférences courantes.
  LearnerSettings get settings => _settings;

  /// Charge les préférences depuis la base.
  Future<void> load() async {
    _apply(await _repository.load());
  }

  /// Applique [next] puis le persiste.
  ///
  /// Une seule porte d'entrée pour l'écran Profil : le widget ne fait que
  /// décrire le changement voulu, jamais comment l'enregistrer.
  Future<void> apply(LearnerSettings next) async {
    if (next == _settings) return;
    final previous = _settings;
    _apply(next);

    await _persist(next, previous);
  }

  Future<void> _persist(LearnerSettings next, LearnerSettings previous) async {
    if (next.name != previous.name) await _repository.setName(next.name);
    if (next.textScale != previous.textScale) {
      await _repository.setTextScale(next.textScale);
    }
    if (next.highContrast != previous.highContrast) {
      await _repository.setHighContrast(next.highContrast);
    }
    if (next.reduceAnimations != previous.reduceAnimations) {
      await _repository.setReduceAnimations(next.reduceAnimations);
    }
  }

  void _apply(LearnerSettings next) {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
  }
}