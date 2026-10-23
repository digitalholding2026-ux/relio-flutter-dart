/// Formateur avancé : fractions de variables, exposants, symboles.
///
/// Ces tests fixent le contrat du chapitre 2 : `AM/AB` s'empile comme une
/// fraction, `x^2` monte en exposant, et les symboles Unicode sont produits
/// par le nettoyage des réponses du tuteur.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter2_bank.dart';
import 'package:relio/domain/curriculum/rich_hint.dart';
import 'package:relio/presentation/widgets/fraction_span.dart';
import 'package:relio/presentation/widgets/math_text.dart';

void main() {
  group('Fractions de variables', () {
    test('reconnaît AM/AB', () {
      final fragments = formatMathText('AM/AB');

      expect(fragments, hasLength(1));
      expect(fragments.single.isFraction, isTrue);
      expect(fragments.single.numerator, 'AM');
      expect(fragments.single.denominator, 'AB');
      expect(fragments.single.text, 'AM/AB');
    });

    test('reconnaît un numérateur décimal et un dénominateur variable', () {
      final fragments = formatMathText('4,5/AC');
      final fraction = fragments.single;

      expect(fraction.isFraction, isTrue);
      expect(fraction.numerator, '4,5');
      expect(fraction.denominator, 'AC');
    });

    test('une égalité de trois fractions donne trois fractions', () {
      final fractions = formatMathText('AM/AB = AN/AC = MN/BC')
          .where((f) => f.isFraction)
          .toList();

      expect(fractions, hasLength(3));
      expect(fractions.map((f) => '${f.numerator}/${f.denominator}'), <String>[
        'AM/AB',
        'AN/AC',
        'MN/BC',
      ]);
    });

    test('les mots du dictionnaire ne deviennent pas des fractions', () {
      expect(formatMathText('et/ou').any((f) => f.isFraction), isFalse);
      expect(formatMathText('km/h').any((f) => f.isFraction), isFalse);
      expect(formatMathText('10/12/2026').any((f) => f.isFraction), isFalse);
    });

    test('les fractions numériques existantes continuent de fonctionner', () {
      final fragments = formatMathText('1/2');
      expect(fragments.single.isFraction, isTrue);
      expect(fragments.single.numerator, '1');
      expect(fragments.single.denominator, '2');
    });

    test('la concaténation rend toujours la source', () {
      const texte = 'AM/AB = AN/AC = MN/BC et 3/5 = 4,5/AC';
      expect(formatMathText(texte).map((f) => f.text).join(), texte);
    });

    test('les RichHints de Thalès portent bien des slashes', () {
      final maths = Chapter2Bank.exercises
          .expand((exercise) => exercise.richHints)
          .expand((hint) => hint.blocks)
          .whereType<MathBlock>();

      expect(maths, isNotEmpty);
      for (final block in maths) {
        if (!block.text.contains('/')) continue;
        expect(
          formatMathText(block.text).any((f) => f.isFraction),
          isTrue,
          reason: block.text,
        );
      }
    });
  });

  group('Variables et exposants', () {
    test('une variable majuscule est reconnue', () {
      final variables = formatMathText('M est sur [AB]')
          .where((f) => f.italic)
          .toList();

      expect(variables.map((f) => f.text), <String>['M', 'AB']);
    });

    test('un mot capitalisé n’est pas une variable', () {
      expect(
        formatMathText('Calcule la valeur').where((f) => f.italic),
        isEmpty,
      );
      expect(
        formatMathText('Vérifie le résultat').where((f) => f.italic),
        isEmpty,
      );
    });

    test('un code D1 n’est pas une variable', () {
      expect(formatMathText('code D1').where((f) => f.italic), isEmpty);
    });

    test('x^2 produit une variable et un exposant', () {
      final fragments = formatMathText('x^2');

      expect(fragments.map((f) => f.text).join(), 'x^2');
      expect(fragments.first.italic, isTrue);
      expect(fragments.first.text, 'x');
      expect(fragments.last.isSuperscript, isTrue);
      expect(fragments.last.exponent, '2');
    });

    test('4a^2 garde le coefficient et surélève le 2', () {
      final fragments = formatMathText('4a^2');

      expect(fragments.map((f) => f.text).join(), '4a^2');
      expect(fragments.where((f) => f.italic).single.text, 'a');
      expect(fragments.where((f) => f.isSuperscript).single.exponent, '2');
    });

    test('un exposant entre accolades est accepté', () {
      final exponent = formatMathText('x^{2}')
          .where((f) => f.isSuperscript)
          .single;

      expect(exponent.exponent, '2');
      expect(exponent.text, '^2');
    });

    testWidgets('la variable est rendue en serif italique', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText(text: 'x', style: TextStyle(fontSize: 16)),
          ),
        ),
      );

      final rich = tester.widget<RichText>(find.byType(RichText));
      // `Text.rich` enveloppe le TextSpan fourni dans un TextSpan de style :
      // le fragment variable est donc le premier enfant de cet enfant.
      final outer = (rich.text as TextSpan).children!.first as TextSpan;
      final span = outer.children!.first as TextSpan;

      expect(span.style?.fontStyle, FontStyle.italic);
      expect(span.style?.fontFamily, kMathVariableFontFamily);
    });

    testWidgets('un exposant est rendu plus petit que le texte', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText(text: 'x^2', style: TextStyle(fontSize: 20)),
          ),
        ),
      );

      final exponent = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((text) => text.data == '2');

      expect(exponent.style?.fontSize, closeTo(14, 0.01));
    });
  });

  group('Symboles Unicode', () {
    test('les comparaisons ASCII deviennent des symboles', () {
      expect(normalizeTutorText('a != b'), 'a ≠ b');
      expect(normalizeTutorText('a <> b'), 'a ≠ b');
      expect(normalizeTutorText('x <= 5'), 'x ≤ 5');
      expect(normalizeTutorText('x >= 5'), 'x ≥ 5');
    });

    test('Delta et emptyset sont substitués', () {
      expect(normalizeTutorText('Delta'), 'Δ');
      expect(normalizeTutorText(r'\Delta'), 'Δ');
      expect(normalizeTutorText('emptyset'), '∅');
      expect(normalizeTutorText(r'\emptyset'), '∅');
    });

    test('in isolé devient appartient, jamais au milieu d’un mot', () {
      expect(normalizeTutorText('x in A'), 'x ∈ A');
      expect(normalizeTutorText(r'x \in A'), 'x ∈ A');
      expect(normalizeTutorText('ainsi va la vie'), 'ainsi va la vie');
    });

    test('sqrt(x) devient une racine', () {
      expect(normalizeTutorText('sqrt(x)'), '√x');
      expect(normalizeTutorText('sqrt(2x+1)'), '√(2x+1)');
    });

    test('les fractions ne sont pas cassées par le nettoyage', () {
      expect(normalizeTutorText('AM/AB = 1/2'), 'AM/AB = 1/2');
    });
  });

  group('Rendu d’une égalité de fractions', () {
    testWidgets('trois fractions et deux signes égal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MathText(
                text: 'AM/AB = AN/AC = MN/BC',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FractionSpan), findsNWidgets(3));
      expect(find.text(' = '), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('l’égalité passe à la ligne sur un écran étroit', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: MathText(
                  text: 'AM/AB = AN/AC = MN/BC',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FractionSpan), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });
}
