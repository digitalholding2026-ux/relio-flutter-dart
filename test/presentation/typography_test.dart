/// Tests de finition visuelle : police embarquée et rendu d'énoncé.
///
/// Ces tests vérifient des PROPRIÉTÉS de configuration, pas un rendu réel :
/// aucune validation visuelle n'est possible sans appareil (cf.
/// `docs/INTERFACE.md`, limite n° 5).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/math_statement.dart';

void main() {
  group('Police Inter', () {
    test('le fichier de police est bien présent dans le dépôt', () {
      expect(
        File('assets/fonts/Inter-Regular.ttf').existsSync(),
        isTrue,
        reason: 'sans le fichier, Flutter bascule en silence sur la police '
            'du système : la conformité typographique serait fictive',
      );
    });

    test('la licence SIL OFL 1.1 accompagne la police', () {
      final licence = File('assets/fonts/Inter-OFL.txt');
      expect(licence.existsSync(), isTrue);
      expect(
        licence.readAsStringSync(),
        contains('SIL OPEN FONT LICENSE'),
      );
    });

    test('chaque graisse du thème déclare l\'axe wght', () {
      // Police VARIABLE : `fontWeight` seul ne produit pas la graisse, il
      // produit un faux gras simulé. Sans `fontVariations`, les titres
      // s'afficheraient tous en 400.
      final theme = RelioTheme.build();
      final styles = <TextStyle>[
        theme.textTheme.displaySmall!,
        theme.textTheme.titleLarge!,
        theme.textTheme.titleMedium!,
        theme.textTheme.bodyLarge!,
        theme.textTheme.bodyMedium!,
        theme.textTheme.labelMedium!,
      ];

      for (final style in styles) {
        expect(
          style.fontVariations,
          isNotNull,
          reason: 'fontSize ${style.fontSize} : wght manquant',
        );
      }

      expect(theme.textTheme.displaySmall!.fontVariations,
          RelioTheme.w700);
      expect(theme.textTheme.bodyMedium!.fontVariations, RelioTheme.w400);
    });

    test('le thème annonce bien la police Inter', () {
      expect(RelioTheme.fontFamily, 'Inter');
      expect(RelioTheme.build().textTheme.bodyMedium!.fontFamily, 'Inter');
    });
  });

  group('Rendu de l\'énoncé', () {
    Widget afficher(String statement) => MaterialApp(
          home: Scaffold(
            body: MathStatement(
              statement: statement,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );

    testWidgets('le texte de l\'énoncé est rendu INTÉGRALEMENT', (tester) async {
      const enonce =
          'Pour deux entiers positifs a = 8 et b = 12, on sait que leur '
          'PGCD vaut 4. Calcule leur PPCM.';

      await tester.pumpWidget(afficher(enonce));

      final rendu = tester.widget<RichText>(find.byType(RichText));
      final texte = rendu.text.toPlainText();
      expect(texte, enonce, reason: 'le découpage ne doit rien perdre');
    });

    testWidgets('une variable d\'affectation est mise en italique', (tester) async {
      await tester.pumpWidget(afficher('Pour a = 8 et b = 12, calcule.'));

      final spans = _spansItalicises(tester);
      expect(spans, containsAll(<String>['a', 'b']));
    });

    testWidgets('les sigles ne sont JAMAIS mis en italique', (tester) async {
      await tester.pumpWidget(
        afficher('On sait que PGCD(12,18) = 6 et PPCM(12,18) = 36.'),
      );

      final spans = _spansItalicises(tester);
      for (final span in spans) {
        expect(
          span.toUpperCase(),
          isNot(anyOf('PGCD', 'PPCM')),
          reason: 'un sigle n\'est pas une variable',
        );
      }
    });

    testWidgets('aucun texte n\'est perdu sur les 11 énoncés', (tester) async {
      for (final exercise in Chapter1Bank.exercises) {
        await tester.pumpWidget(afficher(exercise.statement));
        final rendu = tester.widget<RichText>(find.byType(RichText));
        expect(
          rendu.text.toPlainText(),
          exercise.statement,
          reason: exercise.id,
        );
      }
    });

    testWidgets('les symboles ÷ et × sont conservés tels quels', (tester) async {
      const enonce = '12 × 18 = 6 × PPCM(12,18), donc 216 ÷ 6 = 36.';

      await tester.pumpWidget(afficher(enonce));

      final texte = tester.widget<RichText>(find.byType(RichText)).text;
      expect(texte.toPlainText(), contains('×'));
      expect(texte.toPlainText(), contains('÷'));
    });
  });

  group('Aucun contenu pédagogique inventé', () {
    test('les 11 énoncés sont inchangés', () {
      // Le rendu ne doit avoir touché qu'au style, jamais au texte source.
      expect(
        Chapter1Bank.findExercise(ExerciseIds.ex1)!.statement,
        'Calcule le PGCD de 18 et 12 avec des soustractions successives.',
      );
      expect(
        Chapter1Bank.findExercise(ExerciseIds.ex11)!.statement,
        contains('Explique en une phrase.'),
      );
      expect(Chapter1Bank.exercises, hasLength(11));
    });
  });
}

/// Fragments rendus en italique.
List<String> _spansItalicises(WidgetTester tester) {
  final texte = tester.widget<RichText>(find.byType(RichText)).text;
  final resultats = <String>[];

  void visiter(InlineSpan span) {
    if (span is TextSpan) {
      if (span.style?.fontStyle == FontStyle.italic) {
        resultats.add(span.text ?? '');
      }
      for (final enfant in span.children ?? const <InlineSpan>[]) {
        visiter(enfant);
      }
    }
  }

  visiter(texte);
  return resultats;
}
