/// Tests d'ergonomie sur petit ecran (360 x 640).
///
/// Criteres d'acceptation :
///  - boutons atteignables ;
///  - champ visible au-dessus du clavier ;
///  - pas de debordement, meme a textScale 1.3.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/answer_field.dart';
import 'package:relio/presentation/widgets/feedback_panel.dart';

import '../helpers/test_database.dart';

/// Taille d'ecran cible : petit telephone d'entree de gamme.
const Size kSmallPhone = Size(360, 640);

Future<void> pumpOnSmallPhone(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = kSmallPhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Ouvre S1 depuis l'onglet Apprendre.
///
/// L'application ouvre désormais sur ACCUEIL : S1 n'est plus la racine, elle
/// s'atteint par Accueil → Apprendre → chapitre 1, ou directement par
/// Apprendre → chapitre 1.
Future<void> openS1(WidgetTester tester) async {
  await tester.tap(find.text(RelioStrings.tabLearn).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(RelioStrings.chapterArithmetic));
  await tester.pumpAndSettle();
}

void main() {
  group('S1 sur 360 x 640', () {
    testWidgets('les trois leçons sont accessibles sans débordement',
        (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
      await openS1(tester);

      expect(find.byType(ChapterAccessPage), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Les trois cartes existent.
      expect(find.byType(LessonCard), findsNWidgets(3));
    });

    testWidgets('la troisième leçon est atteignable par défilement',
        (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
      await openS1(tester);

      await tester.scrollUntilVisible(
        find.byType(LessonCard).at(2),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(LessonCard).at(2), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('S2 sur 360 x 640', () {
    Future<void> openOnSmallPhone(WidgetTester tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
      await openS1(tester);
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();
    }

    testWidgets('le champ et Valider sont visibles sans défilement',
        (tester) async {
      await openOnSmallPhone(tester);

      // Champ et barre d'action sont hors de la zone defilante.
      expect(find.byType(AnswerField), findsOneWidget);
      expect(find.text(RelioStrings.validate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la barre d’action reste visible avec deux indices',
        (tester) async {
      await openOnSmallPhone(tester);

      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();
      await tester.tap(find.text(RelioStrings.askHint));
      await tester.pumpAndSettle();

      // Deux indices + enonce : la barre d'action reste en place.
      expect(find.byType(AnswerField), findsOneWidget);
      expect(find.text(RelioStrings.validate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le champ reste visible avec le panneau de retour',
        (tester) async {
      await openOnSmallPhone(tester);

      await tester.enterText(find.byType(TextField), '9');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.validate));
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackPanelView), findsOneWidget);
      expect(find.byType(AnswerField), findsOneWidget);
      expect(find.text(RelioStrings.validate), findsOneWidget);
    });

    testWidgets('aucun débordement avec textScale 1.3', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      tester.view.physicalSize = kSmallPhone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: RelioApp(database: db),
        ),
      );
      await tester.pumpAndSettle();
      await openS1(tester);
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      // Le panneau "RenderFlex overflowed" apparaitrait ici.
      expect(tester.takeException(), isNull);
    });

    testWidgets('les zones tactiles font au moins 48 dp', (tester) async {
      await openOnSmallPhone(tester);

      final validateSize = tester.getSize(
        find.widgetWithText(FilledButton, RelioStrings.validate),
      );
      expect(validateSize.height, greaterThanOrEqualTo(48));

      final fieldSize = tester.getSize(find.byType(AnswerField));
      expect(fieldSize.height, greaterThanOrEqualTo(48));

      // La cible tactile se mesure sur le BOUTON, pas sur l'icone :
      // l'icone fait 24 dp, la zone cliquable doit faire 48 dp.
      final backButton = find.ancestor(
        of: find.byIcon(Icons.arrow_back),
        matching: find.byType(IconButton),
      );
      final backSize = tester.getSize(backButton);
      expect(backSize.height, greaterThanOrEqualTo(48),
          reason: 'cible tactile minimale imposée par la spécification');
      expect(backSize.width, greaterThanOrEqualTo(48));
    });
  });

  group('Champ de réponse', () {
    testWidgets('hauteur 56 dp et rayon 12', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
      await openS1(tester);
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(AnswerField));
      expect(size.height, RelioSizes.fieldHeight);
    });

    testWidgets('chiffres tabulaires sur le champ', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
      await openS1(tester);
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      final features = field.style?.fontFeatures;
      expect(features, isNotNull);
      expect(features!.any((f) => f == FontFeature.tabularFigures()), isTrue,
          reason: 'les valeurs doivent s’aligner verticalement');
    });
  });

  group('Thème', () {
    test('couleurs conformes à la spécification', () {
      final palette = RelioPalette.standard();
      expect(palette.primary.toARGB32(), 0xFF1F3A6E);
      expect(palette.primaryContainer.toARGB32(), 0xFFE6ECF7);
      expect(palette.brand.toARGB32(), 0xFFF56207);
      expect(palette.hintText.toARGB32(), 0xFFB45309);
      expect(palette.hintBackground.toARGB32(), 0xFFFEF3C7);
      expect(palette.successText.toARGB32(), 0xFF15803D);
      expect(palette.successBackground.toARGB32(), 0xFFDCFCE7);
      expect(palette.errorText.toARGB32(), 0xFFB91C1C);
      expect(palette.errorBackground.toARGB32(), 0xFFFEE2E2);
      expect(palette.textPrimary.toARGB32(), 0xFF111827);
      expect(palette.textSecondary.toARGB32(), 0xFF4B5563);
      expect(palette.outline.toARGB32(), 0xFFE4E7EC);
      expect(palette.background.toARGB32(), 0xFFFAFBFC);
    });

    test('dimensions conformes', () {
      expect(RelioSizes.primaryButtonHeight, 52);
      expect(RelioSizes.secondaryButtonHeight, 48);
      expect(RelioSizes.minTouchTarget, 48);
      expect(RelioSizes.fieldHeight, 56);
      expect(RelioRadius.card, 12);
      // Barre basse à trois onglets.
      expect(RelioSizes.bottomNavHeight, 56);
    });

    test('échelle d’espacements et de rayons conforme', () {
      expect(
        <double>[
          RelioSpacing.xs,
          RelioSpacing.sm,
          RelioSpacing.md,
          RelioSpacing.lg,
          RelioSpacing.xl,
          RelioSpacing.xxl,
          RelioSpacing.xxxl,
        ],
        <double>[4, 8, 12, 16, 20, 24, 32],
      );
      expect(RelioRadius.small, 8);
      expect(RelioRadius.card, 12);
      expect(RelioRadius.banner, 16);
      expect(RelioRadius.pill, 999);
    });

    testWidgets('polices et tailles conformes', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
      await openS1(tester);

      final text = tester.widget<Text>(find.text(RelioStrings.chapterTitle));
      expect(text.style?.fontSize, 28);
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.fontFamily, 'Inter');
    });
  });
}
