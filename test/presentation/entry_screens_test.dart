/// Onboarding — les trois écrans ajoutés au parcours d'entrée.
///
/// Ouverture (révélation du logo), Bienvenue, Introduction au
/// questionnaire. Les trois portent des EXIGENCES PARTICULIÈRES que les
/// écrans voisins n'ont pas, et qu'il faut donc vérifier ici :
///
///  - l'ouverture ne porte AUCUN bouton et se termine TOUTE SEULE ;
///  - Bienvenue et Introduction ont un TEXTE EXACT, non reformulable ;
///  - les deux doivent tenir sur 360 × 640 avec la police système à 1,3,
///    sans débordement et sans perdre l'action principale ;
///  - aucune des trois ne mentionne une évaluation.
///
/// `flutter test` signale un débordement comme une EXCEPTION : `tester.pump`
/// suffit donc à le détecter. On vérifie explicitement l'absence de
/// débordement pour que l'échec soit rattaché à son écran.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/intro/opening_page.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_intro_page.dart';
import 'package:relio/presentation/screens/onboarding/onboarding_metrics.dart';
import 'package:relio/presentation/screens/onboarding/welcome_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Écran de référence de la mission : le plus petit écran visé.
const Size kCompact = Size(360, 640);

void main() {
  /// Monte un écran dans une palette complète, avec une taille imposée.
  Future<void> monter(
    WidgetTester tester,
    Widget enfant, {
    Size taille = kCompact,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RelioPaletteScope(
        palette: RelioPalette.standard(),
        child: MaterialApp(
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: enfant,
        ),
      ),
    );
    await tester.pump();
  }

  group('Étape 1 — Ouverture', () {
    testWidgets('ne porte aucun bouton', (WidgetTester tester) async {
      await monter(
        tester,
        OpeningPage(onFinished: () async {}, reduceAnimations: true),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('se termine seule et rend la main', (WidgetTester tester) async {
      bool fini = false;
      await monter(
        tester,
        OpeningPage(
          onFinished: () async => fini = true,
          reduceAnimations: true,
        ),
      );

      expect(fini, isFalse, reason: 'rien n\'est écoule à la première frame');

      // Le passage se fait sur une minuterie, pas sur une animation : on
      // avance l'horloge jusqu'à ce qu'elle ait déclenché.
      for (int i = 0; i < 12 && !fini; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(fini, isTrue,
          reason: 'l\'écran doit s\'enchaîner sans aucune action de l\'élève');
    });

    testWidgets('tient sur 360 × 640 à 1,3', (WidgetTester tester) async {
      await monter(
        tester,
        OpeningPage(onFinished: () async {}, reduceAnimations: true),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('le retour Android ne bloque pas l\'élève',
        (WidgetTester tester) async {
      bool fini = false;
      await monter(
        tester,
        OpeningPage(
          onFinished: () async => fini = true,
          reduceAnimations: true,
        ),
      );

      // Simule le retour Android : `canPop` est faux, donc le framework
      // invoque `onPopInvokedWithResult`, et l'écran rend la main au lieu de
      // sortir de l'application.
      final PopScope<Object?> scope = tester.widget<PopScope<Object?>>(
        find.byType(PopScope<Object?>).first,
      );
      scope.onPopInvokedWithResult!(false, null);
      await tester.pump();

      expect(fini, isTrue,
          reason: 'l\'élève ne doit pas rester piégé sur cet écran');
    });
  });

  group('Étape 2 — Bienvenue', () {
    testWidgets('affiche le texte exact et le bouton', (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      expect(find.text(RelioStrings.welcomeMessage), findsOneWidget);
      expect(find.text(RelioStrings.welcomeStart), findsOneWidget);
    });

    testWidgets('le texte est celui validé, caractère pour caractère',
        (WidgetTester tester) async {
      // Une reformulation — même plus naturelle — ferait échouer ce test.
      expect(
        RelioStrings.welcomeMessage,
        'Salut, moi c\u2019est Relio ! On va avancer ensemble en maths, '
        'à ton rythme. Pr\u00eat à découvrir comment je peux t\u2019aider ?',
      );
    });

    testWidgets('n\'affiche aucun AppBar', (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('tient sur 360 × 640 à 1,3, sans déborder',
        (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull,
          reason: 'aucun débordement sur l\'écran de référence');

      // L'action principale reste ATTEIGNABLE : c'est elle qui conditionne la
      // suite du parcours.
      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.welcomeStart),
      );
      expect(bouton.onPressed, isNotNull);
      expect(find.text(RelioStrings.welcomeStart), findsOneWidget);
    });

    testWidgets('le bouton appelle le point d\'entrée', (WidgetTester tester) async {
      int appels = 0;
      await monter(
        tester,
        WelcomePage(
          onStart: () async => appels++,
          reduceAnimations: true,
        ),
      );

      await tester.tap(find.text(RelioStrings.welcomeStart));
      await tester.pump();

      expect(appels, 1);
    });

    testWidgets('un double tap n\'écrit pas deux fois',
        (WidgetTester tester) async {
      int appels = 0;
      await monter(
        tester,
        WelcomePage(
          onStart: () async {
            appels++;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          },
          reduceAnimations: true,
        ),
      );

      await tester.tap(find.text(RelioStrings.welcomeStart));
      await tester.pump();
      await tester.tap(find.text(RelioStrings.welcomeStart), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(appels, 1,
          reason: 'le marqueur ne doit pas être écrit deux fois');
    });

    testWidgets('ne mentionne aucune évaluation', (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      // Aucun mot ne peut laisser croire à une évaluation : ni « test », ni
      // « examen », ni promesse de note.
      expect(RelioStrings.welcomeMessage.toLowerCase(), isNot(contains('test')));
      expect(RelioStrings.welcomeMessage.toLowerCase(),
          isNot(contains('examen')));
    });
  });

  group('Étape 3 — Introduction au questionnaire', () {
    testWidgets('affiche le texte exact et le bouton', (WidgetTester tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
      );

      expect(find.text(RelioStrings.entryIntroMessage), findsOneWidget);
      expect(find.text(RelioStrings.entryIntroStart), findsOneWidget);
    });

    testWidgets('le texte est celui validé, caractère pour caractère',
        (WidgetTester tester) async {
      expect(
        RelioStrings.entryIntroMessage,
        'Faisons connaissance ! Je vais te proposer 5 petites questions de '
        'maths. Elles m\u2019aideront à mieux comprendre ton point de départ '
        'pour t\u2019accompagner dans la suite. Ici, on avance pas à pas.',
      );
    });

    testWidgets('cinq pastilles, une par question', (WidgetTester tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
      );

      expect(OnboardingMetrics.introChipCount, 5);

      final int pastilles = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) =>
              (c.decoration as BoxDecoration?)?.shape == BoxShape.circle)
          .length;
      expect(pastilles, OnboardingMetrics.introChipCount);

      // Elles sont VIDES : les remplir serait déjà afficher une progression,
      // donc déjà une évaluation. Aucune ne porte d'état de session.
      expect(find.textContaining('sur 5'), findsNothing);
      expect(find.text(RelioStrings.entryIntroCaption), findsOneWidget);
    });

    testWidgets('tient sur 360 × 640 à 1,3', (WidgetTester tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(RelioStrings.entryIntroStart), findsOneWidget,
          reason: 'l\'action principale reste atteignable');
    });

    testWidgets('le bouton enchaîne', (WidgetTester tester) async {
      int appels = 0;
      await monter(
        tester,
        EntryTestIntroPage(onStart: () => appels++, reduceAnimations: true),
      );

      await tester.tap(find.text(RelioStrings.entryIntroStart));
      await tester.pump();

      expect(appels, 1);
    });

    testWidgets('ne promet ni score ni pourcentage',
        (WidgetTester tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: true),
      );

      expect(find.text(RelioStrings.entryIntroCaption), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('sur 5'), findsNothing,
          reason: 'le compteur appartient au test, pas à son annonce');
    });
  });
}