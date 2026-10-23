/// Nettoyage du texte avant synthèse vocale.
///
/// Le texte AFFICHÉ ne change jamais : ces tests portent donc uniquement sur
/// la chaîne donnée au moteur, celle que l'élève ENTEND.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/services/audio/speech_text.dart';

void main() {
  group('speechText — balises', () {
    test('retire les balises <red> sans perdre le texte', () {
      expect(
        speechText('Le PGDC de <red>AM</red> et <red>AB</red>'),
        'Le PGDC de A M et A B',
      );
    });

    test('retire aussi une balise fermante seule ou en majuscules', () {
      expect(speechText('a <RED>b</RED> c'), 'a b c');
    });
  });

  group('speechText — fractions', () {
    test('AM/AB se dit « A M sur A B »', () {
      expect(speechText('AM/AB'), 'A M sur A B');
    });

    test('une fraction numérique se dit « sur »', () {
      expect(speechText('3/4'), '3 sur 4');
    });

    test('une fraction mêlant nombre et variable reste prononçable', () {
      expect(speechText('4,5/AC'), '4,5 sur A C');
    });
  });

  group('speechText — opérateurs', () {
    test('le signe moins devient « moins »', () {
      expect(speechText('24 − 6 = 18'), '24 moins 6 égal à 18');
    });

    test('le tiret de soustraction devient « moins »', () {
      expect(speechText('24 - 6'), '24 moins 6');
    });

    test('le tiret d’un mot reste un tiret', () {
      expect(speechText('peut-être'), 'peut-être');
    });

    test('plus, égal et barre oblique deviennent des mots', () {
      expect(speechText('2 + 3 = 5'), '2 plus 3 égal à 5');
      expect(speechText('24 / 6'), '24 sur 6');
    });

    test('fois, divisé, pour cent et puissances sont prononcés', () {
      expect(speechText('3 × 4'), '3 fois 4');
      expect(speechText('12 ÷ 3'), '12 divisé par 3');
      expect(speechText('50 %'), '50 pour cent');
      expect(speechText('x²'), 'x au carré');
    });
  });

  group('speechText — divers', () {
    test('les variables en majuscules sont épelées', () {
      expect(speechText('AB et MN'), 'A B et M N');
    });

    test('les pictogrammes ne sont pas lus', () {
      expect(speechText('Bravo 🎉 !'), 'Bravo !');
    });

    test('les espaces multiples sont réduits', () {
      expect(speechText('  Bonjour   Relio  '), 'Bonjour Relio');
    });

    test('une chaîne vide reste vide', () {
      expect(speechText(''), '');
      expect(speechText('   '), '');
    });

    test('les espaces insécables deviennent des espaces', () {
      expect(speechText('Prêt\u00A0?'), 'Prêt ?');
    });
  });
}
