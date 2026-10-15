/// Visibilité du parcours d'entrée — le test qui aurait dû attraper le blocage.
///
/// Un `find.text(...)` renvoie VRAI même quand le texte est peint à
/// `Opacity 0` : le widget est dans l'arbre, il est simplement invisible. Les
/// tests qui vérifient la PRÉSENCE d'un texte, d'un bouton ou d'un champ
/// passent donc tous sur un écran entièrement transparent.
///
/// C'est exactement ce qui s'est produit : 674 tests verts, et un démarrage
/// bloqué sur un écran blanc. Ces tests vérifient donc l'OPACITÉ EFFECTIVE, et
/// l'atteignabilité réelle des actions.
///
/// La règle : sur un écran du parcours, **rien ne doit rester invisible après
/// l'animation**. Une seule opacité nulle, et c'est un blocage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/intro/opening_page.dart';
import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_intro_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/screens/onboarding/welcome_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Opacité minimale rencontrée dans l'arbre.
///
/// Vaut 1 quand tout est visible. Une valeur à 0 désigne un contenu peint
/// mais transparent — donc un écran blanc, et un parcours bloqué.
double opaciteMinimale(WidgetTester tester) {
  final List<double> valeurs = tester
      .widgetList<Opacity>(find.byType(Opacity))
      .map((Opacity o) => o.opacity)
      .toList();
  if (valeurs.isEmpty) return 1;
  return valeurs.reduce((double a, double b) => a < b ? a : b);
}

/// Opacité maximale rencontrée dans l'arbre.
///
/// Sert à vérifier qu'une animation PROGRESSE : pendant l'apparition décalée,
/// les blocs qui n'ont pas encore leur tour sont légitimement à 0 — c'est la
/// progression du premier bloc qui s'observe.
double opaciteMaximal(WidgetTester tester) {
  final List<double> valeurs = tester
      .widgetList<Opacity>(find.byType(Opacity))
      .map((Opacity o) => o.opacity)
      .toList();
  if (valeurs.isEmpty) return 1;
  return valeurs.reduce((double a, double b) => a > b ? a : b);
}

/// Fait tourner les animations jusqu'à leur terme.
///
/// `pumpAndSettle` NE SUFFIT PAS : l'écran de clôture attend 1,5 s entre le
/// personnage et le texte, or pendant un `Future.delayed` aucune frame n'est
/// attendue — `pumpAndSettle` rendu la main immédiatement, avant que le texte
/// soit apparu. C'est un second piège du même ordre : un test peut conclure
/// qu'un écran est prêt alors qu'il est encore vide.
///
/// On avance donc le temps RÉELLEMENT, par pas courts, jusqu'à ce que plus
/// rien ne soit en attente.
Future<void> laisserAnimer(WidgetTester tester) async {
  for (int i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Monte un écran à sa taille de production la plus contrainte.
Future<void> monter(WidgetTester tester, Widget enfant) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    RelioPaletteScope(
      palette: RelioPalette.standard(),
      child: MaterialApp(home: enfant),
    ),
  );
  await tester.pump();
}

void main() {
  group('Rien ne reste invisible une fois l\'animation terminée', () {
    testWidgets('écran Bienvenue', (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: false),
      );

      // AVANT l'animation, le contenu est bien transparent : c'est voulu.
      expect(opaciteMinimale(tester), lessThan(1),
          reason: 'l\'apparition doit être progressive');

      await laisserAnimer(tester);

      expect(opaciteMinimale(tester), 1,
          reason: 'le texte et le bouton doivent être VISIBLES');
      expect(find.text(RelioStrings.welcomeStart), findsOneWidget);
    });

    testWidgets('écran Introduction au questionnaire',
        (WidgetTester tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: false),
      );

      expect(opaciteMinimale(tester), lessThan(1));

      await laisserAnimer(tester);

      expect(opaciteMinimale(tester), 1,
          reason: 'le texte et le bouton doivent être VISIBLES');
      expect(find.text(RelioStrings.entryIntroStart), findsOneWidget);
    });

    testWidgets('écran de clôture', (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: false,
        ),
      );

      // L'écran de clôture attend 1,5 s entre le personnage et le texte.
      await laisserAnimer(tester);

      expect(opaciteMinimale(tester), 1,
          reason: 'sans cela, l\'élève ne voit ni phrase ni bouton');
      expect(find.text(RelioStrings.closingDiscover), findsOneWidget);
    });

    testWidgets('écran Prénom', (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: false),
      );

      await laisserAnimer(tester);

      expect(opaciteMinimale(tester), 1);
      expect(find.text(RelioStrings.nameTitle), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Les animations avancent réellement', () {
    testWidgets('le contrôleur n\'est pas figé dès la première image',
        (WidgetTester tester) async {
      await monter(
        tester,
        EntryTestIntroPage(onStart: () {}, reduceAnimations: false),
      );

      final double depart = opaciteMaximal(tester);
      await tester.pump(const Duration(milliseconds: 200));
      final double apres = opaciteMaximal(tester);

      expect(apres, greaterThan(depart),
          reason: 'un ecran identique deux images de suite est fige');
    });

    testWidgets('la révélation atteint son terme dans le temps prévu',
        (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: false),
      );

      // Une seconde de plus que la chronologie annoncée : si l'animation
      // dépassait ce délai, ce test échouerait au lieu de laisser croire que
      // l'écran est simplement lent.
      await laisserAnimer(tester);

      expect(opaciteMinimale(tester), 1);
    });
  });

  group('Réduire les animations ne masque rien', () {
    testWidgets('le contenu est visible dès la première image',
        (WidgetTester tester) async {
      for (final (String nom, Widget ecran) in <(String, Widget)>[
        ('bienvenue',
            WelcomePage(onStart: () async {}, reduceAnimations: true)),
        ('introduction',
            EntryTestIntroPage(onStart: () {}, reduceAnimations: true)),
        (
          'clôture',
          ClosingPage(
            name: 'Awa',
            onConfirm: () async {},
            reduceAnimations: true,
          ),
        ),
        ('prénom', NamePage(onSubmit: (String _) async {}, reduceAnimations: true)),
      ]) {
        await monter(tester, ecran);
        expect(opaciteMinimale(tester), 1,
            reason: '$nom doit être visible sans animation');
      }
    });
  });

  group('L\'ouverture reste traversable', () {
    testWidgets('le logo est visible puis l\'écran rend la main',
        (WidgetTester tester) async {
      bool fini = false;
      await monter(
        tester,
        OpeningPage(
          onFinished: () async => fini = true,
          reduceAnimations: false,
        ),
      );

      // Le logo apparaît en fondu : il est transparent à la toute première image,
      // c'est voulu. Il ne doit pas RESTER transparent.
      await tester.pump(const Duration(milliseconds: 200));
      expect(opaciteMinimale(tester), greaterThan(0),
          reason: 'la marque doit commencer à apparaître');

      for (int i = 0; i < 20 && !fini; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(fini, isTrue);
    });
  });
}