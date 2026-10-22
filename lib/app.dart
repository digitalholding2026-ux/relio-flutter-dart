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

import 'dart:async';

import 'package:flutter/material.dart';

import 'data/db/app_database.dart';
import 'domain/curriculum/chapter1_service.dart';
import 'domain/curriculum/exercise.dart';
import 'domain/entrytest/entry_test_onboarding.dart';
import 'domain/entrytest/entry_test_repository.dart';
import 'domain/learning/learner_progress.dart';
import 'domain/learning/learning_event_repository.dart';
import 'domain/settings/learner_settings.dart';
import 'presentation/home/home_state.dart';
import 'presentation/learn/learn_state.dart';
import 'presentation/rules/v1_screen_rules.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/app_shell_nav.dart';
import 'presentation/screens/chapter_access_page.dart';
import 'presentation/screens/exercise_page.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/intro/intro_preloader.dart';
import 'presentation/screens/intro/opening_page.dart';
import 'presentation/screens/learn_page.dart';
import 'presentation/screens/onboarding/entry_kit.dart';
import 'presentation/screens/onboarding/onboarding_flow.dart';
import 'presentation/screens/onboarding/welcome_page.dart';
import 'presentation/screens/profile_page.dart';
import 'presentation/strings/relio_strings.dart';
import 'presentation/theme/relio_theme.dart';
import 'presentation/widgets/relio_page_route.dart';

/// Étape de premier lancement, lue depuis un seul endroit.
///
/// Le parcours d'entrée est une LIGNE, pas une cascade de drapeaux : deux
/// booléens qui se croisent deviennent illisibles, et le moment où
/// `entryScreenSeen` est écrit devient impossible à vérifier d'un coup d'œil.
enum _Stage {
  /// Le drapeau est lu : ni accueil ni parcours ne s'affichent encore.
  deciding,

  /// Ouverture : révélation du logo.
  opening,

  /// Bienvenue : texte d'accueil et bouton « Commencer ».
  welcome,

  /// Parcours : introduction, prénom, test, clôture.
  onboarding,

  /// Parcours terminé : l'accueil.
  home,

