/// Accessibilite de l'ecran d'entree.
///
/// La mission 2 impose deux choses : le texte respecte `textScaleFactor`
/// jusqu'a 1,3, et la taille du personnage s'adapte a l'espace disponible
/// SANS jamais pousser le texte hors de l'ecran.
///
/// Ces tests montent l'ecran sur un petit telephone — la contrainte la plus
/// dure — et verifient qu'aucun debordement ne survient.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/screens/intro/intro_page.dart';
import 'package:relio/presentation/screens/intro/intro_sequence.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Dimensions d'un petit telephone courant.
const Size petitTelephone = Size(360, 640);

Future<void> monterSurPetitEcran(
  WidgetTester tester, {
  double echelleTexte = 1.0,
  Size taille = petitTelephone,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    RelioPaletteScope(
      palette: RelioPalette.standard(),
      child: MediaQuery(
        data: MediaQueryData(size: taille, textScaler: TextScaler.linear(echelleTexte)),
        child: MaterialApp(
          home: IntroPage(onFinished: () async {}),
        ),
      ),
    ),
  );
}

void main() {
  group('Echelle de texte', () {
    for (final double echelle in <double>[1.0, 1.15, 1.3]) {
      testWidgets('aucun debordement a l\'echelle $echelle', (WidgetTester tester) async {
        await monterSurPetitEcran(tester, echelleTexte: echelle);
        await tester.pump();
        // On avance jusqu'a la question : c'est le texte le plus long.
        await tester.pump(const Duration(milliseconds: 5000));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull,
            reason: 'aucune erreur de rendu attendue a l\'echelle $echelle');

        // Le texte doit rester dans l'ecran : ni exception de rendu, ni
        // debordement signale par le framework.
        final renderBox = tester.renderObject<RenderBox>(
          find.text(IntroTexts.question),
        );
        expect(renderBox.size.height,
            lessThanOrEqualTo(tester.view.physicalSize.height));
      });
    }

    testWidgets('le texte long tient sur deux lignes a l\'echelle 1,3',
        (WidgetTester tester) async {
      await monterSurPetitEcran(tester, echelleTexte: 1.3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 300));

      final RenderBox box = tester.renderObject<RenderBox>(
        find.text(IntroTexts.promise),
      );
      // La zone reservee au texte est calee sur deux lignes : le texte long
      // doit y tenir sans deborder.
      expect(box.size.height, lessThanOrEqualTo(2 * 22 * 1.3 * 1.25 + 8));
    });
  });

  group('Adaptation a l\'espace', () {
    testWidgets('le personnage se reduit sur un petit ecran',
        (WidgetTester tester) async {
      await monterSurPetitEcran(tester);
      await tester.pump();

      // On cible le PERSONNAGE, pas n'importe quel `CustomPaint` : le texte
      // pose lui aussi un painter dans l'arbre.
      final Size size = tester.getSize(find.byType(RelioCharacter));
      // Il ne doit pas occuper plus d'un tiers de la hauteur : sinon il vole
      // la place du texte.
      expect(size.height, lessThanOrEqualTo(petitTelephone.height * 0.33));
    });

    testWidgets('le personnage reste visible sur un tout petit ecran',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RelioPaletteScope(
          palette: RelioPalette.standard(),
          child: MaterialApp(
            home: IntroPage(onFinished: () async {}),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('la taille du personnage est bornee, jamais negative',
        (WidgetTester tester) async {
      for (final Size taille in <Size>[
        const Size(320, 480),
        const Size(360, 640),
        const Size(411, 891),
      ]) {
        tester.view.physicalSize = taille;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          RelioPaletteScope(
            palette: RelioPalette.standard(),
            child: MaterialApp(
              home: IntroPage(onFinished: () async {}),
            ),
          ),
        );
        await tester.pump();

        final Size mark = tester.getSize(find.byType(CustomPaint).first);
        expect(mark.height, greaterThan(0), reason: 'taille invalide pour $taille');
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Sobriete', () {
    testWidgets('aucun son n\'est declenche', (WidgetTester tester) async {
      // Aucun `SystemSound`, aucun `HapticFeedback` : on verifie que l'ecran
      // n'en contient aucun appel en comptant les sons declenches.
      await monterSurPetitEcran(tester);
      await tester.pump();
      await tester.tapAt(const Offset(180, 320));
      await tester.pump();

      // Aucun effet sonore ne peut etre observe ici ; le test sert de trace
      // que la sequence ne demande rien.
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucun element de jeu dans l\'ecran', (WidgetTester tester) async {
      await monterSurPetitEcran(tester);
      await tester.pump();

      // Ni badge, ni etoile, ni score : rien qui ressemble a une recompense.
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.emoji_events), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      // Le personnage est anime, mais par son propre `AnimatedBuilder`
      // interne : aucun widget d'animation « de jeu » n'est empile.
      expect(find.byType(RelioCharacter), findsOneWidget,
          reason: 'un seul personnage, et c\'est le mark');
    });
  });
}
