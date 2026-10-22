/// Synchronisation de l'avancement entre S2 et S1 empiles.
///
/// Le scenario est celui de l'eleve qui enchaîne deux exercices : S1 reste
/// sous S2, et sa carte de lecon doit refleter chaque reussite sans qu'il
/// ait a revenir en arriere.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

Future<void> _ouvrirLecon1(WidgetTester tester) async {
  await tester.pumpWidget(
    RelioApp(database: await openTestDatabase(), showIntro: false),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text(RelioStrings.tabLearn).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(RelioStrings.chapter1CardTitle));
  await tester.pumpAndSettle();

  expect(_progressionLecon1(0), findsOneWidget);

  await tester.tap(find.byType(LessonCard).at(0));
  await tester.pumpAndSettle();
}

/// Le decompte de la PREMIERE carte de lecon, meme quand S1 est sous S2.
Finder _progressionLecon1(int completed) {
  return find.descendant(
    of: find.byType(LessonCard, skipOffstage: false).at(0),
    matching: find.text(
      RelioStrings.lessonExerciseProgress(completed, 4),
      skipOffstage: false,
    ),
  );
}

Future<void> _repondre(WidgetTester tester, String reponse) async {
  await tester.enterText(find.byType(TextField), reponse);
  await tester.pump();
  await tester.tap(find.text(RelioStrings.validate));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('S1 passe de 0/4 a 1/4 puis 2/4 pendant le chaînage', (
    tester,
  ) async {
    await _ouvrirLecon1(tester);

    // Exercice 1 : reussite, puis « Exercice suivant ».
    await _repondre(tester, '6');
    expect(find.text(RelioStrings.nextExercise), findsOneWidget);

    // S1 est sous S2 : on la lit sans la quitter.
    expect(
      _progressionLecon1(1),
      findsOneWidget,
      reason: 'la réussite doit être visible dans S1 dès l’enregistrement',
    );

    await tester.tap(find.text(RelioStrings.nextExercise));
    await tester.pumpAndSettle();

    // Exercice 2 : reussite. S1 doit deja compter 2.
    await _repondre(tester, '5');
    expect(_progressionLecon1(2), findsOneWidget);
  });
}
