/// Tests du VERROUILLAGE du champ après validation, écran S2.
///
/// Règle testée : dès qu'un panneau de retour est affiché, le champ et
/// « Valider » sont verrouillés, et la seule action possible est celle du
/// panneau.
///
/// Ces tests sont purement d'INTERFACE : aucun état n'est ajouté au moteur,
/// la classification et le contenu mathématique sont inchangés.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/domain/curriculum/chapter1_service.dart';
import 'package:relio/domain/curriculum/hint_trajectory.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/screens/exercise_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';
import '../helpers/hint_gestures.dart';

/// Ouvre l'application reelle et aboutit sur le premier exercice de la
/// lecon 1 (PGCD de 18 et 12).
///
/// On utilise le VRAI parcours et non un ExercisePage isole : le cas limite
/// « retour par l'AppBar » exige que la navigation existe reellement.
///
/// L'application ouvre sur ACCUEIL : S1 s'atteint par l'onglet Apprendre
/// puis la carte du chapitre 1.
Future<AppDatabase> ouvrirParcours(WidgetTester tester) async {
  final db = await openTestDatabase();
  registerTestDatabase(db);
  await tester.pumpWidget(RelioApp(database: db, showIntro: false));
  await tester.pumpAndSettle();

  await tester.tap(find.text(RelioStrings.tabLearn).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(RelioStrings.chapter1CardTitle));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(LessonCard).at(0));
  await tester.pumpAndSettle();
  return db;
}

