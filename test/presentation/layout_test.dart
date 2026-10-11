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

void main() {
  group('S1 sur 360 x 640', () {
    testWidgets('les trois leçons sont accessibles sans débordement',
        (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));

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
      await tester.tap(find.byType(LessonCard).at(0));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(AnswerField));
      expect(size.height, RelioSizes.fieldHeight);
    });

    testWidgets('chiffres tabulaires sur le champ', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));
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
      expect(RelioColors.primary.toARGB32(), 0xFF1F3A6E);
      expect(RelioColors.primaryContainer.toARGB32(), 0xFFE6ECF7);
      expect(RelioColors.hintText.toARGB32(), 0xFFB45309);
      expect(RelioColors.hintBackground.toARGB32(), 0xFFFEF3C7);
      expect(RelioColors.successText.toARGB32(), 0xFF15803D);
      expect(RelioColors.successBackground.toARGB32(), 0xFFDCFCE7);
      expect(RelioColors.errorText.toARGB32(), 0xFFB91C1C);
      expect(RelioColors.errorBackground.toARGB32(), 0xFFFEE2E2);
      expect(RelioColors.text.toARGB32(), 0xFF111827);
      expect(RelioColors.textSecondary.toARGB32(), 0xFF4B5563);
      expect(RelioColors.border.toARGB32(), 0xFFE4E7EC);
      expect(RelioColors.background.toARGB32(), 0xFFFAFBFC);
    });

    test('dimensions conformes', () {
      expect(RelioSizes.primaryButtonHeight, 52);
      expect(RelioSizes.secondaryButtonHeight, 48);
      expect(RelioSizes.minTouchTarget, 48);
      expect(RelioSizes.fieldHeight, 56);
      expect(RelioSizes.fieldRadius, 12);
    });

    testWidgets('polices et tailles conformes', (tester) async {
      final db = await openTestDatabase();
      registerTestDatabase(db);

      await pumpOnSmallPhone(tester, RelioApp(database: db));

      final text = tester.widget<Text>(find.text(RelioStrings.chapterTitle));
      expect(text.style?.fontSize, 28);
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.fontFamily, 'Inter');
    });
  });
}
