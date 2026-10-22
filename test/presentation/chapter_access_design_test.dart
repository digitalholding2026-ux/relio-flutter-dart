/// S1 — design de la vue des leçons du chapitre 1.
///
/// Ce que ces tests protègent, au-delà du simple contenu :
///  - le fond indigo très pâle et la carte blanche à arrondi 16 ;
///  - le titre de leçon en 18 / SemiBold et le chevron de navigation ;
///  - l'état vide : trois leçons « À commencer », décomptes à zéro ;
///  - l'effet d'appui sur toute la surface ;
///  - aucun débordement à 360 × 640 avec un texte agrandi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/exercise.dart';
import 'package:relio/presentation/home/home_state.dart';
import 'package:relio/presentation/home/pressable_scale.dart';
import 'package:relio/presentation/learn/learn_state.dart';
import 'package:relio/presentation/screens/chapter_access_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/lesson_status_pill.dart';
import 'package:relio/presentation/widgets/relio_progress_bar.dart';

/// Affiche S1 assez haut pour que les trois cartes soient construites.
Future<void> _pumpS1(WidgetTester tester, {ChapterProgress? chapter}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: RelioTheme.build(),
      home: ChapterAccessPage(chapter: chapter, onOpenLesson: (String _) {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S1 — fondations', () {
    testWidgets('fond indigo pâle, barre de retour et titre du chapitre', (
      tester,
    ) async {
      await _pumpS1(tester);

      final palette = RelioPalette.standard();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, palette.homeBackground);

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text(RelioStrings.chapterCaption), findsOneWidget);
    });

    testWidgets('en-tête : Arithmétique en Display 28 / Bold Indigo', (
      tester,
    ) async {
      await _pumpS1(tester);

      final palette = RelioPalette.standard();
      final title = tester.widget<Text>(find.text(RelioStrings.chapterTitle));

      expect(title.style?.fontSize, 28);
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(title.style?.color, palette.primary);

      final intro = tester.widget<Text>(find.text(RelioStrings.chapterIntro));
      expect(intro.style?.fontSize, 16);
      expect(intro.style?.color, palette.textSecondary);
    });
  });

  group('S1 — cartes de leçon', () {
    testWidgets('carte blanche, arrondi 16, bordure orange et ombre douce', (
      tester,
    ) async {
      await _pumpS1(tester);

      final palette = RelioPalette.standard();
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(LessonCard).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      expect(decoration.color, palette.surface);
      expect(decoration.borderRadius, RelioRadius.bannerAll);
      expect(border.top.color, palette.brand);
      expect(border.top.width, RelioSizes.heroBorderWidth);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('titre en 18 / SemiBold et chevron sur chaque carte', (
      tester,
    ) async {
      await _pumpS1(tester);

      final title = tester.widget<Text>(
        find.text(ArithmeticLesson.lesson1Subtractions.title),
      );
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);

      expect(find.byType(LessonCard), findsNWidgets(3));
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });

    testWidgets('état vide : tout est « À commencer » et à zéro', (
      tester,
    ) async {
      await _pumpS1(tester);

      expect(find.text(RelioStrings.statusNotStarted), findsNWidgets(3));
      expect(find.text(RelioStrings.statusInProgress), findsNothing);
      expect(find.text(RelioStrings.statusMastered), findsNothing);

      // Totaux officiels de la banque : 4, 3 et 4 exercices.
      expect(
        find.text(RelioStrings.lessonExerciseProgress(0, 4)),
        findsNWidgets(2),
      );
      expect(
        find.text(RelioStrings.lessonExerciseProgress(0, 3)),
        findsOneWidget,
      );
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('une leçon absente du chapitre garde un décompte à zéro', (
      tester,
    ) async {
      await _pumpS1(
        tester,
        chapter: const ChapterProgress(
          number: 1,
          available: true,
          title: RelioStrings.chapterArithmetic,
          lessons: <LessonProgress>[],
        ),
      );

      // Aucun état inventé, mais le total reste celui de la banque validée.
      expect(find.text(RelioStrings.statusNotStarted), findsNWidgets(3));
      expect(
        find.text(RelioStrings.lessonExerciseProgress(0, 4)),
        findsNWidgets(2),
      );
      expect(find.byType(RelioProgressBar), findsNWidgets(3));
    });

    testWidgets('chaque carte porte une pastille et une barre', (tester) async {
      await _pumpS1(tester);

      expect(find.byType(LessonStatusPill), findsNWidgets(3));
      expect(find.byType(RelioProgressBar), findsNWidgets(3));
    });

    testWidgets('l’effet d’appui 0,97 couvre les trois cartes', (tester) async {
      await _pumpS1(tester);

      final effects = tester.widgetList<PressableScale>(
        find.descendant(
          of: find.byType(LessonCard),
          matching: find.byType(PressableScale),
        ),
      );
      expect(effects, hasLength(3));
      for (final effect in effects) {
        expect(effect.scale, 0.97);
      }
    });
  });

  group('S1 — robustesse', () {
    testWidgets('aucun débordement avec un texte agrandi à 1,3', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            theme: RelioTheme.build(),
            home: ChapterAccessPage(onOpenLesson: (String _) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // La dernière carte reste atteignable, sans casser la mise en page.
      await tester.scrollUntilVisible(
        find.text(ArithmeticLesson.lesson3PpcmPgcdRelation.title),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
