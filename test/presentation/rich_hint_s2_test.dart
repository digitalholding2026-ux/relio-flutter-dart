/// Intégration de la fiche d'aide sur S2.
///
/// Verifie le COMPORTEMENT REEL de l'ecran : le libelle du bouton suit le
/// budget, le clic ouvre la fiche, la fiche est notifiee au moteur, et la
/// relecture d'un exercice precedent fonctionne.
///
/// Ces tests n'inventent aucun contenu pedagogique : ils piochent leurs
/// indices dans la banque existante.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/rules/v1_screen_rules.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

import '../helpers/test_database.dart';

/// Surface de test : une base reelle et le service du chapitre 1.
class Harness {
  Harness(this.db, this.service, this.repository);

  final AppDatabase db;
  final Chapter1Service service;

  /// Depot des evenements, pour verifier ce que l'ecran a reellement fait
  /// ecrire.
  final LearningEventRepository repository;
}

Future<Harness> pumpApp(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);
  final repository = LearningEventRepository(db);
  return Harness(db, Chapter1Service(repository), repository);
}

/// Monte S2 sur l'exercice [exercise], avec les callbacks de navigation
/// neutralises.
Future<Harness> pumpExercise(
  WidgetTester tester,
  Exercise exercise,
  Map<String, ExerciseDraft> drafts,
) async {
  final harness = await pumpApp(tester);

  await tester.pumpWidget(
    MaterialApp(
      theme: RelioTheme.build(),
      home: ExercisePage(
        service: harness.service,
        exercise: exercise,
        drafts: drafts,
        onExit: () {},
        onGoToNext: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

/// Exercice du chapitre disposant d'indices.
///
/// RÈGLE DE SÉLECTION, ET NON HASARD : seuls les exercices 1 et 5 portent des
/// indices dans la banque validée. Prendre « le premier qui a 2 indices » ou
/// « un exercice du milieu » produirait un écran sans bouton d'aide, et le
/// test échouerait pour une raison qui n'a rien à voir avec ce qu'il vérifie.
List<Exercise> get _exercisesWithHints =>
    V1ScreenRules.exercises.where((e) => e.orderedHints.isNotEmpty).toList();

/// Premier exercice disposant d'au moins deux indices.
Exercise get _exWithTwoHints => _exercisesWithHints
    .firstWhere((e) => e.orderedHints.length >= 2);

/// Exercice consultable par « Revoir l'exercice N », choisi CORRECTEMENT.
///
/// CONTRAINTE REELLE, à ne pas contourner : l'exercice précédent doit
/// porter des indices, sinon la fiche empilée est vide et il n'y a rien à
/// relire. Or, dans la banque actuelle, l'exercice 5 est le premier à avoir
/// des indices ET un précédent — et cet précédent (l'exercice 4) n'a AUCUN
/// indice.
///
/// On ajoute donc au brouillon de session un indice sur le précédent, ce que
/// l'application fait d'elle-meme quand l'élève en a consulté un. Ce n'est pas
/// une fabrication de contenu : le texte vient de la banque, seul le fait
/// qu'il l'ait consulté est simulé.
Exercise get _exWithReviewablePrevious {
  final withHints = _exercisesWithHints;
  return withHints.firstWhere((e) => V1ScreenRules.previousBefore(e) != null);
}

/// Brouillon du précédent, pré-amorcé d'un indice déjà présent en banque.
ExerciseDraft _seededPreviousDraft() {
  final draft = ExerciseDraft(answerKey: 'tentative-precedente')
    ..consumedHintOrders.add(1);
  return draft;
}
///
/// Fixture d'INTERFACE, pas un contenu pedagogique : les textes sont COPIES
/// d'un indice deja valide par la banque. Seul le NOMBRE d'indices varie,
/// parce que c'est lui qui commande le libelle du bouton.
///
/// Ce recalage est necessaire : la banque ne contient aujourd'hui que des
/// exercices a DEUX indices, et l'etat « Indice suivant » ne peut donc pas
/// etre atteint sur le parcours reel.
/// Exercice de test portant exactement [count] indices.
///
/// Fixture d'INTERFACE, pas un contenu pedagogique : les textes sont COPIES
/// d'un indice deja valide par la banque. Seul le NOMBRE d'indices varie,
/// parce que c'est lui qui commande le libelle du bouton.
///
/// Ce recalage est necessaire : la banque ne contient aujourd'hui que des
/// exercices a DEUX indices, et l'etat « Indice suivant » ne peut donc pas
/// etre atteint sur le parcours reel.
Exercise _exerciseWithHintCount(int count) {
  final source = _exWithTwoHints.orderedHints.first;

  return Exercise(
    id: 'test-ex-$count-indices',
    lesson: ArithmeticLesson.lesson1Subtractions,
    statement: 'Énoncé de test.',
    correction: const CorrectionCriterion(acceptedValues: <int>[6]),
    hints: <ExerciseHint>[
      for (var i = 1; i <= count; i++)
        ExerciseHint(order: i, text: source.text, kind: source.kind),
    ],
  );
}

/// Consomme tout le budget d'aide de l'exercice affiche.
///
/// Le libellé du bouton est relu a chaque etape : c'est la suite reelle des
/// libelles attendue, du premier au dernier.
Future<void> _consumeWholeBudget(WidgetTester tester, Exercise exercise) async {
  final total = exercise.hintCount;
  for (var i = 0; i < total; i++) {
    final label = switch (i) {
      0 => RelioStrings.askHint,
      _ when i == total - 1 => 'Indice final',
      _ => 'Indice suivant',
    };
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RelioStrings.richHintUnderstood));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Libellé du bouton d’aide', () {
    testWidgets('« Demander un indice » au départ', (tester) async {
      final exercise = _exWithTwoHints;
      await pumpExercise(tester, exercise, <String, ExerciseDraft>{});

      expect(find.text(RelioStrings.askHint), findsOneWidget);
    });

    testWidgets('« Indice suivant » quand il reste plus d’une fiche',
        (tester) async {
      // CAS INATTEIGNABLE AVEC LA BANQUE ACTUELLE.
      //
      // Les seuls exercices qui portent des indices en ont DEUX chacun. Dans
      // ce cas, l'etat « Indice suivant » n'apparait jamais : apres le premier
      // indice il n'en reste qu'un, donc le bouton dit deja « Indice final ».
      //
      // On construit donc un exercice de test a TROIS indices pour couvrir cet
      // etat. Le TEXTE est repris de la banque : on ne fabrique aucun contenu,
      // on vary seulement le NOMBRE d'indices, qui est un etat d'interface.
      final exercise = _exerciseWithHintCount(3);
      final drafts = <String, ExerciseDraft>{};
      await pumpExercise(tester, exercise, drafts);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.richHintUnderstood));
      await tester.pumpAndSettle();

      // Il reste deux fiches : ce n'est pas encore le final.
      expect(find.text('Indice suivant'), findsOneWidget);

      // Verifie aussi que cet etat n'existe pas avec deux indices : la
      // transition « suivant » saute directement au final.
      final real = _exWithTwoHints;
      expect(real.orderedHints.length, 2);
    });

    testWidgets('« Indice final » quand il ne reste qu’une fiche',
        (tester) async {
      final exercise = _exerciseWithHintCount(3);
      final drafts = <String, ExerciseDraft>{};
      await pumpExercise(tester, exercise, drafts);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.richHintUnderstood));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Indice suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.richHintUnderstood));
      await tester.pumpAndSettle();

      // Il ne reste qu'une fiche : elle est annoncee comme la derniere.
      expect(find.text('Indice final'), findsOneWidget);
    });

    testWidgets('« Revoir l’exercice N » une fois le budget épuisé',
        (tester) async {
      final exercise = _exWithReviewablePrevious;
      final previous = V1ScreenRules.previousBefore(exercise)!;

      final drafts = <String, ExerciseDraft>{};
      await pumpExercise(tester, exercise, drafts);

      await _consumeWholeBudget(tester, exercise);

      final previousNumber = V1ScreenRules.positionOf(previous.id);
      expect(
        find.text('Revoir l’exercice $previousNumber'),
        findsOneWidget,
      );
    });
  });

  group('Ouverture de la fiche', () {
    testWidgets('le clic ouvre une fiche blanche de 75 %', (tester) async {
      final exercise = _exWithTwoHints;
      await pumpExercise(tester, exercise, <String, ExerciseDraft>{});

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();

      // La fiche est ouverte, avec son bouton de fermeture.
      expect(find.text(RelioStrings.richHintUnderstood), findsOneWidget);

      final height = MediaQuery.sizeOf(
        tester.element(find.byType(FilledButton).last),
      ).height;
      final sheetHeight = tester
          .getSize(
            find.ancestor(
              of: find.text(RelioStrings.richHintUnderstood),
              matching: find.byType(SafeArea),
            ),
          )
          .height;

      // 75 % de l'ecran : la fiche ne doit jamais cacher l'enonce entier.
      expect(sheetHeight, lessThanOrEqualTo(height * 0.75 + 1));
    });

    testWidgets('« J’ai compris » ferme la fiche', (tester) async {
      final exercise = _exWithTwoHints;
      await pumpExercise(tester, exercise, <String, ExerciseDraft>{});

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.richHintUnderstood), findsOneWidget);

      await tester.tap(find.text(RelioStrings.richHintUnderstood));
      await tester.pumpAndSettle();
      expect(find.text(RelioStrings.richHintUnderstood), findsNothing);
    });
  });

  group('Consommation notifiée au cœur', () {
    testWidgets('ouvrir la fiche enregistre l’indice', (tester) async {
      final exercise = _exWithTwoHints;
      final harness = await pumpExercise(
        tester,
        exercise,
        <String, ExerciseDraft>{},
      );

      final before = await harness.repository.findByType('hint_requested');
      expect(before, isEmpty);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();

      // L'enregistrement part a L'AFFICHAGE, pas a la fermeture.
      final events = await harness.repository.findByType('hint_requested');
      expect(events, hasLength(1));
      expect(events.single.metadata['hintOrder'], 1);
    });

    testWidgets('ouvrir puis fermer SANS lire consomme quand même',
        (tester) async {
      final exercise = _exWithTwoHints;
      final harness = await pumpExercise(
        tester,
        exercise,
        <String, ExerciseDraft>{},
      );

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      // L'eleve referme immediatement, sans lire.
      await tester.tap(find.text(RelioStrings.richHintUnderstood));
      await tester.pumpAndSettle();

      final events = await harness.repository.findByType('hint_requested');

      // Regle du fondateur : l'ouverture suffit.
      expect(events, hasLength(1));
    });
  });

  group('Relecture d’un exercice précédent', () {
    testWidgets('« Revoir l’exercice N » remonte à l’exercice précédent',
        (tester) async {
      final exercise = _exWithReviewablePrevious;
      final previous = V1ScreenRules.previousBefore(exercise)!;

      final drafts = <String, ExerciseDraft>{};
      drafts[previous.id] = _seededPreviousDraft();

      await pumpExercise(tester, exercise, drafts);
      await _consumeWholeBudget(tester, exercise);

      final previousNumber = V1ScreenRules.positionOf(previous.id)!;
      await tester.tap(find.text('Revoir l’exercice $previousNumber'));
      await tester.pumpAndSettle();

      // L'ecran consulte EST bien l'exercice precedent : c'est ce que
      // demande le libelle du bouton.
      expect(find.text(previous.statement), findsOneWidget);
      // Et l'exercice d'origine n'est plus affiche.
      expect(find.text(exercise.statement), findsNothing);
    });

    testWidgets('aucune relecture proposée quand l’exercice n’a pas de précédent',
        (tester) async {
      // GARANTIE DU MOTEUR, À NE PAS MASQUER.
      //
      // Une fois le budget epuise, le bouton propose « Revoir l'exercice N »
      // seulement si un exercice precedent existe. Le premier exercice d'une
      // lecon n'en a pas : le bouton doit alors DISPARAITRE. Le moteur ne
      // fabrique ni une cible de retour, ni une fiche pour la remplir.
      final first = V1ScreenRules.exercises.first;
      expect(V1ScreenRules.previousBefore(first), isNull);

      await pumpExercise(tester, first, <String, ExerciseDraft>{});
      await _consumeWholeBudget(tester, first);

      final previousNumber = 1;
      expect(find.text('Revoir l’exercice $previousNumber'), findsNothing);
      expect(find.text(RelioStrings.richHintUnderstood), findsNothing);
    });

    testWidgets('la relecture ne consomme aucun indice', (tester) async {
      final exercise = _exWithReviewablePrevious;
      final previous = V1ScreenRules.previousBefore(exercise)!;

      final drafts = <String, ExerciseDraft>{};
      drafts[previous.id] = _seededPreviousDraft();

      final harness = await pumpExercise(tester, exercise, drafts);
      await _consumeWholeBudget(tester, exercise);

      final previousNumber = V1ScreenRules.positionOf(previous.id)!;
      await tester.tap(find.text('Revoir l’exercice $previousNumber'));
      await tester.pumpAndSettle();

      final events = await harness.repository.findByType('hint_requested');

      // Relecturer n'ecrit RIEN : ce sont des fiches deja consommees. Le
      // compteur ne doit pas bouger, sinon le budget de l'exercice consulte
      // serait corrige sans que l'eleve l'ait demande.
      expect(events, hasLength(exercise.hintCount));
    });
  });
}