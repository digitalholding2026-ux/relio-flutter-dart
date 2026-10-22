/// Nettoyage des réponses du tuteur avant affichage.
///
/// Le modèle écrit parfois du LaTeX ou des opérateurs ASCII : la bulle doit
/// rester lisible sans jamais réécrire les mots de l'élève (le nettoyage n'est
/// appliqué qu'aux messages du tuteur, voir `relio_tutor_sheet.dart`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/widgets/math_text.dart';

void main() {
  group('normalizeTutorText', () {
    test('retire les délimiteurs LaTeX', () {
      expect(normalizeTutorText(r'\(18 - 12 = 6\)'), '18 − 12 = 6');
    });

    test('retire aussi les délimiteurs à crochets', () {
      expect(normalizeTutorText(r'\[2 * 3 = 6\]'), '2 × 3 = 6');
    });

    test('convertit les opérateurs entre deux opérandes', () {
      expect(normalizeTutorText('8/2'), '8÷2');
      expect(normalizeTutorText('2*3*4'), '2×3×4');
      expect(normalizeTutorText('(18-12)'), '(18−12)');
    });

    test('ne touche jamais aux tirets de mot', () {
      expect(
        normalizeTutorText('peut-être a-t-il raison, d’accord ?'),
        'peut-être a-t-il raison, d’accord ?',
      );
    });

    test('convertit les commandes LaTeX usuelles', () {
      expect(normalizeTutorText(r'2 \times 3'), '2 × 3');
      expect(normalizeTutorText(r'6 \div 2'), '6 ÷ 2');
    });

    test('laisse intact un texte sans notation', () {
      const texte = 'Où est-ce que tu bloques ?';
      expect(normalizeTutorText(texte), texte);
    });

    test('un texte vide reste vide', () {
      expect(normalizeTutorText(''), '');
    });

    test('le texte nettoyé traverse ensuite le formateur sans perte', () {
      final cleaned = normalizeTutorText(r'\(12\) ÷ \(3\)');
      expect(cleaned, '12 ÷ 3');
      expect(
        formatMathText(cleaned).map((f) => f.text).join(),
        cleaned,
        reason: 'formater ne doit jamais réécrire un caractère',
      );
    });
  });
}
