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
import '../../domain/curriculum/curriculum_bank.dart';
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

  /// Identifiant stable de la leçon — celui de [CurriculumLesson.id].
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

/// Un chapitre OUVERT, avec son numéro, son intitulé et ses leçons.
///
/// La liste des chapitres ouverts vient de [CurriculumBank] : l'accueil ne
/// code jamais « chapitre 1 » en dur. Ajouter une banque suffit donc à la voir
/// apparaître dans le programme et dans la carte de reprise.
@immutable
class HomeChapter {
  /// Crée la description d'un chapitre ouvert.
  const HomeChapter({
    required this.number,
    required this.title,
    required this.lessons,
  });

  /// Numéro du chapitre dans le programme.
  final int number;

  /// Intitulé transcrit du programme officiel.
  final String title;

  /// Leçons du chapitre, dans l'ordre du programme.
  final List<CurriculumLesson> lessons;

  /// Titre complet affiché sur la carte : « Chapitre 2 : Théorème de Thalès ».
  String get cardTitle => RelioStrings.chapterCardTitle(number, title);
}

/// Chapitre proposé en carte principale (reprise, ou premier démarrage).
@immutable
class ResumeTarget {
  /// Crée la cible de reprise.
  const ResumeTarget({
    required this.chapterNumber,
    required this.chapterTitle,
    this.positionLabel,
  });

