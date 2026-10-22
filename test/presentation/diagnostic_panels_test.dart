/// Panneaux C et D dans S2, et pont d'erreur du tuteur.
///
/// Les tests partent d'un ExercisePage reel, avec la vraie base de test :
/// aucun panneau n'est fabrique a la main. Ils verifient aussi qu'aucun code
/// D1…D8 ne fuit dans l'interface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/tutor/tutor_client.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';
import 'package:relio/domain/tutor/tutor_message.dart';
import 'package:relio/presentation/rules/feedback_selection.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/feedback_panel.dart';

import '../helpers/test_database.dart';

class _SignalTutor implements TutorClient {
  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) async {
    return 'Tu as fait une soustraction à l’envers. '
        '[[relio-erreur:soustraction_fausse]]';
  }

  @override
  void close() {}
}

Future<Chapter1Service> _pumpExercise(
  WidgetTester tester,
  String exerciseId, {
  TutorClient? tutor,
}) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);
  final service = Chapter1Service(LearningEventRepository(db));
  final exercise = Chapter1Bank.findExercise(exerciseId)!;

  await tester.pumpWidget(
    MaterialApp(
      theme: RelioTheme.build(),
      home: ExercisePage(
        service: service,
        exercise: exercise,
        drafts: <String, ExerciseDraft>{},
        onExit: () {},
        onGoToNext: () {},
        tutor: tutor,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

Future<void> _submit(WidgetTester tester, String answer) async {
  await tester.enterText(find.byType(TextField).first, answer);
  await tester.pump();
  await tester.tap(find.text(RelioStrings.validate));
  await tester.pumpAndSettle();
}

FeedbackSelection _selection(WidgetTester tester) {
  return tester
      .widget<FeedbackPanelView>(find.byType(FeedbackPanelView))
      .selection;
}

void main() {
  group('Panneau C — intervention', () {
    testWidgets('une reponse mappee de l’exercice 1 ouvre C', (tester) async {
      await _pumpExercise(tester, ExerciseIds.ex1);
      await _submit(tester, '5');

      final selection = _selection(tester);
      expect(selection.panel, FeedbackPanel.intervention);
      expect(selection.showRetry, isTrue);
      expect(find.text(RelioStrings.retry), findsOneWidget);

      // L'intervention est celle de D1, jamais le panneau generique E.
      final question = Chapter1Bank.diagnosticCases
          .firstWhere((c) => c.id == 'D1')
          .intervention
          .question;
      expect(find.text(question), findsOneWidget);
      expect(find.textContaining('D1'), findsNothing);
    });

    testWidgets('un PPCM faux apres PGCD donne quitte E pour C', (
      tester,
    ) async {
      await _pumpExercise(tester, ExerciseIds.ex8);
      await _submit(tester, '0');

      final selection = _selection(tester);
      expect(selection.panel, FeedbackPanel.intervention);
      expect(selection.showRetry, isTrue);
      expect(find.text(RelioStrings.retry), findsOneWidget);
      expect(find.textContaining('D5'), findsNothing);
      expect(find.textContaining('D6'), findsNothing);

      // Carte blanche, liseré orange à gauche.
      final accent = find.descendant(
        of: find.byType(FeedbackPanelView),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color == RelioPalette.standard().brand,
        ),
      );
      expect(accent, findsOneWidget);

      // Le message affiche est celui de l'intervention validee, pas un
      // texte invente par l'ecran.
      final question = Chapter1Bank.diagnosticCases
          .firstWhere((c) => c.id == 'D5')
          .intervention
          .question;
      expect(find.text(question), findsOneWidget);
    });
  });

  group('Panneau D — clarification', () {
    testWidgets('le PGCD repondu au lieu du PPCM ouvre D', (tester) async {
      await _pumpExercise(tester, ExerciseIds.ex9);
      await _submit(tester, '4');

      final selection = _selection(tester);
      expect(selection.panel, FeedbackPanel.clarification);
      expect(selection.message, isNotEmpty);
      expect(find.text(RelioStrings.clarificationTitle), findsOneWidget);
      for (final option in RelioStrings.clarificationOptions) {
        expect(find.text(option), findsOneWidget);
      }

      // Le bouton est inactif tant qu'aucune option n'est choisie.
      final bouton = find.widgetWithText(
        FilledButton,
        RelioStrings.clarificationSubmit,
      );
      expect(tester.widget<FilledButton>(bouton).onPressed, isNull);

      await tester.ensureVisible(find.text('Oui'));
      await tester.tap(find.text('Oui'));
      await tester.pump();

      expect(tester.widget<FilledButton>(bouton).onPressed, isNotNull);

      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      // La clarification ferme la question : l'interface revient a C.
      final apres = _selection(tester);
      expect(apres.panel, FeedbackPanel.intervention);
      expect(find.text(RelioStrings.clarificationSubmit), findsNothing);
      expect(find.text(RelioStrings.retry), findsOneWidget);
      expect(find.textContaining('D5'), findsNothing);
      expect(find.textContaining('D6'), findsNothing);
    });
  });

  group('Pont tuteur', () {
    testWidgets(
      'un marqueur valide declenche le diagnostic, sans etre affiche',
      (tester) async {
        await _pumpExercise(tester, ExerciseIds.ex2, tutor: _SignalTutor());

        await tester.tap(find.text(RelioStrings.askRelio));
        await tester.pumpAndSettle();

        final sheetField = find.byType(TextField).last;
        await tester.enterText(sheetField, 'Je crois que je me suis trompé.');
        await tester.pump();
        await tester.tap(find.byTooltip(RelioStrings.tutorSend));
        await tester.pumpAndSettle();

        // Le marqueur ne doit jamais apparaitre dans la conversation.
        expect(find.textContaining('relio-erreur'), findsNothing);

        // Fermer la feuille : le panneau est deja pose derriere.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        final selection = _selection(tester);
        expect(selection.panel, FeedbackPanel.intervention);

        final question = Chapter1Bank.diagnosticCases
            .firstWhere((c) => c.id == 'D1')
            .intervention
            .question;
        expect(find.text(question), findsOneWidget);
        expect(find.textContaining('D1'), findsNothing);
      },
    );
  });
}
