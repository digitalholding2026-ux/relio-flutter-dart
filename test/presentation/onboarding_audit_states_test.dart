/// AUDIT 2 - etats, contrastes et zones cliquables.
///
/// Cherche les defauts qu'un test de position ne voit pas :
///  - un bouton desactive dont on ne distingue pas l'etat ;
///  - un element devenu invisible mais RESTE cliquable ;
///  - une animation qui laisse une zone morte.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:relio/presentation/screens/onboarding/closing_page.dart';
import 'package:relio/presentation/screens/onboarding/name_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

void main() {
  Future<void> monter(WidgetTester tester, Widget enfant) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RelioPaletteScope(
        palette: RelioPalette.standard(),
        child: MaterialApp(theme: RelioTheme.build(), home: enfant),
      ),
    );
    await tester.pump();
  }

  group('Bouton desactive', () {
    testWidgets('le bouton « Continuer » vide reste identifiable',
        (WidgetTester tester) async {
      await monter(
        tester,
        NamePage(onSubmit: (String _) async {}, reduceAnimations: true),
      );

      final Finder boutonFinder = find.widgetWithText(
        FilledButton,
        RelioStrings.nameContinue,
      );
      final FilledButton bouton = tester.widget<FilledButton>(boutonFinder);
      expect(bouton.onPressed, isNull, reason: 'il doit etre desactive');

      // États de LA REFONTE, lus sur le style du bouton lui-même : fond
      // navy à 40 %, texte blanc à 60 %, jamais de contour.
      //
      // Le contraste AA (4,5:1) ne s'applique pas ici : WCAG exempte les
      // composants inactifs, et l'état désactivé est volontairement estompé.
      // L'action reste identifiable par son libellé et sa position ancrée.
      final ButtonStyle? style = bouton.style;
      expect(
        style?.backgroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        RelioPalette.standard().primary.withValues(alpha: 0.4),
      );
      expect(
        style?.foregroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        Colors.white.withValues(alpha: 0.6),
      );
      expect(
        style?.side?.resolve(<WidgetState>{WidgetState.disabled}),
        BorderSide.none,
        reason: 'le bouton du parcours ne porte jamais de contour',
      );
      expect(find.text(RelioStrings.nameContinue), findsOneWidget,
          reason: 'le libellé reste affiché, même désactivé');
    });
  });

  group('Zones cliquables', () {
    testWidgets('une seconde validation pendant l\'écriture est refusee',
        (WidgetTester tester) async {
      // Pendant l'écriture, l'indicateur REMPLACE le libellé : il n'y a
      // plus rien à taper, et le bouton est neutralisé. Le prénom ne peut
      // pas être écrit deux fois.
      var appele = 0;
      await monter(
        tester,
        NamePage(
          onSubmit: (String _) async => appele++,
          reduceAnimations: true,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Awa');
      await tester.pump();

      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
      );
      await tester.pump();
      expect(appele, 1);

      // Le bouton reste dans l'arbre, en chargement, sans libellé à taper.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, RelioStrings.nameContinue),
        findsNothing,
      );

      await tester.tap(
        find.byType(CircularProgressIndicator),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(appele, 1, reason: 'aucune double soumission pendant l\'écriture');
    });

    testWidgets('le bouton de cloture reste actif apres un echec',
        (WidgetTester tester) async {
      await monter(
        tester,
        ClosingPage(
          name: 'Awa',
          onConfirm: () async => throw StateError('base indisponible'),
          reduceAnimations: true,
        ),
      );

      await tester.tap(
        find.widgetWithText(FilledButton, RelioStrings.closingDiscover),
      );
      await tester.pump();
      await tester.pump();

      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.closingDiscover),
      );
      expect(bouton.onPressed, isNotNull,
          reason: 'apres un echec, l\'eleve doit pouvoir reessayer');
    });
  });
}