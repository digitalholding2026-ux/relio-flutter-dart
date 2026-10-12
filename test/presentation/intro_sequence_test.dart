/// Chronologie de l'ecran d'entree.
///
/// Ces tests sont le contrat de la mission 2. Ils ne dessinent rien : ils
/// verifient qu'a un instant donne, l'etat est bien celui annonce par la
/// specification.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/intro/intro_sequence.dart';

/// Etat a un instant donne, en millisecondes.
IntroSequenceState at(int ms) => IntroSequenceState.at(Duration(milliseconds: ms));

void main() {
  group('Chronologie', () {
    test('T = 0 : le personnage est seul, aucun texte', () {
      final s = at(0);
      expect(s.stage, IntroStage.character);
      expect(s.textVisible, isFalse);
      expect(s.textOpacity, 0);
      expect(s.buttonVisible, isFalse);
    });

    test('le personnage apparait en fondu, de 0,9 a 1,0, sur 300 ms', () {
      expect(at(0).characterOpacity, 0);
      // A mi-parcours, il est a moitie visible et entre les deux echelles.
      final mid = at(150);
      expect(mid.characterOpacity, greaterThan(0));
      expect(mid.characterOpacity, lessThan(1));
      expect(mid.characterScale, greaterThan(0.9));
      expect(mid.characterScale, lessThan(1.0));
      // A 300 ms, l'entree est finie.
      expect(at(300).characterOpacity, 1);
      expect(at(300).characterScale, 1.0);
    });

    test('l\'echelle ne descend jamais sous 0,9', () {
      for (int ms = 0; ms <= 400; ms += 5) {
        expect(at(ms).characterScale, greaterThanOrEqualTo(0.9));
      }
    });

    test('T = 1,5 s : premier texte', () {
      final s = at(1500);
      expect(s.stage, IntroStage.greeting);
      expect(s.textVisible, isTrue);
      expect(s.buttonVisible, isFalse);
    });

    test('T = 3 s : deuxieme texte', () {
      expect(at(3000).stage, IntroStage.promise);
      expect(at(3000).textVisible, isTrue);
    });

    test('T = 5 s : la question', () {
      expect(at(5000).stage, IntroStage.question);
      expect(at(5000).buttonVisible, isFalse);
    });

    test('T = 5,3 s : le bouton est visible', () {
      final s = at(5300);
      expect(s.buttonVisible, isTrue);
      expect(s.stage, IntroStage.ready);
    });

    test('le bouton est absent a 5,299 s et present a 5,3 s', () {
      expect(at(5299).buttonVisible, isFalse);
      expect(at(5300).buttonVisible, isTrue);
    });

    test('le bouton est visible 300 ms apres la question', () {
      const int question = 5000;
      const int bouton = 5300;
      expect(bouton - question, 300);
    });

    test('la sequence entiere tient en 5,3 s', () {
      // Bornes de la specification : « 5,3 secondes maximum avant que le
      // bouton soit visible ».
      final s = at(5300);
      expect(s.finished, isTrue);
      expect(at(5299).finished, isFalse);
    });
  });

  group('Fondu des textes', () {
    test('un texte apparait en 250 ms', () {
      expect(at(1500).textOpacity, 0, reason: 'rien au moment exact');
      expect(at(1625).textOpacity, closeTo(0.5, 0.02));
      expect(at(1750).textOpacity, 1);
    });

    test('l\'opacite reste dans [0, 1] sur toute la sequence', () {
      for (int ms = 0; ms <= 6000; ms += 10) {
        final o = at(ms).textOpacity;
        expect(o, inInclusiveRange(0, 1), reason: 'opacite invalide a ${ms}ms');
      }
    });

    test('un seul texte est affiche a la fois', () {
      // La specification impose remplacement, pas accumulation.
      expect(at(1500).stage, IntroStage.greeting);
      expect(at(2999).stage, IntroStage.greeting);
      expect(at(3000).stage, IntroStage.promise);
      expect(at(4999).stage, IntroStage.promise);
      expect(at(5000).stage, IntroStage.question);
    });

    test('la question reste affichee jusqu\'a la confirmation', () {
      expect(IntroTexts.forStage(at(6000).stage), IntroTexts.question);
    });
  });

  group('Inclinaison', () {
    test('le personnage s\'incline quand un texte apparait', () {
      final s = at(1500);
      expect(s.leanDegrees, greaterThan(0));
      expect(s.leanDegrees, inInclusiveRange(2, 3));
    });

    test('il est droit avant le premier texte', () {
      expect(at(0).leanDegrees, 0);
    });

    test('il se redresse pour la question et pour le bouton', () {
      expect(at(5000).leanDegrees, 0);
      expect(at(5300).leanDegrees, 0);
    });

    test('l\'inclinaison reste dans la plage de la specification', () {
      for (int ms = 0; ms <= 6000; ms += 25) {
        final lean = at(ms).leanDegrees;
        expect(lean, inInclusiveRange(0, 3),
            reason: 'inclinaison hors plage a ${ms}ms : $lean');
      }
    });
  });

  group('Acceleration par tap', () {
    test('un tap affiche le texte en 150 ms', () {
      final s = IntroSequenceState.accelerated(Duration.zero);
      expect(s.textOpacity, 0);
      expect(IntroSequenceState.accelerated(const Duration(milliseconds: 150))
          .textOpacity, 1);
    });

    test('le bouton apparait 200 ms apres le tap', () {
      final s = IntroSequenceState.accelerated(const Duration(milliseconds: 199));
      expect(s.buttonVisible, isFalse);
      expect(
        IntroSequenceState.accelerated(const Duration(milliseconds: 200)).buttonVisible,
        isTrue,
      );
    });

    test('la sequence intermediaire est court-circuitee', () {
      // immediately apres le tap, on est deja a l'etape finale.
      final s = IntroSequenceState.accelerated(Duration.zero);
      expect(s.stage, IntroStage.ready);
      expect(IntroTexts.forStage(s.stage), IntroTexts.question);
    });

    test('l\'acceleration est plus rapide que la sequence naturelle', () {
      final accel = IntroSequenceState.accelerated(const Duration(milliseconds: 450));
      expect(accel.finished, isTrue);
      // 450 ms apres le tap, contre 5,3 s sans tap.
      expect(450, lessThan(5300));
    });

    test('le personnage ne rejoue pas sa micro-animation', () {
      final s = IntroSequenceState.accelerated(Duration.zero);
      expect(s.characterOpacity, 1);
      expect(s.characterScale, 1.0);
    });

    test('apres le bouton, un tap ne fait plus rien', () {
      expect(at(5300).accelerates, isFalse);
      expect(at(6000).accelerates, isFalse);
      expect(at(1000).accelerates, isTrue);
    });

    test('une sequence terminee ne s\'accelere plus', () {
      final s = IntroSequenceState.accelerated(const Duration(milliseconds: 500));
      expect(s.finished, isTrue);
      expect(s.accelerates, isFalse);
    });
  });

  group('Textes', () {
    test('les trois textes sont ceux de la specification', () {
      expect(IntroTexts.greeting, 'Salut. Je suis Relio.');
      expect(IntroTexts.promise, 'Je t\'accompagne en maths, à ton rythme.');
      expect(IntroTexts.question, 'On commence ?');
      expect(IntroTexts.startButton, 'Commencer');
    });

    test('aucune promesse de resultat', () {
      // La mission 2 l'interdit explicitement : pas de « reussir », pas de
      // « champion », pas d'engagement de performance.
      for (final String t in <String>[
        IntroTexts.greeting,
        IntroTexts.promise,
        IntroTexts.question,
        IntroTexts.startButton,
      ]) {
        for (final String interdit in <String>[
          'reussir', 'réussir', 'champion', 'score', 'progression',
          'niveau', 'maitrise', 'maîtrise', 'premier', 'gagner',
        ]) {
          expect(t.toLowerCase(), isNot(contains(interdit)),
              reason: '« $interdit » dans : $t');
        }
      }
    });

    test('aucun ton commercial', () {
      for (final String t in <String>[
        IntroTexts.greeting,
        IntroTexts.promise,
        IntroTexts.question,
      ]) {
        expect(t.toLowerCase(), isNot(contains('bienvenue')));
        expect(t.toLowerCase(), isNot(contains('aventure')));
        expect(t.toLowerCase(), isNot(contains('prêt')));
      }
    });

    test('le bouton se dit « Commencer »', () {
      expect(IntroTexts.startButton, 'Commencer');
    });
  });
}
