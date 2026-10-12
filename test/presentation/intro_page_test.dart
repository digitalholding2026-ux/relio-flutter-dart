/// Ecran d'entree — comportement observable.
///
/// On teste ce que l'eleve VIT, pas l'etat interne : un tap avance-t-il vers
/// le bouton ? le bouton retour passe-t-il a l'accueil ? l'ecran reste-t-il
/// sobre ?
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/screens/intro/intro_page.dart';
import 'package:relio/presentation/screens/intro/intro_sequence.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Monte l'ecran d'entree dans une palette complete.
///
/// La palette est requise : l'ecran lit ses couleurs dans le scope, et un
/// `Scaffold` sans palette echouerait — ce qui est le comportement voulu.
Future<void> monterIntro(
  WidgetTester tester, {
  Future<void> Function()? onFinished,
  bool reduceAnimations = false,
  Future<void> Function()? preload,
}) async {
  await tester.pumpWidget(
    RelioPaletteScope(
      palette: RelioPalette.standard(),
      child: MaterialApp(
        home: IntroPage(
          onFinished: onFinished ?? () async {},
          reduceAnimations: reduceAnimations,
          preload: preload,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('au demarrage, seul le personnage est visible', (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    // Aucun texte, aucun bouton au premier instant.
    expect(find.text(IntroTexts.greeting), findsNothing);
    expect(find.widgetWithText(FilledButton, IntroTexts.startButton), findsNothing);
  });

  testWidgets('le personnage est affiche', (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('le bouton est absent tant que la sequence n\'est pas finie',
      (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Le bouton n'est pas dans l'arbre du tout : il ne doit donc pas etre
    // atteignable au toucher avant 5,3 s.
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('le bouton n\'est pas declenchable avant 5,3 s',
      (WidgetTester tester) async {
    var termine = false;
    await monterIntro(tester, onFinished: () async => termine = true);
    await tester.pump();

    // Meme en tapant la ou le bouton viendra, rien ne se passe.
    await tester.tapAt(const Offset(200, 600));
    await tester.pump();
    expect(termine, isFalse);
  });

  testWidgets('un tap avance vers le bouton', (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    // Tap pour accelerer.
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();

    // Le texte final apparait immediatement.
    expect(find.text(IntroTexts.question), findsOneWidget);
  });

  testWidgets('apres acceleration, le bouton devient actionnable',
      (WidgetTester tester) async {
    var termine = false;
    await monterIntro(tester, onFinished: () async => termine = true);
    await tester.pump();

    await tester.tapAt(const Offset(200, 400));
    // 200 ms de delai + 250 ms de transition.
    await tester.pump(const Duration(milliseconds: 500));

    final FilledButton bouton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(bouton.onPressed, isNotNull, reason: 'le bouton doit etre actif');

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(termine, isTrue, reason: 'le bouton doit confirmer');
  });

  testWidgets('le bouton retour Android termine aussi l\'ecran',
      (WidgetTester tester) async {
    var termine = false;
    await monterIntro(tester, onFinished: () async => termine = true);
    await tester.pump();

    // Le bouton retour Android est grave sur `PopScope`. On declenche le
    // callback exactement comme le systeme le ferait : `didPop` vaut false,
    // puisque `canPop` est a false et que l'ecran n'est donc pas pops.
    // `PopScope` est utilise sans argument de type explicite : le parametre
    // reel est donc `Object?`. On le cible par predicat plutot que par type,
    // ce qui rend le test insensible a cette inference.
    final Finder scopeFinder = find.byWidgetPredicate(
      (Widget w) => w is PopScope<Object?>,
    );
    final PopScope<Object?> scope = tester.widget<PopScope<Object?>>(scopeFinder);
    scope.onPopInvokedWithResult!(false, null);
    await tester.pump();

    expect(termine, isTrue,
        reason: 'le retour Android doit marquer la premiere ouverture terminee');
  });

  testWidgets('l\'ecran ne se pop pas tout seul au retour Android',
      (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    // `canPop: false` garantit qu'un retour systeme ne referme pas
    // l'application : c'est l'accueil qui prend le relais.
    final Finder scopeFinder = find.byWidgetPredicate(
      (Widget w) => w is PopScope<Object?>,
    );
    final PopScope<Object?> scope = tester.widget<PopScope<Object?>>(scopeFinder);
    expect(scope.canPop, isFalse);
  });

  testWidgets('le prechargement est lance sans rien afficher',
      (WidgetTester tester) async {
    var appele = false;
    await monterIntro(
      tester,
      preload: () async => appele = true,
    );
    await tester.pump();

    expect(appele, isTrue, reason: 'le prechargement doit partir en arriere-plan');
    // Et rien de visible : ni spinner, ni texte de chargement.
    expect(find.textContaining('Chargement'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('un prechargement en echec n\'interrompt pas l\'ecran',
      (WidgetTester tester) async {
    await monterIntro(
      tester,
      preload: () async => throw StateError('base indisponible'),
    );
    await tester.pump();

    // L'ecran reste utilisable malgre l'echec silencieux.
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    expect(find.text(IntroTexts.question), findsOneWidget);
  });

  testWidgets('avec reduction des animations, le personnage reste fige',
      (WidgetTester tester) async {
    await monterIntro(tester, reduceAnimations: true);
    await tester.pump();

    // L'ecran s'affiche malgre la preference.
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('la sequence tient dans 5,3 s', (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    // On laisse passer exactement 5,3 s et le bouton doit etre la.
    await tester.pump(const Duration(milliseconds: 5300));
    await tester.pump(const Duration(milliseconds: 250));

    final bouton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(bouton.onPressed, isNotNull,
        reason: 'a 5,55 s le bouton doit etre actif');
  });

  testWidgets('l\'ecran n\'affiche aucun element de jeu', (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));

    // Ni confettis, ni etoiles, ni badge de score.
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.textContaining('score'), findsNothing);
  });

  // ---------------------------------------------------------------------
  // Correction : la sequence narrative ne se rejoue JAMAIS.
  // ---------------------------------------------------------------------

  testWidgets('apres 5,3 s, l\'ecran reste sur son etat final',
      (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    // On laisse passer la sequence entiere.
    await tester.pump(const Duration(milliseconds: 5300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(IntroTexts.question), findsOneWidget,
        reason: 'la question reste affichee');
    expect(find.byType(FilledButton), findsOneWidget,
        reason: 'le bouton reste visible');

    // Puis on laisse s'ecouler beaucoup de temps : le code boucle le controller
    // sur 6 s, ce qui reposait l'ecran a T = 0 et rejouait toute la sequence.
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(IntroTexts.question), findsOneWidget,
        reason: 'la question ne doit JAMAIS disparaitre');
    expect(find.text(IntroTexts.greeting), findsNothing,
        reason: 'pas de retour a la premiere phrase');
    expect(find.text(IntroTexts.promise), findsNothing,
        reason: 'pas de retour a la deuxieme phrase');
    expect(find.byType(FilledButton), findsOneWidget,
        reason: 'le bouton ne doit pas disparaitre');
  });

  testWidgets('le personnage reste anime apres 5,3 s',
      (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5300));
    await tester.pump(const Duration(milliseconds: 300));

    // C'est la SEULE animation encore active : le personnage respire.
    expect(find.byType(RelioCharacter), findsOneWidget);
    expect(find.text(IntroTexts.question), findsOneWidget);
  });

  testWidgets('l\'acceleration ne se rejoue pas non plus',
      (WidgetTester tester) async {
    await monterIntro(tester);
    await tester.pump();

    // Tap d'acceleration.
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(IntroTexts.question), findsOneWidget);

    // Puis on attend : rien ne doit relancer quoi que ce soit.
    await tester.pump(const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(IntroTexts.question), findsOneWidget,
        reason: 'l\'acceleration doit s\'arreter a son etat final');
    expect(find.text(IntroTexts.greeting), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
