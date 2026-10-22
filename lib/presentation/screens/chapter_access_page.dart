/// S1 — Vue des leçons du chapitre 1.
///
/// Atteinte depuis le catalogue « Apprendre » (ou depuis l'accueil, via la
/// carte « Reprendre »). Elle montre les trois leçons du chapitre avec leur
/// état et leur avancement, puis ouvre l'exercice choisi.
///
/// DONNÉES RÉELLES : l'état des leçons vient de la coquille, calculé depuis
/// les événements d'apprentissage. Le défaut est l'état vide : aucune leçon
/// n'est présentée comme commencée sans fait correspondant.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/curriculum/exercise.dart';
import '../../domain/learning/learner_progress.dart';
import '../home/home_state.dart';
import '../home/pressable_scale.dart';
import '../learn/learn_state.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import '../widgets/lesson_status_pill.dart';
import '../widgets/relio_progress_bar.dart';

/// Couleur d'un état de leçon.
///
/// L'orange signale un travail commencé, le gris un retour à faire, le vert
/// une leçon stabilisée. La couleur ne porte jamais seule l'information : le
/// libellé de [LessonStatusPill] la double toujours.
Color lessonStatusColor(RelioPalette palette, LessonStatus status) {
  return switch (status) {
    LessonStatus.notStarted => palette.textMuted,
    LessonStatus.inProgress => palette.brand,
    LessonStatus.toReview => palette.textSecondary,
    LessonStatus.mastered => palette.successText,
  };
}

/// Carte de sélection d'une leçon.
class LessonCard extends StatelessWidget {
  /// Crée une carte de leçon.
  const LessonCard({
    super.key,
    required this.lesson,
    required this.progress,
    required this.onTap,
    this.reduceAnimations = false,
  });

  /// Leçon affichée.
  final ArithmeticLesson lesson;

  /// État et avancement de la leçon.
  final LessonProgress progress;

  /// Ouvre le premier exercice de la leçon.
  final VoidCallback onTap;

  /// Désactive l'effet d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    // L'intitulé est affiché TEL QUEL : la leçon 2 porte « PGDC », conservé
    // fidèlement à la source.
    final palette = RelioPaletteScope.of(context);
    final Color statusColor = lessonStatusColor(palette, progress.status);
    final String? countLabel = progress.exerciseProgressLabel;

