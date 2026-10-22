/// Modèles de l'onglet « Apprendre » — catalogue et leçons.
///
/// DEUX SOURCES, UN SEUL TYPE.
///
///  - [LearnState.fromProgress] est utilisée en PRODUCTION : elle reflète les
///    faits observés, donc une leçon jamais commencée est « À commencer » avec
///    une barre vide ;
///  - [LearnState.mock] ne sert plus qu'aux tests et aux aperçus.
///
/// ⚠️ Rien ici n'est persisté. La règle 5 interdit de stocker une maîtrise, un
/// score ou un niveau ; ces états sont une PROJECTION d'affichage, calculée à
/// la volée à partir de faits observables. Ils ne doivent jamais rejoindre le
/// schéma de la base.
library;

import 'package:flutter/foundation.dart';

import '../../domain/curriculum/chapter2_bank.dart';
import '../../domain/curriculum/curriculum_bank.dart';
import '../../domain/curriculum/exercise.dart';
import '../../domain/learning/learner_progress.dart';
import '../../domain/learning/learning_event.dart';
import '../home/home_state.dart';
import '../strings/relio_strings.dart';

/// Un chapitre du programme, tel qu'il s'affiche dans le catalogue.
@immutable
class ChapterProgress {
  /// Crée l'état d'affichage d'un chapitre.
  const ChapterProgress({
    required this.number,
    required this.available,
    this.title,
    this.lessons = const <LessonProgress>[],
    this.validatedLessons = 0,
  });

  /// Numéro du chapitre, pour l'affichage.
  final int number;

  /// Chapitre ouvert : cliquable, avec chevron et progression.
  final bool available;

  /// Intitulé officiel, quand il est arrêté.
  ///
  /// `null` pour un chapitre non disponible : inventer un intitulé serait du
  /// contenu pédagogique fabriqué (règle 8).
  final String? title;

  /// Leçons du chapitre, dans l'ordre du programme.
  ///
  /// Vide tant que le chapitre n'est pas ouvert.
  final List<LessonProgress> lessons;

  /// Nombre de leçons déjà validées — valeur d'affichage, jamais persistée.
  final int validatedLessons;

  /// Titre complet de la carte : « Chapitre 1 : Arithmétique ».
  ///
  /// Un chapitre indisponible n'affiche que son numéro ; le sous-titre
  /// [subtitle] porte alors « Bientôt disponible ».
  String get cardTitle => available && title != null
      ? RelioStrings.chapterCardTitle(number, title!)
      : RelioStrings.chapterLabel(number);

  /// Sous-titre de la carte : avancement, ou « Bientôt disponible ».
  String get subtitle => available
      ? RelioStrings.chapterLessonsValidated(validatedLessons, lessons.length)
      : RelioStrings.chapterComingSoon;

  /// Part validée, entre 0 et 1 — largeur du trait, jamais un pourcentage.
  double get ratio {
    if (lessons.isEmpty) return 0;
    return (validatedLessons / lessons.length).clamp(0.0, 1.0);
  }

  /// Leçon d'identifiant [lessonId], ou `null`.
  LessonProgress? lessonById(String lessonId) {
    for (final lesson in lessons) {
      if (lesson.lessonId == lessonId) return lesson;
    }
    return null;
  }
}

/// Tout ce que l'onglet « Apprendre » affiche.
@immutable
class LearnState {
  /// Crée un état de catalogue complet.
  const LearnState({required this.chapters});

  /// Chapitres du programme, dans l'ordre officiel.
  final List<ChapterProgress> chapters;

  /// Chapitre ouvert, s'il existe.
  ChapterProgress? get activeChapter {
    for (final chapter in chapters) {
      if (chapter.available) return chapter;
    }
    return null;
  }

  /// Chapitre de numéro [number], ou `null` s'il n'est pas au programme.
  ChapterProgress? chapterByNumber(int number) {
    for (final chapter in chapters) {
      if (chapter.number == number) return chapter;
    }
    return null;
  }

