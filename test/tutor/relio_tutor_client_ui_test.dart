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
import 'package:relio/presentation/widgets/fraction_span.dart';
import 'package:relio/presentation/widgets/math_text.dart';
import 'package:relio/presentation/widgets/relio_tutor_sheet.dart';

const TutorExerciseContext _exercise = TutorExerciseContext(
  statement: 'Calcule le PGCD de 18 et 12.',
  expectedAnswer: 'Valeurs acceptées : 6.',
);

/// Client qui répond immédiatement et garde trace de l'appel.
class _FakeTutorClient implements TutorClient {
  _FakeTutorClient([
    this.replyText = 'Et si tu commençais par les diviseurs ?',
  ]);

  final String replyText;

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

/// Un fragment du texte est-il peint en rouge ?
bool _aDuRouge(InlineSpan span) {
  if (span is TextSpan) {
    if (span.style?.color == kHighlightRed) return true;
    for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
      if (_aDuRouge(child)) return true;
    }
  }
  return false;
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

  group('Tuteur — nettoyage des réponses', () {
    testWidgets('les balises LaTeX ne sont jamais affichées', (tester) async {
      final client = _FakeTutorClient(r'\(18 - 12 = 6\). Tu suis ?');
      await _pumpSheet(tester, client);

      await _send(tester, 'Je ne comprends pas.');
      await tester.pumpAndSettle();

      // Le texte est lisible : délimiteurs retirés, signe moins typographique.
      expect(find.text('18 − 12 = 6. Tu suis ?'), findsOneWidget);
      expect(find.textContaining(r'\('), findsNothing);
      expect(find.textContaining(r'\)'), findsNothing);
    });

    testWidgets('les opérateurs ASCII deviennent des glyphes, les fractions s’empilent',
        (tester) async {
      final client = _FakeTutorClient('Fais 8/2 puis 2*3.');
      await _pumpSheet(tester, client);

      await _send(tester, 'Comment ?');
      await tester.pumpAndSettle();

      // 8/2 est une FRACTION : elle est empilée, pas convertie en division.
      expect(find.byType(FractionSpan), findsOneWidget);
      expect(find.textContaining('puis 2×3.'), findsOneWidget);
      expect(find.textContaining('÷'), findsNothing);
    });

    testWidgets('le message de l’élève reste exactement le sien', (tester) async {
      final client = _FakeTutorClient();
      await _pumpSheet(tester, client);

      await _send(tester, 'J’ai trouvé 8/2.');
      await tester.pumpAndSettle();

      // Aucune réécriture du texte de l'élève, même sur un opérateur.
      expect(find.text('J’ai trouvé 8/2.'), findsOneWidget);
    });

    testWidgets('la mise en évidence du modèle est rendue en rouge',
        (tester) async {
      final client = _FakeTutorClient(
        'Multiplie par <red>4</red> : 2/3 devient 8/12.',
      );
      await _pumpSheet(tester, client);

      await _send(tester, 'Comment ?');
      await tester.pumpAndSettle();

      final RichText bulle = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((r) => r.text.toPlainText().contains('Multiplie'));

      // Les balises sont consommées, le contenu reste.
      expect(bulle.text.toPlainText(), contains('Multiplie par 4'));
      expect(bulle.text.toPlainText(), isNot(contains('<red>')));
      expect(_aDuRouge(bulle.text), isTrue);

      // Et les fractions du modèle s'empilent.
      expect(find.byType(FractionSpan), findsNWidgets(2));
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
