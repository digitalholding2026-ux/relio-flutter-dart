/// Écran Apprendre — onglet 2 : catalogue de progression.
///
/// OBJECTIF : montrer le programme de 3e comme un parcours, pas comme une
/// liste plate. Un chapitre ouvert porte son avancement ; les chapitres
/// suivants sont annoncés sans être cliquables.
///
/// DONNÉES RÉELLES : l'état vient de la coquille, calculé depuis les
/// événements d'apprentissage ([LearnState.fromProgress]). Le défaut de
/// l'écran est l'état vide : aucune progression inventée.
///
/// Aucun personnage n'est utilisé ici : la marque et le personnage restent sur
/// l'ouverture, le prénom et la clôture.
library;

import 'package:flutter/material.dart';

import '../home/pressable_scale.dart';
import '../learn/learn_state.dart';import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import '../widgets/relio_progress_bar.dart';
import '../widgets/voice_toggle_button.dart';

/// Carte d'un chapitre du catalogue.
///
/// Deux formes seulement :
///  - chapitre ouvert : fond blanc, bordure orange, ombre douce, chevron,
///    barre de progression ;
///  - chapitre indisponible : fond gris, sans ombre, sans chevron, inerte.
class ChapterCard extends StatelessWidget {
  /// Crée une carte de chapitre.
  const ChapterCard({
    super.key,
    required this.chapter,
    this.onTap,
    this.reduceAnimations = false,
  });

  /// Chapitre décrit par la carte.
  final ChapterProgress chapter;

  /// Ouvre les leçons du chapitre. `null` rend la carte inerte.
  final VoidCallback? onTap;

  /// Désactive l'effet d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: chapter.available ? palette.surface : palette.inactiveSurface,
        borderRadius: RelioRadius.bannerAll,
        border: chapter.available
            ? Border.all(
                color: palette.brand,
                width: RelioSizes.heroBorderWidth,
              )
            : null,
        boxShadow: chapter.available
            ? <BoxShadow>[
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  chapter.cardTitle,
                  style: RelioType.chapterTitle(palette).copyWith(
                    color: chapter.available
                        ? palette.textPrimary
                        : palette.textMuted,
                  ),
                ),
                const SizedBox(height: RelioSpacing.xs),
                Text(
                  chapter.subtitle,
                  style: RelioType.body(palette).copyWith(
                    color: chapter.available
                        ? palette.textSecondary
                        : palette.textMuted,
                  ),
                ),
                if (chapter.available) ...<Widget>[
                  const SizedBox(height: RelioSpacing.md),
                  RelioProgressBar(
                    ratio: chapter.ratio,
                    color: palette.brand,
                    track: palette.outline,
                  ),
                ],
              ],
            ),
          ),
          if (chapter.available) ...<Widget>[
            const SizedBox(width: RelioSpacing.md),
            Icon(Icons.chevron_right, color: palette.textSecondary),
          ],
        ],
      ),
    );

    if (!chapter.available || onTap == null) return content;

    return Semantics(
      button: true,
      label: chapter.cardTitle,
      child: PressableScale(
        onTap: onTap!,
        reduceAnimations: reduceAnimations,
        child: content,
      ),
    );
  }
}

/// Écran Apprendre — catalogue des chapitres.
class LearnPage extends StatelessWidget {
  /// Crée l'écran Apprendre.
  const LearnPage({
    super.key,
    required this.onOpenChapter1,
    this.onOpenChapter2,
    this.learnState,
    this.reduceAnimations = false,
  });

  /// Ouvre les leçons du chapitre 1.
  final VoidCallback onOpenChapter1;

  /// Ouvre les leçons du chapitre 2.
  ///
  /// `null` conserve l'ancien comportement (ouvrir le chapitre 1) : un écran
  /// monté sans cette action ne doit pas introduire une cible inventée.
  final VoidCallback? onOpenChapter2;

  /// État à afficher.
  ///
  /// `null` : [LearnState.empty]. Un écran monté sans données ne doit jamais
  /// montrer une progression de démonstration.
  final LearnState? learnState;

  /// Désactive les effets d'appui.
  final bool reduceAnimations;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final state = learnState ?? LearnState.empty();

    return Scaffold(
      // Même teinte que l'accueil : les cartes blanches se détachent sans
      // qu'on ajoute une bordure à chacune.
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
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    RelioStrings.learnTitle,
                    style: RelioType.display(palette).copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
                const SizedBox(width: RelioSpacing.sm),
                // Emplacement préparé pour la recherche : il n'ouvre encore
                // rien, et le dit plutôt que de rester muet.
                IconButton(
                  onPressed: () => _showSearchComingSoon(context),
                  tooltip: RelioStrings.searchTooltip,
                  color: palette.textSecondary,
                  constraints: const BoxConstraints(
                    minWidth: RelioSizes.minTouchTarget,
                    minHeight: RelioSizes.minTouchTarget,
                  ),
                  icon: const Icon(Icons.search),
                ),
                const VoiceToggleButton(),
              ],
            ),
            const SizedBox(height: RelioSpacing.xl),
            for (final chapter in state.chapters) ...<Widget>[
              ChapterCard(
                chapter: chapter,
                // Seul un chapitre ouvert porte l'action. Un chapitre à venir
                // n'a rien à ouvrir : il reste inerte, sans chevron.
                onTap: chapter.available
                    ? _openChapter(chapter)
                    : null,
                reduceAnimations: reduceAnimations,
              ),
              const SizedBox(height: RelioSpacing.cardGap),
            ],
          ],
        ),
      ),
    );
  }

  /// Action d'ouverture d'un chapitre disponible.
  VoidCallback _openChapter(ChapterProgress chapter) {
    if (chapter.number == 2) return onOpenChapter2 ?? onOpenChapter1;
    return onOpenChapter1;
  }

  /// Dit que la recherche n'est pas encore disponible.
  void _showSearchComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(RelioStrings.searchComingSoon)),
      );
  }
}
