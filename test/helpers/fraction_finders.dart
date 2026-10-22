/// Recherche des fractions empilées dans les tests d'interface.
///
/// Une fraction n'est plus un `Text` portant `2/4` : c'est un widget
/// [FractionSpan] qui empile deux nombres. `find.text('2/4')` ne peut donc plus
/// la trouver, et les tests doivent désigner le composant, pas une chaîne.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/widgets/fraction_span.dart';

/// Fraction dont le numérateur et le dénominateur sont exactement ceux donnés.
Finder fractionSpan(String top, String bottom) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is FractionSpan &&
          widget.numerator == top &&
          widget.denominator == bottom,
    );

/// Fraction désignée par sa notation source, par exemple « 2/4 ».
Finder fraction(String text) {
  final List<String> parts = text.split('/');
  expect(parts, hasLength(2), reason: '« $text » n’est pas une fraction');
  return fractionSpan(parts[0], parts[1]);
}

/// Fractions affichées, dans l'ordre de l'arbre.
List<FractionSpan> fractionsAffichees(WidgetTester tester) =>
    tester.widgetList<FractionSpan>(find.byType(FractionSpan)).toList();
