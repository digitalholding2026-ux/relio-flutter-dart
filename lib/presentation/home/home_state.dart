/// Modèles de l'écran d'accueil.
///
/// DONNÉES FACTICES, ET ASSUMÉES COMME TELLES.
///
/// Aucun de ces objets n'est lu ni écrit en base : l'accueil ne reçoit pour
/// l'instant aucune donnée d'apprentissage. Ils décrivent la FORME que le
/// moteur remplira plus tard — un chapitre à reprendre, des leçons et leur
/// état d'avancement — afin que l'écran n'ait pas à changer de structure le
/// jour où les faits observés seront disponibles.
///
/// Le jour où le cœur fournira ces données, seule [HomeState.mock] disparaîtra :
/// les widgets d'accueil ne dépendent que des types ci-dessous.
///
/// ⚠️ Rien ici n'est persisté. La règle 5 interdit de stocker une maîtrise, un
/// score ou un niveau ; ces états sont une PROJECTION d'affichage, calculée à
/// la volée à partir de faits observables. Ils ne doivent jamais rejoindre le
/// schéma de la base.
library;

import 'package:flutter/foundation.dart';

import '../../domain/curriculum/exercise.dart';
import '../strings/relio_strings.dart';

/// État d'une leçon tel qu'il s'affiche dans la liste « Ton programme ».
///
/// Trois états seulement, et jamais un pourcentage : l'élève voit où il en est,
/// pas une note.
enum LessonStatus {
  /// Commencée, non terminée : à reprendre en priorité.
  toReview,

  /// En cours de travail.
  inProgress,

  /// Terminée et stabilisée.
  mastered,
}

/// Une leçon du chapitre courant, avec son état d'affichage.
@immutable
class LessonProgress {
  /// Crée l'état d'affichage d'une leçon.
  const LessonProgress({
    required this.lessonId,
    required this.title,
    required this.status,
    required this.fill,
  });

  /// Identifiant stable de la leçon — celui de [ArithmeticLesson.id].
  final String lessonId;

  /// Intitulé affiché, repris du document pédagogique validé.
  final String title;

  /// État d'affichage.
  final LessonStatus status;

  /// Remplissage de la barre, entre 0 et 1.
  ///
  /// Sert UNIQUEMENT à la largeur du trait : ce n'est pas un score, et il n'est
  /// jamais affiché sous forme de chiffre.
  final double fill;

  /// Libellé qui accompagne la pastille de couleur.
  ///
  /// L'information n'est jamais portée par la seule couleur : chaque état est
  /// doublé de ce texte.
  String get statusLabel => switch (status) {
        LessonStatus.toReview => RelioStrings.statusToReview,
        LessonStatus.inProgress => RelioStrings.statusInProgress,
        LessonStatus.mastered => RelioStrings.statusMastered,
      };
}

/// Chapitre proposé en reprise dans la carte principale.
@immutable
class ResumeTarget {
  /// Crée la cible de reprise.
  const ResumeTarget({
    required this.chapterTitle,
    required this.positionLabel,
  });

  /// Titre du chapitre, repris du document validé.
  final String chapterTitle;

  /// Position dans le chapitre : « Exercice 2 sur 4 ».
  final String positionLabel;
}

/// Tout ce que l'écran d'accueil affiche.
@immutable
class HomeState {
  /// Crée un état d'accueil complet.
  const HomeState({
    required this.message,
    required this.resume,
    required this.lessons,
  });

  /// Message de Relio sous l'en-tête.
  final String message;

  /// Chapitre à reprendre.
  final ResumeTarget resume;

  /// Leçons du chapitre courant, dans l'ordre du programme.
  final List<LessonProgress> lessons;

  /// État de démonstration, en attendant les données du moteur.
  ///
  /// Les intitulés de leçons sont ceux du document validé (via
  /// [ArithmeticLesson]) : le mock n'invente aucun contenu pédagogique. Seuls
  /// les états et les remplissages sont factices.
  factory HomeState.mock() {
    const List<LessonStatus> statuses = <LessonStatus>[
      LessonStatus.inProgress,
      LessonStatus.toReview,
      LessonStatus.mastered,
    ];
    const List<double> fills = <double>[0.45, 0.15, 1];

    return HomeState(
      message: RelioStrings.relioMessage,
      resume: ResumeTarget(
        chapterTitle: RelioStrings.chapterArithmetic,
        positionLabel: RelioStrings.resumeProgress(2, 4),
      ),
      lessons: <LessonProgress>[
        for (final (int index, ArithmeticLesson lesson)
            in ArithmeticLesson.values.indexed)
          LessonProgress(
            lessonId: lesson.id,
            title: lesson.title,
            status: statuses[index],
            fill: fills[index],
          ),
      ],
    );
  }
}
