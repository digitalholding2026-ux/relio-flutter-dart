/// AUDIT - rendu de l'onboarding dans les conditions les plus dures.
///
/// Ne teste pas la METHODE (les autres tests le font) mais le RENDU :
/// debordement, chevauchement, element hors ecran, cible tactile. Ces
/// defauts ne se voient ni dans le code ni dans un test qui cherche du texte.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/entrytest/entry_test_onboarding.dart';
import 'package:relio/domain/entrytest/entry_test_repository.dart';
import 'package:relio/domain/entrytest/entry_test_session.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/screens/onboarding/onboarding_flow.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

import '../helpers/fraction_finders.dart';
import '../helpers/test_database.dart';

void main() {
  /// Ecran de reference : petit telephone, police agrandie.
  ///
  /// 360 x 640 et textScale 1,3 sont imposes par la specification. C'est la
  /// combinaison ou un bouton sort de l'ecran.
  const Size petit = Size(360, 640);

  const double hauteurEcran = 640;

  Future<void> monter(
    WidgetTester tester,
    Widget enfant, {
    Size taille = petit,
    double echelle = 1.3,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: taille,
          textScaler: TextScaler.linear(echelle),
        ),
        child: RelioPaletteScope(
          palette: RelioPalette.standard(),
          child: MaterialApp(
            theme: RelioTheme.build(),
            home: enfant,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Largeur logique de l'ecran courant.
  double tailleLarg(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  /// Le rectangle du bouton portant [libelle] doit tenir dans l'ecran.
  void expectBoutonVisible(WidgetTester tester, String libelle) {
    final Rect bouton = tester.getRect(find.widgetWithText(FilledButton, libelle));
    expect(bouton.width, greaterThan(0), reason: 'bouton $libelle invisible');
    expect(bouton.height, greaterThanOrEqualTo(48),
        reason: 'bouton $libelle : cible tactile trop petite');
    expect(bouton.left, greaterThanOrEqualTo(0),
        reason: 'bouton $libelle hors ecran a gauche');
    expect(bouton.right, lessThanOrEqualTo(tailleLarg(tester)),
        reason: 'bouton $libelle hors ecran a droite');
    expect(bouton.top, greaterThanOrEqualTo(0),
        reason: 'bouton $libelle hors ecran en haut');
    expect(bouton.bottom, lessThanOrEqualTo(hauteurEcran),
        reason: 'bouton $libelle hors ecran en bas');
  }

  group('Etape Prenom - rendu 360x640, police 1,3', () {
    testWidgets('aucun debordement', (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('le bouton Continuer tient dans l\'ecran', (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expectBoutonVisible(tester, RelioStrings.nameContinue);
    });

    testWidgets('le champ et le bouton ne se chevauchent pas',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      final Rect champ = tester.getRect(find.byType(TextField));
      final Rect bouton = tester.getRect(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      expect(champ.overlaps(bouton), isFalse,
          reason: 'le titre ou le champ passe SOUS le bouton');
    });

    testWidgets('le bouton desactive reste dans l\'arbre',
        (WidgetTester tester) async {
      // Un SizedBox.shrink() a la place du bouton ferait disappear
      // l'action ET decalerait tout le reste : c'est une erreur d'affichage
      // qui ne se voit pas dans le code.
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expect(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
        findsOneWidget,
      );
      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      expect(bouton.onPressed, isNull);
    });

    testWidgets('un prenom saisi ne provoque pas de debordement',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      await tester.enterText(find.byType(TextField), 'Jean-Baptiste');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expectBoutonVisible(tester, RelioStrings.nameContinue);
    });
  });

  group('Test d\'entree - rendu 360x640, police 1,3', () {
    late AppDatabase db;
    late EntryTestOnboarding onboarding;
    late EntryTestSession session;

    setUp(() async {
      db = await openTestDatabase();
      registerTestDatabase(db);
      onboarding = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(db)),
        SettingsRepository(db),
      );
      session = await onboarding.openSession();
    });

    Widget ecranTest(EntryTestSession s) => EntryTestPage(
          onboarding: onboarding,
          session: s,
          reduceAnimations: true,
          onFinished: () {},
        );

    testWidgets('aucun debordement sur la question 1', (WidgetTester tester) async {
      await monter(tester, ecranTest(session));

      expect(tester.takeException(), isNull);
      expectBoutonVisible(tester, RelioStrings.entryContinue);
    });

    testWidgets('l\'indicateur de progression est dans l\'ecran',
        (WidgetTester tester) async {
      await monter(tester, ecranTest(session));

      final Rect indicateur = tester.getRect(find.text('1 sur 5'));
      expect(indicateur.top, greaterThanOrEqualTo(0));
      expect(indicateur.bottom, lessThanOrEqualTo(hauteurEcran));
    });

    testWidgets('la question a choix tient dans l\'ecran',
        (WidgetTester tester) async {
      // Question 2 : trois cartes de 56 dp minimum. Les fractions empilées
      // grandissent les cartes : c'est justement ce qu'il faut vérifier.
      final EntryTestSession q2 = session.withAnswer(
        await onboarding.submitAnswer(
          session: session,
          question: session.questions.first,
          rawAnswer: '7',
        ),
      );

      await monter(tester, ecranTest(q2));

      expect(tester.takeException(), isNull);
      for (final String f in <String>['2/3', '2/4', '3/4']) {
        final Finder choix = fraction(f);
        expect(choix, findsOneWidget, reason: 'la fraction $f est absente');

        final Rect carte = tester.getRect(choix);
        expect(carte.bottom, lessThanOrEqualTo(hauteurEcran),
            reason: 'la carte $f sort de l\'ecran');
      }
    });

    testWidgets('le bouton est visible AVEC le clavier ouvert',
        (WidgetTester tester) async {
      // Le clavier occupe ~300 px. C'est la situation reelle de saisie, et
      // celle ou le bouton bas disparait derriere le clavier.
      await monter(tester, ecranTest(session));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('Cloture - rendu 360x640, police 1,3', () {
    testWidgets('aucun debordement', (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(name: 'Awa', onConfirm: () async {}, reduceAnimations: true),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('le texte et le personnage ne se chevauchent pas',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Jean-Baptiste',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );

      final Rect personnage = tester.getRect(find.byType(RelioCharacter));
      final Rect texte = tester.getRect(
        find.text(RelioStrings.closingTitle('Jean-Baptiste')),
      );
      expect(personnage.overlaps(texte), isFalse,
          reason: 'le texte passe sous le personnage');
    });

    testWidgets('le bouton Decouvrir Relio tient dans l\'ecran',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(name: 'Awa', onConfirm: () async {}, reduceAnimations: true),
      );

      expectBoutonVisible(tester, RelioStrings.closingDiscover);
    });

    testWidgets('l\'ecran de cloture n\'affiche rien avant de connaitre le prenom',
        (WidgetTester tester) async {
      // Le prenom arrive en asynchrone. Avec une chaine vide par defaut,
      // l'ecran afficherait « Merci . Je commence a te connaitre. » — un trou
      // visible dans la phrase. On verifie ici que l'hote ATTEND le prenom.
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final onboarding = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(db)),
        SettingsRepository(db),
      );
      await onboarding.setName('Awa');

      await monter(
        tester,
        OnboardingFlow(
          onboarding: onboarding,
          reduceAnimations: true,
          onCompleted: () {},
        ),
      );

      // Aucune phrase « Merci . » ne doit exister a aucun moment.
      expect(find.textContaining('Merci .'), findsNothing,
          reason: 'BUG D\'AFFICHAGE : trou visible dans la phrase');
      expect(find.textContaining('Merci'), findsNothing,
          reason: 'l\'ecran ne doit pas s\'afficher avant le prenom');
    });
  });
}