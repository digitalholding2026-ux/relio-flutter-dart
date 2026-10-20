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

/// Chapitre proposé en reprise dans la carte principale.@immutable
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

/// Objectif de séquence affiché en tête d'accueil.
///
/// « Séquence 1 • 2 notions sur 5 validées » : trois nombres, rien d'autre.
/// Ce n'est ni une note ni un score — seulement la position dans le programme.
/// Comme le reste de [HomeState], cet objet est une PROJECTION d'affichage :
/// il n'est jamais persisté et sera calculé par le moteur à partir des faits
/// observés.
@immutable
class SequenceObjective {
  /// Crée l'objectif affiché.
  const SequenceObjective({
    required this.sequence,
    required this.validated,
    required this.notions,
  });

  /// Numéro de la séquence en cours.
  final int sequence;

  /// Nombre de notions déjà validées.
  final int validated;

  /// Nombre total de notions de la séquence.
  final int notions;

  /// Part validée, entre 0 et 1 — largeur du trait, jamais affichée en chiffre.
  double get ratio {
    if (notions <= 0) return 0;
    return (validated / notions).clamp(0.0, 1.0);
  }

  /// Libellé affiché au-dessus du prénom.
  String get label => RelioStrings.sequenceObjective(sequence, validated, notions);
}

/// Codes de blocage récent que les mocks savent reconnaître.
///
/// Un code est un FAIT observé (« soustraction_fausse »), pas un jugement :
/// c'est le message affiché qui choisit comment en parler. Le moteur en
/// fournira d'autres ; l'interface n'en connaît qu'un pour l'instant.
abstract final class RecentBlockCodes {
  /// Hésitation constatée sur une soustraction.
  static const String subtractionWrong = 'soustraction_fausse';
}

/// Tout ce que l'écran d'accueil affiche.
@immutable
class HomeState {
  /// Crée un état d'accueil complet.
  const HomeState({
    required this.objective,
    required this.message,
    required this.resume,
    required this.lessons,
  });

  /// Objectif de séquence, affiché au-dessus du prénom.
  final SequenceObjective objective;

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
  /// les états, les remplissages et le message contextuel sont factices.
  ///
  /// [recentBlock] permet de voir la variante de message : passer
  /// [RecentBlockCodes.subtractionWrong] affiche le rappel sur les
  /// soustractions. Tout autre code — ou l'absence de code — laisse le message
  /// par défaut.
  factory HomeState.mock({String? recentBlock}) {
    const List<LessonStatus> statuses = <LessonStatus>[
      LessonStatus.inProgress,
      LessonStatus.toReview,
      LessonStatus.mastered,
    ];
    const List<double> fills = <double>[0.45, 0.15, 1];

    return HomeState(
      objective: const SequenceObjective(sequence: 1, validated: 2, notions: 5),
      message: switch (recentBlock) {
        RecentBlockCodes.subtractionWrong => RelioStrings.relioMessageSubtraction,
        _ => RelioStrings.relioMessage,
      },
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
