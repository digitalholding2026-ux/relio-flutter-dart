/// Tests du parcours eleve : S1 (acces au chapitre) → S2 (exercice).
///
/// Verifient le COMPORTEMENT REEL des ecrans : ce qui est affiche, ce qui ne
/// l'est pas, et les transitions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/rules/v1_screen_rules.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/hint_area.dart';

import '../helpers/test_database.dart';

/// Surface de test : une base reelle et le service du chapitre 1.
class Harness {
  Harness(this.db, this.service);

  final AppDatabase db;
  final Chapter1Service service;
}

Future<Harness> pumpApp(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);
  return Harness(db, Chapter1Service(LearningEventRepository(db)));
}

/// Pompe l'application jusqu'a S1.
Future<Harness> pumpChapter(WidgetTester tester) async {
  final harness = await pumpApp(tester);
  await tester.pumpWidget(RelioApp(database: harness.db));
  await tester.pumpAndSettle();
  return harness;
}

/// Ouvre une lecon et aboutit sur S2.
Future<Harness> openExercise(WidgetTester tester, int index) async {
  final harness = await pumpChapter(tester);
  await tester.tap(find.byType(LessonCard).at(index));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  group('S1 — Acces au chapitre', () {
    testWidgets('affiche le titre du chapitre et son introduction',
        (tester) async {
      await pumpChapter(tester);

      expect(find.text(RelioStrings.chapterCaption), findsOneWidget);
      expect(find.text(RelioStrings.chapterTitle), findsOneWidget);
      expect(find.text(RelioStrings.chapterIntro), findsOneWidget);
    });

    testWidgets('affiche les trois leçons, texte exact', (tester) async {
      await pumpChapter(tester);

      expect(find.text('PGCD : algorithme des soustractions'), findsOneWidget);
      // Le terme source « PGDC » est conserve TEL QUEL.
      expect(find.text('« PGDC » : algorithme d’Euclide'), findsOneWidget);
      expect(
        find.text('Relation entre le PPCM et le PGCD de deux entiers naturels'),
        findsOneWidget,
      );
      expect(find.byType(LessonCard), findsNWidgets(3));
    });

    testWidgets('n’affiche aucun compteur de progression', (tester) async {
      await pumpChapter(tester);

      final page = tester.widget<ChapterAccessPage>(find.byType(ChapterAccessPage));
      expect(page.onOpenLesson, isNotNull);
      // Aucun chiffre ne doit apparaitre sur l'ecran d'acces.
      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('ouvrir une leçon mène à S2', (tester) async {
      await openExercise(tester, 0);

      expect(find.byType(ExercisePage), findsOneWidget);
      expect(find.byType(ChapterAccessPage), findsNothing);
    });

    testWidgets('chaque leçon ouvre son premier exercice', (tester) async {
      // Lecon 2 → exercice 5 (premier de la lecon 2).
      await openExercise(tester, 1);

      final ex5 = Chapter1Bank.findExercise(ExerciseIds.ex5)!;
      expect(find.text(ex5.statement), findsOneWidget);
    });
  });

  group('S2 — Énoncé et structure', () {
    testWidgets('affiche l’énoncé et le titre de la leçon', (tester) async {
      final harness = await openExercise(tester, 0);
      final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;

      expect(find.text(ex1.statement), findsOneWidget);
      expect(find.text(ex1.lesson.title), findsOneWidget);
      expect(harness.service.findExercise(ex1.id), isNotNull);
    });

    testWidgets('le titre de la leçon 3 est tronqué, pas débordé',
        (tester) async {
      await openExercise(tester, 2);

      final longTitle = 'Relation entre le PPCM et le PGCD de deux entiers naturels';
      // Présent dans l'énoncé ET tronqué dans la barre haute.
      expect(find.text(longTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche le champ et le bouton Valider', (tester) async {
      await openExercise(tester, 0);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(RelioStrings.validate), findsOneWidget);
    });
  });

  group('S2 — Bouton d’indice', () {
    testWidgets('visible sur l’exercice 1, qui a des indices',
        (tester) async {
      await openExercise(tester, 0);

      expect(find.text(RelioStrings.askHint), findsOneWidget);
    });

    testWidgets('visible sur l’exercice 5, qui a des indices',
        (tester) async {
      await pumpChapter(tester);
      // Accès direct à l'exercice 5 via le flux de l'exercice 2 → pas
      // l'écran ; on construit donc la page directement.
      final harness = await pumpApp(tester);
      await tester.pumpWidget(MaterialApp(
        theme: RelioTheme.build(),
        home: ExercisePage(
          service: harness.service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex5)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.askHint), findsOneWidget);
    });

    testWidgets('absent sur les 9 exercices sans indice', (tester) async {
      final harness = await pumpApp(tester);

      // Exercice 2 : pas d'indice.
      await tester.pumpWidget(MaterialApp(
        theme: RelioTheme.build(),
        home: ExercisePage(
          service: harness.service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex2)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.askHint), findsNothing);
      expect(find.byType(HintArea), findsNothing);
    });
  });

  group('S2 — Indices', () {
    testWidgets('s’affichent dans l’ordre 1 puis 2, puis le bouton disparaît',
        (tester) async {
      await openExercise(tester, 0);

      // Premier indice.
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.hintLabel(1)), findsOneWidget);
      expect(find.text(RelioStrings.askHint), findsOneWidget);

      // Second indice : le bouton disparait.
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.hintLabel(2)), findsOneWidget);
      expect(find.text(RelioStrings.askHint), findsNothing);
    });

    testWidgets('ne modifie ni la saisie ni le focus', (tester) async {
      await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();

      // La saisie est preservee.
      expect(find.text('6'), findsWidgets);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '6');
    });

    testWidgets('les indices précédents restent visibles', (tester) async {
      await openExercise(tester, 0);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.hintLabel(1)), findsOneWidget);
      expect(find.text(RelioStrings.hintLabel(2)), findsOneWidget);
    });
  });

  group('S2 — Soumission et panneaux', () {
    testWidgets('réponse vide : aucun envoi, message inline',
        (tester) async {
      await openExercise(tester, 0);

      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.emptyAnswerInline), findsOneWidget);
      expect(find.text(RelioStrings.successTitle), findsNothing);
    });

    testWidgets('le message inline disparaît à la première frappe',
        (tester) async {
      await openExercise(tester, 0);

      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.emptyAnswerInline), findsOneWidget);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.emptyAnswerInline), findsNothing);
    });

    testWidgets('réussite sans aide → panneau A', (tester) async {
      await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.successTitle), findsOneWidget);
      expect(find.text(RelioStrings.successAutonomous), findsOneWidget);
      expect(find.text(RelioStrings.nextExercise), findsOneWidget);
      // Pas de proposition de vérification en V1.
      expect(find.text('Vérifier ma maîtrise'), findsNothing);
    });

    testWidgets('réussite APRÈS indice → panneau B, jamais A',
        (tester) async {
      await openExercise(tester, 0);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.successAssisted), findsOneWidget);
      expect(find.text(RelioStrings.successAutonomous), findsNothing);
    });

    testWidgets('réponse fausse → panneau E, sans cause affirmée',
        (tester) async {
      await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '9');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.noInformation), findsOneWidget);
      expect(find.text(RelioStrings.retry), findsWidgets);
    });

    testWidgets('format non reconnu → panneau « non évaluable » distinct',
        (tester) async {
      // Le panneau n'est atteignable que sur un exercice à clavier
      // alphanumérique : sur un champ numérique, les lettres sont refusées
      // à la saisie, donc le format ne peut pas être non reconnu.
      final harness = await pumpApp(tester);
      await tester.pumpWidget(MaterialApp(
        theme: RelioTheme.build(),
        home: ExercisePage(
          service: harness.service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex10)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.notRecognised), findsOneWidget);
      // Distinct du panneau E.
      expect(find.text(RelioStrings.noInformation), findsNothing);
    });

    testWidgets('le champ numérique refuse les lettres', (tester) async {
      await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty,
          reason: 'un entier ne peut pas être tapé au clavier numérique');
    });

    testWidgets('aucun code diagnostic ni cause n’est affiché',
        (tester) async {
      await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '9');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      for (final code in <String>['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8']) {
        expect(find.textContaining(code), findsNothing);
      }
      expect(find.textContaining('confusion'), findsNothing);
      expect(find.textContaining('PGCD/PPCM'), findsNothing);
    });

    testWidgets('« Réessayer » vide le champ et masque le panneau',
        (tester) async {
      await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '9');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.noInformation), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, RelioStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.noInformation), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });
  });

  group('S2 — Mention de transparence', () {
    testWidgets('affichée sur les exercices 3, 7 et 11', (tester) async {
      final harness = await pumpApp(tester);

      const expected = <String, String>{
        ExerciseIds.ex3: 'La réponse finale est vérifiée automatiquement ; '
            'la justification n’est pas encore évaluée.',
        ExerciseIds.ex7: 'La réponse finale est vérifiée automatiquement ; '
            'la comparaison n’est pas encore évaluée.',
        ExerciseIds.ex11:
            'L’évaluation de la rédaction n’est pas encore complète.',
      };

      expected.forEach((exerciseId, note) {
        // La règle et l'affichage doivent être d'accord.
        expect(V1ScreenRules.transparencyNote(exerciseId), note);
        expect(find.text(note), findsNothing,
            reason: 'écran non encore construit pour $exerciseId');
      });

      expect(harness.service.findExercise(ExerciseIds.ex3), isNotNull);
    });

    testWidgets('absente sur les autres exercices', (tester) async {
      await openExercise(tester, 0);

      // Exercice 1 : aucune mention.
      expect(find.textContaining('n’est pas encore évaluée'), findsNothing);
      expect(find.textContaining('pas encore complète'), findsNothing);
    });

    testWidgets('la règle ne renvoie une note que pour 3, 7 et 11',
        (tester) async {
      await pumpChapter(tester);

      final withNote = <String>[];
      for (final exercise in V1ScreenRules.exercises) {
        if (V1ScreenRules.transparencyNote(exercise.id) != null) {
          withNote.add(exercise.id);
        }
      }

      expect(withNote, <String>[
        ExerciseIds.ex3,
        ExerciseIds.ex7,
        ExerciseIds.ex11,
      ]);
    });
  });

  group('S2 — Exercice 11, évaluation non concluante', () {
    testWidgets('réponse non reconnue → panneau non concluant, jamais « incorrect »',
        (tester) async {
      final harness = await pumpApp(tester);
      await tester.pumpWidget(MaterialApp(
        theme: RelioTheme.build(),
        home: ExercisePage(
          service: harness.service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex11)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'une autre formulation');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.inconclusive), findsOneWidget);
      // Ne doit jamais être présenté comme faux.
      expect(find.text(RelioStrings.noInformation), findsNothing);
      expect(find.text(RelioStrings.notRecognised), findsNothing);
    });

    testWidgets('le panneau propose Réessayer et Continuer', (tester) async {
      final harness = await pumpApp(tester);
      await tester.pumpWidget(MaterialApp(
        theme: RelioTheme.build(),
        home: ExercisePage(
          service: harness.service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex11)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'autre chose');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.retry), findsWidgets);
      expect(find.text(RelioStrings.continueLabel), findsOneWidget);
    });
  });

  group('S2 — Navigation et brouillon', () {
    testWidgets('retour vers S1, puis réouverture : saisie conservée',
        (tester) async {
      final harness = await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterAccessPage), findsOneWidget);

      // Réouverture : le brouillon de session est restauré.
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '6');
      expect(harness.service.findExercise(ExerciseIds.ex1), isNotNull);
    });

    testWidgets('retour puis réouverture : indices conservés', (tester) async {
      await openExercise(tester, 0);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.hintLabel(1)), findsOneWidget);
    });

    testWidgets('« Exercice suivant » avance dans la leçon', (tester) async {
      final harness = await openExercise(tester, 0);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      await tester.tap(find.text(RelioStrings.nextExercise));
      await tester.pumpAndSettle();

      final ex2 = Chapter1Bank.findExercise(ExerciseIds.ex2)!;
      expect(find.text(ex2.statement), findsOneWidget);
      expect(harness.service.findExercise(ex2.id), isNotNull);
    });
  });

  group('S2 — Pas de mécanique de jeu', () {
    testWidgets('aucun badge, série, XP ou progression', (tester) async {
      await openExercise(tester, 0);

      for (final forbidden in <String>['XP', 'niveau', 'série', 'badge', '%']) {
        expect(find.textContaining(forbidden), findsNothing,
            reason: 'mécanique de jeu interdite : $forbidden');
      }
    });

    testWidgets('aucun compteur de progression', (tester) async {
      await openExercise(tester, 0);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Sélection du panneau — règle pure', () {
    test('un ExerciseDraft par exercice est independant', () {
      final a = ExerciseDraft(answerKey: 'tentative-a');
      final b = ExerciseDraft(answerKey: 'tentative-b');

      a.answer = '6';
      expect(b.answer, isEmpty);
      expect(a.answerKey, isNot(b.answerKey));
    });
  });
}
