/// Modèles de l'écran d'accueil.
///
/// DEUX SOURCES, UN SEUL TYPE.
///
///  - [HomeState.fromProgress] est utilisée en PRODUCTION : les décomptes et
///    les états viennent des événements d'apprentissage, donc un nouvel élève
///    voit « 0 » et jamais une progression inventée ;
///  - [HomeState.mock] ne sert plus qu'aux tests et aux aperçus.
///
/// Aucun de ces objets n'est persisté. La règle 5 interdit de stocker une
/// maîtrise, un score ou un niveau ; ces états sont une PROJECTION d'affichage,
/// calculée à la volée à partir de faits observables. Ils ne doivent jamais
/// rejoindre le schéma de la base.
library;

import 'package:flutter/foundation.dart';

import '../../domain/curriculum/academic_calendar.dart';
import '../../domain/curriculum/chapter1_bank.dart';
import '../../domain/curriculum/curriculum_data.dart';
import '../../domain/curriculum/exercise.dart';
import '../../domain/learning/learner_progress.dart';
import '../strings/relio_strings.dart';

/// État d'une leçon tel qu'il s'affiche dans la liste « Ton programme ».
///
/// Quatre états seulement, et jamais un pourcentage : l'élève voit où il en est,
/// pas une note.
enum LessonStatus {
  /// Jamais commencée : pastille grise, barre vide.
  notStarted,

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
    this.completedExercises,
    this.totalExercises,
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

  /// Exercices terminés, quand l'écran affiche un décompte.
  ///
  /// Facultatif : l'accueil ne montre qu'une barre. La vue des leçons du
  /// chapitre affiche « 2/4 exercices » ; le moteur renseignera ces deux
  /// valeurs, l'interface ne les calcule jamais.
  final int? completedExercises;

  /// Exercices de la leçon, quand l'écran affiche un décompte.
  final int? totalExercises;

  /// Décompte affiché, ou `null` si l'écran n'en demande pas.
  String? get exerciseProgressLabel {
    final done = completedExercises;
    final total = totalExercises;
    if (done == null || total == null) return null;
    return RelioStrings.lessonExerciseProgress(done, total);
  }

  /// Libellé qui accompagne la pastille de couleur.
  ///
  /// L'information n'est jamais portée par la seule couleur : chaque état est
  /// doublé de ce texte.
  String get statusLabel => switch (status) {
        LessonStatus.notStarted => RelioStrings.statusNotStarted,
        LessonStatus.toReview => RelioStrings.statusToReview,
        LessonStatus.inProgress => RelioStrings.statusInProgress,
        LessonStatus.mastered => RelioStrings.statusMastered,
      };
}

/// Chapitre proposé en carte principale (reprise, ou premier démarrage).
@immutable
class ResumeTarget {
  /// Crée la cible de reprise.
  const ResumeTarget({
    required this.chapterTitle,
    this.positionLabel,
  });

  /// Titre du chapitre, repris du document validé.
  final String chapterTitle;

