/// Le prompt système est une donnée pédagogique versionnée.
///
/// `docs/TUTEUR_LLM.md` fait foi. Ce test rejoue la comparaison : si la
/// constante Dart dérive du document (ou l'inverse), la suite échoue.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/tutor/tutor_prompt.dart';

const String _startMarker = '<!-- SYSTEM_PROMPT_START -->';
const String _endMarker = '<!-- SYSTEM_PROMPT_END -->';

String _normalize(String text) => text.replaceAll('\r\n', '\n').trim();

/// Extrait le prompt du document de référence.
String _promptFromDocument() {
  final document = File('docs/TUTEUR_LLM.md').readAsStringSync();
  final start = document.indexOf(_startMarker);
  final end = document.indexOf(_endMarker);

  expect(start, greaterThanOrEqualTo(0), reason: 'marqueur de début absent');
  expect(
    end,
    greaterThan(start),
    reason: 'marqueur de fin absent ou antérieur',
  );

  return _normalize(document.substring(start + _startMarker.length, end));
}

void main() {
  group('Prompt système officiel', () {
    test('la constante Dart est identique au document validé', () {
      expect(_normalize(kTutorSystemPrompt), _promptFromDocument());
    });

    test('les règles non négociables sont présentes', () {
      const String prompt = kTutorSystemPrompt;

      // Rôle et public.
      expect(prompt, contains('tuteur personnel de mathématiques'));
      expect(prompt, contains('élèves de 3e au Cameroun'));

      // Interdiction de révéler la réponse.
      expect(prompt, contains('JAMAIS donner la réponse finale'));
      expect(prompt, contains('Je ne peux pas te donner la réponse'));

      // Guidage socratique, une question à la fois.
      expect(prompt, contains('La méthode socratique'));
      expect(prompt, contains('une seule instruction ou une seule question'));

      // Brièveté : 2 à 3 phrases.
      expect(prompt, contains('2 ou 3 phrases maximum'));

      // L'erreur n'est pas jugée.
      expect(prompt, contains('ne dis pas "C\'est faux"'));
    });

    test('le document reste la source, la constante ne l’absorbe pas', () {
      // Garde-fou : un prompt déplacé dans le code sans documentation
      // laisserait ce test passer sur un document vide.
      expect(_promptFromDocument().isNotEmpty, isTrue);
      expect(kTutorSystemPrompt.contains(_startMarker), isFalse);
    });
  });
}
