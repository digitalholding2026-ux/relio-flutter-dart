/// Tests du tuteur Relio — panneau de conversation de S2.
///
/// Ce que ces tests protègent :
///  - le bouton secondaire existe, SOUS « Demander un indice » ;
///  - le panneau occupe 75 % de la hauteur, sans déborder sur petit écran ;
///  - la marque, le titre et le message d'accueil sont VISIBLES (pas seulement
///    présents dans l'arbre) ;
///  - l'envoi affiche la question de l'élève puis la réponse MOCK ;
///  - un envoi vide ne produit rien.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/presentation/branding/relio_mark.dart';
import 'package:relio/presentation/screens/app_shell_nav.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/widgets/relio_tutor_sheet.dart';

import '../helpers/test_database.dart';

/// Ouvre S2 sur un écran de téléphone (360 × 640).
Future<AppDatabase> pumpExercise(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = await openTestDatabase();
  registerTestDatabase(db);

  await tester.pumpWidget(RelioApp(database: db, showIntro: false));
  await tester.pumpAndSettle();

  await tester.tap(find.text(RelioTab.learn.label).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(RelioStrings.chapter1CardTitle));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(LessonCard).first);
  await tester.pumpAndSettle();

  expect(find.byType(ExercisePage), findsOneWidget);
  return db;
}

/// Ouvre la conversation depuis S2.
Future<void> openTutor(WidgetTester tester) async {
  await tester.tap(find.text(RelioStrings.askRelio));
  await tester.pumpAndSettle();
  expect(find.byType(RelioTutorSheet), findsOneWidget);
}

void main() {
  group('S2 — bouton du tuteur', () {
    testWidgets('le bouton est sous « Demander un indice »', (tester) async {
      await pumpExercise(tester);

      expect(find.text(RelioStrings.askHint), findsOneWidget);
      expect(find.text(RelioStrings.askRelio), findsOneWidget);

      final double indice = tester.getTopLeft(find.text(RelioStrings.askHint)).dy;
      final double relio = tester.getTopLeft(find.text(RelioStrings.askRelio)).dy;
      expect(relio, greaterThan(indice));

      // L'ajout du bouton ne fait pas déborder la barre d'action.
      expect(tester.takeException(), isNull);
    });
  });

  group('Tuteur — ouverture', () {
    testWidgets('le panneau occupe 75 % de la hauteur et montre la marque',
        (tester) async {
      await pumpExercise(tester);
      await openTutor(tester);

      expect(
        tester.getSize(find.byType(RelioTutorSheet)).height,
        closeTo(640 * kRelioTutorSheetHeightFactor, 0.5),
      );

      expect(find.byType(RelioMark), findsOneWidget);
      expect(find.text(RelioStrings.tutorTitle), findsOneWidget);

      // VISIBILITÉ : le message d'accueil est atteignable au doigt, pas
      // seulement présent dans l'arbre.
      expect(
        find.text(RelioStrings.tutorGreeting).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('la fermeture ramène à l’exercice', (tester) async {
      await pumpExercise(tester);
      await openTutor(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(RelioTutorSheet), findsNothing);
      expect(find.byType(ExercisePage), findsOneWidget);
    });
  });

  group('Tuteur — conversation', () {
    testWidgets('envoyer affiche la question puis la réponse MOCK',
        (tester) async {
      await pumpExercise(tester);
      await openTutor(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(RelioTutorSheet),
          matching: find.byType(TextField),
        ),
        'Je bloque sur le PGCD.',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Je bloque sur le PGCD.'), findsOneWidget);
      expect(find.text(RelioStrings.tutorMockReply), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un envoi vide ne produit aucun message', (tester) async {
      await pumpExercise(tester);
      await openTutor(tester);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.tutorMockReply), findsNothing);
      expect(find.text(RelioStrings.tutorGreeting), findsOneWidget);
    });

    testWidgets('le champ se vide après l’envoi', (tester) async {
      await pumpExercise(tester);
      await openTutor(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(RelioTutorSheet),
          matching: find.byType(TextField),
        ),
        'Une question.',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byType(RelioTutorSheet),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller?.text, isEmpty);
    });
  });
}
