/// Conversation branchée sur le modèle : réponse, attente, échec, reprise.
///
/// Les clients sont des faux : aucun appel réseau.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/tutor/mock_tutor_client.dart';
import 'package:relio/domain/tutor/tutor_client.dart';
import 'package:relio/domain/tutor/tutor_exercise_context.dart';
import 'package:relio/domain/tutor/tutor_message.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/widgets/relio_tutor_sheet.dart';

const TutorExerciseContext _exercise = TutorExerciseContext(
  statement: 'Calcule le PGCD de 18 et 12.',
  expectedAnswer: 'Valeurs acceptées : 6.',
);

/// Client qui répond immédiatement et garde trace de l'appel.
class _FakeTutorClient implements TutorClient {
  _FakeTutorClient();

  final String replyText = 'Et si tu commençais par les diviseurs ?';

  TutorExerciseContext? lastExercise;
  List<TutorMessage>? lastHistory;
  int calls = 0;

  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) async {
    calls++;
    lastExercise = exercise;
    lastHistory = history;
    return replyText;
  }

  @override
  void close() {}
}

/// Client dont la réponse est libérée par le test : l'attente est observable.
class _DelayedTutorClient implements TutorClient {
  final Completer<String> completer = Completer<String>();

  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) {
    return completer.future;
  }

  @override
  void close() {}
}

/// Client qui échoue au premier appel, puis répond.
///
/// Reproduit une panne passagère (réseau instable) : le bouton « Réessayer »
/// doit ramener une réponse sans que l'élève réécrive sa question.
class _FlakyTutorClient implements TutorClient {
  int calls = 0;

  @override
  Future<String> reply({
    required TutorExerciseContext exercise,
    required List<TutorMessage> history,
  }) async {
    calls++;
    if (calls == 1) {
      throw const TutorException(TutorFailure.network);
    }
    return 'Reprenons : quel est le diviseur commun ?';
  }

  @override
  void close() {}
}

/// Affiche le panneau seul, à la taille d'un téléphone.
Future<void> _pumpSheet(WidgetTester tester, TutorClient client) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RelioTutorSheet(client: client, exercise: _exercise),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(RelioTutorSheet),
      matching: find.byType(TextField),
    ),
    text,
  );
  await tester.pump();
  await tester.tap(find.byIcon(Icons.send_rounded));
}

void main() {
  group('Tuteur — réponse du modèle', () {
    testWidgets('affiche la réponse reçue et transmet l’exercice', (
      tester,
    ) async {
      final client = _FakeTutorClient();
      await _pumpSheet(tester, client);

      await _send(tester, 'Je bloque sur le PGCD.');
      await tester.pumpAndSettle();

      expect(client.calls, 1);
      expect(client.lastExercise?.statement, 'Calcule le PGCD de 18 et 12.');
      expect(client.lastExercise?.expectedAnswer, 'Valeurs acceptées : 6.');
      expect(client.lastHistory?.last.text, 'Je bloque sur le PGCD.');
      expect(client.lastHistory?.last.fromRelio, isFalse);

      expect(
        find.text('Et si tu commençais par les diviseurs ?'),
        findsOneWidget,
      );
      expect(find.text(RelioStrings.tutorThinking), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche l’attente pendant l’appel, puis la réponse', (
      tester,
    ) async {
      final client = _DelayedTutorClient();
      await _pumpSheet(tester, client);

      await _send(tester, 'Une question.');
      await tester.pump();

      // L'élève voit que Relio travaille : ni champ bloqué sans explication,
      // ni second envoi possible.
      expect(find.text(RelioStrings.tutorThinking), findsOneWidget);
      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send_rounded),
      );
      expect(sendButton.onPressed, isNull);

      client.completer.complete('Regarde le premier diviseur.');
      await tester.pumpAndSettle();

      expect(find.text('Regarde le premier diviseur.'), findsOneWidget);
      expect(find.text(RelioStrings.tutorThinking), findsNothing);
    });
  });

  group('Tuteur — échec et reprise', () {
    testWidgets('un échec du modèle propose de réessayer', (tester) async {
      await _pumpSheet(tester, const UnavailableTutorClient());

      await _send(tester, 'Je bloque.');
      await tester.pumpAndSettle();

      expect(find.text('Je bloque.'), findsOneWidget);
      expect(find.text(RelioStrings.tutorBusyReply), findsOneWidget);
      expect(find.text(RelioStrings.tutorRetry), findsOneWidget);
      expect(find.text(RelioStrings.tutorThinking), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Réessayer » relance l’appel sans réécrire la question', (
      tester,
    ) async {
      final client = _FlakyTutorClient();
      await _pumpSheet(tester, client);

      await _send(tester, 'Je bloque.');
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.tutorBusyReply), findsOneWidget);

      await tester.tap(find.text(RelioStrings.tutorRetry));
      await tester.pumpAndSettle();

      expect(client.calls, 2);
      // La question n'est pas dupliquée : elle était déjà dans le fil.
      expect(find.text('Je bloque.'), findsOneWidget);
      expect(find.text('Reprenons : quel est le diviseur commun ?'),
          findsOneWidget);
      expect(find.text(RelioStrings.tutorBusyReply), findsNothing);
    });
  });

  group('Tuteur — mode simulé', () {
    testWidgets('sans clé, le tuteur simulé répond sans réseau', (tester) async {
      await _pumpSheet(tester, const MockTutorClient());

      await _send(tester, 'Je bloque sur le PGCD.');
      await tester.pump();

      // L'attente est réelle : elle est visible pendant la latence simulée.
      expect(find.text(RelioStrings.tutorThinking), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text(kMockTutorReply), findsOneWidget);
      expect(find.text(RelioStrings.tutorThinking), findsNothing);
      expect(find.text(RelioStrings.tutorRetry), findsNothing);
    });
  });
}
