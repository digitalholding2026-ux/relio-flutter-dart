/// Séquence du programme en cours, déduite de la date.
///
/// RÈGLE DE CALENDRIER — volontairement simple, et testée :
///
/// | Mois | Séquence |
/// |---|---|
/// | septembre | 1 |
/// | octobre, novembre | 2 |
/// | décembre | 3 |
/// | janvier, février | 4 |
/// | mars, avril | 5 |
/// | mai, juin, juillet, août | 6 |
///
/// Les intitulés du programme se chevauchent (S1 va de septembre à octobre,
/// S2 d'octobre à novembre, S4 de janvier à mars, S5 de mars à mai…). Le mois
/// de bascule est attribué à la séquence qui COMMENCE : octobre vaut donc S2
/// et mars vaut S5, comme l'indique la consigne. Janvier, début de la S4, vaut
/// de même S4. Juillet et août sont hors année scolaire : la dernière séquence
/// reste l'objectif, plutôt que d'annoncer une séquence qui n'a pas encore
/// commencé.
///
/// Aucune notion de l'élève n'intervient : la date seule décide. L'horloge
/// est un paramètre, ce qui rend la règle testable sans attendre un mois
/// particulier.
library;

import 'curriculum_data.dart';

/// Numéro de la séquence associée à [month] (1 = janvier … 12 = décembre).
int sequenceNumberForMonth(int month) {
  assert(month >= 1 && month <= 12, 'mois hors calendrier : $month');
  return switch (month) {
    9 => 1,
    10 || 11 => 2,
    12 => 3,
    1 || 2 => 4,
    3 || 4 => 5,
    _ => 6,
  };
}

/// Séquence en cours à la date [date].
AcademicSequence sequenceForDate(DateTime date) {
  final int number = sequenceNumberForMonth(date.month);
  for (final AcademicSequence sequence in officialProgram) {
    if (sequence.number == number) return sequence;
  }
  // `officialProgram` couvre 1 à 6 : cette branche ne peut être atteinte que
  // si la table du programme est modifiée sans la règle de calendrier.
  throw StateError('Aucune séquence $number dans le programme officiel.');
}

/// Séquences DÉJÀ parcourues avant [current], dans l'ordre du programme.
///
/// Sert à distinguer les chapitres du programme actuel de ceux qui relèvent
/// d'une révision. La comparaison est ordinale : en septembre, aucune
/// séquence ne précède la première.
List<AcademicSequence> previousSequences(AcademicSequence current) {
  return <AcademicSequence>[
    for (final AcademicSequence sequence in officialProgram)
      if (sequence.number < current.number) sequence,
  ];
}
