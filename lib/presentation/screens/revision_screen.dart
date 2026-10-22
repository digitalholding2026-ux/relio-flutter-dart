/// Écran Révision — le coach d'examen.
///
/// TROIS BLOCS, DANS CET ORDRE :
///
///  1. l'objectif : la séquence du programme en cours, déduite de la date ;
///  2. les chapitres de cette séquence ;
///  3. les leçons des séquences précédentes où des erreurs ont été
///     réellement constatées.
///
/// Le bouton « Lancer ma préparation » ouvre une session de trois exercices
/// en puisant dans les deux sections. Aucune donnée n'est inventée : le plan
/// ([RevisionPlan]) est calculé depuis le programme officiel et l'historique
/// des tentatives. Sans exercice disponible, le bouton reste désactivé plutôt
/// que d'ouvrir une session vide.
library;

import 'package:flutter/material.dart';

import '../../domain/learning/revision_plan.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Écran de révision.
class RevisionScreen extends StatelessWidget {
  /// Crée l'écran.
  const RevisionScreen({
    super.key,
    required this.plan,
    required this.onStart,
  });

  /// Plan affiché — séquence, chapitres, faiblesses et exercices.
  final RevisionPlan plan;

  /// Lance la préparation de trois exercices.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return Scaffold(
      backgroundColor: palette.homeBackground,
      appBar: AppBar(
        title: Text(
          RelioStrings.revisionScreenTitle,
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
            RelioSpacing.lg,
            RelioSpacing.horizontal,
            RelioSpacing.xxxl,
          ),
          children: <Widget>[
            _ObjectiveHeader(sequenceTitle: plan.sequence.title),
            const SizedBox(height: RelioSpacing.sectionGap),
            _SectionTitle(text: RelioStrings.revisionProgramSection),
            const SizedBox(height: RelioSpacing.md),
            _ProgramCard(chapters: plan.sequence.chapters),
            const SizedBox(height: RelioSpacing.sectionGap),
            _SectionTitle(text: RelioStrings.revisionWeakSection),
            const SizedBox(height: RelioSpacing.md),
            if (plan.weaknesses.isEmpty)
              const _EmptyWeaknessCard()
            else
              _WeaknessCard(weaknesses: plan.weaknesses),
            if (plan.usesFallback) ...<Widget>[
              const SizedBox(height: RelioSpacing.md),
              Text(
                RelioStrings.revisionFallbackNote,
                style: RelioType.caption(palette),
              ),
            ],
            const SizedBox(height: RelioSpacing.sectionGap),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: plan.canStart ? onStart : null,
                child: const Text(RelioStrings.revisionStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête : « Objectif : Séquence … », puis la consigne.
class _ObjectiveHeader extends StatelessWidget {
  const _ObjectiveHeader({required this.sequenceTitle});

  final String sequenceTitle;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${RelioStrings.revisionObjectiveLabel} : $sequenceTitle',
          style: RelioType.title(palette),
        ),
        const SizedBox(height: RelioSpacing.sm),
        Text(
          RelioStrings.revisionSubtitle,
          style: RelioType.subtitle(palette),
        ),
      ],
    );
  }
}

/// Titre de section, discret et constant.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);
    return Text(text, style: RelioType.sectionTitle(palette));
  }
}

/// Carte blanche commune aux deux sections.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: RelioRadius.bannerAll,
        border: Border.all(color: palette.outline),
      ),
      child: child,
    );
  }
}

/// Chapitres de la séquence en cours.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.chapters});

  final List<String> chapters;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (int index, String chapter) in chapters.indexed) ...<Widget>[
            if (index > 0) const SizedBox(height: RelioSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: palette.primary,
                ),
                const SizedBox(width: RelioSpacing.sm),
                Expanded(
                  child: Text(chapter, style: RelioType.body(palette)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Leçons à retravailler, avec le nombre d'erreurs observées.
class _WeaknessCard extends StatelessWidget {
  const _WeaknessCard({required this.weaknesses});

  final List<RevisionWeakness> weaknesses;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (int index, RevisionWeakness weakness)
              in weaknesses.indexed) ...<Widget>[
            if (index > 0) const SizedBox(height: RelioSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.replay_rounded,
                  size: 20,
                  color: palette.brand,
                ),
                const SizedBox(width: RelioSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        weakness.lesson.title,
                        style: RelioType.bodyStrong(palette),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        RelioStrings.revisionErrorCount(weakness.errorCount),
                        style: RelioType.caption(palette),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Message affiché quand aucune erreur n'a été relevée.
class _EmptyWeaknessCard extends StatelessWidget {
  const _EmptyWeaknessCard();

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: palette.successText,
          ),
          const SizedBox(width: RelioSpacing.sm),
          Expanded(
            child: Text(
              RelioStrings.revisionNoWeakness,
              style: RelioType.body(palette),
            ),
          ),
        ],
      ),
    );
  }
}
