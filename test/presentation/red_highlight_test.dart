/// Mise en évidence `<red>...</red>` — formateur, rendu et contraste.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/fraction_span.dart';
import 'package:relio/presentation/widgets/math_text.dart';

/// Contraste WCAG entre deux couleurs opaques.
double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

/// Premier fragment de texte effectivement peint en rouge.
TextSpan? _spanRouge(InlineSpan span) {
  if (span is TextSpan) {
    if (span.style?.color == kHighlightRed &&
        (span.text?.isNotEmpty ?? false)) {
      return span;
    }
    for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
      final TextSpan? trouve = _spanRouge(child);
      if (trouve != null) return trouve;
    }
  }
  return null;
}

void main() {
  group('formatMathText — mise en évidence', () {
    test('retire les balises et marque le contenu', () {
      final fragments = formatMathText('On multiplie par <red>4</red>.');

      expect(fragments.map((f) => f.text).join(), 'On multiplie par 4.');
      final rouges = fragments.where((f) => f.highlighted).toList();
      expect(rouges, hasLength(1));
      expect(rouges.single.text, '4');
    });

    test('plusieurs passages rouges dans la même phrase', () {
      final rouges = formatMathText('(2 × <red>4</red>) / (5 × <red>4</red>)')
          .where((f) => f.highlighted)
          .map((f) => f.text)
          .toList();

      expect(rouges, <String>['4', '4']);
    });

    test('une fraction entièrement rouge', () {
      final fragments = formatMathText('La moitié : <red>1/2</red>.');
      final fractions = fragments.where((f) => f.isFraction).toList();

      expect(fractions, hasLength(1));
      expect(fractions.single.numerator, '1');
      expect(fractions.single.denominator, '2');
      expect(fractions.single.highlighted, isTrue);
      expect(fragments.where((f) => f.highlighted), hasLength(1));
    });

    test('le rouge encadre plusieurs fractions', () {
      final fragments = formatMathText('<red>1/2 + 1/4</red>');

      expect(fragments.where((f) => f.isFraction), hasLength(2));
      expect(fragments.every((f) => f.highlighted), isTrue);
    });

    test('une balise non fermée colore jusqu’à la fin', () {
      final fragments = formatMathText('Attention <red>4 × 2');

      expect(fragments.where((f) => f.highlighted), isNotEmpty);
      expect(fragments.map((f) => f.text).join(), 'Attention 4 × 2');
    });

    test('une fermante orpheline est ignorée, jamais affichée', () {
      final fragments = formatMathText('4</red> × 2');

      expect(fragments.any((f) => f.highlighted), isFalse);
      expect(fragments.map((f) => f.text).join(), '4 × 2');
    });

    test('une balise ouvrante seule n’est jamais affichée', () {
      final fragments = formatMathText('<red>4</red>');

      expect(fragments.map((f) => f.text).join(), '4');
    });

    test('le rouge ne casse pas la détection des variables', () {
      final fragments = formatMathText('<red>x</red> = 8');
      final italiques = fragments.where((f) => f.italic).toList();

      expect(italiques, hasLength(1));
      expect(italiques.single.text, 'x');
      expect(italiques.single.highlighted, isTrue);
    });
  });

  group('MathText — rendu du rouge', () {
    Future<void> monter(WidgetTester tester, String texte) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MathText(
                text: texte,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('le contenu balisé est peint en rouge', (tester) async {
      await monter(tester, 'On multiplie par <red>4</red>.');

      final RichText rich = tester.widget<RichText>(find.byType(RichText));
      final TextSpan? rouge = _spanRouge(rich.text);

      expect(rouge, isNotNull);
      expect(rouge!.text, contains('4'));
      expect(rich.text.toPlainText(), 'On multiplie par 4.');
    });

    testWidgets('une fraction rouge garde sa barre rouge', (tester) async {
      await monter(tester, '<red>1/2</red>');

      expect(find.byType(FractionSpan), findsOneWidget);
      final FractionSpan fraction =
          tester.widget<FractionSpan>(find.byType(FractionSpan));
      expect(fraction.style?.color, kHighlightRed);

      final Container barre = tester.widget<Container>(
        find.descendant(
          of: find.byType(FractionSpan),
          matching: find.byType(Container),
        ),
      );
      expect(barre.color, kHighlightRed);
    });

    testWidgets('le rouge autour d’une fraction ne la démonte pas',
        (tester) async {
      await monter(tester, 'On garde <red>2/4 et encore 2/4</red>.');

      // Deux fractions empilées, toutes deux rouges.
      expect(find.byType(FractionSpan), findsNWidgets(2));
      for (final FractionSpan fraction
          in tester.widgetList<FractionSpan>(find.byType(FractionSpan))) {
        expect(fraction.style?.color, kHighlightRed);
      }
      expect(find.textContaining('<red>'), findsNothing);
      expect(find.textContaining('</red>'), findsNothing);
    });
  });

  group('Lisibilité du rouge', () {
    test('le rouge est #B91C1C', () {
      expect(kHighlightRed, const Color(0xFFB91C1C));
    });

    test('contraste AA sur tous les fonds clairs de l’application', () {
      final RelioPalette palette = RelioPalette.standard();
      for (final Color fond in <Color>[
        palette.surface,
        palette.hintMathBackground,
        palette.hintHighlightBackground,
        palette.primaryContainer,
      ]) {
        expect(
          _contraste(kHighlightRed, fond),
          greaterThanOrEqualTo(4.5),
          reason: 'rouge illisible sur $fond',
        );
      }
    });
  });
}
