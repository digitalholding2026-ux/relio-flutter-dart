/// Onboarding — flux complet de l'ecran d'entree.
///
/// EXERCE REELLEMENT [_RelioAppState._completeFirstLaunch].
///
/// Les seize usages de `RelioApp` existants passent tous par
/// `showIntro: false`, ce qui court-circuite l'ecran d'entree et laisse donc
/// ce flux sans couverture. Ce fichier le couvre enfin.
///
/// CHOIX TECHNIQUE — DUREE INJECTEE, et non horloge de test.
///
/// La sequence de l'ecran d'entree est portee par un `AnimationController` que
/// le code avance lui-meme (`_controller.forward()`). Injecter une horloge
/// n'y changerait rien : il n'y a pas d'horloge `DateTime` a prendre. La seule
/// prise sur ce temps est la DUREE du controller — d'ou un parametre dedie,
/// qui COMPRESSE toute la chronologie dans les memes proportions.
///
/// L'ecran d'entree garde sa chronologie figee en production : `duration` vaut
/// `null`, ce qui restitue exactement les 5,3 s de la regle 10. Le parametre
/// n'existe que pour les tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/screens/intro/intro_sequence.dart';
import 'package:relio/presentation/screens/onboarding/onboarding_flow.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  /// Duree injectee : 20 ms suffisent a exhausted la sequence, qui se joue
  /// proportionnellement a cette duree.
  const Duration quick = Duration(milliseconds: 20);

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    settings = SettingsRepository(db);
  });

  /// Monte l'application avec l'ecran d'entree ACTIF et une sequence ramenee
  /// a [quick].
  Future<void> monterAvecIntro(WidgetTester tester) async {
    await tester.pumpWidget(
      RelioApp(database: db, introDuration: quick),
    );
    // La lecture du marqueur est asynchrone : on laisse l'application
    // decider avant d'affirmer quoi que ce soit sur son ecran.
    await tester.pump();
  }

  /// Laisse le parcours finir de resoudre son etape de depart.
///
/// Le parcours enchaîne PLUSIEURS lectures asynchrones — marqueur de fin,
/// prénom, ouverture de session — et chacune a besoin d'un tour de boucle
/// pour se propager. On pompe donc plusieurs fois plutot qu'une.
///
/// `pumpAndSettle` est exclu : le personnage respire en boucle, l'etat ne
/// se stabilise donc jamais, et la boucle expirerait. C'est exactement la
/// raison pour laquelle la regle 10 interdit de tester l'ecran d'entree par
/// `pumpAndSettle`.
Future<void> laisserResoudre(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 5));
  }
}

group('Premiere ouverture', () {
    testWidgets('l\'ecran d\'entree s\'affiche quand il n\'a jamais ete vu',
        (WidgetTester tester) async {
      await monterAvecIntro(tester);

      expect(find.text(IntroTexts.greeting), findsNothing,
          reason: 'la sequence n\'a pas encore debut : rien n\'est affiche');

      // On laisse la sequence se jouer jusqu'a son terme.
      await tester.pump(quick);
      await tester.pump(quick);

      expect(find.text(IntroTexts.question), findsOneWidget,
          reason: 'la derniere phrase de l\'ecran d\'entree doit etre la');
      expect(find.text(IntroTexts.startButton), findsOneWidget);
    });

    testWidgets('apres le tap, entryScreenSeen passe a true',
        (WidgetTester tester) async {
      await monterAvecIntro(tester);
      await tester.pump(quick);
      await tester.pump(quick);

      expect(await settings.hasSeenEntryScreen(), isFalse,
          reason: 'avant le tap, rien n\'est ecrit');

      await tester.tap(find.text(IntroTexts.startButton));
      await tester.pump();
      await laisserResoudre(tester);

      expect(await settings.hasSeenEntryScreen(), isTrue,
          reason: 'le tap sur « Commencer » marque l\'ecran comme vu');
    });

    testWidgets('le tap ne solde PAS le parcours', (WidgetTester tester) async {
      await monterAvecIntro(tester);
      await tester.pump(quick);
      await tester.pump(quick);

      await tester.tap(find.text(IntroTexts.startButton));
      await tester.pump();
      await laisserResoudre(tester);

      // C'est LA distinction des deux marqueurs : l'ecran a ete vu, le
      // parcours n'est pas termine. Sans elle, un test interrompu serait
      // definitivement perdu.
      expect(await settings.hasSeenEntryScreen(), isTrue);
      expect(await settings.hasCompletedFirstLaunch(), isFalse,
          reason: 'aucun parcours ne peut etre solde par le seul ecran d\'entree');
    });

    testWidgets('le parcours enchaine vers l\'etape Prenom',
        (WidgetTester tester) async {
      await monterAvecIntro(tester);
      await tester.pump(quick);
      await tester.pump(quick);

      await tester.tap(find.text(IntroTexts.startButton));
      await tester.pump();
      await laisserResoudre(tester);

      // Aucun prenom en base : l'etape Prenom est donc proposee.
      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(find.text(RelioStrings.nameTitle), findsOneWidget);
      expect(find.text(RelioStrings.namePlaceholder), findsOneWidget);
    });

    testWidgets('le parcours enchaine vers le TEST si le prenom existe deja',
        (WidgetTester tester) async {
      // L'etape Prenom est facultative : un prenom deja connu la fait sauter.
      await settings.setName('Awa');

      await monterAvecIntro(tester);
      await tester.pump(quick);
      await tester.pump(quick);

      await tester.tap(find.text(IntroTexts.startButton));
      await tester.pump();
      await laisserResoudre(tester);

      expect(find.text(RelioStrings.nameTitle), findsNothing,
          reason: 'l\'etape Prenom doit etre sautee silencieusement');
      // Le test d'entree demarre : la premiere question est affichee.
      expect(find.text('1 sur 5'), findsOneWidget);
    });
  });

  group('Reprise', () {
    testWidgets('un parcours deja termine ouvre directement sur l\'accueil',
        (WidgetTester tester) async {
      await settings.markEntryScreenSeen();
      await settings.markFirstLaunchCompleted();

      await monterAvecIntro(tester);
      await tester.pump();
      await laisserResoudre(tester);

      expect(find.text(IntroTexts.question), findsNothing,
          reason: 'l\'ecran d\'entree ne doit pas etre rejoue');
      expect(find.byType(OnboardingFlow), findsNothing);
    });

    testWidgets('ecran d\'entree vu mais parcours en cours : on reprend le test',
        (WidgetTester tester) async {
      // C'est l'etat de REPRISE : l'ecran a ete vu, le parcours non termine.
      await settings.markEntryScreenSeen();

      await monterAvecIntro(tester);
      await laisserResoudre(tester);

      expect(find.text(IntroTexts.question), findsNothing,
          reason: 'entryScreenSeen suffit a sauter l\'ecran d\'entree');
      expect(find.text(RelioStrings.nameTitle), findsOneWidget,
          reason: 'le parcours n\'est pas termine : il reprend');
    });
  });
}