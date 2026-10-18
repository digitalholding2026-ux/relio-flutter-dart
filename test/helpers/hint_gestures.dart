/// Gestes de test pour la fiche d'aide riche.
///
/// UN SEUL ENDROIT definit comment « demander un indice » se fait depuis un
/// test. Les tests historiques faisaient :
///
/// ```dart
/// await tester.tap(find.text(RelioStrings.askHint));
/// await tester.pumpAndSettle();
/// ```
///
/// Ce geste n'a plus le meme effet : le bouton ouvre une FICHE, et le libelle
/// change apres consommation. Un test qui enchaîne une action sur l'ecran
/// SANS refermer la fiche agirait sur le fond, pas sur la fiche.
///
/// [askHintAndClose] reproduit donc le parcours reel de l'eleve : il demande
/// l'indice, lit la fiche, puis la referme. Les tests qui consommaient
/// l'indice explicitement gardent leur propre code.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

/// Demande un indice, puis referme la fiche.
///
/// [label] est le libelle ATTENDU du bouton. Par defaut, le premier clic.
///
/// Utilise [RelioStrings.richHintUnderstood] pour refermer : c'est le meme
/// bouton que dans l'application, donc le test ne peut pas diverger de
/// l'interface sur ce point.
Future<void> askHintAndClose(
  WidgetTester tester, {
  String? label,
}) async {
  await tester.tap(find.text(label ?? RelioStrings.askHint));
  await tester.pumpAndSettle();

  // La fiche est ouverte. Si elle ne l'est pas, le test echouera ensuite sur
  // l'absence du bouton : mieux vaut une erreur explicite ici.
  expect(
    find.text(RelioStrings.richHintUnderstood),
    findsOneWidget,
    reason: 'la fiche d\'aide doit etre ouverte apres le clic',
  );

  await tester.tap(find.text(RelioStrings.richHintUnderstood));
  await tester.pumpAndSettle();
}

/// Demande un indice SANS refermer la fiche.
///
/// Pour les tests qui verifient l'etat de la fiche elle-meme.
Future<void> openHintSheet(WidgetTester tester, {String? label}) async {
  await tester.tap(find.text(label ?? RelioStrings.askHint));
  await tester.pumpAndSettle();
}

/// Libelle du bouton d'aide pour un index de clic donne.
///
/// Reproduit la suite des libelles a partir du nombre de fiches du budget
/// attendu : le test n'a ainsi pas a ecrire « Indice suivant » en dur, et
/// reste valide si l'interface renomme un libelle.
String hintLabelForClick(int click, int total) => switch (click) {
      0 => RelioStrings.askHint,
      _ when click == total - 1 => 'Indice final',
      _ => 'Indice suivant',
    };

/// Ignore les Icons, pour ne pas confondre la fleche de « Revoir l'exercice »
/// avec celle du retour S2.
///
/// La fleche du bouton de relecture est DANS le bouton, la fleche de retour est
/// dans l'AppBar : les deux portent `Icons.arrow_back`.
Finder backIconInAppBar() => find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.arrow_back),
    );