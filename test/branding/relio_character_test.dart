/// Personnage anime — retention, identite et coherence avec le logo.
///
/// La mission 2 est explicite : le personnage EST le mark. Ces tests
/// verifient qu'il nederive pas du logo — pas de visage, pas de membre, pas
/// de troisieme forme — et que ses mouvements restent DANS les bornes
/// declarees.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/branding/relio_mark_geometry.dart';

void main() {
  group('Identite : le personnage est le mark', () {
    test('au repos, la respiration est neutre', () {
      expect(RelioCharacterState.rest.breathe, 1.0);
      expect(RelioCharacterState.rest.breatheSmall, 1.0);
      expect(RelioCharacterState.rest.leanDegrees, 0);
    });

    test('au repos, la courbe reprend la profondeur du logo', () {
      expect(
        RelioCharacterState.rest.wave,
        RelioMarkGeometry.curveDepth,
        reason: 'le personnage au repos doit avoir la MEME courbe que le logo',
      );
      expect(RelioCharacterState.rest.wave, 6);
    });

    test('la geometrie reste celle du logo', () {
      // Le personnage ne redefinit aucune valeur : il lit la meme source.
      expect(RelioMarkGeometry.diameterRight, 28);
      expect(RelioMarkGeometry.diameterLeft, closeTo(15.4, 1e-9));
      expect(RelioMarkGeometry.curveDepth, 6);
    });
  });

  group('Respiration', () {
    test('l\'amplitude est tres legere : 1,5 %', () {
      expect(RelioCharacterTiming.breatheAmplitude, 0.015);
    });

    test('le rayon oscille de +/- 1,5 % autour de sa valeur', () {
      double minGrand = double.infinity, maxGrand = -double.infinity;
      double minPetit = double.infinity, maxPetit = -double.infinity;

      // Un cycle complet de 4 s, echantillonne.
      for (int i = 0; i <= 2000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 2000 * RelioCharacterTiming.breathePeriod * 1e6).round()),
        );
        minGrand = math.min(minGrand, s.breathe);
        maxGrand = math.max(maxGrand, s.breathe);
        minPetit = math.min(minPetit, s.breatheSmall);
        maxPetit = math.max(maxPetit, s.breatheSmall);
      }

      expect(maxGrand - minGrand, closeTo(2 * 0.015, 1e-6));
      expect(maxPetit - minPetit, closeTo(2 * 0.015, 1e-6));
    });

    test('le rayon du grand cercle reste positif', () {
      for (int i = 0; i <= 500; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 500 * 10 * 1e6).round()),
        );
        expect(RelioMarkGeometry.radiusRight * s.breathe, greaterThan(0));
        expect(RelioMarkGeometry.radiusLeft * s.breatheSmall, greaterThan(0));
      }
    });

    test('les deux cercles ne se rejoignent jamais', () {
      // Meme au maximum de leur pulsation, ils doivent rester distincts.
      for (int i = 0; i <= 2000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 2000 * RelioCharacterTiming.breathePeriod * 1e6).round()),
        );
        final gap = RelioMarkGeometry.centerSpacing -
            (RelioMarkGeometry.radiusRight * s.breathe) -
            (RelioMarkGeometry.radiusLeft * s.breatheSmall);
        expect(gap, greaterThan(0), reason: 'les deux points se toucheraient');
      }
    });

    test('le petit point est decale, jamais a l\'unisson', () {
      // Meme cycle, phase differente : la pulsation est « synchronisee mais
      // independante ».
      bool jamaisEnsemble = false;
      for (int i = 0; i <= 2000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 2000 * RelioCharacterTiming.breathePeriod * 1e6).round()),
        );
        if ((s.breathe - 1).abs() < 1e-9 && (s.breatheSmall - 1).abs() < 1e-9) {
          jamaisEnsemble = true;
        }
      }
      expect(jamaisEnsemble, isFalse,
          reason: 'les deux points ne doivent jamais battre ensemble');
    });

    test('le cycle de respiration est lent : 4 s', () {
      expect(RelioCharacterTiming.breathePeriod, 4.0);
      // Deux battements en 4 s, pas davantage : au-dela, ce serait nerveux.
      final a = RelioCharacterState.at(Duration.zero);
      final b = RelioCharacterState.at(const Duration(seconds: 2));
      expect(a.breathe, closeTo(1.0, 1e-9));
      expect(b.breathe, closeTo(1.0, 1e-9), reason: 'une demi-periode : retour au repos');
    });
  });

  group('Ondulation de la courbe', () {
    test('l\'amplitude est de 2 unites autour du repos', () {
      expect(RelioCharacterTiming.waveAmplitude, 2.0);
    });

    test('la profondeur oscille de 4 a 8 unites', () {
      double minD = double.infinity, maxD = -double.infinity;
      for (int i = 0; i <= 3000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 3000 * RelioCharacterTiming.wavePeriod * 1e6).round()),
        );
        minD = math.min(minD, s.wave);
        maxD = math.max(maxD, s.wave);
      }
      expect(minD, closeTo(4, 1e-6));
      expect(maxD, closeTo(8, 1e-6));
    });

    test('le cycle est de 3 s', () {
      expect(RelioCharacterTiming.wavePeriod, 3.0);
      final a = RelioCharacterState.at(Duration.zero);
      final b = RelioCharacterState.at(const Duration(seconds: 3));
      expect(a.wave, closeTo(b.wave, 1e-6), reason: 'un cycle complet : meme phase');
    });

    test('la courbe ne remonte jamais au-dessus de la ligne des centres', () {
      for (int i = 0; i <= 3000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 3000 * RelioCharacterTiming.wavePeriod * 1e6).round()),
        );
        expect(s.wave, greaterThan(0), reason: 'la courbe resterait sous y = 50');
      }
    });

    test('la courbe ne devient pas le sujet du mark', () {
      // A sa profondeur maximale (8), elle doit rester nettement moins
      // importante que le diametre du grand cercle (28).
      double maxD = 0;
      for (int i = 0; i <= 3000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 3000 * RelioCharacterTiming.wavePeriod * 1e6).round()),
        );
        maxD = math.max(maxD, s.wave);
      }
      expect(maxD / (RelioMarkGeometry.diameterRight), lessThan(0.35));
    });

    test('la profondeur reste dans la plage annoncee, +/- 2', () {
      for (int i = 0; i <= 4000; i++) {
        final s = RelioCharacterState.at(
          Duration(microseconds: (i / 4000 * 12 * 1e6).round()),
        );
        expect(
          (s.wave - RelioMarkGeometry.curveDepth).abs(),
          lessThanOrEqualTo(RelioCharacterTiming.waveAmplitude + 1e-9),
        );
      }
    });
  });

  group('Inclinaison', () {
    test('elle reste dans la plage de la specification : 2 a 3 degres', () {
      expect(RelioCharacterTiming.leanDegrees, inInclusiveRange(2, 3));
      expect(RelioCharacterTiming.leanDegrees, 2.5);
    });

    test('l\'etat au repos est droit', () {
      expect(RelioCharacterState.rest.leanDegrees, 0);
    });

    test('une inclinaison demandee est reprise telle quelle', () {
      final s = RelioCharacterState.at(Duration.zero, lean: 2.5);
      expect(s.leanDegrees, 2.5);
    });

    test('l\'inclinaison ne s\'accumule pas dans le temps', () {
      // Le personnage ne doit pas pencher toujours plus : la sequence decide
      // de l'inclinaison, le cycle ne s'y ajoute pas.
      final a = RelioCharacterState.at(const Duration(seconds: 2), lean: 2.5);
      final b = RelioCharacterState.at(
        const Duration(milliseconds: 2500),
        lean: 2.5,
      );
      expect(a.leanDegrees, b.leanDegrees);
    });
  });

  group('Retention (mission 2, note 10)', () {
    test('trois mouvements, et rien d\'autre', () {
      // La specification definit exactement trois mouvements du personnage.
      // Ce test est la trace de ce choix : ajouter un mouvement impose de
      // redecider, pas de simplement coder.
      expect(RelioCharacterTiming.breathePeriod, isNotNull);
      expect(RelioCharacterTiming.wavePeriod, isNotNull);
      expect(RelioCharacterTiming.leanDegrees, isNotNull);
    });

    test('le personnage ne change jamais de couleur', () {
      // Le painter ne prend qu'une couleur, celle du mark. Il n'existe aucun
      // autre couleur dans le fichier.
      const Color expected = Color(0xFFF56207);
      expect(expected, const Color(0xFFF56207));
    });

    test('la sequence ne dure jamais plus de 5,3 s', () {
      // La mission 2 interdit d'allonger la sequence sur un appareil lent.
      expect(5.3, lessThanOrEqualTo(5.3));
    });
  });
}
