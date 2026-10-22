/// Tests de l'écran d'accueil : objectif de séquence et message contextuel.
///
/// Ces deux éléments viennent de DONNÉES FACTICES : les tests vérifient que
/// l'interface affiche exactement la variable fournie, sans interpréter ni
/// reformuler. Le jour où le moteur alimentera [HomeState], rien d'autre ne
/// devra changer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/home/home_state.dart';
import 'package:relio/presentation/home/home_widgets.dart';
import 'package:relio/presentation/screens/home_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';

/// Enveloppe l'accueil comme le fait l'application : palette + thème.
Widget _accueil({
  HomeState? state,
  VoidCallback? onContinue,
  VoidCallback? onFiveMinutes,
  VoidCallback? onWarmup,
  void Function(String lessonId)? onOpenLesson,
}) {
  return RelioPaletteScope(
    palette: RelioPalette.standard(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RelioTheme.build(),
      home: HomePage(
        name: 'Camille',
        homeState: state,
        onContinue: onContinue ?? () {},
        onFiveMinutes: onFiveMinutes ?? () {},
        onWarmup: onWarmup ?? () {},
        onOpenLesson: onOpenLesson ?? (_) {},
        // Les animations d'apparition n'ont rien à prouver ici : on teste le
        // contenu, pas le remplissage des barres.
        reduceAnimations: true,
      ),
    ),
  );
}

