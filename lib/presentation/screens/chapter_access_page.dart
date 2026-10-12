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
    return Semantics(
      button: true,
      label: lesson.title,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RelioSizes.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RelioSizes.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RelioSizes.cardRadius),
              border: Border.all(
                color: RelioColors.border,
                width: RelioSizes.cardBorderWidth,
              ),
            ),
            padding: const EdgeInsets.all(RelioSpacing.cardInner),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontVariations: RelioTheme.w600,
                      height: 1.3,
                      fontFamily: RelioTheme.fontFamily,
                      color: RelioColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  color: RelioColors.textSecondary,
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
    return Scaffold(
      appBar: AppBar(
        // S1 est la racine en V1 : pas de retour possible.
        automaticallyImplyLeading: false,
        title: const Text(''),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelioSpacing.horizontal,
            8,
            RelioSpacing.horizontal,
            24,
          ),
          children: <Widget>[
            Text(
              RelioStrings.chapterCaption,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontVariations: RelioTheme.w500,
                fontFamily: RelioTheme.fontFamily,
                color: RelioColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              RelioStrings.chapterTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontVariations: RelioTheme.w700,
                height: 1.2,
                fontFamily: RelioTheme.fontFamily,
                color: RelioColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              RelioStrings.chapterIntro,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                fontFamily: RelioTheme.fontFamily,
                color: RelioColors.textSecondary,
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
