/// S1 — Acces au chapitre.
///
/// Trois lecons empilees, selectionnables. Aucun compteur, aucune progression :
/// le moteur n'expose aucune donnee fiable de ce type, et la specification
/// l'interdit explicitement.
library;

import 'package:flutter/material.dart';

import '../../domain/curriculum/exercise.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Carte de selection d'une lecon.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final ArithmeticLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // L'intitule est affiche TEL QUEL : la lecon 2 porte « PGDC », conserve
    // fidelement a la source.
    final palette = RelioPaletteScope.of(context);

    return Semantics(
      button: true,
      label: lesson.title,
      child: Material(
        color: palette.surface,
        borderRadius: RelioRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: RelioRadius.cardAll,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: RelioRadius.cardAll,
              border: Border.all(
                color: palette.outline,
                width: RelioSizes.cardBorderWidth,
              ),
            ),
            padding: const EdgeInsets.all(RelioSpacing.cardInner),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      fontFamily: RelioTheme.fontFamily,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ecran d'acces au chapitre.
class ChapterAccessPage extends StatelessWidget {
  const ChapterAccessPage({super.key, required this.onOpenLesson});

  /// Appele avec l'identifiant de la lecon selectionnee.
  final void Function(String lessonId) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Scaffold(
      appBar: AppBar(
        // S1 n'est PLUS la racine : elle est atteinte depuis l'onglet
        // Apprendre, via la carte du chapitre 1. Sa flèche de retour est donc
        // active et ramène à l'écran Apprendre.
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: RelioStrings.back,
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
              style: RelioType.display(palette),
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
              LessonCard(
                lesson: lesson,
                onTap: () => onOpenLesson(lesson.id),
              ),
              const SizedBox(height: RelioSpacing.cardGap),
            ],
          ],
        ),
      ),
    );
  }
}