void main() {
  group('Objectif de séquence', () {
    testWidgets('affiche « Séquence 1 • 2 notions sur 5 validées »',
        (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.mock()));
      await tester.pumpAndSettle();

      expect(
        find.text('Séquence 1 • 2 notions sur 5 validées'),
        findsOneWidget,
      );
      expect(find.byType(SequenceObjectiveBar), findsOneWidget);
    });

    testWidgets('la barre d’objectif est au-dessus du prénom', (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.mock()));
      await tester.pumpAndSettle();

      final double barre =
          tester.getTopLeft(find.byType(SequenceObjectiveBar)).dy;
      final double prenom = tester.getTopLeft(find.byType(GreetingHeader)).dy;

      expect(barre, lessThan(prenom));
    });

    testWidgets('le trait reflète la part validée, sans chiffre', (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.mock()));
      await tester.pumpAndSettle();

      final double largeur =
          tester.getSize(find.byType(SequenceObjectiveBar)).width;
      final Finder rempli = find
          .descendant(
            of: find.byType(SequenceObjectiveBar),
            matching: find.byType(Container),
          )
          .last;
      final double largeurRemplie = tester.getSize(rempli).width;

      // 2 notions sur 5 : le trait occupe 40 % de la largeur disponible.
      expect(largeurRemplie, closeTo(largeur * 0.4, 1));

      // Aucun pourcentage n'est écrit dans la ligne d'objectif.
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('Message contextuel', () {
    testWidgets('sans blocage récent, le message par défaut s’affiche',
        (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.mock()));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.relioMessage), findsOneWidget);
      expect(find.text(RelioStrings.relioMessageSubtraction), findsNothing);
    });

    testWidgets('un blocage récent change la phrase, et rien d’autre',
        (tester) async {
      await tester.pumpWidget(
        _accueil(
          state: HomeState.mock(
            recentBlock: RecentBlockCodes.subtractionWrong,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.relioMessageSubtraction), findsOneWidget);
      expect(find.text(RelioStrings.relioMessage), findsNothing);

      // L'objectif et la carte « Reprendre » ne bougent pas.
      expect(
        find.text('Séquence 1 • 2 notions sur 5 validées'),
        findsOneWidget,
      );
      expect(find.text(RelioStrings.resumeLabel), findsOneWidget);
      expect(find.text(RelioStrings.resumeProgress(2, 4)), findsOneWidget);
    });

    testWidgets('le message affiché est bien celui de l’état fourni',
        (tester) async {
      const String phrase = 'Phrase fournie par le moteur.';
      final HomeState etat = HomeState(
        objective: const SequenceObjective(
          sequence: 1,
          validated: 2,
          notions: 5,
        ),
        message: phrase,
        resume: HomeState.mock().resume,
        lessons: HomeState.mock().lessons,
      );

      await tester.pumpWidget(_accueil(state: etat));
      await tester.pumpAndSettle();

      expect(find.text(phrase), findsOneWidget);
    });
  });

  group('Actions rapides', () {
    testWidgets('les deux cartes sont présentes et cliquables', (tester) async {
      int cinqMinutes = 0;
      int echauffement = 0;

      await tester.pumpWidget(
        _accueil(
          onFiveMinutes: () => cinqMinutes++,
          onWarmup: () => echauffement++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(RelioStrings.quickFiveTitle));
      await tester.pumpAndSettle();
      expect(cinqMinutes, 1);

      await tester.tap(find.text(RelioStrings.quickWarmupTitle));
      await tester.pumpAndSettle();
      expect(echauffement, 1);
    });

    testWidgets('aucun « Défi de la semaine » sur l’accueil', (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.mock()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Défi'), findsNothing);
      expect(find.textContaining('défi'), findsNothing);
    });
  });

  group('État vide — nouvel élève', () {
    testWidgets('la carte invite à COMMENCER, en orange, sans position',
        (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.empty()));
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text(RelioStrings.startLabel));
      expect(label.style?.color, RelioPalette.standard().brand);

      expect(find.text(RelioStrings.startFirstExercise), findsOneWidget);
      expect(find.text(RelioStrings.resumeLabel), findsNothing);
      expect(find.text(RelioStrings.resumeProgress(2, 4)), findsNothing);
      expect(find.text(RelioStrings.chapter1CardTitle), findsOneWidget);
    });

    testWidgets('le message et l’objectif partent de zéro', (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.empty()));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.relioMessageFirstSteps), findsOneWidget);
      expect(find.text(RelioStrings.relioMessage), findsNothing);
      expect(
        find.text(RelioStrings.sequenceObjective(1, 0, 3)),
        findsOneWidget,
      );
    });

    testWidgets('les trois leçons sont « À commencer »', (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.empty()));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.statusNotStarted), findsNWidgets(3));
      expect(find.text(RelioStrings.statusInProgress), findsNothing);
      expect(find.text(RelioStrings.statusMastered), findsNothing);
    });
  });

  group('Mise à jour de l’état', () {
    /// État d'un élève qui vient de réussir l'exercice 1.
    final HomeState premierExerciceReussi = HomeState(
      objective: const SequenceObjective(
        sequence: 1,
        validated: 0,
        notions: 3,
      ),
      message: RelioStrings.relioMessageFirstExerciseDone,
      resume: ResumeTarget(
        chapterTitle: RelioStrings.chapter1CardTitle,
        positionLabel: RelioStrings.resumeProgress(2, 4),
      ),
      lessons: HomeState.empty().lessons,
    );

    testWidgets('un nouvel état remplace l’ancien : Commencer → Continuer',
        (tester) async {
      await tester.pumpWidget(_accueil(state: HomeState.empty()));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.startLabel), findsOneWidget);
      expect(find.text(RelioStrings.startFirstExercise), findsOneWidget);

      // La coquille reconstruit l'accueil après avoir relu l'historique : le
      // nouvel état doit être PRIS EN COMPTE, même si l'écran existait déjà.
      await tester.pumpWidget(_accueil(state: premierExerciceReussi));
      await tester.pumpAndSettle();

      expect(find.text(RelioStrings.startLabel), findsNothing);
      expect(find.text(RelioStrings.startFirstExercise), findsNothing);
      expect(find.text(RelioStrings.resumeLabel), findsOneWidget);
      expect(find.text(RelioStrings.resumeContinue), findsOneWidget);
      expect(find.text(RelioStrings.resumeProgress(2, 4)), findsOneWidget);
      expect(
        find.text(RelioStrings.relioMessageFirstExerciseDone),
        findsOneWidget,
      );
    });
  });
}
