/// Refonte du parcours d'entrée — verrous de composition.
///
/// Ces tests verrouillent les critères d'acceptation de la mission :
/// tailles de marque par écran, bouton indigo sans contour, pastilles de
/// progression, bouton ancré en bas, absence de `spaceBetween`, transitions
/// en fondu 250–300 ms, tap pour sauter l'ouverture, aucun AppBar.
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
import 'package:relio/presentation/branding/relio_mark.dart';
import 'package:relio/presentation/screens/intro/opening_page.dart';
import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/entry_kit.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_intro_page.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/screens/onboarding/onboarding_metrics.dart';
import 'package:relio/presentation/screens/onboarding/welcome_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

import '../helpers/test_database.dart';

/// Monte un écran à la taille de référence, police à 1,3.
Future<void> monter(WidgetTester tester, Widget enfant) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    RelioPaletteScope(
      palette: RelioPalette.standard(),
      child: MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: enfant,
      ),
    ),
  );
  await tester.pump();
}

/// Aucune colonne de mise en page n'utilise `spaceBetween`.
///
/// Seules les colonnes pleine largeur sont vérifiées : les colonnes internes
/// des composants ne portent pas la mise en page de l'écran.
void expectPasDeSpaceBetween(WidgetTester tester) {
  for (final Column colonne
      in tester.widgetList<Column>(find.byType(Column))) {
    double largeur;
    try {
      largeur = tester.getRect(find.byWidget(colonne)).width;
    } catch (_) {
      continue;
    }
    if (largeur < 300) continue;
    expect(
      colonne.mainAxisAlignment,
      isNot(MainAxisAlignment.spaceBetween),
      reason: 'colonne de ${largeur.toStringAsFixed(0)} dp : '
          'le bouton doit être ancré en bas, pas réparti',
    );
  }
}

/// Le bouton portant [libelle] est ancré en bas, dans l'écran.
void expectBoutonAncreEnBas(WidgetTester tester, String libelle) {
  final Rect bouton = tester.getRect(
    find.widgetWithText(FilledButton, libelle),
  );
  expect(bouton.bottom, lessThanOrEqualTo(640),
      reason: 'le bouton sort de l\'écran');
  expect(bouton.bottom, greaterThanOrEqualTo(640 - 48),
      reason: 'le bouton flotte dans un espace vide au lieu d\'être ancré');
}

void main() {
  group('Niveaux de présence de la marque', () {
    testWidgets('ouverture : 160 dp, aucun texte', (tester) async {
      await monter(
        tester,
        OpeningPage(onFinished: () async {}, reduceAnimations: true),
      );

      expect(tester.getSize(find.byType(RelioMark)).width, EntryBrand.opening);
      // Aucun texte : ni titre, ni mot de marque, ni signature.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('bienvenue : 100 dp', (tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      expect(tester.getSize(find.byType(RelioMark)).width, EntryBrand.welcome);
    });

    testWidgets('explication : 80 dp', (tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
      );

      expect(tester.getSize(find.byType(RelioMark)).width, EntryBrand.intro);
    });

    testWidgets('prénom : 64 dp', (tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expect(tester.getSize(find.byType(RelioCharacter)).width, EntryBrand.name);
    });

    testWidgets('clôture : 120 dp', (tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );

      expect(tester.getSize(find.byType(RelioCharacter)).width, EntryBrand.closing);
    });
  });

  group('Bouton indigo, sans contour', () {
    testWidgets('état normal : fond navy, aucun contour',
        (tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      final ButtonStyle? style = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, RelioStrings.welcomeStart),
          )
          .style;
      expect(
        style?.backgroundColor?.resolve(<WidgetState>{}),
        RelioBrand.wordmark,
      );
      expect(
        style?.side?.resolve(<WidgetState>{}),
        BorderSide.none,
      );
    });

    testWidgets('état désactivé : fond 40 %, texte 60 %, sans contour',
        (tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      final ButtonStyle? style = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, RelioStrings.nameContinue),
          )
          .style;
      expect(
        style?.backgroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        RelioBrand.wordmark.withValues(alpha: 0.4),
      );
      expect(
        style?.foregroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        Colors.white.withValues(alpha: 0.6),
      );
      expect(
        style?.side?.resolve(<WidgetState>{WidgetState.disabled}),
        BorderSide.none,
      );
    });
  });

  group('Écran de test', () {
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

    Future<void> monterTest(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RelioPaletteScope(
          palette: RelioPalette.standard(),
          child: MaterialApp(
            home: EntryTestPage(
              onboarding: onboarding,
              session: session,
              reduceAnimations: true,
              onFinished: () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('mark de 24 dp et cinq pastilles sur la barre',
        (tester) async {
      await monterTest(tester);

      expect(tester.getSize(find.byType(RelioCharacter)).width, EntryBrand.test);

      final int pastilles = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) =>
              (c.decoration as BoxDecoration?)?.shape == BoxShape.circle)
          .length;
      expect(pastilles, 5);
    });

    testWidgets('« N sur 5 » reste, en Caption sous la barre',
        (tester) async {
      await monterTest(tester);

      final Finder caption = find.text('1 sur 5');
      expect(caption, findsOneWidget);
      expect(
        tester.widget<Text>(caption).style?.fontSize,
        RelioType.caption(RelioPalette.standard()).fontSize,
      );
    });
  });

  group('Grille commune', () {
    testWidgets('bienvenue : pas de spaceBetween, bouton ancré',
        (tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      expectPasDeSpaceBetween(tester);
      expectBoutonAncreEnBas(tester, RelioStrings.welcomeStart);
    });

    testWidgets('explication : pas de spaceBetween, bouton ancré',
        (tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
      );

      expectPasDeSpaceBetween(tester);
      expectBoutonAncreEnBas(tester, RelioStrings.entryIntroStart);
    });

    testWidgets('prénom : pas de spaceBetween, bouton ancré',
        (tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expectPasDeSpaceBetween(tester);
      expectBoutonAncreEnBas(tester, RelioStrings.nameContinue);
    });

    testWidgets('clôture : pas de spaceBetween, bouton ancré',
        (tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );

      expectPasDeSpaceBetween(tester);
      expectBoutonAncreEnBas(tester, RelioStrings.closingDiscover);
    });
  });

  group('Transitions et navigation', () {
    test('le fondu croisé dure 250–300 ms', () {
      expect(OnboardingMetrics.entryTransitionMs,
          greaterThanOrEqualTo(250));
      expect(OnboardingMetrics.entryTransitionMs, lessThanOrEqualTo(300));
    });

    testWidgets('un tap sur l\'ouverture saute à l\'écran suivant',
        (tester) async {
      var fini = false;
      await monter(
        tester,
        OpeningPage(
          onFinished: () async => fini = true,
          reduceAnimations: true,
        ),
      );

      await tester.tapAt(const Offset(180, 320));
      await tester.pump();

      expect(fini, isTrue,
          reason: 'la transition est interruptible par tap');
    });

    testWidgets('aucun AppBar sur les écrans du parcours', (tester) async {
      for (final Widget ecran in <Widget>[
        OpeningPage(onFinished: () async {}, reduceAnimations: true),
        WelcomePage(onStart: () async {}, reduceAnimations: true),
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      ]) {
        await monter(tester, ecran);
        expect(find.byType(AppBar), findsNothing);
      }
    });
  });
}