  /// Numéro du chapitre à ouvrir : c'est lui que « Continuer » doit viser.
  final int chapterNumber;

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
  String get label =>
      RelioStrings.sequenceObjective(sequence, validated, notions);
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
    this.currentChapterNumber = 1,
  });

  /// Objectif de séquence, affiché au-dessus du prénom.
  final SequenceObjective objective;

  /// Message de Relio sous l'en-tête.
  final String message;

  /// Chapitre à reprendre, ou à commencer.
  final ResumeTarget resume;

  /// Leçons affichées : le chapitre courant d'abord, puis les leçons
  /// commencées et non terminées des chapitres précédents.
  final List<LessonProgress> lessons;

  /// Numéro du chapitre affiché comme « en cours ».
  final int currentChapterNumber;

  /// Le chapitre affiché a-t-il déjà été commencé ?
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
  ///
  /// LE CHAPITRE SUIT LA SÉQUENCE. L'accueil ne montre plus systématiquement
  /// l'arithmétique :
  ///
  ///  1. on lit la séquence du mois dans [officialProgram] ;
  ///  2. on retient le premier chapitre OUVERT dont l'intitulé figure dans
  ///     cette séquence (`Arithmétique` en septembre, par exemple) ;
  ///  3. si la séquence ne contient aucun chapitre ouvert — octobre et
  ///     novembre annoncent « Nombres réels (suite) » et « Trigonométrie »,
  ///     dont les banques n'existent pas encore —, on retient le dernier
  ///     chapitre ouvert, c'est-à-dire celui qui vient d'être enseigné :
  ///     « Théorème de Thalès ». C'est le chapitre que l'élève doit
  ///     travailler, pas un chapitre vide.
  factory HomeState.fromProgress(LearnerProgress progress, {DateTime? now}) {
    final DateTime date = now ?? DateTime.now();
    final AcademicSequence sequence = sequenceForDate(date);
    final HomeChapter chapter = _currentChapterFor(sequence);

    return HomeState(
      objective: SequenceObjective(
        sequence: sequence.number,
        validated: progress.masteredNotionsIn(chapter.lessons),
        notions: chapter.lessons.length,
      ),
      message: _messageFor(progress, date, sequence.number),
      resume: _resumeTarget(chapter, progress),
      lessons: <LessonProgress>[
        // Le chapitre en cours d'abord.
        for (final CurriculumLesson lesson in chapter.lessons)
          lessonProgress(lesson, progress),
        // Puis les leçons des chapitres précédents qui sont commencées et
        // non terminées : c'est le « à revoir » de l'élève, sans rien
        // inventer pour les leçons jamais ouvertes.
        for (final HomeChapter previous in _chaptersBefore(chapter.number))
          for (final CurriculumLesson lesson in previous.lessons)
            if (progress.startedLesson(lesson.id) &&
                !progress.isLessonMastered(lesson.id))
              lessonProgress(lesson, progress),
      ],
      started: chapter.lessons.any(
        (CurriculumLesson lesson) => progress.startedLesson(lesson.id),
      ),
      currentChapterNumber: chapter.number,
    );
  }

  /// Chapitres ouverts, dans l'ordre du programme.
  ///
  /// Aucun numéro n'est codé en dur : le registre [CurriculumBank] fait foi.
  static List<HomeChapter> openChapters() {
    final numbers = <int>{
      for (final CurriculumLesson lesson in CurriculumBank.lessons)
        lesson.chapterNumber,
    }.toList()..sort();

    return <HomeChapter>[
      for (final int number in numbers)
        HomeChapter(
          number: number,
          title: _chapterTitle(number),
          lessons: CurriculumBank.lessonsForChapter(number),
        ),
    ];
  }

  /// Intitulé d'un chapitre ouvert.
  ///
  /// Seuls les chapitres dont la banque existe sont nommés ici : un chapitre
  /// sans banque n'est jamais affiché comme courant.
  static String _chapterTitle(int number) => switch (number) {
    1 => RelioStrings.chapterArithmetic,
    2 => RelioStrings.chapterThales,
    _ => RelioStrings.chapterLabel(number),
  };

  /// Chapitre courant d'une séquence.
  static HomeChapter _currentChapterFor(AcademicSequence sequence) {
    final List<HomeChapter> chapters = openChapters();
    for (final HomeChapter chapter in chapters) {
      if (sequence.chapters.contains(chapter.title)) return chapter;
    }
    // La séquence ne contient aucun chapitre ouvert : on garde le dernier
    // chapitre enseigné, plutôt que d'afficher une liste vide.
    return chapters.last;
  }

  /// Chapitres ouverts strictement antérieurs à [number].
  static List<HomeChapter> _chaptersBefore(int number) => <HomeChapter>[
    for (final HomeChapter chapter in openChapters())
      if (chapter.number < number) chapter,
  ];

  /// État d'affichage d'une leçon, déduit des faits.
  ///
  /// Une leçon jamais tentée reste « À commencer », avec une barre vide :
  /// c'est la définition de l'état vide demandée pour l'onglet Apprendre.
  static LessonProgress lessonProgress(
    CurriculumLesson lesson,
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
  /// Deux cas seulement :
  ///  - exactement un exercice réussi → félicitation et proposition de
  ///    continuer, une seule fois ;
  ///  - tout le reste → repère temporel : mois et séquence en cours.
  ///
  /// Le repère temporel est le message PAR DÉFAUT : un nouvel élève comme un
  /// élève avancé sait ainsi où il se situe dans l'année. Le nombre
  /// d'exercices vient de l'historique (réussites comprises) : ce n'est ni un
  /// score ni une interprétation de la réponse.
  static String _messageFor(
    LearnerProgress progress,
    DateTime date,
    int sequence,
  ) {
    if (progress.completedExercises == 1) {
      return RelioStrings.relioMessageFirstExerciseDone;
    }
    return RelioStrings.relioSeasonMessage(date, sequence);
  }

  /// Cible de la carte principale : premier exercice non terminé du chapitre.
  ///
  /// Le parcours suit les leçons du chapitre, puis leurs exercices. Une leçon
  /// entièrement réussie est sautée : la carte annonce le premier travail qui
  /// reste réellement à faire.
  static ResumeTarget _resumeTarget(
    HomeChapter chapter,
    LearnerProgress progress,
  ) {
    final bool started = chapter.lessons.any(
      (CurriculumLesson lesson) => progress.startedLesson(lesson.id),
    );

    if (!started) {
      // Premier démarrage du chapitre : le titre porte son numéro, puisqu'il
      // n'y a ni position ni leçon à rappeler.
      return ResumeTarget(
        chapterNumber: chapter.number,
        chapterTitle: chapter.cardTitle,
      );
    }

    for (final CurriculumLesson lesson in chapter.lessons) {
      final List<Exercise> exercises = CurriculumBank.exercisesOfLesson(
        lesson.id,
      );
      if (exercises.isEmpty) continue;

      final done =
          progress.completedExerciseIdsByLesson[lesson.id] ?? const <String>{};
      final int index = exercises.indexWhere((e) => !done.contains(e.id));
      if (index >= 0) {
        return ResumeTarget(
          chapterNumber: chapter.number,
          chapterTitle: chapter.cardTitle,
          positionLabel: RelioStrings.resumeProgress(
            index + 1,
            exercises.length,
          ),
        );
      }
    }

    // Tout est terminé : on annonce la dernière position connue plutôt qu'une
    // position inventée.
    final CurriculumLesson lastLesson = chapter.lessons.last;
    final int total = progress.totalFor(lastLesson.id);
    return ResumeTarget(
      chapterNumber: chapter.number,
      chapterTitle: chapter.cardTitle,
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
        RecentBlockCodes.subtractionWrong =>
          RelioStrings.relioMessageSubtraction,
        _ => RelioStrings.relioMessage,
      },
      resume: ResumeTarget(
        chapterNumber: 1,
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
