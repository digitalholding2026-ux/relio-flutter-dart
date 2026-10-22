/// Programme officiel de la 3e — données statiques.
///
/// SOURCE : la consigne produit « Option 2 — L'onglet Révision intelligent »
/// (22/10/2026). Les six séquences, leurs intitulés, leurs trimestres et
/// leurs chapitres sont transcrits **tels quels** : aucun chapitre n'est
/// ajouté, retiré ni reformulé ici (règle 8).
///
/// Ces données ne disent rien de l'élève : elles décrivent le programme. La
/// projection personnelle (faiblesses, exercices disponibles) est calculée
/// séparément dans `revision_plan.dart`, à partir des faits d'apprentissage.
///
/// Branchement futur : le jour où le moteur exposera le programme par API,
/// [officialProgram] sera remplacé par la réponse du moteur sans changer les
/// types ([AcademicSequence], [SequencePeriod]) ni les écrans qui les lisent.
library;

/// Trimestre auquel appartient une séquence.
enum SequencePeriod {
  /// Premier trimestre de l'année scolaire.
  trimestre1,

  /// Deuxième trimestre.
  trimestre2,

  /// Troisième trimestre.
  trimestre3,
}

/// Une séquence du programme officiel.
class AcademicSequence {
  /// Crée une séquence.
  const AcademicSequence({
    required this.number,
    required this.title,
    required this.period,
    required this.chapters,
  });

  /// Numéro de la séquence, de 1 à 6.
  final int number;

  /// Intitulé affiché, avec sa période : « Séquence 1 (Septembre - Octobre) ».
  final String title;

  /// Trimestre de rattachement.
  final SequencePeriod period;

  /// Chapitres enseignés pendant la séquence, dans l'ordre du programme.
  final List<String> chapters;
}

/// Les six séquences de l'année, dans l'ordre.
const List<AcademicSequence> officialProgram = <AcademicSequence>[
  AcademicSequence(
    number: 1,
    title: 'Séquence 1 (Septembre - Octobre)',
    period: SequencePeriod.trimestre1,
    chapters: <String>[
      'Arithmétique',
      'Théorème de Thalès',
      'Nombres réels (bases)',
    ],
  ),
  AcademicSequence(
    number: 2,
    title: 'Séquence 2 (Octobre - Novembre)',
    period: SequencePeriod.trimestre1,
    chapters: <String>['Nombres réels (suite)', 'Trigonométrie'],
  ),
  AcademicSequence(
    number: 3,
    title: 'Séquence 3 (Décembre - Janvier)',
    period: SequencePeriod.trimestre2,
    chapters: <String>['Calcul littéral', 'Sections de cônes et pyramides'],
  ),
  AcademicSequence(
    number: 4,
    title: 'Séquence 4 (Janvier - Mars)',
    period: SequencePeriod.trimestre2,
    chapters: <String>['Vecteurs', 'Équations et inéquations'],
  ),
  AcademicSequence(
    number: 5,
    title: 'Séquence 5 (Mars - Mai)',
    period: SequencePeriod.trimestre3,
    chapters: <String>[
      'Angles inscrits',
      'Polygones réguliers',
      'Statistiques',
      'Homothétie',
    ],
  ),
  AcademicSequence(
    number: 6,
    title: 'Séquence 6 (Mai - Juin)',
    period: SequencePeriod.trimestre3,
    chapters: <String>['Applications linéaires et affines'],
  ),
];
