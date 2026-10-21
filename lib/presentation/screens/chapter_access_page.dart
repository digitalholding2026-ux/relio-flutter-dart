/// S1 — Vue des leçons du chapitre 1.
///
/// Atteinte depuis le catalogue « Apprendre » (ou depuis l'accueil, via la
/// carte « Reprendre »). Elle montre les trois leçons du chapitre avec leur
/// état et leur avancement, puis ouvre l'exercice choisi.
///
/// DONNÉES FACTICES : les états viennent de [LearnState.mockChapter1]. Aucun
/// fait d'apprentissage n'est lu en base ; les types sont ceux que le moteur
/// remplira.
library;

import 'package:flutter/material.dart';

import '../../domain/curriculum/exercise.dart';
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
            color: palette.surface,
            borderRadius: RelioRadius.bannerAll,
            border: Border.all(
              color: palette.outline,
              width: RelioSizes.cardBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: RelioType.bodyStrong(palette),
                    ),
                  ),
                  const SizedBox(width: RelioSpacing.sm),
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
    this.reduceAnimations = false,
  });

  /// Appelé avec l'identifiant de la leçon sélectionnée.
  final void Function(String lessonId) onOpenLesson;

  /// Chapitre affiché. `null` : chapitre 1 de démonstration.
  final ChapterProgress? chapter;

  /// Désactive les effets d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final shown = chapter ?? LearnState.mockChapter1();

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
              style: RelioType.display(palette).copyWith(
                color: palette.primary,
              ),
            ),
            const SizedBox(height: RelioSpacing.sm),
            Text(
              RelioStrings.chapterIntro,
              style: RelioType.body(palette).copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: RelioSpacing.sectionGap),
            for (final lesson in ArithmeticLesson.values) ...<Widget>[
              // Une leçon sans progression connue ne doit pas disparaître :
              // on affiche un état neutre plutôt que de sauter la ligne.
              LessonCard(
                lesson: lesson,
                progress:
                    shown.lessonById(lesson.id) ?? _fallbackProgress(lesson),
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
  LessonProgress _fallbackProgress(ArithmeticLesson lesson) {
    return LessonProgress(
      lessonId: lesson.id,
      title: lesson.title,
      status: LessonStatus.toReview,
      fill: 0,
    );
  }
}
