/// Tests de la salutation selon l'heure.
///
/// La règle est volontairement simple et figée : « Bonjour » de 05h00 à 17h59,
/// « Bonsoir » de 18h00 à 04h59. L'heure vient de l'appareil ; les tests
/// injectent une date pour ne pas dépendre du moment où ils s'exécutent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

Widget _header(DateTime Function() now, {String name = 'Camille'}) {
  return RelioPaletteScope(
    palette: RelioPalette.standard(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RelioTheme.build(),
      home: Scaffold(body: GreetingHeader(name: name, now: now)),
    ),
  );
}

void main() {
  group('salutation', () {
    test('« Bonjour » de 05h00 à 17h59', () {
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 5, 0)),
        'Bonjour',
      );
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 12, 30)),
        'Bonjour',
      );
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 17, 59)),
        'Bonjour',
      );
    });

    test('« Bonsoir » de 18h00 à 04h59', () {
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 18, 0)),
        'Bonsoir',
      );
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 21, 0)),
        'Bonsoir',
      );
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 0, 0)),
        'Bonsoir',
      );
      expect(
        RelioStrings.greetingFor(DateTime(2026, 11, 22, 4, 59)),
        'Bonsoir',
      );
    });
  });

  group('message de Relio', () {
    test('le matin, il salue et propose d’avancer', () {
      final String message = RelioStrings.relioSeasonMessage(
        DateTime(2026, 11, 22, 10),
        2,
      );

      expect(message, startsWith('Bonjour'));
      expect(message, contains('Nous sommes en Novembre'));
      expect(message, contains('tu prépares la Séquence 2'));
      expect(message, contains('Prêt à avancer'));
      expect(message, isNot(contains('ce soir')));
    });

    test('le soir, il salue et propose une session du soir', () {
      final String message = RelioStrings.relioSeasonMessage(
        DateTime(2026, 11, 22, 21),
        2,
      );

      expect(message, startsWith('Bonsoir'));
      expect(message, contains('Nous sommes en Novembre'));
      expect(message, contains('tu prépares la Séquence 2'));
      expect(message, contains('Prêt pour une petite session ce soir'));
      expect(message, isNot(contains('Prêt à avancer')));
    });
  });

  group('en-tête', () {
    testWidgets('affiche « Bonjour » à 10h', (tester) async {
      await tester.pumpWidget(_header(() => DateTime(2026, 11, 22, 10)));

      expect(find.text('Bonjour Camille'), findsOneWidget);
    });

    testWidgets('affiche « Bonsoir » à 21h', (tester) async {
      await tester.pumpWidget(_header(() => DateTime(2026, 11, 22, 21)));

      expect(find.text('Bonsoir Camille'), findsOneWidget);
    });

    testWidgets('sans prénom, la salutation reste seule', (tester) async {
      await tester.pumpWidget(
        _header(() => DateTime(2026, 11, 22, 21), name: '  '),
      );

      expect(find.text('Bonsoir'), findsOneWidget);
      expect(find.text('Bonsoir '), findsNothing);
    });

    testWidgets('bascule à 18h00 sans quitter l’écran', (tester) async {
      DateTime now = DateTime(2026, 11, 22, 17, 59);

      await tester.pumpWidget(_header(() => now));
      expect(find.text('Bonjour Camille'), findsOneWidget);

      now = DateTime(2026, 11, 22, 18, 0);
      await tester.pump(const Duration(minutes: 1));

      expect(find.text('Bonsoir Camille'), findsOneWidget);
    });
  });
}
