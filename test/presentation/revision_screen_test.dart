/// Tests de l'écran Révision.
///
/// L'écran ne fabrique aucune donnée : il affiche le plan fourni. Ces tests
/// vérifient les trois blocs (objectif, programme, faiblesses), l'état vide et
/// l'action de préparation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/exercise_attempt.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/learning/learning_event.dart';
import 'package:relio/domain/learning/observed_error.dart';
import 'package:relio/domain/learning/revision_plan.dart';
import 'package:relio/presentation/screens/revision_screen.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

Widget _ecran(RevisionPlan plan, {VoidCallback? onStart}) {
  return RelioPaletteScope(
    palette: RelioPalette.standard(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RelioTheme.build(),
      home: RevisionScreen(plan: plan, onStart: onStart ?? () {}),
    ),
  );
}

LearningEvent _erreur(String lessonId) {
  final DateTime at = DateTime(2026, 9, 15);
  return LearningEvent(
    id: 'event-$lessonId',
    type: kLearnerAttemptEventType,
    occurredAt: at,
    metadata: <String, Object?>{'lessonId': lessonId},
    attempt: ExerciseAttempt(
      exerciseId: 'ex',
      startedAt: at,
      outcome: AnswerOutcome.incorrect,
      error: ObservedError(id: 'err', occurredAt: at, errorType: 'test'),
    ),
  );
}

RevisionPlan _plan({bool withWeakness = true}) {
  return const RevisionPlanBuilder().build(
    date: DateTime(2026, 10, 22),
    events: withWeakness
        ? <LearningEvent>[
            _erreur(ArithmeticLesson.lesson1Subtractions.id),
            _erreur(ArithmeticLesson.lesson1Subtractions.id),
          ]
        : const <LearningEvent>[],
  );
}

void main() {
  testWidgets('affiche l’objectif et la consigne', (WidgetTester tester) async {
    await tester.pumpWidget(_ecran(_plan()));

    expect(
      find.text('Objectif : Séquence 2 (Octobre - Novembre)'),
      findsOneWidget,
    );
    expect(find.text(RelioStrings.revisionSubtitle), findsOneWidget);
  });

  testWidgets('affiche les chapitres de la séquence en cours', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_ecran(_plan()));

    expect(find.text(RelioStrings.revisionProgramSection), findsOneWidget);
    expect(find.text('Nombres réels (suite)'), findsOneWidget);
    expect(find.text('Trigonométrie'), findsOneWidget);
    // Les chapitres de la séquence 1 ne sont pas le programme actuel.
    expect(find.text('Théorème de Thalès'), findsNothing);
  });

  testWidgets('affiche les points faibles et le nombre d’erreurs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_ecran(_plan()));

    expect(find.text(RelioStrings.revisionWeakSection), findsOneWidget);
    expect(
      find.text(ArithmeticLesson.lesson1Subtractions.title),
      findsOneWidget,
    );
    expect(find.text(RelioStrings.revisionErrorCount(2)), findsOneWidget);
  });

  testWidgets('sans erreur, affiche un message neutre', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_ecran(_plan(withWeakness: false)));

    expect(find.text(RelioStrings.revisionNoWeakness), findsOneWidget);
    expect(
      find.text(ArithmeticLesson.lesson1Subtractions.title),
      findsNothing,
    );
  });

  testWidgets('signale le vivier de secours quand les sections sont vides', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_ecran(_plan(withWeakness: false)));

    expect(find.text(RelioStrings.revisionFallbackNote), findsOneWidget);
  });

  testWidgets('le bouton lance la préparation', (WidgetTester tester) async {
    int starts = 0;
    await tester.pumpWidget(_ecran(_plan(), onStart: () => starts++));

    await tester.ensureVisible(find.text(RelioStrings.revisionStart));
    await tester.tap(find.text(RelioStrings.revisionStart));
    await tester.pump();

    expect(starts, 1);
  });

  testWidgets('le bouton est désactivé sans exercice', (
    WidgetTester tester,
  ) async {
    final RevisionPlan plan = RevisionPlan(
      sequence: const RevisionPlanBuilder()
          .build(date: DateTime(2026, 10, 22), events: const <LearningEvent>[])
          .sequence,
      weaknesses: const <RevisionWeakness>[],
      currentExercises: const <Exercise>[],
      weakExercises: const <Exercise>[],
      fallbackExercises: const <Exercise>[],
    );

    await tester.pumpWidget(_ecran(plan));

    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, RelioStrings.revisionStart),
    );
    expect(button.onPressed, isNull);
    // Le bouton est visible : c'est son action qui manque, pas sa place.
    expect(find.text(RelioStrings.revisionStart), findsOneWidget);
  });

  test('la banque fournit bien des exercices au vivier de secours', () {
    // Garde-fou : le test « bouton désactivé » ci-dessus décrit un cas qui ne
    // peut pas arriver avec la banque actuelle.
    expect(
      Chapter1Bank.exercises.where(
        (exercise) => exercise.kind == BankElementKind.exercise,
      ),
      isNotEmpty,
    );
  });
}
