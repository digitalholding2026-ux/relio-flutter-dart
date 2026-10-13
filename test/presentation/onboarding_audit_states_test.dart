/// AUDIT 2 - etats, contrastes et zones cliquables.
///
/// Cherche les defauts qu'un test de position ne voit pas :
///  - un bouton desactive dont on ne distingue pas l'etat ;
///  - un element devenu invisible mais RESTE cliquable ;
///  - une animation qui laisse une zone morte.
library;

import 'dart:math' as math;

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

  /// Contraste WCAG entre deux couleurs, ALPHA COMPOSITE sur [fond].
  ///
  /// Composer d'abord est indispensable : une couleur semi-transparente
  /// donne un contraste sans commune mesure avec son contraste reel. Ignorer
  /// l'alpha revient a mesurer une couleur qui n'est jamais affichee.
  double contraste(Color a, Color b) {
    // Sur fond blanc, cas de Relio : toutes les surfaces sont claires.
    Color compose(Color c) => Color.lerp(const Color(0xFFFFFFFF), c, c.a)!;

    double lum(Color c) {
      double canal(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
    }

    final double la = lum(compose(a));
    final double lb = lum(compose(b));
    final double hi = la > lb ? la : lb;
    final double lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
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

      // Couleurs EFFECTIVES de l'etat desactive, resolues par le theme.
      final ThemeData theme = Theme.of(tester.element(boutonFinder));

      final Color? arrierePlan = theme.filledButtonTheme.style?.backgroundColor
          ?.resolve(<WidgetState>{WidgetState.disabled});
      final Color? avantPlan = theme.filledButtonTheme.style?.foregroundColor
          ?.resolve(<WidgetState>{WidgetState.disabled});

      // Couleur EFFECTIVE du libelle, telle que rendue : c'est le
      // DefaultTextStyle que le bouton applique a son enfant.
      final BuildContext ctx = tester.element(
        find.text(RelioStrings.nameContinue),
      );
      final Color effective = DefaultTextStyle.of(ctx).style.color ??
          const Color(0xFF000000);

      // ignore: avoid_print
      print('DEBUG desactive libelleRendu=$effective contrasteSurBlanc='
          '${contraste(effective, const Color(0xFFFFFFFF)).toStringAsFixed(2)}');

      // Le libelle du bouton désactivé doit rester lisible : 4,5:1 pour du
      // texte de 16 dp. Le défaut Material (onSurface à 38 %) plafonne à
      // 2,37:1 — l'élève ne voit plus l'action.
      expect(
        contraste(effective, const Color(0xFFFFFFFF)),
        greaterThanOrEqualTo(4.5),
        reason: 'libelle du bouton desactive illisible (WCAG AA exige 4,5:1)',
      );

      // Un bouton desactive doit rester identifiable : fond et libelle ne
      // peuvent pas se confondre, sinon l'eleve ne voit plus l'action.
      if (arrierePlan != null && avantPlan != null) {
        expect(contraste(avantPlan, arrierePlan), greaterThan(2.0),
            reason: 'libelle et fond du bouton desactive se confondent');
      }
      // Et son fond ne doit pas disparaitre dans l'ecran.
      // Le fond seul (`primaryContainer`) est trop proche de l'ecran :
      // c'est la BORDURE qui redessine le contour du bouton desactive.
      final BorderSide? bordure = theme.filledButtonTheme.style?.side
          ?.resolve(<WidgetState>{WidgetState.disabled});
      expect(bordure, isNotNull, reason: 'le bouton desactivé doit avoir un contour');
      expect(bordure!.width, greaterThan(0),
          reason: 'bouton desactive sans contour : sa forme disparait');
    });
  });

  group('Zones cliquables', () {
    testWidgets('une seconde validation pendant la sortie est refusee',
        (WidgetTester tester) async {
      // Le contenu s'estompe mais reste dans l'arbre : `Opacity` a 0 ne
      // bloque PAS le toucher. Le bouton doit donc etre desactive par son
      // `onPressed`, sinon le prenom serait ecrit deux fois.
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

      final Finder bouton = find.widgetWithText(
        FilledButton,
        RelioStrings.nameContinue,
      );

      await tester.tap(bouton);
      await tester.pump();
      expect(appele, 1);

      // Le bouton reste dans l'arbre, mais il doit etre inactif.
      expect(bouton, findsOneWidget);
      expect(tester.widget<FilledButton>(bouton).onPressed, isNull);

      await tester.tap(bouton, warnIfMissed: false);
      await tester.pump();
      expect(appele, 1, reason: 'aucune double soumission pendant la sortie');
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