TextField champ(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

/// Saisit une réponse puis valide.
Future<void> repondre(WidgetTester tester, String reponse) async {
  await tester.enterText(find.byType(TextField), reponse);
  await tester.pump();
  await tester.tap(find.text(RelioStrings.validate));
  await tester.pumpAndSettle();
}

/// Amène un bouton du panneau dans la zone visible avant de le taper.
/// Le panneau vit dans une zone défilante : sans cela, le tap peut porter
/// sur la barre d'action et ne jamais atteindre le bouton.
Future<void> taperPanneau(WidgetTester tester, String libelle) async {
  final cible = find.text(libelle);
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Bouton de la barre d'action portant ce libellé.
Widget boutonAction(WidgetTester tester, String libelle) => tester.widget(
      find.ancestor(of: find.text(libelle), matching: find.byType(TextButton)),
    );

FilledButton boutonValider(WidgetTester tester) => tester.widget(
      find.ancestor(
        of: find.text(RelioStrings.validate),
        matching: find.byType(FilledButton),
      ),
    );

void main() {
  group('Verrouillage après validation', () {
    testWidgets('le champ devient non éditable', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      expect(champ(tester).readOnly, isTrue);
    });

    testWidgets('le champ affiche TOUJOURS la valeur saisie', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      // L'eleve doit pouvoir relire sa reponse pour comprendre le retour.
      expect(champ(tester).controller!.text, '6');
    });

    testWidgets('la sélection et le copier-coller sont bloqués', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      expect(champ(tester).enableInteractiveSelection, isFalse,
          reason: 'sans cela, un appui long proposerait encore « Copier »');
    });

    testWidgets('un tap sur le champ verrouillé ne fait RIEN', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      final avant = champ(tester).controller!.text;

      // Le tap ne doit produire : ni focus, ni clavier, ni message.
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(champ(tester).focusNode!.hasFocus, isFalse,
          reason: 'un champ verrouille ne doit jamais prendre le focus');
      expect(champ(tester).controller!.text, avant);
      expect(find.text(RelioStrings.emptyAnswerInline), findsNothing,
          reason: 'aucun message ne doit apparaitre');
    });

    testWidgets('aucune saisie n\'est acceptée après validation', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      await tester.enterText(find.byType(TextField), '42');
      await tester.pumpAndSettle();

      expect(champ(tester).controller!.text, '6',
          reason: 'la reponse figee ne doit pas pouvoir etre remplacee');
    });

    testWidgets('« Valider » reste visible mais désactivé', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      expect(boutonValider(tester).onPressed, isNull);
      // Structure de la barre d'action inchangee : le bouton ne disparait pas.
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('le clavier est fermé dès l\'apparition du panneau',
        (tester) async {
      await ouvrirParcours(tester);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pump();
      expect(champ(tester).focusNode!.hasFocus, isTrue,
          reason: 'precondition : le champ avait le focus pendant la saisie');

      await tester.tap(find.text(RelioStrings.validate));
      await tester.pump();

      expect(champ(tester).focusNode!.hasFocus, isFalse,
          reason: 'aucun etat intermediaire ne doit laisser un clavier ouvert '
              'au-dessus d\'un champ verrouille');
      await tester.pumpAndSettle();
    });
  });

  group('« Demander un indice » est neutralisé', () {
    testWidgets('le bouton reste visible mais désactivé', (tester) async {
      await ouvrirParcours(tester);

      // L'exercice 1 a DEUX indices : il en reste un a la validation.
      expect(find.text(RelioStrings.askHint), findsOneWidget);
      await repondre(tester, '6');

      final bouton = boutonAction(tester, RelioStrings.askHint);
      expect((bouton as TextButton).onPressed, isNull);
      expect(find.text(RelioStrings.askHint), findsOneWidget,
          reason: 'le disparaitre modifierait la barre d\'action');
    });

    testWidgets('aucun indice n\'est ajouté après validation', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      expect(find.text(RelioStrings.hintLabel(1)), findsNothing);
      expect(find.text(RelioStrings.hintLabel(2)), findsNothing);
    });

    testWidgets('sur l\'exercice sans indice, le bouton reste absent',
        (tester) async {
      // Leçon 3 : aucune fiche n'y a été rédigée, le bouton n'a donc pas
      // lieu d'être. L'exercice est monté directement, le parcours séquentiel
      // ne mène pas jusqu'à la leçon 3.
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final service = Chapter1Service(LearningEventRepository(db));
      await tester.pumpWidget(MaterialApp(
        home: ExercisePage(
          service: service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex8)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.askHint), findsNothing);
    });
  });

  group('Retour AppBar — l\'état quitté est conservé', () {
    testWidgets('le panneau, la valeur et le verrouillage reviennent',
        (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');
      expect(find.text(RelioStrings.successTitle), findsOneWidget);

      // L'eleve quitte S2 par la fleche de l'AppBar...
      await tester.tap(find.byTooltip(RelioStrings.back));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterAccessPage), findsOneWidget);

      // ...et rouvre le meme exercice.
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.successTitle), findsOneWidget,
          reason: 'le retour pedagogique ne doit pas disparaitre');
      expect(champ(tester).controller!.text, '6');
      expect(champ(tester).readOnly, isTrue);
    });

    testWidgets('rouvrir n\'impose aucune nouvelle tentative', (tester) async {
      final db = await ouvrirParcours(tester);
      await repondre(tester, '6');
      expect(
        await LearningEventRepository(db).findByType(kAttemptEventType),
        hasLength(1),
      );

      await tester.tap(find.byTooltip(RelioStrings.back));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      expect(
        await LearningEventRepository(db).findByType(kAttemptEventType),
        hasLength(1),
        reason: 'rouvrir un exercice verrouille ne doit rien resoumettre',
      );
    });
  });

  group('Déverrouillage', () {
    testWidgets('« Exercice suivant » vide, déverrouille et reprend le focus',
        (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      await taperPanneau(tester, RelioStrings.nextExercise);

      // On est desormais sur l'exercice 2.
      expect(champ(tester).controller!.text, isEmpty);
      expect(champ(tester).readOnly, isFalse);
      expect(champ(tester).focusNode!.hasFocus, isTrue,
          reason: 'le focus revient sur le champ du nouvel exercice');
    });

    testWidgets('« Réessayer » vide, déverrouille et reprend le focus',
        (tester) async {
      await ouvrirParcours(tester);
      await askHintAndClose(tester);
      await repondre(tester, '9');

      expect(find.text(RelioStrings.noInformation), findsOneWidget);

      await taperPanneau(tester, RelioStrings.retry);

      expect(champ(tester).controller!.text, isEmpty);
      expect(champ(tester).readOnly, isFalse);
      expect(champ(tester).focusNode!.hasFocus, isTrue);
      expect(find.text(RelioStrings.noInformation), findsNothing,
          reason: 'le panneau doit etre masque');
      expect(find.text(RelioStrings.hintLabel(1)), findsNothing,
          reason: 'les indices deja consultes sont effaces');
    });

    testWidgets('après « Réessayer », le champ accepte de nouveau la saisie',
        (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '9');
      await taperPanneau(tester, RelioStrings.retry);

      await tester.enterText(find.byType(TextField), '6');
      await tester.pumpAndSettle();

      expect(champ(tester).controller!.text, '6');
      await repondre(tester, '6');
      expect(find.text(RelioStrings.successAutonomous), findsOneWidget,
          reason: 'la nouvelle tentative est evaluee comme autonome : le '
              'verrouillage n\'a rien laisse derriere lui');
    });
  });

  group('Comportement identique sur les cinq panneaux', () {
    void verifierVerrouillage(WidgetTester tester) {
      expect(champ(tester).readOnly, isTrue);
      expect(boutonValider(tester).onPressed, isNull);
      // « Valider » reste present : c'est sa disponibilite qui change,
      // pas la structure de la barre d'action.
      expect(find.text(RelioStrings.validate), findsOneWidget);
    }

    testWidgets('panneau A — réussite autonome', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '6');

      expect(find.text(RelioStrings.successAutonomous), findsOneWidget);
      verifierVerrouillage(tester);
    });

    testWidgets('panneau B — réussite assistée', (tester) async {
      await ouvrirParcours(tester);
      await askHintAndClose(tester);
      await repondre(tester, '6');

      expect(find.text(RelioStrings.successAssisted), findsOneWidget);
      verifierVerrouillage(tester);
    });

    testWidgets('panneau E — erreur sans information', (tester) async {
      await ouvrirParcours(tester);
      await repondre(tester, '9');

      expect(find.text(RelioStrings.noInformation), findsOneWidget);
      verifierVerrouillage(tester);
    });

    testWidgets('panneau « non évaluable »', (tester) async {
      // Atteignable sur l'exercice 10, a clavier alphanumerique.
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final service = Chapter1Service(LearningEventRepository(db));
      await tester.pumpWidget(MaterialApp(
        home: ExercisePage(
          service: service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex10)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();
      await repondre(tester, 'xyz');

      expect(find.text(RelioStrings.notRecognised), findsOneWidget);
      verifierVerrouillage(tester);
    });

    testWidgets('panneau « non concluant » — exercice 11', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final service = Chapter1Service(LearningEventRepository(db));
      await tester.pumpWidget(MaterialApp(
        home: ExercisePage(
          service: service,
          exercise: Chapter1Bank.findExercise(ExerciseIds.ex11)!,
          drafts: <String, ExerciseDraft>{},
          onExit: () {},
          onGoToNext: () {},
        ),
      ));
      await tester.pumpAndSettle();
      await repondre(tester, '24');

      expect(find.text(RelioStrings.inconclusive), findsOneWidget);
      verifierVerrouillage(tester);
    });
  });

  group('Aucun changement de structure de la barre d\'action', () {
    testWidgets('la taille de « Valider » est identique avant et après',
        (tester) async {
      await ouvrirParcours(tester);

      final avant = tester.getSize(
        find.ancestor(
          of: find.text(RelioStrings.validate),
          matching: find.byType(FilledButton),
        ),
      );

      await repondre(tester, '6');

      final apres = tester.getSize(
        find.ancestor(
          of: find.text(RelioStrings.validate),
          matching: find.byType(FilledButton),
        ),
      );

      expect(apres.height, avant.height,
          reason: '« Valider » ne doit ni disparaitre ni changer de taille');
      expect(apres.width, avant.width);
    });
  });

  group('Le moteur n\'a pas bougé', () {
    testWidgets('le verrouillage n\'écrit aucun événement supplémentaire',
        (tester) async {
      final db = await ouvrirParcours(tester);
      await repondre(tester, '6');
      final avant =
          await LearningEventRepository(db).findByType(kAttemptEventType);

      // Interactions variees sur un champ verrouille.
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.validate), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        await LearningEventRepository(db).findByType(kAttemptEventType),
        hasLength(avant.length),
      );
    });

    test('la classification reste celle du moteur', () {
      // Rappel non-regression : le verrouillage est une regle d'ecran, il
      // ne redefinit aucun statut pedagogique.
      expect(AttemptClassification.autonomousSuccess.name, 'autonomousSuccess');
      expect(AttemptClassification.assistedSuccess.name, 'assistedSuccess');
    });
  });
}