    return Semantics(
      button: true,
      label: '${lesson.title}, ${progress.statusLabel}',
      child: PressableScale(
        onTap: onTap,
        reduceAnimations: reduceAnimations,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(RelioSpacing.cardInner),
          decoration: BoxDecoration(
            // Mêmes jetons que la carte de chapitre de l'onglet Apprendre :
            // fond blanc, arrondi 16, bordure orange et ombre douce.
            color: palette.surface,
            borderRadius: RelioRadius.bannerAll,
            border: Border.all(
              color: palette.brand,
              width: RelioSizes.heroBorderWidth,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Le titre garde toute la largeur utile. La pastille
                    // passe à la ligne suivante quand l'intitulé est long,
                    // plutôt que de le comprimer en colonne étroite.
                    Wrap(
                      spacing: RelioSpacing.sm,
                      runSpacing: RelioSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          lesson.title,
                          style: RelioType.sectionTitle(palette),
                        ),
                        LessonStatusPill(
                          label: progress.statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: RelioSpacing.md),
                    RelioProgressBar(
                      ratio: progress.fill,
                      color: statusColor,
                      track: palette.outline,
                    ),
                    if (countLabel != null) ...<Widget>[
                      const SizedBox(height: RelioSpacing.xs),
                      Text(countLabel, style: RelioType.captionSmall(palette)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: RelioSpacing.md),
              // Le chevron dit que toute la carte ouvre la leçon ; l'effet
              // d'appui porte sur la surface entière.
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran d'accès aux leçons du chapitre.
class ChapterAccessPage extends StatelessWidget {
  /// Crée la vue des leçons.
  const ChapterAccessPage({
    super.key,
    required this.onOpenLesson,
    this.chapter,
    this.progressListenable,
    this.reduceAnimations = false,
  });

  /// Appelé avec l'identifiant de la leçon sélectionnée.
  final void Function(String lessonId) onOpenLesson;

  /// Chapitre affiché. `null` : chapitre 1 à l'état vide.
  ///
  /// Instantané utilisé par les tests et les aperçus. En production, c'est
  /// [progressListenable] qui est fourni : un instantané figé laisserait la
  /// page afficher « 0/4 » après un exercice réussi.
  final ChapterProgress? chapter;

  /// Avancement observé, écouté en direct.
  ///
  /// S1 reste empilé sous S2 : sans écoute, sa carte de leçon garderait l'état
  /// du jour de l'ouverture. Le moteur reste la seule source : la page ne
  /// recalcule rien, elle relit la projection à chaque fait nouveau.
  final ValueListenable<LearnerProgress>? progressListenable;

  /// Désactive les effets d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final listenable = progressListenable;
    if (listenable == null) return _build(context, chapter);

    return ValueListenableBuilder<LearnerProgress>(
      valueListenable: listenable,
      builder: (BuildContext context, LearnerProgress progress, Widget? _) =>
          _build(context, LearnState.fromProgress(progress).activeChapter),
    );
  }

  Widget _build(BuildContext context, ChapterProgress? chapter) {
    final palette = RelioPaletteScope.of(context);
    final shown = chapter ?? LearnState.empty().activeChapter;

    return Scaffold(
      backgroundColor: palette.homeBackground,
      appBar: AppBar(
        backgroundColor: palette.homeBackground,
        // S1 n'est pas la racine : sa flèche ramène au catalogue.
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: RelioStrings.backToProgram,
          // Cible tactile d'au moins 48 dp : l'icône seule mesure 24 dp.
          constraints: const BoxConstraints(
            minWidth: RelioSizes.minTouchTarget,
            minHeight: RelioSizes.minTouchTarget,
          ),
        ),
        title: Text(
          RelioStrings.chapterCaption,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: RelioTheme.fontFamily,
            color: palette.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelioSpacing.horizontal,
            RelioSpacing.sm,
            RelioSpacing.horizontal,
            RelioSpacing.xxl,
          ),
          children: <Widget>[
            Text(
              RelioStrings.chapterTitle,
              style: RelioType.display(palette)
                  .copyWith(color: palette.primary),
            ),
            const SizedBox(height: RelioSpacing.sm),
            Text(
              RelioStrings.chapterIntro,
              style: RelioType.body(palette)
                  .copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: RelioSpacing.sectionGap),
            for (final lesson in ArithmeticLesson.values) ...<Widget>[
              // Une leçon sans progression connue ne doit pas disparaître :
              // on affiche un état neutre plutôt que de sauter la ligne.
              LessonCard(
                lesson: lesson,
                progress:
                    shown?.lessonById(lesson.id) ?? _fallbackProgress(lesson),
                onTap: () => onOpenLesson(lesson.id),
                reduceAnimations: reduceAnimations,
              ),
              const SizedBox(height: RelioSpacing.cardGap),
            ],
          ],
        ),
      ),
    );
  }

  /// État neutre d'une leçon absente du chapitre fourni.
  ///
  /// Les totaux viennent de la banque validée : même sans fait, la carte
  /// affiche « 0/4 exercices » plutôt qu'un décompte absent.
  LessonProgress _fallbackProgress(ArithmeticLesson lesson) {
    final totals = LearnerProgress.officialChapter1ExerciseTotals();

    return LessonProgress(
      lessonId: lesson.id,
      title: lesson.title,
      status: LessonStatus.notStarted,
      fill: 0,
      completedExercises: 0,
      totalExercises: totals[lesson.id] ?? 0,
    );
  }
}
