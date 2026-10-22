/// Navigation Accueil → Révision → préparation.
///
/// L'écran Révision doit être accessible depuis la carte de l'accueil, et son
/// bouton doit ouvrir une session rapide de trois exercices — sans passer par
/// S1 ni par un écran intermédiaire.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/screens/revision_screen.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

Future<void> _pumpAccueil(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);

  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(RelioApp(database: db, showIntro: false));
  await tester.pumpAndSettle();
}

Future<void> _ouvrirRevision(WidgetTester tester) async {
  final Finder carte = find.text(RelioStrings.revisionCardTitle);

  await tester.ensureVisible(carte);
  await tester.tap(carte);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la carte de l’accueil ouvre l’écran Révision', (tester) async {
    await _pumpAccueil(tester);

    expect(find.byType(RevisionScreen), findsNothing);

    await _ouvrirRevision(tester);

    expect(find.byType(RevisionScreen), findsOneWidget);
    expect(find.text(RelioStrings.revisionScreenTitle), findsOneWidget);
    expect(find.text(RelioStrings.revisionProgramSection), findsOneWidget);
    expect(find.text(RelioStrings.revisionWeakSection), findsOneWidget);
  });

  testWidgets('le retour ramène à l’accueil', (tester) async {
    await _pumpAccueil(tester);
    await _ouvrirRevision(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(RevisionScreen), findsNothing);
  });

  testWidgets('« Lancer ma préparation » ouvre une session de 3 exercices', (
    tester,
  ) async {
    await _pumpAccueil(tester);
    await _ouvrirRevision(tester);

    final Finder bouton = find.text(RelioStrings.revisionStart);
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    expect(find.byType(ExercisePage), findsOneWidget);
    expect(
      find.text(RelioStrings.quickSessionProgress(1, 3)),
      findsOneWidget,
    );
    // La préparation a remplacé l'écran Révision : le retour ramène à
    // l'accueil, pas à une page de réglage déjà consommée.
    expect(find.byType(RevisionScreen), findsNothing);
  });

  testWidgets('le message de Relio situe l’élève dans l’année', (tester) async {
    await _pumpAccueil(tester);

    // Même sans historique, la bulle donne le mois et la séquence du jour.
    expect(
      find.textContaining('tu prépares la Séquence'),
      findsOneWidget,
    );
  });
}
