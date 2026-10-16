/// Absence de RECOUVREMENT entre le personnage et le contenu.
///
/// Ce test existe parce qu'un `Stack` ne lève rien quand deux enfants se
/// marchent dessus : `tester.takeException()` reste nul, et les assertions
/// d'opacité, de présence et de débordement passent toutes. Seule une
/// comparaison de rectangles voit le problème.
///
/// C'est ce qui a laissé passer 50 px de recouvrement entre le titre de
/// l'écran du prénom et le personnage, sur les quatre écrans du parcours.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/branding/relio_mark.dart';
import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/screens/onboarding/welcome_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Rectangles des deux éléments qui ne doivent jamais se toucher.
void attendrePasDeRecouvrement(
  WidgetTester tester, {
  required Finder personnage,
  required Finder contenu,
  required String quoi,
}) {
  final Rect a = tester.getRect(personnage);
  final Rect b = tester.getRect(contenu);

  expect(
    a.overlaps(b),
    isFalse,
    reason: '$quoi : le personnage (${a.top.toStringAsFixed(0)} → '
        '${a.bottom.toStringAsFixed(0)}) et le contenu '
        '(${b.top.toStringAsFixed(0)} → ${b.bottom.toStringAsFixed(0)}) '
        'se recouvrent',
  );
}

void main() {
  /// Monte un écran à la taille de référence, à l'échelle d'accessibilité
  /// maximale — c'est là que les recouvrements apparaissent.
  Future<void> monter(WidgetTester tester, Widget ecran) async {
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
          home: ecran,
        ),
      ),
    );
    await tester.pump();
  }

  group('Écran du prénom', () {
    testWidgets('le titre ne recouvre pas le personnage',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      attendrePasDeRecouvrement(
        tester,
        personnage: find.byType(RelioCharacter),
        contenu: find.text(RelioStrings.nameTitle),
        quoi: 'titre / personnage',
      );
    });

    testWidgets('le champ ne recouvre pas le personnage',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      attendrePasDeRecouvrement(
        tester,
        personnage: find.byType(RelioCharacter),
        contenu: find.byType(TextField),
        quoi: 'champ / personnage',
      );
    });

    testWidgets('le bouton reste en bas, sous le champ',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      final Rect champ = tester.getRect(find.byType(TextField));
      final Rect bouton =
          tester.getRect(find.widgetWithText(FilledButton, RelioStrings.nameContinue));

      expect(bouton.top, greaterThanOrEqualTo(champ.bottom),
          reason: 'le bouton ne doit pas remonter sur le champ');
      expect(bouton.bottom, lessThanOrEqualTo(640),
          reason: 'le bouton doit rester dans l\'écran');
    });
  });

  group('Écran de clôture', () {
    testWidgets('le texte ne recouvre pas le personnage',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );

      attendrePasDeRecouvrement(
        tester,
        personnage: find.byType(RelioCharacter),
        contenu: find.textContaining('Merci Awa'),
        quoi: 'phrase / personnage',
      );
    });
  });

  group('Écran de bienvenue', () {
    testWidgets('le titre ne recouvre pas le mark',
        (WidgetTester tester) async {
      await monter(
        tester,
        WelcomePage(onStart: () async {}, reduceAnimations: true),
      );

      // L'écran de bienvenue ne montre plus le lockup : le mark seul
      // (100 dp), puis le titre.
      attendrePasDeRecouvrement(
        tester,
        personnage: find.byType(RelioMark),
        contenu: find.text(RelioStrings.welcomeTitle),
        quoi: 'titre / mark',
      );
    });
  });
}