  /// État de démonstration, pour les tests et les aperçus.
  ///
  /// Les intitulés de leçons sont ceux du document validé (via
  /// [ArithmeticLesson]) : le mock n'invente aucun contenu pédagogique. Seuls
  /// les états, les décomptes et les remplissages sont factices.
  factory LearnState.mock() {
    return LearnState(
      chapters: <ChapterProgress>[
        mockChapter1(),
        mockChapter2(),
        const ChapterProgress(number: 3, available: false),
      ],
    );
  }

  /// État d'un nouvel élève : aucune leçon commencée, aucune progression.
  ///
  /// Les totaux officiels restent ceux de la banque : une leçon jamais tentée
  /// affiche « 0/4 exercices », jamais « 0/0 ».
  factory LearnState.empty() => LearnState.fromProgress(
    LearnerProgress.fromEvents(const <LearningEvent>[]),
  );

  /// État calculé depuis les faits observés.
  ///
  /// C'est l'UNIQUE constructeur utilisé en production. Les totaux viennent de
  /// la banque validée : une leçon non tentée affiche « 0/4 exercices » et une
  /// barre vide, jamais un avancement inventé.
  factory LearnState.fromProgress(LearnerProgress progress) {
    return LearnState(
      chapters: <ChapterProgress>[
        ChapterProgress(
          number: 1,
          available: true,
          title: RelioStrings.chapterArithmetic,
          lessons: List<LessonProgress>.unmodifiable(<LessonProgress>[
            for (final ArithmeticLesson lesson in ArithmeticLesson.values)
              HomeState.lessonProgress(lesson, progress),
          ]),
          validatedLessons: progress.masteredNotionsIn(
            ArithmeticLesson.values,
          ),
        ),
        ChapterProgress(
          number: 2,
          available: true,
          title: RelioStrings.chapterThales,
          lessons: List<LessonProgress>.unmodifiable(<LessonProgress>[
            for (final ThalesLesson lesson in ThalesLesson.values)
              HomeState.lessonProgress(lesson, progress),
          ]),
          validatedLessons: progress.masteredNotionsIn(ThalesLesson.values),
        ),
        const ChapterProgress(number: 3, available: false),
      ],
    );
  }

  /// Chapitre 1, avec ses trois leçons et leur avancement factice.
  ///
  /// Les totaux d'exercices sont ceux de la banque validée (4, 3 et 4) : ils
  /// ne sont pas saisis à la main, donc ils ne peuvent pas diverger du
  /// contenu. Seuls les nombres TERMINÉS sont factices.
  static ChapterProgress mockChapter1() {
    const List<LessonStatus> statuses = <LessonStatus>[
      LessonStatus.inProgress,
      LessonStatus.toReview,
      LessonStatus.mastered,
    ];
    const List<int> completed = <int>[2, 1, 4];

    final lessons = <LessonProgress>[];
    for (final (int index, ArithmeticLesson lesson)
        in ArithmeticLesson.values.indexed) {
      final int total = _officialExerciseCount(lesson);
      final int done = completed[index].clamp(0, total);
      lessons.add(
        LessonProgress(
          lessonId: lesson.id,
          title: lesson.title,
          status: statuses[index],
          fill: total == 0 ? 0 : done / total,
          completedExercises: done,
          totalExercises: total,
        ),
      );
    }

    return ChapterProgress(
      number: 1,
      available: true,
      title: RelioStrings.chapterArithmetic,
      lessons: List<LessonProgress>.unmodifiable(lessons),
      validatedLessons: 2,
    );
  }

  /// Chapitre 2, avec ses deux leçons à l'état vide.
  ///
  /// Aucun exercice n'est inventé : les totaux sont comptés dans
  /// [Chapter2Bank] via [CurriculumBank].
  static ChapterProgress mockChapter2() {
    const LearnerProgress empty = LearnerProgress.empty;

    return ChapterProgress(
      number: 2,
      available: true,
      title: RelioStrings.chapterThales,
      lessons: List<LessonProgress>.unmodifiable(<LessonProgress>[
        for (final ThalesLesson lesson in ThalesLesson.values)
          HomeState.lessonProgress(lesson, empty),
      ]),
      validatedLessons: 0,
    );
  }

  /// Nombre d'exercices officiels d'une leçon.
  static int _officialExerciseCount(CurriculumLesson lesson) {
    return CurriculumBank.exercisesOfLesson(lesson.id).length;
  }
}