  /// Position dans le chapitre : « Exercice 2 sur 4 ».
  ///
  /// `null` au premier démarrage : il n'y a encore aucune position à
  /// annoncer, et en inventer une serait exactement ce que l'état vide doit
  /// éviter.
  final String? positionLabel;
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
    this.started = true,
  });

  /// Objectif de séquence, affiché au-dessus du prénom.
  final SequenceObjective objective;

  /// Message de Relio sous l'en-tête.
  final String message;

  /// Chapitre à reprendre, ou à commencer.
  final ResumeTarget resume;

  /// Leçons du chapitre courant, dans l'ordre du programme.
  final List<LessonProgress> lessons;

  /// L'élève a-t-il déjà soumis au moins une tentative ?
  ///
  /// `false` : la carte principale propose de COMMENCER, sans position ni
  /// progression inventée. `true` : elle propose de REPRENDRE.
  final bool started;

  /// État d'un nouvel élève : aucun fait, aucun décompte inventé.
  factory HomeState.empty() => HomeState.fromProgress(LearnerProgress.empty);

  /// État calculé depuis les faits observés.
  ///
  /// C'est l'UNIQUE constructeur utilisé en production. [HomeState.mock]
  /// reste réservé aux tests et aux aperçus.
  /// [now] permet de fixer la date dans les tests. En production, la date
  /// locale de l'appareil choisit la séquence : c'est elle qui situe l'élève
  /// dans l'année scolaire.
  factory HomeState.fromProgress(LearnerProgress progress, {DateTime? now}) {
    final DateTime date = now ?? DateTime.now();
    final AcademicSequence sequence = sequenceForDate(date);

    return HomeState(
      objective: SequenceObjective(
        sequence: sequence.number,
        validated: progress.masteredNotions,
        notions: ArithmeticLesson.values.length,
      ),
      message: _messageFor(progress, date, sequence.number),
      resume: _resumeTarget(progress),
      lessons: <LessonProgress>[
        for (final ArithmeticLesson lesson in ArithmeticLesson.values)
          lessonProgress(lesson, progress),
      ],
      started: progress.hasStarted,
    );
  }

  /// État d'affichage d'une leçon, déduit des faits.
  ///
  /// Une leçon jamais tentée reste « À commencer », avec une barre vide :
  /// c'est la définition de l'état vide demandée pour l'onglet Apprendre.
  static LessonProgress lessonProgress(
    ArithmeticLesson lesson,
    LearnerProgress progress,
  ) {
    final int total = progress.totalFor(lesson.id);
    final int done = progress.completedIn(lesson.id);
    final LessonStatus status;
    if (!progress.startedLesson(lesson.id)) {
      status = LessonStatus.notStarted;
    } else if (total > 0 && done >= total) {
      status = LessonStatus.mastered;
    } else {
      status = LessonStatus.inProgress;
    }

    return LessonProgress(
      lessonId: lesson.id,
      title: lesson.title,
      status: status,
      fill: total == 0 ? 0 : (done / total).clamp(0.0, 1.0),
      completedExercises: done,
      totalExercises: total,
    );
  }

  /// Message de Relio, choisi sur un fait observable et la période de l'année.
  ///
  /// Trois cas seulement, dans cet ordre :
  ///  - rien n'a été tenté → invitation à commencer ;
  ///  - exactement un exercice réussi → félicitation et proposition de
  ///    continuer ;
  ///  - tout le reste → repère temporel : mois et séquence en cours.
  ///
  /// Le nombre d'exercices vient de l'historique (réussites comprises) : ce
  /// n'est ni un score ni une interprétation de la réponse.
  static String _messageFor(
    LearnerProgress progress,
    DateTime date,
    int sequence,
  ) {
    if (!progress.hasStarted) return RelioStrings.relioMessageFirstSteps;
    if (progress.completedExercises == 1) {
      return RelioStrings.relioMessageFirstExerciseDone;
    }
    return RelioStrings.relioSeasonMessage(date, sequence);
  }

  /// Cible de la carte principale : premier exercice non terminé.
  static ResumeTarget _resumeTarget(LearnerProgress progress) {
    if (!progress.hasStarted) {
      // Premier démarrage : le titre porte le numéro du chapitre, puisqu'il
      // n'y a ni position ni leçon à rappeler.
      return ResumeTarget(chapterTitle: RelioStrings.chapter1CardTitle);
    }

    for (final ArithmeticLesson lesson in ArithmeticLesson.values) {
      final exercises = Chapter1Bank.exercises
          .where(
            (exercise) =>
                exercise.kind == BankElementKind.exercise &&
                exercise.lesson == lesson,
          )
          .toList();
      if (exercises.isEmpty) continue;

      final done = progress.completedExerciseIdsByLesson[lesson.id] ??
          const <String>{};
      final int index = exercises.indexWhere((e) => !done.contains(e.id));
      if (index >= 0) {
        return ResumeTarget(
          chapterTitle: RelioStrings.chapterArithmetic,
          positionLabel: RelioStrings.resumeProgress(index + 1, exercises.length),
        );
      }
    }

    // Tout est terminé : on annonce la dernière position connue plutôt qu'une
    // position inventée.
    final firstLesson = ArithmeticLesson.values.first;
    final int total = progress.totalFor(firstLesson.id);
    return ResumeTarget(
      chapterTitle: RelioStrings.chapterArithmetic,
      positionLabel: RelioStrings.resumeProgress(total, total),
    );
  }

  /// État de démonstration, pour les tests et les aperçus.
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
