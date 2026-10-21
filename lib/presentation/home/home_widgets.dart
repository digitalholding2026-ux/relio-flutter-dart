/// Briques visuelles de l'écran d'accueil.
///
/// Toutes puisent leurs couleurs, leurs rayons et leurs espacements dans
/// `RelioTheme` : aucun écran ne porte de valeur littérale.
library;

import 'package:flutter/material.dart';

import '../branding/relio_mark.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import '../widgets/lesson_status_pill.dart';
import '../widgets/relio_progress_bar.dart';
import 'home_state.dart';
import 'pressable_scale.dart';

/// Objectif de séquence : une ligne discrète, et un trait qui la situe.
///
/// C'est le premier élément de l'écran, avant même le prénom : il répond à
/// « où j'en suis dans le programme ? » sans prendre la place d'un titre.
class SequenceObjectiveBar extends StatelessWidget {
  /// Crée la barre d'objectif.
  const SequenceObjectiveBar({super.key, required this.objective});

  /// Séquence, notions validées et total.
  final SequenceObjective objective;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          objective.label,
          style: RelioType.captionSmall(palette),
        ),
        const SizedBox(height: RelioSpacing.xs),
        _ObjectiveBar(
          ratio: objective.ratio,
          track: palette.outline,
          fill: palette.primary,
        ),
      ],
    );
  }
}

/// Trait de progression de la séquence — 3 dp, sans chiffre.
class _ObjectiveBar extends StatelessWidget {
  const _ObjectiveBar({
    required this.ratio,
    required this.track,
    required this.fill,
  });

  final double ratio;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          height: RelioSizes.objectiveBarHeight,
          decoration: BoxDecoration(
            color: track,
            borderRadius: RelioRadius.pillAll,
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: constraints.maxWidth * ratio.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: RelioRadius.pillAll,
            ),
          ),
        );
      },
    );
  }
}

/// Message de Relio : le mark à gauche, la bulle de texte à droite.
///
/// Le logo n'est pas décoratif ici : il DÉSIGNE l'auteur du message. C'est la
/// raison pour laquelle il est le seul élément non textuel de la carte.
class RelioMessageCard extends StatelessWidget {
  /// Crée la carte de message.
  const RelioMessageCard({super.key, required this.message});

  /// Texte du message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: RelioRadius.bannerAll,
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Le mark est instancié, jamais redessiné : sa géométrie vient de
          // `relio_mark_geometry.dart` (règle 9).
          const RelioMark(size: 28),
          const SizedBox(width: RelioSpacing.md),
          Expanded(
            child: Text(
              message,
              style: RelioType.body(palette).copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte principale : le chapitre à reprendre, et le bouton pour y aller.
class ResumeCard extends StatelessWidget {
  /// Crée la carte de reprise.
  const ResumeCard({
    super.key,
    required this.target,
    required this.onContinue,
    this.reduceAnimations = false,
  });

  /// Chapitre et position à reprendre.
  final ResumeTarget target;

  /// Ouvre la leçon en cours.
  final VoidCallback onContinue;

  /// Désactive l'effet d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
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
      child: ClipRRect(
        borderRadius: RelioRadius.bannerAll,
        child: Stack(
          children: <Widget>[
            // Motif de fond : cercles et symboles, très légers. Il donne de la
            // matière à la carte sans jamais passer derrière un texte lisible.
            Positioned.fill(
              child: CustomPaint(
                painter: HomePatternPainter(color: palette.brand),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(RelioSpacing.cardInner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    RelioStrings.resumeLabel,
                    style: RelioType.overline(palette).copyWith(
                      color: palette.brand,
                    ),
                  ),
                  const SizedBox(height: RelioSpacing.sm),
                  Text(
                    target.chapterTitle,
                    style: RelioType.titleBold(palette),
                  ),
                  const SizedBox(height: RelioSpacing.xs),
                  Text(
                    target.positionLabel,
                    style: RelioType.body(palette).copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: RelioSpacing.lg),
                  PressableScale(
                    onTap: onContinue,
                    reduceAnimations: reduceAnimations,
                    child: Container(
                      height: RelioSizes.primaryButtonHeight,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: RelioRadius.cardAll,
                      ),
                      child: Text(
                        RelioStrings.resumeContinue,
                        style: RelioType.bodyStrong(palette).copyWith(
                          color: palette.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action rapide : une icône, un titre, un sous-titre.
class QuickActionCard extends StatelessWidget {
  /// Crée une action rapide.
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.reduceAnimations = false,
  });

  /// Icône illustrée.
  final IconData icon;

  /// Couleur de l'icône et de son fond.
  final Color iconColor;

  /// Titre de l'action.
  final String title;

  /// Sous-titre de l'action.
  final String subtitle;

  /// Action au tap.
  final VoidCallback onTap;

  /// Désactive l'effet d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return PressableScale(
      onTap: onTap,
      reduceAnimations: reduceAnimations,
      child: Container(
        padding: const EdgeInsets.all(RelioSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: RelioRadius.bannerAll,
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: RelioRadius.cardAll,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: RelioSpacing.md),
            Text(title, style: RelioType.bodyStrong(palette)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: RelioType.caption(palette),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Une leçon dans la liste « Ton programme ».
class LessonTimelineTile extends StatelessWidget {
  /// Crée une ligne de programme.
  const LessonTimelineTile({
    super.key,
    required this.lesson,
    required this.appearance,
    required this.onTap,
    this.reduceAnimations = false,
  });

  /// Leçon affichée.
  final LessonProgress lesson;

  /// Avancement de l'animation d'apparition, entre 0 et 1.
  final double appearance;

  /// Ouvre la leçon.
  final VoidCallback onTap;

  /// Désactive l'effet d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final Color statusColor = switch (lesson.status) {
      LessonStatus.toReview => palette.textSecondary,
      LessonStatus.inProgress => palette.brand,
      LessonStatus.mastered => palette.successText,
    };

    return PressableScale(
      onTap: onTap,
      reduceAnimations: reduceAnimations,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(RelioSpacing.lg),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: RelioRadius.bannerAll,
          border: Border.all(color: palette.outline),
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
                  label: lesson.statusLabel,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: RelioSpacing.md),
            RelioProgressBar(
              ratio: lesson.fill * appearance.clamp(0.0, 1.0),
              color: statusColor,
              track: palette.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// Motif géométrique de fond de la carte principale.
///
/// Volontairement pauvre : trois cercles et deux opérateurs, tracés à 8 %
/// d'opacité. Assez pour donner une matière, trop peu pour concurrencer le
/// texte — c'est un filigrane, pas une illustration.
class HomePatternPainter extends CustomPainter {
  /// Crée le motif.
  const HomePatternPainter({required this.color});

  /// Couleur du motif ; l'opacité est appliquée ici.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawCircle(Offset(size.width - 14, 18), 46, stroke);
    canvas.drawCircle(Offset(size.width - 72, 74), 22, stroke);
    canvas.drawCircle(Offset(size.width - 18, 104), 12, stroke);

    _cross(canvas, Offset(size.width - 108, 22), 7, stroke);
    _diagonalCross(canvas, Offset(size.width - 122, 108), 6, stroke);
  }

  /// Dessine un « + ».
  void _cross(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
  }

  /// Dessine un « × ».
  void _diagonalCross(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      center.translate(-radius, -radius),
      center.translate(radius, radius),
      paint,
    );
    canvas.drawLine(
      center.translate(-radius, radius),
      center.translate(radius, -radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(HomePatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
