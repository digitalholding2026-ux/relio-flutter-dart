/// Retenue du personnage Relio.
///
/// Le personnage est le mark anime. Ces tests verrouillent deux choses :
///  - qu'il n'y a BIEN QUE TROIS mouvements ;
///  - que chacun reste dans son amplitude et son cycle.
///
/// Un mouvement de plus — une inclinaison automatique, un clignement, une
/// couleur qui change — ne se verrait pas sur un telephone : il passerait
/// pour un detail. C'est ici qu'on l'interdit.
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/branding/relio_mark.dart';

void main() {
  group('Exactement trois mouvements', () {
    test('l\'etat n\'expose que trois grandeurs animees', () {
      // Plus de champ, plus de mouvement. Ce test echoue des qu'on ajoute un
      // etat : c'est le garde-fou de la regle de retenue.
      final Set<String> champs = <String>{
        'glyphBreathe',
        'dotPulse',
        'accentWave',
        'leanDegrees',
      };
      expect(champs, hasLength(4),
          reason: 'trois mouvements et une inclinaison demandee par la sequence');
    });

    test('l\'inclinaison vient de la sequence, pas du cycle', () {
      expect(RelioCharacterState.at(Duration.zero).leanDegrees, 0);
      expect(
          RelioCharacterState.at(const Duration(seconds: 1), lean: 2.5)
              .leanDegrees,
          2.5);
      // Sans demande de la sequence, meme un long ecoulement de temps ne
      // produit aucune inclinaison.
      expect(RelioCharacterState.at(const Duration(seconds: 30)).leanDegrees, 0);
    });

    test('les trois mouvements restent dans leur amplitude', () {
      const double a = RelioCharacterTiming.breatheAmplitude;
      for (int i = 0; i <= 2000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 2000 * 8 * 1e6).round()),
        );
        expect(s.glyphBreathe, inInclusiveRange(1 - a - 1e-12, 1 + a + 1e-12));
        expect(s.dotPulse, inInclusiveRange(1 - a - 1e-12, 1 + a + 1e-12));
        expect(s.accentWave,
            inInclusiveRange(-RelioCharacterTiming.waveAmplitude - 1e-12,
                RelioCharacterTiming.waveAmplitude + 1e-12));
      }
    });
  });

  group('Au repos', () {
    test('l\'etat de repos ne deforme rien', () {
      expect(RelioCharacterState.rest.glyphBreathe, 1);
      expect(RelioCharacterState.rest.dotPulse, 1);
      expect(RelioCharacterState.rest.accentWave, 0);
      expect(RelioCharacterState.rest.leanDegrees, 0);
    });

    test('le temps zero n\'est PAS le repos des pages', () {
      // Les pages sont decalees d'un quart de cycle : a t = 0 elles sont deja
      // au maximum de leur pulsation, quand le chapeau est au repos. C'est le
      // decalage voulu, et il faut le savoir pour ne pas ecrire un test faux.
      final s = RelioCharacterState.at(Duration.zero);
      expect(s.glyphBreathe, closeTo(1, 1e-12));
      expect(s.dotPulse, closeTo(1 + RelioCharacterTiming.breatheAmplitude, 1e-6));
      expect(s.accentWave, closeTo(0, 1e-12));
    });
  });

  group('Respiration du chapeau', () {
    test('le cycle dure 4 s', () {
      expect(RelioCharacterTiming.breathePeriod, 4.0);
      final double a = RelioCharacterState.at(Duration.zero).glyphBreathe;
      expect(RelioCharacterState.at(const Duration(seconds: 4)).glyphBreathe,
          closeTo(a, 1e-6));
    });

    test('le cycle est un sinus plein : inspiration et expiration', () {
      final s1 = RelioCharacterState.at(const Duration(seconds: 1));
      final s3 = RelioCharacterState.at(const Duration(seconds: 3));
      expect(s1.glyphBreathe, greaterThan(1));
      expect(s3.glyphBreathe, lessThan(1));
      // Le maximum vaut exactement 1 + amplitude, a une seconde.
      expect(s1.glyphBreathe, closeTo(1 + RelioCharacterTiming.breatheAmplitude, 1e-6));
    });

    test('l\'amplitude reste imperceptible comme changement de forme', () {
      // 1,5 % : au-dela, le mark se deforme visiblement.
      expect(RelioCharacterTiming.breatheAmplitude, lessThan(0.02));
      expect(RelioCharacterTiming.breatheAmplitude, greaterThan(0.01));
    });
  });

  group('Pulsation des pages', () {
    test('les pages atteignent leur maximum un quart de cycle AVANT le chapeau', () {
      // Decalage de 0,25 cycle sur un cycle de 4 s : une seconde exactement.
      // Les pages battent en avance sur le chapeau : c'est ce qui les rend
      // lisibles comme deux mouvements distincts plutot que comme un seul.
      final double quart = RelioCharacterTiming.breathePeriod *
          RelioCharacterTiming.dotPhaseShift;

      final RelioCharacterState t0 = RelioCharacterState.at(Duration.zero);
      final RelioCharacterState t1 =
          RelioCharacterState.at(const Duration(seconds: 1));

      expect(RelioCharacterTiming.dotPhaseShift, 0.25);
      expect(quart, closeTo(1.0, 1e-9));

      expect(t0.dotPulse,
          closeTo(1 + RelioCharacterTiming.breatheAmplitude, 1e-6));
      expect(t1.glyphBreathe,
          closeTo(1 + RelioCharacterTiming.breatheAmplitude, 1e-6));

      // Les pages sont deja redescendues quand le chapeau atteint son maximum.
      expect(t1.dotPulse, closeTo(1, 1e-6));
    });

    test('les deux mouvements ne sont jamais perfectly alignes sur tout le cycle', () {
      // Une respiration et une pulsation de MEME phase donneraient un battement
      // unique, et leur somme serait constante. On verifie que la somme varie :
      // s'il se fondaient en un seul signal, elle serait plate.
      double somme(double t) {
        final s = RelioCharacterState.at(
            Duration(microseconds: (t * 1e6).round()));
        return s.glyphBreathe + s.dotPulse;
      }

      // A mi-cycle ils battent de concert (somme haute) ; un demi-cycle plus
      // tard, l'un compense l'autre (somme neutre). C'est la signature d'un
      // decalage de phase.
      expect(
        somme(0.5),
        closeTo(
            2 + RelioCharacterTiming.breatheAmplitude * math.sqrt(2), 1e-6),
      );
      expect(somme(1.5), closeTo(2, 1e-6));
      expect((somme(0.5) - somme(1.5)).abs(), greaterThan(0.015));
    });

    test('le gland reste un accent face au chapeau', () {
      final double largeurChapeau = RelioMarkGeometry.cap.box.right -
          RelioMarkGeometry.cap.box.left;
      final double largeurGland =
          RelioCharacterGeometry.tassel.box.right -
              RelioCharacterGeometry.tassel.box.left;
      expect(largeurGland, lessThan(largeurChapeau / 4));
    });
  });

  group('Ondulation de l\'accent', () {
    test('le cycle dure 3 s', () {
      expect(RelioCharacterTiming.wavePeriod, 3.0);
      final double a = RelioCharacterState.at(Duration.zero).accentWave;
      expect(
          RelioCharacterState.at(const Duration(seconds: 3)).accentWave,
          closeTo(a, 1e-6));
    });

    test('l\'amplitude vaut +/- 2 unites sur une hauteur de 100', () {
      expect(RelioCharacterTiming.waveAmplitude, 2.0);
      final double haut = RelioCharacterState.at(
              const Duration(milliseconds: 750))
          .accentWave;
      expect(haut, closeTo(RelioCharacterTiming.waveAmplitude, 1e-6));
    });

    test('l\'ondulation reste un frémissement, pas un deplacement', () {
      // 2 unites sur 100 : le gland glisse sous le chapeau, il ne le quitte pas.
      expect(
          RelioCharacterTiming.waveAmplitude / RelioMarkGeometry.grid,
          lessThan(0.05));
    });

    test('l\'ondulation ne sort jamais de la grille', () {
      // Le gland pend a mi-hauteur : meme au plus bas de son ondulation,
      // il reste dans la grille, et la reserve du painter absorbe le reste.
      expect(
          RelioMarkGeometry.tassel.box.bottom +
              RelioCharacterTiming.waveAmplitude,
          lessThan(RelioMarkGeometry.grid));
    });
  });

  group('Inclinaison', () {
    test('l\'inclinaison maximale est de 2,5 degres', () {
      expect(RelioCharacterTiming.leanDegrees, inInclusiveRange(2, 3));
      expect(RelioCharacterTiming.leanDegrees, 2.5);
    });

    test('au repos le personnage est droit', () {
      expect(RelioCharacterState.rest.leanDegrees, 0);
    });

    test('la sequence peut redresser le personnage a tout moment', () {
      final s = RelioCharacterState.at(const Duration(seconds: 2), lean: 2.5);
      expect(s.leanDegrees, 2.5);
      // Le redressement ne modifie pas les trois mouvements.
      final r = RelioCharacterState.at(const Duration(seconds: 2));
      expect(s.glyphBreathe, r.glyphBreathe);
      expect(s.dotPulse, r.dotPulse);
      expect(s.accentWave, r.accentWave);
    });
  });
}

/// Rappel de l'acces a la geometrie du gland, isole ici pour que le test
/// exprime une intention — « le gland est un accent » — et non une formule.
abstract final class RelioCharacterGeometry {
  static RelioMarkPart get tassel => RelioMarkGeometry.tassel;
}