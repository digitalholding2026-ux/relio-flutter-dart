/// Tests de l'écran Profil — refonte UX/UI.
///
/// OBJECTIF : vérifier ce que voit l'élève, pas seulement la présence des
/// widgets. Les points sensibles de cette refonte sont :
///  - la carte d'identité (avatar, prénom vide ou renseigné, bouton Modifier) ;
///  - les deux faits de « Mon parcours » ;
///  - le libellé « Taille du texte » sur toute la largeur, au-dessus du
///    sélecteur (le bug de découpe verticale) ;
///  - les cartes à rayon 16 et ombre douce, dont la carte principale à
///    bordure orange.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/learning/learner_progress.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/screens/profile_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Construit l'écran Profil avec sa palette et son échelle de texte.
Widget buildProfileHarness({
  required LearnerSettings settings,
  required ValueChanged<LearnerSettings> onChanged,
  double textScale = 1,
  LearnerProgress progress = LearnerProgress.empty,
}) {
  final palette = RelioPalette.of(highContrast: settings.highContrast);

  return MaterialApp(
    theme: RelioTheme.build(settings: settings),
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: RelioPaletteScope(
      palette: palette,
      child: ProfilePage(
        settings: settings,
        progress: progress,
        onChanged: onChanged,
      ),
    ),
  );
}

/// Avancement de démonstration : [completed] exercices répartis sur trois
/// leçons de quatre exercices (donc trois notions maîtrisées au maximum).
LearnerProgress _progressWith({int lessons = 3, int perLesson = 4}) {
  final byLesson = <String, Set<String>>{};
  final all = <String>{};
  final totals = <String, int>{};

  for (var lesson = 0; lesson < lessons; lesson++) {
    final id = 'lecon-$lesson';
    totals[id] = perLesson;
    byLesson[id] = <String>{
      for (var index = 0; index < perLesson; index++) '$id-ex-$index',
    };
    all.addAll(byLesson[id]!);
  }

  return LearnerProgress(
    startedLessonIds: byLesson.keys.toSet(),
    completedExerciseIds: all,
    completedExerciseIdsByLesson: byLesson,
    lessonExerciseTotals: totals,
  );
}

/// Monte l'écran avec un état local reflétant les modifications.
Future<LearnerSettings> pumpProfile(
  WidgetTester tester, {
  LearnerSettings settings = LearnerSettings.defaults,
  double textScale = 1,
  LearnerProgress progress = LearnerProgress.empty,
}) async {
  var current = settings;

  await tester.pumpWidget(
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return buildProfileHarness(
          settings: current,
          textScale: textScale,
          progress: progress,
          onChanged: (LearnerSettings next) {
            setState(() => current = next);
          },
        );
      },
    ),
  );
  await tester.pumpAndSettle();

  return current;
}