  /// Le drapeau n'a pas pu être lu : on propose de réessayer.
  ///
  /// Cet état EXISTE parce que l'absence d'écran est le pire échec possible :
  /// sans lui, une lecture de base qui ne répond pas laisserait l'application
  /// sur un fond blanc, sans explication et sans issue.
  startupFailed,
}

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
  /// d'écran devrait traverser l'ouverture et la Bienvenue. La décision
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

  /// Passage du parcours d'entrée.
  ///
  /// L'interface d'onboarding passe UNIQUEMENT par cet objet : ni
  /// `SettingsRepository`, ni `EntryTestRepository` ne sont touchés depuis un
  /// écran. Un seul point d'entrée, donc une seule règle à vérifier.
  late final EntryTestOnboarding _entryOnboarding = EntryTestOnboarding(
    EntryTestRepository(LearningEventRepository(widget.database)),
    _repository,
  );

  /// Étape courante du premier lancement.
  ///
  /// [_Stage.deciding] tant que le drapeau n'est pas lu. On ne suppose
  /// JAMAIS « première ouverture » par défaut : afficher l'ouverture à un
  /// élève déjà habitué serait une faute, et la cacher à un nouvel élève en
  /// serait une autre.
  _Stage _stage = _Stage.deciding;

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(widget.database);

    final provided = widget.settingsController;
    _ownsController = provided == null;
    _controller = provided ?? SettingsController(_repository);
    if (_ownsController) _controller.load();

    if (!widget.showIntro) {
      _stage = _Stage.home;
    } else {
      _resolveFirstLaunch();
    }
  }

  /// Tranche : l'écran d'entrée a-t-il déjà été vu ?
  ///
  /// La décision porte sur `entryScreenSeen`, et NON sur
  /// `firstLaunchCompleted`. Les deux marqueurs sont distincts, et c'est leur
  /// distinction qui permet de reprendre un test d'entrée interrompu :
  ///
  ///  - `entryScreenSeen` dit « l'écran a été présenté » ;
  ///  - `firstLaunchCompleted` dit « le parcours est terminé ».
  ///
  /// Un élève qui a vu l'écran, puis refermé l'application au milieu du test,
  /// se trouve avec `entryScreenSeen == true` et
  /// `firstLaunchCompleted == false` : l'écran d'entrée est sauté, et le
  /// parcours reprend directement à la bonne question. Fonder la décision
  /// sur `hasCompletedFirstLaunch()` aurait rejoué cet écran une seconde fois,
  /// et surtout aurait fait perdre la reprise du test.
  ///
  /// Une lecture en ÉCHEC vaut « déjà vu » : mieux vaut laisser l'élève
  /// directement à l'accueil que bloquer l'application sur une préférence
  /// illisible.
  ///
  /// Une lecture qui NE RÉPOND PAS, en revanche, ne vaut pas « déjà vu » : elle
  /// ne répond pas non plus. On lui impose un délai au-delà duquel l'écran
  /// d'échec est proposé, avec un bouton de réessai. Sans ce filet, la
  /// moindre attente non satisfaite — verrou de base, migration lente, I/O
  /// bloqué — laisserait l'application sur un fond blanc, sans explication et
  /// sans issue.
  static const Duration _resolveTimeout = Duration(seconds: 8);

  Future<void> _resolveFirstLaunch() async {
    bool seen;
    try {
      seen = await _repository.hasSeenEntryScreen().timeout(_resolveTimeout);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _stage = _Stage.startupFailed);
      return;
    } catch (_) {
      seen = true;
    }
    if (!mounted) return;
    setState(() {
      // Ouverture SAUTÉE : c'est précisément le cas où le parcours doit
      // prendre le relais. Un élève ayant refermé l'application au milieu du
      // test d'entrée doit y RETOMBER, pas à l'accueil.
      //
      // L'Ouverture ET la Bienvenue sont alors sautées ensemble. La Bienvenue
      // annonce un parcours qui a déjà commencé : la republier retarderait la
      // reprise sans rien apprendre à l'élève.
      //
      // `OnboardingFlow` décide de l'étape de départ — introduction, prénom,
      // reprise à la bonne question, ou clôture si les cinq réponses sont
      // déjà enregistrées. S'il constate que le parcours est DÉJÀ terminé, il
      // rend la main immédiatement et l'accueil s'affiche : le parcours, et
      // lui seul, connaît cette condition.
      _stage = seen ? _Stage.onboarding : _Stage.opening;
    });
  }

  @override
  void dispose() {
    // Seul un contrôleur créé ici est détruit : un contrôleur fourni par un
    // parent reste la responsabilité de son propriétaire.
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// L'ouverture est terminée : on présente l'écran Bienvenue.
  ///
  /// L'ouverture ne porte aucun bouton. Elle rend donc la main toute seule, et
  /// c'est le tap sur « Commencer » qui vaut « j'ai vu le parcours ».
  ///
  /// ⚠️ AUCUN marqueur n'est écrit ici. Ni `entryScreenSeen`, ni
  /// `firstLaunchCompleted`. Une ouverture regardée puis quittée n'a rien
  /// enregistré : l'élève la reverra au prochain lancement, ce qui est
  /// correct — mieux vaut cela qu'un parcours commencé puis abandonné en
  /// silence.
  Future<void> _onOpeningFinished() async {
    if (!mounted) return;
    setState(() => _stage = _Stage.welcome);
  }

  /// La Bienvenue est validée : le parcours commence.
  ///
  /// Appelé par le bouton « Commencer ».
  ///
  /// `entryScreenSeen` EST écrit ici, et seulement ici : c'est le tap sur
  /// « Commencer » qui vaut « j'ai vu cet écran ». Rien d'autre n'est écrit —
  /// ni session, ni `firstLaunchCompleted`.
  ///
  /// ⚠️ `firstLaunchCompleted` n'est écrit QUE par la fin RÉELLE du parcours,
  /// via `EntryTestOnboarding.finishSession()`. L'écrire ici empêcherait la
  /// reprise : un élève ayant fermé l'application au milieu du test verrait son
  /// parcours définitivement soldé, et le test ne pourrait plus être repris.
  Future<void> _completeFirstLaunch() async {
    // L'écriture précède le changement d'écran : si l'application est fermée
    // juste après, l'ouverture et la Bienvenue ne seront pas rejouées.
    try {
      await _entryOnboarding.markEntryScreenSeen();
    } catch (_) {
      // Échec de l'écriture : on enchaîne quand même. L'élève n'a rien à
      // corriger, et l'écran d'entrée le reverra au prochain lancement.
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.onboarding);
  }

  /// Le parcours d'onboarding est terminé : on bascule sur l'accueil.
  ///
  /// Appelé par [OnboardingFlow] APRÈS l'écriture CONFIRMÉE du marqueur de
  /// fin. Tant qu'il n'est pas appelé, l'accueil n'est pas affiché : l'élève
  /// ne doit pas pouvoir contourner la clôture en tombant dessus.
  void _onOnboardingCompleted() {
    if (mounted) setState(() => _stage = _Stage.home);
  }

  /// Le démarrage a échoué : on propose de réessayer.
  ///
  /// Le réessai RELIT le drapeau depuis le début. Il ne suppose rien de
  /// l'échec précédent : si la base est simplement lente au premier accès, le
  /// second essai passe.
  void _retryStartup() {
    if (!mounted) return;
    setState(() => _stage = _Stage.deciding);
    _resolveFirstLaunch();
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
              // on n'affiche ni l'accueil ni le parcours : afficher un ecran
              // puis le remplacer ferait un clignotement.
              //
              // Fondu croisé entre les moments du parcours (ouverture,
              // bienvenue, onboarding) : 275 ms, sans glissement,
              // interruptible. Le logo ne « vole » pas — chaque écran pose
              // le sien.
              home: EntryTransition(
                child: switch (_stage) {
                  _Stage.deciding => const _SplashGate(
                      key: ValueKey<_Stage>(_Stage.deciding),
                    ),

                  // L'ouverture montre la marque, puis rend la main. Elle porte
                  // le prechargement de l'accueil : il a toute la durée de la
                  // revelation pour deriver, en silence.
                  _Stage.opening => OpeningPage(
                      key: const ValueKey<_Stage>(_Stage.opening),
                      reduceAnimations: settings.reduceAnimations,
                      onFinished: _onOpeningFinished,
                      preload: IntroPreloader(widget.database).run,
                    ),

                  _Stage.welcome => WelcomePage(
                      key: const ValueKey<_Stage>(_Stage.welcome),
                      reduceAnimations: settings.reduceAnimations,
                      onStart: _completeFirstLaunch,
                    ),

                  _Stage.onboarding => OnboardingFlow(
                      key: const ValueKey<_Stage>(_Stage.onboarding),
                      onboarding: _entryOnboarding,
                      reduceAnimations: settings.reduceAnimations,
                      onCompleted: _onOnboardingCompleted,
                    ),

                  _Stage.home => _RelioShell(
                      key: const ValueKey<_Stage>(_Stage.home),
                      database: widget.database,
                      settings: settings,
                      controller: _controller,
                    ),

                  // Jamais un fond blanc sans issue : on dit ce qu'il se passe
                  // et on donne un moyen de recommencer.
                  _Stage.startupFailed => _StartupError(
                      key: const ValueKey<_Stage>(_Stage.startupFailed),
                      onRetry: _retryStartup,
                    ),
                },
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
  const _SplashGate({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
      );
}

/// Écran d'échec du démarrage, avec réessai.
///
/// Il EXISTE pour une raison précise : sans lui, toute initialisation qui ne
/// aboutit pas se traduit par un écran blanc. L'élève verrait une page vide,
/// sans savoir s'il doit attendre, relancer, ou quoi que ce soit.
class _StartupError extends StatelessWidget {
  const _StartupError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: RelioSpacing.horizontal,
              vertical: RelioSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  RelioStrings.startupErrorTitle,
                  textAlign: TextAlign.center,
                  style: RelioType.title(palette),
                ),
                const SizedBox(height: RelioSpacing.md),
                Text(
                  RelioStrings.startupErrorMessage,
                  textAlign: TextAlign.center,
                  style: RelioType.body(palette),
                ),
                const SizedBox(height: RelioSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRetry,
                    child: const Text(RelioStrings.startupRetry),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Coquille des trois onglets, avec la navigation du chapitre.
class _RelioShell extends StatefulWidget {
  const _RelioShell({
    super.key,
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

  /// Lecture de l'avancement réel — jamais une valeur d'attente.
  late final LearnerProgressRepository _progressRepository =
      LearnerProgressRepository(LearningEventRepository(widget.database));

  /// Avancement affiché. Démarre à l'état VIDE : avant la première lecture,
  /// l'écran ne prétend rien savoir de l'élève.
  LearnerProgress _progress = LearnerProgress.empty;

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  /// Relit les faits et met à jour l'accueil, le programme et le profil.
  ///
  /// Une lecture en échec ne casse rien : l'état vide reste affiché, ce qui
  /// est exact — on ne sait simplement rien de plus.
  Future<void> _refreshProgress() async {
    try {
      final progress = await _progressRepository.load();
      if (!mounted) return;
      setState(() => _progress = progress);
    } catch (_) {
      // Historique illisible : l'écran garde l'état vide plutôt que d'afficher
      // une progression inventée.
    }
  }

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
  /// « Commencer » (Accueil) et le chapitre 1 (Apprendre) convergent donc vers
  /// le MÊME parcours, sans dupliquer la pile.
  ///
  /// Bascule AUSSI sur l'onglet Apprendre : pousser une page dans la pile d'un
  /// onglet sans l'afficher laisserait S1 invisible.
  Future<void> _openChapter1() async {
    _shellKey.currentState?.selectTab(RelioTab.learn);

    final navigator = _learnNavigator;
    if (navigator == null) return;
    await navigator.push<void>(
      RelioPageRoute<void>(
        reduceAnimations: widget.settings.reduceAnimations,
        builder: (_) => ChapterAccessPage(
          onOpenLesson: _openLesson,
          // Les leçons affichées sont celles que les faits décrivent : une
          // leçon jamais tentée reste « À commencer ».
          chapter: LearnState.fromProgress(_progress).activeChapter,
          reduceAnimations: widget.settings.reduceAnimations,
        ),
      ),
    );
    // Le parcours est refermé : les faits peuvent avoir changé.
    await _refreshProgress();
  }

  /// Ouvre S2 sur le premier exercice de la leçon.
  Future<void> _openLesson(String lessonId) async {
    final exercise = V1ScreenRules.firstOfLesson(lessonId);
    // Leçon inconnue : ne rien ouvrir plutôt qu'afficher un écran vide.
    if (exercise == null) return;

    // Même règle que [_openChapter1] : une page poussée dans la pile d'un
    // onglet qui n'est pas affiché resterait invisible. L'accueil ouvre donc
    // la leçon ET bascule sur Apprendre.
    _shellKey.currentState?.selectTab(RelioTab.learn);

    final navigator = _learnNavigator;
    if (navigator == null) return;

    await navigator.push<void>(
      RelioPageRoute<void>(
        reduceAnimations: widget.settings.reduceAnimations,
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

    // Retour à S1 : l'exercice peut avoir été réussi, donc les décomptes de
    // l'accueil et du profil doivent être relus.
    await _refreshProgress();
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
      RelioPageRoute<void>(
        reduceAnimations: widget.settings.reduceAnimations,
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
              reduceAnimations: widget.settings.reduceAnimations,
              // État calculé depuis les faits : « COMMENCER » pour un nouvel
              // élève, « REPRENDRE » dès la première tentative.
              homeState: HomeState.fromProgress(_progress),
              // La carte principale et les deux actions rapides ouvrent le
              // même chapitre : c'est le seul parcours disponible en V1.
              onContinue: _openChapter1,
              onFiveMinutes: _openChapter1,
              onWarmup: _openChapter1,
              onOpenLesson: _openLesson,
            ),
        (context, _) => LearnPage(
              learnState: LearnState.fromProgress(_progress),
              onOpenChapter1: _openChapter1,
              reduceAnimations: widget.settings.reduceAnimations,
            ),
        (context, _) => ProfilePage(
              settings: widget.settings,
              progress: _progress,
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