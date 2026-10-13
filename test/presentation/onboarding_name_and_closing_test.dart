/// Onboarding — etape Prenom et ecran de cloture.
///
/// Les deux ecrans qui encadrent le test d'entree. Ce qu'ils doivent faire :
/// demander un prenom sans rien exiger de sa forme, et cloturer le parcours
/// sans rendre le moindre resultat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/screens/onboarding/onboarding_metrics.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

void main() {
  /// Monte un ecran dans une palette complete, comme le ferait l'application.
  Future<void> monter(
    WidgetTester tester,
    Widget enfant,
  ) async {
    await tester.pumpWidget(
      RelioPaletteScope(
        palette: RelioPalette.standard(),
        child: MaterialApp(home: enfant),
      ),
    );
    await tester.pump();
  }

  group('Etape Prenom', () {
    testWidgets('affiche le titre et le champ', (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expect(find.text(RelioStrings.nameTitle), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(RelioStrings.namePlaceholder), findsOneWidget);
    });

    testWidgets('n\'affiche aucun AppBar', (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('le bouton est inactif tant que le champ est vide',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      expect(bouton.onPressed, isNull);
    });

    testWidgets('le bouton devient actif apres saisie',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      await tester.enterText(find.byType(TextField), 'Awa');
      await tester.pump();

      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('les chiffres sont rejetes a la frappe',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      await tester.enterText(find.byType(TextField), 'Awa42');
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Awa');
    });

    testWidgets('la saisie est bornee a 24 caracteres',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      await tester.enterText(find.byType(TextField), 'a' * 40);
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text.length,
        OnboardingMetrics.nameMaxLength,
      );
    });

    // Un test par prenom : remonter l'ecran dans une boucle laisse le widget
    // precedent detruit sans etre pumpE, et l'animation de sortie tournerait
    // encore. Un test par cas, c'est plus lent mais exact.
    testWidgets('un prenom court comme « Jo » passe',
        (WidgetTester tester) async {
      String? recu;
      await monter(
        tester,
        NamePage(onSubmit: (String n) async => recu = n, reduceAnimations: true),
      );

      await tester.enterText(find.byType(TextField), 'Jo');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      await tester.pump();
      await tester.pump();

      expect(recu, 'Jo');
    });

    testWidgets('un prenom compose comme « Jean-Baptiste » passe',
        (WidgetTester tester) async {
      // Aucune validation de forme : c'est la decision validee.
      String? recu;
      await monter(
        tester,
        NamePage(onSubmit: (String n) async => recu = n, reduceAnimations: true),
      );

      await tester.enterText(find.byType(TextField), 'Jean-Baptiste');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      await tester.pump();
      await tester.pump();

      expect(recu, 'Jean-Baptiste');
    });

    testWidgets('le prenom est capitalise avant d\'etre transmis',
        (WidgetTester tester) async {
      String? recu;
      await monter(
        tester,
        NamePage(
          onSubmit: (String name) async => recu = name,
          reduceAnimations: true,
        ),
      );

      await tester.enterText(find.byType(TextField), 'awa');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      await tester.pump();
      await tester.pump();

      expect(recu, 'Awa');
    });

    testWidgets('aucun message d\'erreur n\'est affiche',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      // Champ vide, puis saisie : dans aucun cas l'ecran ne se plaint.
      expect(find.textContaining('erreur'), findsNothing);
      await tester.enterText(find.byType(TextField), 'A');
      await tester.pump();
      expect(find.textContaining('erreur'), findsNothing);
    });
  });

  group('Cloture', () {
    testWidgets('remercie l\'eleve par son prenom',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Merci Awa. Je commence à te connaître.'), findsOneWidget);
    });

    testWidgets('capitalise un prenom venu en minuscules',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Merci Awa'), findsOneWidget);
    });

    testWidgets('n\'affiche aucun bilan ni resultat',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Ni score, ni nombre de reponses, ni mention de reussite.
      for (final String interdit in <String>[
        'score',
        'réussi',
        'sur 5',
        '/5',
        '5/5',
      ]) {
        expect(find.textContaining(interdit), findsNothing,
            reason: '« $interdit » ne doit jamais apparaitre en cloture');
      }
    });

    testWidgets('n\'affiche aucun AppBar', (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async {},
          reduceAnimations: true,
        ),
      );

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('le bouton « Découvrir Relio » declenche la confirmation',
        (WidgetTester tester) async {
      var confirme = false;
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async => confirme = true,
          reduceAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.closingDiscover),
      );
      await tester.pump();
      await tester.pump();

      expect(confirme, isTrue);
    });

    testWidgets('un echec de confirmation laisse l\'ecran en place',
        (WidgetTester tester) async {
      // La confirmation echoue : l'ecran de clôture doit RESTER affiche et son
      // bouton redevenir actif. Aucune avancee forcee.
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async => throw StateError('base indisponible'),
          reduceAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.closingDiscover),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Merci Awa'), findsOneWidget,
          reason: 'l\'eleve doit rester sur l\'ecran de cloture');
      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.closingDiscover),
      );
      expect(bouton.onPressed, isNotNull,
          reason: 'le bouton doit redevenir actif pour permettre le reessai');
    });
  });

  group('Personnage', () {
    test('tailles prevues : 140 / 80 / 140 dp', () {
      // Prénom 140, Test 80, Clôture 140 — la regle de la mission.
      expect(OnboardingMetrics.characterSize(width: 400, large: true), 140);
      expect(OnboardingMetrics.characterSize(width: 400, large: false), 80);
      expect(OnboardingMetrics.characterSize(width: 400, large: true), 140);
    });

    test('tailles prevues sur petit ecran : 120 / 70 / 120 dp', () {
      expect(OnboardingMetrics.characterSize(width: 320, large: true), 120);
      expect(OnboardingMetrics.characterSize(width: 320, large: false), 70);
      expect(OnboardingMetrics.characterSize(width: 320, large: true), 120);
    });
  });
}