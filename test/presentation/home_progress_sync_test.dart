/// Synchro entre la réussite d'un exercice (S2) et l'accueil (onglet 1).
///
/// Le parcours est joué en entier, sans raccourci : l'élève ouvre le chapitre,
/// réussit l'exercice 1, enchaîne sur l'exercice 2, revient, puis ouvre
/// l'accueil. C'est le seul contrôle qui prouve que l'accueil relit
/// l'historique au lieu de garder l'état du premier démarrage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

void main() {
  testWidgets(
      'réussir l’exercice 1 met l’accueil à jour : Continuer, Exercice 2 sur 4',
      (tester) async {
    final db = await openTestDatabase();
    registerTestDatabase(db);

    await tester.pumpWidget(
      RelioApp(
        database: db,
        showIntro: false,
        now: DateTime(2026, 9, 10, 10),
      ),
    );
    await tester.pumpAndSettle();

    // Départ : accueil d'un nouvel élève.
    expect(find.text(RelioStrings.startLabel), findsOneWidget);

    // Onglet Apprendre → chapitre → leçon 1 → exercice 1.
    await tester.tap(find.text(RelioStrings.tabLearn).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(RelioStrings.chapter1CardTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LessonCard).at(0));
    await tester.pumpAndSettle();

    final ex1 = Chapter1Bank.findExercise(ExerciseIds.ex1)!;
    expect(find.text(ex1.statement), findsOneWidget);

    // Réponse juste : « 6 » (PGCD de 18 et 12).
    await tester.enterText(find.byType(TextField), '6');
    await tester.pump();
    await tester.tap(find.text(RelioStrings.validate));
    await tester.pumpAndSettle();

    // S2 → S2 : l'exercice suivant affiche SON énoncé.
    await tester.tap(find.text(RelioStrings.nextExercise));
    await tester.pumpAndSettle();

    final ex2 = Chapter1Bank.findExercise(ExerciseIds.ex2)!;
    expect(find.text(ex2.statement), findsOneWidget);
    expect(find.text(ex1.statement), findsNothing);

    // Retour à S1, puis accueil : l'état doit avoir été relu.
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();
    expect(find.byType(ChapterAccessPage), findsOneWidget);

    await tester.tap(find.text(RelioStrings.tabHome).last);
    await tester.pumpAndSettle();

    expect(find.text(RelioStrings.startLabel), findsNothing);
    expect(find.text(RelioStrings.resumeLabel), findsOneWidget);
    expect(find.text(RelioStrings.resumeContinue), findsOneWidget);
    expect(find.text(RelioStrings.resumeProgress(2, 4)), findsOneWidget);
    expect(
      find.text(RelioStrings.relioMessageFirstExerciseDone),
      findsOneWidget,
    );
  });
}
