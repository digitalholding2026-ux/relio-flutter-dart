/// Fractions empilées — reconnaissance par le formateur et rendu du widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/widgets/fraction_span.dart';
import 'package:relio/presentation/widgets/math_text.dart';

void main() {
  group('formatMathText — fractions', () {
    test('reconnaît 1/2', () {
      final fragments = formatMathText('1/2');

      expect(fragments, hasLength(1));
      expect(fragments.single.isFraction, isTrue);
      expect(fragments.single.numerator, '1');
      expect(fragments.single.denominator, '2');
      // La notation source reste le texte du fragment.
      expect(fragments.single.text, '1/2');
    });

    test('reconnaît des nombres à plusieurs chiffres', () {
      final fragments = formatMathText('12/5');

      expect(fragments.single.isFraction, isTrue);
      expect(fragments.single.numerator, '12');
      expect(fragments.single.denominator, '5');
    });

    test('reconnaît une fraction au milieu d’une phrase', () {
      final fragments = formatMathText('La fraction 3/4 est plus grande.');
      final fractions = fragments.where((f) => f.isFraction).toList();

      expect(fractions, hasLength(1));
      expect(fractions.single.numerator, '3');
      expect(fractions.single.denominator, '4');
    });

    test('la concaténation rend toujours le texte d’origine', () {
      const texte = 'Quelle fraction est égale à 1/2 ? (2/4, 3/4)';
      expect(formatMathText(texte).map((f) => f.text).join(), texte);
    });

    test('deux fractions dans la même phrase', () {
      final fractions =
          formatMathText('1/2 et 3/4').where((f) => f.isFraction).toList();

      expect(fractions, hasLength(2));
      expect(fractions.first.numerator, '1');
      expect(fractions.last.denominator, '4');
    });

    test('une division écrite avec ÷ n’est jamais une fraction', () {
      final fragments = formatMathText('24 ÷ 6');

      expect(fragments.any((f) => f.isFraction), isFalse);
    });

    test('un slash entouré d’espaces reste du texte', () {
      final fragments = formatMathText('24 / 6');

      expect(fragments.any((f) => f.isFraction), isFalse);
    });

    test('une date n’est pas une fraction', () {
      final fragments = formatMathText('10/12/2026');

      expect(fragments.any((f) => f.isFraction), isFalse);
      expect(fragments.map((f) => f.text).join(), '10/12/2026');
    });

    test('les variables restent italiques autour d’une fraction', () {
      final fragments = formatMathText('x = 1/2');
      final italiques = fragments.where((f) => f.italic).toList();

      expect(italiques, hasLength(1));
      expect(italiques.single.text, 'x');
      expect(fragments.any((f) => f.isFraction), isTrue);
    });
  });

  group('FractionSpan — rendu', () {
    /// Monte une phrase contenant la fraction 12/5.
    Future<void> monter(WidgetTester tester, {double taille = 16}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathText(
                text: 'Une fraction 12/5 ici',
                style: TextStyle(
                  fontSize: taille,
                  color: const Color(0xFF0E1821),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder dansLaFraction(Finder motif) => find.descendant(
          of: find.byType(FractionSpan),
          matching: motif,
        );

    testWidgets('numérateur au-dessus, barre au milieu, dénominateur dessous',
        (tester) async {
      await monter(tester);

      expect(find.byType(FractionSpan), findsOneWidget);

      final Rect haut = tester.getRect(dansLaFraction(find.text('12')));
      final Rect bas = tester.getRect(dansLaFraction(find.text('5')));
      // `Container` comprend sa marge : la barre peinte est le `ColoredBox`.
      final Rect barre =
          tester.getRect(dansLaFraction(find.byType(ColoredBox)));

      expect(haut.bottom, lessThanOrEqualTo(barre.top));
      expect(barre.bottom, lessThanOrEqualTo(bas.top));

      // 2 dp de respiration de chaque côté de la barre.
      expect(barre.top - haut.bottom, closeTo(2, 0.5));
      expect(bas.top - barre.bottom, closeTo(2, 0.5));
      // Barre fine, jamais un trait épais.
      expect(barre.height, closeTo(FractionSpan.barThickness, 0.01));
    });

    testWidgets('la fraction est centrée horizontalement', (tester) async {
      await monter(tester);

      final Rect fraction = tester.getRect(find.byType(FractionSpan));
      final Rect haut = tester.getRect(dansLaFraction(find.text('12')));
      final Rect bas = tester.getRect(dansLaFraction(find.text('5')));

      expect(haut.center.dx, closeTo(fraction.center.dx, 0.5));
      expect(bas.center.dx, closeTo(fraction.center.dx, 0.5));
    });

    testWidgets('la barre a la couleur du texte', (tester) async {
      await monter(tester);

      final Container barre = tester.widget<Container>(
        dansLaFraction(find.byType(Container)),
      );
      expect(barre.color, const Color(0xFF0E1821));
    });

    testWidgets('la taille de police suit le texte environnant',
        (tester) async {
      await monter(tester, taille: 24);

      final Text haut = tester.widget<Text>(dansLaFraction(find.text('12')));
      final Text bas = tester.widget<Text>(dansLaFraction(find.text('5')));

      expect(haut.style?.fontSize, 24);
      expect(bas.style?.fontSize, 24);
    });

    testWidgets('la ligne de base du texte voisin n’est pas décalée',
        (tester) async {
      await monter(tester);

      // Le formateur a bien laissé le texte autour de la fraction.
      expect(find.textContaining('Une fraction'), findsOneWidget);
      expect(find.textContaining('ici'), findsOneWidget);

      // Le milieu de la fraction coïncide avec le milieu de la ligne : le
      // texte n'est ni remonté ni descendu.
      final Rect ligne = tester.getRect(find.byType(MathText));
      final Rect fraction = tester.getRect(find.byType(FractionSpan));
      expect(fraction.center.dy, closeTo(ligne.center.dy, 1.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('la fraction ne déborde jamais de sa ligne', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              child: MathText(
                text: '1/2 et 3/4 dans un espace étroit',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
