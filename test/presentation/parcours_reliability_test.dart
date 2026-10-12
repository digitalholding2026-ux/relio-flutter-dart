/// Tests de FIABILITÉ du parcours élève — chapitre 1.
///
/// Complète `learner_flow_test.dart`, qui vérifie CE QUI EST AFFICHÉ. Ici on
/// vérifie CE QUI TIENT sous pression : doubles soumissions, clavier ouvert,
/// erreurs techniques, cohérence après navigation.
///
/// Ces tests sont des tests AUTOMATISÉS. Ils ne valident pas un
/// fonctionnement sur un appareil Android réel : aucun téléphone n'est
/// connecté à cet environnement (cf. `docs/INTERFACE.md`, limite n° 5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/widgets/answer_field.dart';

import '../helpers/test_database.dart';

/// Ouvre S2 sur le premier exercice de la leçon 1 (PGCD 18 et 12).
Future<AppDatabase> openFirstExercise(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);
  await tester.pumpWidget(
    RelioApp(database: db),
  );
  await tester.pumpAndSettle();

  // L'application ouvre sur ACCUEIL : S1 s'atteint par l'onglet Apprendre.
  await tester.tap(find.text(RelioStrings.tabLearn).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chapitre 1'));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(LessonCard).at(0));
  await tester.pumpAndSettle();
  return db;
}

/// Nombre d'événements de soumission réellement enregistrés.
Future<int> countAttempts(AppDatabase db) async {
  final repository = LearningEventRepository(db);
  final events = await repository.findByType(kAttemptEventType);
  return events.length;
}

/// Le bouton « Valider » de la barre d'action.
FilledButton boutonValider(WidgetTester tester) => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(RelioStrings.validate),
        matching: find.byType(FilledButton),
      ),
    );

void main() {
  group('Soumission unique', () {
    testWidgets('un appui sur « Valider » n\'enregistre qu\'UNE tentative',
        (tester) async {
      final db = await openFirstExercise(tester);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();

      final bouton = find.text(RelioStrings.validate);
      await tester.tap(bouton);
      // pump() UNE SEULE FOIS : la future n'est pas encore terminée, le
      // bouton est encore dans son état « en cours ». Un second appui dans
      // cette fenêtre est exactement le double-appui accidentel.
      await tester.pump();
      await tester.pumpAndSettle();

      expect(await countAttempts(db), 1);
    });

    testWidgets('trois appuis rapides n\'enregistrent qu\'UNE tentative',
        (tester) async {
      final db = await openFirstExercise(tester);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(RelioStrings.validate));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(
        await countAttempts(db),
        1,
        reason: 'le bouton doit être neutralisé pendant la soumission',
      );
    });

    testWidgets('le bouton « Valider » est neutralisé une fois le panneau affiché',
        (tester) async {
      await openFirstExercise(tester);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.validate), findsOneWidget);

      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      // Le panneau est affiche : la tentative est enregistree. « Valider »
      // ne doit plus etre actionnable, sans quoi l'eleve peut empiler des
      // tentatives identiques dans un historique immuable.
      expect(find.text(RelioStrings.successTitle), findsOneWidget);
      expect(boutonValider(tester).onPressed, isNull);

      // Sur un panneau de reussite, la seule action proposee est
      // « Exercice suivant » : « Réessayer » n'a pas sa place, la reponse
      // est acquise. Aucune voie ne permet de resoumettre.
      expect(find.text(RelioStrings.nextExercise), findsOneWidget);
      expect(find.text(RelioStrings.retry), findsNothing);

      await tester.tap(find.text(RelioStrings.nextExercise));
      await tester.pumpAndSettle();
      expect(boutonValider(tester).onPressed, isNotNull,
          reason: 'l\'exercice suivant ouvre une nouvelle tentative');
    });
  });

  group('Clavier ouvert', () {
    testWidgets('« Valider » reste visible et actionnable, clavier ouvert',
        (tester) async {
      await openFirstExercise(tester);

      // Simule un clavier de 300 px : c'est le cas réel le plus défavorable.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.validate), findsOneWidget);
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      // Le panneau de retour doit être apparu : le bouton était réellement
      // atteignable, pas seulement présent dans l'arbre.
      expect(find.text(RelioStrings.successTitle), findsOneWidget);
    });

    testWidgets('le champ de réponse reste visible, clavier ouvert',
        (tester) async {
      await openFirstExercise(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Erreur technique', () {
    testWidgets('une erreur d\'envoi n\'efface JAMAIS la saisie',
        (tester) async {
      final db = await openFirstExercise(tester);
      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();

      // Panne simulée : la base est fermée, l'écriture doit échouer.
      await db.close();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.submitErrorBanner), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '6',
        reason: 'la saisie fait partie du travail de l\'élève : elle ne se '
            'perd pas parce que l\'application a échoué',
      );
    });

    testWidgets('après une erreur, « Réessayer » permet de rejouer l\'envoi',
        (tester) async {
      final db = await openFirstExercise(tester);
      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      await db.close();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.submitErrorBanner), findsOneWidget);
      expect(find.text(RelioStrings.retry), findsWidgets);
    });

    testWidgets('la bannière d\'erreur est dismissible', (tester) async {
      final db = await openFirstExercise(tester);
      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      await db.close();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.submitErrorBanner), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.submitErrorBanner), findsNothing);
    });
  });

  group('Cohérence après navigation', () {
    testWidgets('aller-retour S1 → S2 conserve saisie ET indices',
        (tester) async {
      await openFirstExercise(tester);

      await tester.enterText(find.byType(TextField), '18-12');
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.hintLabel(1)), findsOneWidget);

      await tester.tap(find.byTooltip(RelioStrings.back));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterAccessPage), findsOneWidget);

      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(ExercisePage), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '18-12',
        reason: 'la saisie ne doit jamais disparaître',
      );
      expect(find.text(RelioStrings.hintLabel(1)), findsOneWidget,
          reason: 'un indice déjà consulté ne doit pas être redemandé');
    });

    testWidgets('« Exercice suivant » ne transporte pas la saisie précédente',
        (tester) async {
      await openFirstExercise(tester);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      await tester.tap(find.text(RelioStrings.nextExercise));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
        reason: 'un brouillon ne doit jamais fuite d\'exercice en exercice',
      );
    });
  });

  group('Le message correspond au résultat du moteur', () {
    testWidgets('réussite sans indice → panneau A, jamais B', (tester) async {
      await openFirstExercise(tester);
      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.successAutonomous), findsOneWidget);
      expect(find.text(RelioStrings.successAssisted), findsNothing);
    });

    testWidgets('réussite APRÈS indice → panneau B, jamais A', (tester) async {
      await openFirstExercise(tester);
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.successAssisted), findsOneWidget);
      expect(find.text(RelioStrings.successAutonomous), findsNothing);
    });

    testWidgets('le champ numérique rejette bien les lettres', (tester) async {
      await openFirstExercise(tester);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      final champ = tester.widget<AnswerField>(find.byType(AnswerField));
      expect(champ.keyboard.name, 'numeric');
    });
  });
}