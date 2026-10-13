/// Onboarding — saisie du prenom.
///
/// La logique de clavier est testee comme fonction PURE : chiffres, symboles,
/// emojis, tirets, apostrophes. C'est plus fiable qu'une simulation tactile,
/// et ca couvre les caracteres qu'un clavier physique ne peut pas taper.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/onboarding/name_input.dart';

void main() {
  group('Caracteres autorises', () {
    test('les lettres latines passent', () {
      for (final String letter in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
        expect(isNameCharacter(letter), isTrue, reason: 'lettre $letter');
      }
      for (final String letter in 'ABCXYZ'.split('')) {
        expect(isNameCharacter(letter), isTrue, reason: 'lettre $letter');
      }
    });

    test('les lettres accentuees passent', () {
      // Un eleve ecrit son prenom comme il le prononce : « Zoé » doit
      // pouvoir etre saisi sans correction.
      for (final String letter in <String>['é', 'è', 'ê', 'à', 'ç', 'û', 'î']) {
        expect(isNameCharacter(letter), isTrue, reason: 'lettre $letter');
      }
    });

    test('l\'espace, le trait d\'union et l\'apostrophe passent', () {
      expect(isNameCharacter(' '), isTrue);
      expect(isNameCharacter('-'), isTrue);
      expect(isNameCharacter("'"), isTrue);
      expect(isNameCharacter('\u2019'), isTrue,
          reason: 'apostrophe typographique — deux claviers, un seul nom');
    });

    test('les chiffres sont rejetes a la frappe', () {
      for (final String chiffre in '0123456789'.split('')) {
        expect(isNameCharacter(chiffre), isFalse, reason: 'chiffre $chiffre');
      }
    });

    test('la ponctuation et les symboles sont rejetes', () {
      for (final String symbole in <String>['.', ',', '!', '?', '@', '#', '+']) {
        expect(isNameCharacter(symbole), isFalse, reason: 'symbole $symbole');
      }
    });

    test('les emojis sont rejetes', () {
      // Un emoji est un caractere hors alphabet latin : il doit disparaitre
      // a la frappe, comme n'importe quel caractere interdit.
      expect(isNameCharacter('\u{1F600}'), isFalse);
      expect(isNameCharacter('\u2764'), isFalse);
    });

    test('une chaine vide ne contient aucun caractere valide', () {
      expect(isNameCharacter(''), isFalse);
    });
  });

  group('Nettoyage', () {
    test('un prenom valide ne change pas', () {
      expect(sanitizeName('Awa'), 'Awa');
      expect(sanitizeName('Jean-Pierre'), 'Jean-Pierre');
      expect(sanitizeName("N'Diaye"), "N'Diaye");
    });

    test('les chiffres sont retires', () {
      expect(sanitizeName('Awa2'), 'Awa');
      expect(sanitizeName('1er'), 'er');
    });

    test('les emojis sont retires', () {
      expect(sanitizeName('Awa\u{1F600}'), 'Awa');
    });

    test('les espaces internes sont conserves', () {
      expect(sanitizeName('Marie Claire'), 'Marie Claire');
    });
  });

  group('Capitalisation', () {
    test('la premiere lettre est capitalisee', () {
      expect(capitalizeName('awa'), 'Awa');
    });

    test('le reste du nom est laisse tel quel', () {
      // « McDonald » ne doit pas devenir « Mcdonald » : la casse d'un nom
      // propre n'appartient pas a l'ecran.
      expect(capitalizeName('mcDonald'), 'McDonald');
      expect(capitalizeName('jean-pierre'), 'Jean-pierre');
    });

    test('une chaine vide reste vide', () {
      expect(capitalizeName(''), '');
    });

    test('un nom deja capitalise ne change pas', () {
      expect(capitalizeName('Awa'), 'Awa');
    });
  });

  group('Preparation complete', () {
    test('nettoie puis capitalise dans l\'ordre', () {
      expect(prepareName('  awa  '), 'Awa');
      expect(prepareName('awa2!'), 'Awa');
      expect(prepareName("n'diaye"), "N'diaye");
    });

    test('un prenom long est accepte sans forme imposee', () {
      // La troncature a 24 caracteres est une BORNE DE SAISIE, appliquee par
      // le widget au moment de la frappe. La logique pure, elle, ne valide
      // aucune longueur : c'est la decision validee.
      const String long = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      expect(prepareName(long).length, 32,
          reason: 'la logique pure n\'impose aucune longueur');
    });
  });
}