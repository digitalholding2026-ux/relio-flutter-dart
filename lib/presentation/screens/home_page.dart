/// Écran Accueil — onglet 1.
///
/// OBJECTIF : dire à l'élève, en trois secondes, ce qu'il peut faire
/// maintenant. Quatre blocs, dans cet ordre :
///
///  1. l'en-tête et le message de Relio — qui parle ;
///  2. la carte « Reprendre » — ce qu'il y a à faire ;
///  3. deux actions rapides — ce qu'il peut faire s'il a peu de temps ;
///  4. le programme — où il en est.
///
/// DONNÉES RÉELLES : l'état est fourni par la coquille, calculé depuis les
/// événements d'apprentissage ([HomeState.fromProgress]). Le défaut de l'écran
/// est l'ÉTAT VIDE : sans données, on n'affiche aucune progression inventée.
library;

import 'package:flutter/material.dart';

import '../home/home_state.dart';
import '../home/home_widgets.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// En-tête d'accueil : « Bonjour », suivi du prénom s'il est renseigné.
class GreetingHeader extends StatelessWidget {
  /// Crée l'en-tête.
  const GreetingHeader({super.key, required this.name});

  /// Prénom de l'élève. Vide si non renseigné.
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final trimmed = name.trim();

    // Sans prénom : « Bonjour » seul. On n'invente pas de texte d'attente.
    final text = trimmed.isEmpty
        ? RelioStrings.greeting
        : '${RelioStrings.greeting} $trimmed';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            text,
            style: RelioType.display(palette).copyWith(color: palette.primary),
          ),
        ),
        const SizedBox(width: RelioSpacing.sm),
        // Discret, aligné sur la ligne du prénom : il informe sans occuper le
        // centre de l'écran.
        const GreetingClock(),
      ],
    );
  }
}

/// Écran d'accueil.
class HomePage extends StatefulWidget {
  /// Crée l'écran d'accueil.
  const HomePage({
    super.key,
    required this.name,
    required this.onContinue,
    required this.onFiveMinutes,
    required this.onWarmup,
    required this.onOpenLesson,
    required this.onRevision,
    this.homeState,
    this.reduceAnimations = false,
  });

  /// Prénom de l'élève, éventuellement vide.
  final String name;

  /// Ouvre le chapitre à l'endroit où l'élève s'est arrêté.
  final VoidCallback onContinue;

  /// Action « J'ai 5 minutes ».
  final VoidCallback onFiveMinutes;

  /// Action « Échauffement ».
  final VoidCallback onWarmup;

  /// Ouvre une leçon précise depuis le programme.
  final void Function(String lessonId) onOpenLesson;

  /// Ouvre l'écran Révision (coach d'examen).
  final VoidCallback onRevision;

  /// État à afficher.
  ///
  /// `null` : [HomeState.empty]. Ce défaut est volontaire — un écran monté
  /// sans données ne doit jamais montrer une progression de démonstration.
  /// La coquille de l'application fournit l'état réel.
  final HomeState? homeState;

  /// Supprime les animations d'apparition et d'appui.
  final bool reduceAnimations;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  /// Durée de l'apparition du programme.
  static const Duration _entranceDuration = Duration(milliseconds: 900);

  /// Repli quand aucun état n'est fourni : montage isolé, tests, aperçus.
  static final HomeState _emptyState = HomeState.empty();

  /// État affiché, RELU à chaque construction.
  ///
  /// Il ne peut pas être figé dans un `late final` : la coquille reconstruit
  /// cet écran après chaque lecture de l'historique. Un état figé à la
  /// première construction laisserait l'accueil sur « Commencer » alors que
  /// l'exercice 1 vient d'être réussi.
  HomeState get _state => widget.homeState ?? _emptyState;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    if (widget.reduceAnimations) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Avancement de l'apparition de la ligne [index].
  ///
  /// Les lignes se remplissent l'une après l'autre : c'est ce décalage qui
  /// donne à la liste l'air de se construire, plutôt que de clignoter d'un
  /// bloc. Chaque ligne reste bornée : la dernière a fini avant 900 ms.
  double _appearanceOf(int index) {
    if (widget.reduceAnimations) return 1;
    final double start = (index * 0.12).clamp(0.0, 0.55);
    final double end = (start + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ).value;
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Scaffold(
      // Teinte propre à l'accueil : elle détache les cartes blanches sans
      // ajouter de bordure à chacune.
      backgroundColor: palette.homeBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelioSpacing.horizontal,
            RelioSpacing.xl,
            RelioSpacing.horizontal,
            RelioSpacing.xxxl,
          ),
          children: <Widget>[
            SequenceObjectiveBar(objective: _state.objective),
            const SizedBox(height: RelioSpacing.md),
            GreetingHeader(name: widget.name),
            const SizedBox(height: RelioSpacing.sm),
            RelioMessageCard(message: _state.message),
            const SizedBox(height: RelioSpacing.xl),
            ResumeCard(
              target: _state.resume,
              started: _state.started,
              onContinue: widget.onContinue,
              reduceAnimations: widget.reduceAnimations,
            ),
            const SizedBox(height: RelioSpacing.lg),
            // `IntrinsicHeight` : les deux cartes prennent la hauteur de la
            // plus grande. Sans lui, un sous-titre sur deux lignes laisserait
            // deux cartes de hauteurs différentes côte à côte.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.bolt_rounded,
                      iconColor: palette.primary,
                      title: RelioStrings.quickFiveTitle,
                      subtitle: RelioStrings.quickFiveSubtitle,
                      onTap: widget.onFiveMinutes,
                      reduceAnimations: widget.reduceAnimations,
                    ),
                  ),
                  const SizedBox(width: RelioSpacing.md),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: palette.brand,
                      title: RelioStrings.quickWarmupTitle,
                      subtitle: RelioStrings.quickWarmupSubtitle,
                      onTap: widget.onWarmup,
                      reduceAnimations: widget.reduceAnimations,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RelioSpacing.md),
            RevisionEntryCard(
              title: RelioStrings.revisionCardTitle,
              subtitle: RelioStrings.revisionCardSubtitle,
              onTap: widget.onRevision,
              reduceAnimations: widget.reduceAnimations,
            ),
            const SizedBox(height: RelioSpacing.sectionGap),
            Text(
              RelioStrings.programSectionTitle,
              style: RelioType.sectionTitle(palette),
            ),
            const SizedBox(height: RelioSpacing.md),
            AnimatedBuilder(
              animation: _entrance,
              builder: (BuildContext context, Widget? _) {
                return Column(
                  children: <Widget>[
                    for (final (int index, LessonProgress lesson)
                        in _state.lessons.indexed) ...<Widget>[
                      if (index > 0)
                        const SizedBox(height: RelioSpacing.md),
                      LessonTimelineTile(
                        lesson: lesson,
                        appearance: _appearanceOf(index),
                        onTap: () => widget.onOpenLesson(lesson.lessonId),
                        reduceAnimations: widget.reduceAnimations,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
