/// Tests du programme officiel et du calendrier scolaire.
///
/// Le programme est une DONNÉE TRANSCRITE : ces tests figent les intitulés,
/// les trimestres et les chapitres pour qu'une retouche silencieuse échoue.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/academic_calendar.dart';
import 'package:relio/domain/curriculum/curriculum_data.dart';

void main() {
  group('programme officiel', () {
    test('six séquences numérotées de 1 à 6', () {
      expect(officialProgram, hasLength(6));
      expect(
        officialProgram.map((sequence) => sequence.number),
        <int>[1, 2, 3, 4, 5, 6],
      );
    });

    test('intitulés et trimestres transcrits tels quels', () {
      expect(
        officialProgram.map((sequence) => sequence.title),
        <String>[
          'Séquence 1 (Septembre - Octobre)',
          'Séquence 2 (Octobre - Novembre)',
          'Séquence 3 (Décembre - Janvier)',
          'Séquence 4 (Janvier - Mars)',
          'Séquence 5 (Mars - Mai)',
          'Séquence 6 (Mai - Juin)',
        ],
      );
      expect(
        officialProgram.map((sequence) => sequence.period),
        <SequencePeriod>[
          SequencePeriod.trimestre1,
          SequencePeriod.trimestre1,
          SequencePeriod.trimestre2,
          SequencePeriod.trimestre2,
          SequencePeriod.trimestre3,
          SequencePeriod.trimestre3,
        ],
      );
    });

    test('chapitres transcrits chapitre par chapitre', () {
      expect(officialProgram[0].chapters, <String>[
        'Arithmétique',
        'Théorème de Thalès',
        'Nombres réels (bases)',
      ]);
      expect(officialProgram[1].chapters, <String>[
        'Nombres réels (suite)',
        'Trigonométrie',
      ]);
      expect(officialProgram[2].chapters, <String>[
        'Calcul littéral',
        'Sections de cônes et pyramides',
      ]);
      expect(officialProgram[3].chapters, <String>[
        'Vecteurs',
        'Équations et inéquations',
      ]);
      expect(officialProgram[4].chapters, <String>[
        'Angles inscrits',
        'Polygones réguliers',
        'Statistiques',
        'Homothétie',
      ]);
      expect(officialProgram[5].chapters, <String>[
        'Applications linéaires et affines',
      ]);
    });
  });

  group('calendrier', () {
    test('octobre et novembre renvoient la séquence 2', () {
      expect(sequenceForDate(DateTime(2026, 10, 22)).number, 2);
      expect(sequenceForDate(DateTime(2026, 11, 30)).number, 2);
    });

    test('chaque mois renvoie la séquence attendue', () {
      const Map<int, int> expected = <int, int>{
        1: 3,
        2: 4,
        3: 4,
        4: 5,
        5: 5,
        6: 6,
        7: 6,
        8: 6,
        9: 1,
        10: 2,
        11: 2,
        12: 3,
      };

      for (final MapEntry<int, int> entry in expected.entries) {
        final DateTime date = DateTime(2026, entry.key, 15);
        expect(
          sequenceForDate(date).number,
          entry.value,
          reason: 'mois ${entry.key}',
        );
      }
    });

    test('la séquence renvoyée appartient au programme officiel', () {
      final AcademicSequence sequence = sequenceForDate(DateTime(2026, 3, 1));

      expect(officialProgram, contains(sequence));
      expect(sequence.title, 'Séquence 4 (Janvier - Mars)');
    });

    test('les séquences précédentes sont celles de numéro inférieur', () {
      final AcademicSequence current = sequenceForDate(DateTime(2026, 11, 1));

      expect(
        previousSequences(current).map((sequence) => sequence.number),
        <int>[1],
      );
    });

    test('en septembre, aucune séquence ne précède la première', () {
      final AcademicSequence current = sequenceForDate(DateTime(2026, 9, 1));

      expect(previousSequences(current), isEmpty);
    });

    test('un mois hors calendrier est refusé', () {
      expect(
        () => sequenceNumberForMonth(13),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
