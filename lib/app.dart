/// Application Relio — racine de l'interface.
///
/// Point d'entree du parcours eleve du chapitre 1 :
///   S1 (acces au chapitre) → S2 (exercice).
///
/// La navigation est PORTEE ici : les ecrans ne connaissent que les
/// evenements qu'ils emettent, jamais la suite du parcours.
library;

import 'package:flutter/material.dart';

import 'data/db/app_database.dart';
import 'domain/catalog/notion_catalog.dart';
import 'domain/curriculum/chapter1_service.dart';
import 'domain/curriculum/exercise.dart';
import 'domain/learning/learning_event_repository.dart';
import 'presentation/rules/v1_screen_rules.dart';
import 'presentation/screens/chapter_access_page.dart';
import 'presentation/screens/exercise_page.dart';
import 'presentation/theme/relio_theme.dart';

class RelioApp extends StatelessWidget {
  const RelioApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relio',
      debugShowCheckedModeBanner: false,
      theme: RelioTheme.build(),
      home: LearnerFlow(
        service: Chapter1Service(LearningEventRepository(database)),
      ),
    );
  }
}

/// Parcours eleve : S1 puis S2.
///
/// Porte la navigation ET les brouillons de session, afin que la saisie et
/// les indices restent disponibles apres un aller-retour entre ecrans.
class LearnerFlow extends StatefulWidget {
  const LearnerFlow({super.key, required this.service});

  final Chapter1Service service;

  @override
  State<LearnerFlow> createState() => _LearnerFlowState();
}

class _LearnerFlowState extends State<LearnerFlow> {
  /// Brouillons par identifiant d'exercice — memoire de session uniquement.
  ///
  /// V1 : aucune persistance. Une fermeture forcee de l'application perd la
  /// saisie ; limite ACCEPTEE et non masquee.
  final Map<String, ExerciseDraft> _drafts = <String, ExerciseDraft>{};

  /// Ouvre S2 sur le premier exercice de la lecon.
  Future<void> _openLesson(String lessonId) async {
    final exercise = V1ScreenRules.firstOfLesson(lessonId);
    // Lecon inconnue : ne rien ouvrir plutot que d'afficher un ecran vide.
    if (exercise == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExercisePage(
          service: widget.service,
          exercise: exercise,
          drafts: _drafts,
          onExit: () => Navigator.of(context).pop(),
          onGoToNext: () => _goToNext(exercise),
        ),
      ),
    );
  }

  /// Passe a l'exercice suivant, ou revient a S1 apres le dernier.
  Future<void> _goToNext(Exercise exercise) async {
    final next = V1ScreenRules.nextAfter(exercise);
    if (next == null) {
      // Dernier exercice du chapitre : retour a S1.
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;
    // Remplace S2 par l'exercice suivant : la pile ne s'empile pas.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ExercisePage(
          service: widget.service,
          exercise: next,
          drafts: _drafts,
          onExit: () => Navigator.of(context).pop(),
          onGoToNext: () => _goToNext(next),
          // L'eleve enchaîne : le champ du nouvel exercice doit etre
          // pret a ecrire, sans avoir a le toucher.
          requestFocusOnOpen: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChapterAccessPage(onOpenLesson: _openLesson);
  }
}

/// Service de catalogue conserve pour les usages futurs.
///
/// L'ecran d'accueil technique a ete remplace par le parcours eleve ; le
/// depot reste disponible pour les notebooks et la suite du parcours.
typedef CatalogueService = NotionRepository;