/// Fait défiler l'écran jusqu'au libellé [label].
Future<void> scrollProfileTo(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Fondations et en-tête', () {
    testWidgets('le fond est indigo pâle et le titre indigo', (tester) async {
      await pumpProfile(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, RelioPalette.standard().homeBackground);

      final title = tester.widget<Text>(find.text(RelioStrings.profileTitle));
      expect(title.style?.fontSize, 28);
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(title.style?.color, RelioPalette.standard().primary);
    });
  });

  group('Carte d’identité', () {
    testWidgets('sans prénom : invitation, silhouette et classe', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text(RelioStrings.nameHint), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.text('Classe de 3e'), findsOneWidget);
      expect(find.text(RelioStrings.profileModify), findsOneWidget);
    });

    testWidgets('avec prénom : initiale, prénom et classe', (tester) async {
      await pumpProfile(
        tester,
        settings: const LearnerSettings(name: 'Camille'),
      );

      expect(find.text('C'), findsOneWidget);
      expect(find.text('Camille'), findsOneWidget);
      expect(find.text('Classe de 3e'), findsOneWidget);
      expect(find.text(RelioStrings.nameHint), findsNothing);
    });

    testWidgets('« Modifier » ouvre le champ, la saisie est persistée', (
      tester,
    ) async {
      var current = LearnerSettings.defaults;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return buildProfileHarness(
              settings: current,
              onChanged: (LearnerSettings next) {
                setState(() => current = next);
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text(RelioStrings.profileModify));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Lina');
      await tester.pumpAndSettle();

      // La saisie part immédiatement vers les préférences…
      expect(current.name, 'Lina');

      // … et le bouton referme le champ une fois la saisie finie.
      await tester.tap(find.text(RelioStrings.profileDone));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Lina'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });
  });

  group('Carte « Mon parcours »', () {
    testWidgets('un nouvel élève voit deux zéros', (tester) async {
      await pumpProfile(tester);

      expect(find.text(RelioStrings.profileJourneyTitle), findsOneWidget);
      // État vide : aucun exercice terminé, aucune notion maîtrisée.
      expect(find.text('0 Exercice terminé'), findsOneWidget);
      expect(find.text('0 Notion maîtrisée'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('les deux faits affichent les décomptes fournis',
        (tester) async {
      await pumpProfile(tester, progress: _progressWith());

      expect(
        find.text(RelioStrings.completedExercises(12)),
        findsOneWidget,
      );
      expect(find.text(RelioStrings.masteredNotions(3)), findsOneWidget);
    });

    testWidgets('aucune note, aucun score, aucun pourcentage', (tester) async {
      await pumpProfile(tester);

      expect(find.text('Note'), findsNothing);
      expect(find.text('Score'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('Réglages', () {
    testWidgets('« Taille du texte » est au-dessus du sélecteur, non coupé', (
      tester,
    ) async {
      await pumpProfile(tester);

      final label = find.text(RelioStrings.textSizeLabel);
      final selector = find.byType(SegmentedButton<TextScalePreference>);

      expect(label, findsOneWidget);
      expect(selector, findsOneWidget);

      final labelRect = tester.getRect(label);
      final selectorRect = tester.getRect(selector);

      // Le libellé occupe sa propre ligne : aucun recouvrement vertical.
      expect(labelRect.bottom, lessThanOrEqualTo(selectorRect.top));
      // Sa hauteur suffit à peindre la ligne entière (pas de découpe).
      expect(labelRect.height, greaterThanOrEqualTo(16));

      // Le sélecteur occupe toute la largeur intérieure de la carte :
      // 800 - 2 × 20 (marges écran) - 2 × 20 (rembourrage carte).
      expect(selectorRect.width, closeTo(720, 0.5));

      for (final option in TextScalePreference.values) {
        expect(find.text(option.label), findsOneWidget);
      }
    });

    testWidgets('les interrupteurs mettent à jour les préférences', (
      tester,
    ) async {
      var current = LearnerSettings.defaults;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return buildProfileHarness(
              settings: current,
              onChanged: (LearnerSettings next) {
                setState(() => current = next);
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await scrollProfileTo(tester, RelioStrings.highContrastLabel);
      await tester.tap(find.text(RelioStrings.highContrastLabel));
      await tester.pumpAndSettle();
      expect(current.highContrast, isTrue);

      await scrollProfileTo(tester, RelioStrings.reduceAnimationsLabel);
      await tester.tap(find.text(RelioStrings.reduceAnimationsLabel));
      await tester.pumpAndSettle();
      expect(current.reduceAnimations, isTrue);
    });
  });

  group('Mise en page', () {
    testWidgets('cinq cartes blanches, rayon 16, ombre douce', (
      tester,
    ) async {
      // Écran assez haut pour que les cinq cartes soient construites : la
      // liste est paresseuse, une carte hors cache n'existerait pas encore.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpProfile(tester);

      final cards = tester.widgetList<Container>(find.byType(Container)).where((
        Container container,
      ) {
        final BoxDecoration? decoration =
            container.decoration as BoxDecoration?;
        return decoration != null &&
            decoration.borderRadius == RelioRadius.bannerAll &&
            (decoration.boxShadow?.isNotEmpty ?? false);
      });

      expect(cards, hasLength(5));
    });

    testWidgets('la carte d’identité porte la bordure orange 1.5', (
      tester,
    ) async {
      await pumpProfile(tester);

      final hero = tester.widgetList<Container>(find.byType(Container)).where((
        Container container,
      ) {
        final BoxDecoration? decoration =
            container.decoration as BoxDecoration?;
        final BoxBorder? border = decoration?.border;
        return border is Border &&
            border.top.color == RelioPalette.standard().brand &&
            border.top.width == RelioSizes.heroBorderWidth;
      });

      expect(hero, hasLength(1));
    });

    testWidgets('aucun débordement sur 360 × 640 avec textScale 1.3', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpProfile(tester, textScale: 1.3);

      await tester.scrollUntilVisible(
        find.text(RelioStrings.textSizeLabel),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final labelRect = tester.getRect(find.text(RelioStrings.textSizeLabel));
      final selectorRect = tester.getRect(
        find.byType(SegmentedButton<TextScalePreference>),
      );
      expect(labelRect.bottom, lessThanOrEqualTo(selectorRect.top));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
