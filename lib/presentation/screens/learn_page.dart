/// Écran Apprendre — onglet 2.
///
/// OBJECTIF : donner accès au programme officiel de mathématiques de 3e.
///
/// V1 : la liste est STATIQUE. Le chapitre 1 est le seul actif. Les intitulés
/// des chapitres suivants ne sont pas arrêtés, ils sont donc affichés
/// génériquement (« Chapitre 2 ») avec « Bientôt disponible » : inventer les
/// intitulés officiels serait du contenu pédagogique fabriqué, interdit par la
/// règle 8 d'`AGENTS.md`.
///
/// Ce que l'écran n'affiche PAS : aucun compteur de chapitres terminés, aucune
/// barre de progression, aucun indicateur de déblocage, aucun encouragement.
library;

import 'package:flutter/material.dart';

import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import 'app_shell.dart';

/// Un chapitre du programme, dans son état d'avancement.
@immutable
class ChapterEntry {
  const ChapterEntry({
    required this.number,
    required this.subtitle,
    required this.active,
    this.onTap,
  });

  /// Numéro du chapitre, pour l'affichage.
  final int number;

  /// Intitulé du chapitre. Générique si l'intitulé officiel n'est pas arrêté.
  final String subtitle;

  /// Chapitre disponible : cliquable, chevron présent.
  final bool active;

  /// Action au tap. Non nul si et seulement si [active].
  final VoidCallback? onTap;

  /// Titre affiché : « Chapitre N ».
  String get title => 'Chapitre $number';
}

/// Programme de 3e — liste statique du chapitre 1.
///
/// Le chapitre 1 est le seul actif en V1. Les chapitres 2 à 3 sont des
/// emplacements réservés : affichés, mais inertes.
const List<ChapterEntry> kChapterProgram = <ChapterEntry>[
  ChapterEntry(
    number: 1,
    subtitle: RelioStrings.chapterArithmetic,
    active: true,
  ),
  ChapterEntry(number: 2, subtitle: RelioStrings.chapterComingSoon, active: false),
  ChapterEntry(number: 3, subtitle: RelioStrings.chapterComingSoon, active: false),
];

/// Carte de chapitre de l'écran Apprendre.
class ChapterCard extends StatelessWidget {
  const ChapterCard({super.key, required this.chapter});

  /// Chapitre décrit par la carte.
  final ChapterEntry chapter;

  @override
  Widget build(BuildContext context) {
    // Un chapitre inactif affiche « Bientôt disponible » comme sous-titre ;
    // un chapitre actif affiche son intitulé et un chevron.
    final subtitle = chapter.active
        ? chapter.subtitle
        : RelioStrings.chapterComingSoon;

    return NavCard(
      title: chapter.title,
      subtitle: subtitle,
      onTap: chapter.onTap,
      // Pas de chevron sur un chapitre indisponible : rien à ouvrir.
      showChevron: chapter.active,
      elevated: false,
    );
  }
}

/// Écran Apprendre.
class LearnPage extends StatelessWidget {
  const LearnPage({super.key, required this.onOpenChapter1});

  /// Ouvre S1 du chapitre 1.
  final VoidCallback onOpenChapter1;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    // Le chapitre 1 est le seul actif : c'est lui qui porte l'action.
    final chapters = <ChapterEntry>[
      for (final chapter in kChapterProgram)
        if (chapter.active)
          ChapterEntry(
            number: chapter.number,
            subtitle: chapter.subtitle,
            active: true,
            onTap: onOpenChapter1,
          )
        else
          chapter,
    ];

    return Scaffold(
      // Racine d'onglet : pas de flèche de retour.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          RelioStrings.learnTitle,
          style: RelioType.title(palette),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelioSpacing.horizontal,
            RelioSpacing.md,
            RelioSpacing.horizontal,
            RelioSpacing.xxl,
          ),
          children: <Widget>[
            for (final chapter in chapters) ...<Widget>[
              ChapterCard(chapter: chapter),
              const SizedBox(height: RelioSpacing.cardGap),
            ],
          ],
        ),
      ),
    );
  }
}