/// Onboarding — flux complet du parcours d'entrée, de l'ouverture à l'accueil.
///
/// EXERCE RÉELLEMENT la machine à étapes de `RelioApp`. Les autres usages de
/// `RelioApp` passent tous par `showIntro: false`, ce qui court-circuite le
/// parcours et laisse donc ce flux sans couverture. Ce fichier le couvre.
///
/// LE TEMPS EST AVANCÉ, PAS INJECTÉ. L'ouverture ne porte plus de séquence
/// narrative : elle se joue, puis rend la main. Un test ne peut donc pas
/// « compresser » une chronologie — il avance simplement l'horloge, ce qui
/// exerce exactement le même code que la production.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/screens/intro/opening_page.dart';
import 'package:relio/presentation/screens/onboarding/onboarding_flow.dart';
import 'package:relio/presentation/screens/onboarding/welcome_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    settings = SettingsRepository(db);
  });

  /// Monte l'application avec le parcours d'entrée ACTIF.
  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(RelioApp(database: db));
    // La lecture du marqueur est asynchrone : on laisse l'application
    // décider avant d'affirmer quoi que ce soit sur son écran.
    await tester.pump();
  }

  /// Joue l'ouverture et arrive sur l'écran Bienvenue.
  ///
  /// L'horloge est avancée PAR PAS COURTS, et non d'un seul coup. Deux raisons
  /// : l'écran est construit pendant un `pump` et son contrôleur ne démarre
  /// qu'au suivant ; et `pumpAndSettle` s'arrête dès qu'aucune frame n'est
  /// plus attendue — il n'avancerait donc pas jusqu'à la minuterie de sortie.
  ///
  /// Le total (12 × 250 ms) dépasse largement révélation + sortie, sans quoi
  /// un simple réglage de la chronologie ferait échouer le test au lieu de
  /// vérifier qu'elle reste traversable.
  Future<void> allerABienvenue(WidgetTester tester) async {
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget,
        reason: 'l\'ouverture doit toujours mener à la Bienvenue');
  }

  /// Laisse le parcours résoudre son étape de départ.
  ///
  /// Le parcours enchaîne plusieurs lectures asynchrones — marqueur de fin,
  /// prénom, ouverture de session — et chacune a besoin d'un tour de boucle
  /// pour se propager. On pompe donc plusieurs fois plutôt qu'une.
  ///
  /// Le total dépasse aussi le fondu croisé entre étapes (275 ms) : pendant
  /// le fondu, l'ancien écran reste dans l'arbre, et un `findsNothing` sur
  /// son contenu échouerait à tort.
  ///
  /// `pumpAndSettle` est exclu : le personnage respire en boucle, l'état ne
  /// se stabilise donc jamais, et la boucle expirerait.
  Future<void> laisserResoudre(WidgetTester tester) async {
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Tap sur « Commencer », puis résolution du parcours.
  Future<void> validerBienvenue(WidgetTester tester) async {
    await tester.tap(find.text(RelioStrings.welcomeStart));
    await tester.pump();
    await laisserResoudre(tester);
  }

  group('Étape 1 — Ouverture', () {
    testWidgets('le logo s\'affiche, sans bouton', (WidgetTester tester) async {
      await monter(tester);

      // Ni l'accueil, ni un bouton : l'ouverture ne demande rien.
      expect(find.byType(OnboardingFlow), findsNothing);
      expect(find.byType(FilledButton), findsNothing,
          reason: 'l\'ouverture ne porte aucun bouton');

      await allerABienvenue(tester);
    });

    testWidgets('l\'ouverture ne marque RIEN', (WidgetTester tester) async {
      await monter(tester);
      await allerABienvenue(tester);

      // Ni « vu », ni « terminé » : une ouverture regardée puis quittée ne
      // doit laisser aucun trace, sinon l'élève perdrait la reprise.
      expect(await settings.hasSeenEntryScreen(), isFalse);
      expect(await settings.hasCompletedFirstLaunch(), isFalse);
    });

    testWidgets('l\'ouverture mène à l\'écran Bienvenue, texte exact',
        (WidgetTester tester) async {
      await monter(tester);
      await allerABienvenue(tester);

      expect(find.text(RelioStrings.welcomeTitle), findsOneWidget);
      expect(find.text(RelioStrings.welcomeSubtitle), findsOneWidget);
      expect(find.text(RelioStrings.welcomeQuestion), findsOneWidget);
      expect(find.text(RelioStrings.welcomeStart), findsOneWidget);
    });

    testWidgets('avec animations réduites, l\'ouverture reste traversable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        RelioApp(
          database: db,
          settingsController: SettingsController(settings)
            ..apply((await settings.load()).copyWith(reduceAnimations: true)),
        ),
      );
      await tester.pump();
      await allerABienvenue(tester);

      expect(find.text(RelioStrings.welcomeStart), findsOneWidget,
          reason: 'réduire les animations ne doit pas bloquer le parcours');
    });
  });

  group('Étape 2 — Bienvenue', () {
    testWidgets('le tap sur Commencer marque l\'écran comme vu',
        (WidgetTester tester) async {
      await monter(tester);
      await allerABienvenue(tester);

      expect(await settings.hasSeenEntryScreen(), isFalse,
          reason: 'avant le tap, rien n\'est écrit');

      await validerBienvenue(tester);

      expect(await settings.hasSeenEntryScreen(), isTrue);
    });

    testWidgets('le tap ne solde PAS le parcours', (WidgetTester tester) async {
      await monter(tester);
      await allerABienvenue(tester);
      await validerBienvenue(tester);

      // C'est LA distinction des deux marqueurs : l'écran a été vu, le
      // parcours n'est pas terminé. Sans elle, un test interrompu serait
      // définitivement perdu.
      expect(await settings.hasSeenEntryScreen(), isTrue);
      expect(await settings.hasCompletedFirstLaunch(), isFalse);
    });
  });

  group('Étape 3 — Introduction au questionnaire', () {
    testWidgets('le parcours présente l\'introduction, texte exact',
        (WidgetTester tester) async {
      await monter(tester);
      await allerABienvenue(tester);
      await validerBienvenue(tester);

      expect(find.text(RelioStrings.entryIntroTitle), findsOneWidget);
      expect(find.text(RelioStrings.entryIntroBody), findsOneWidget);
      expect(find.text(RelioStrings.entryIntroFinal), findsOneWidget);
      expect(find.text(RelioStrings.entryIntroStart), findsOneWidget);
    });

    testWidgets('puis le prénom', (WidgetTester tester) async {
      await monter(tester);
      await allerABienvenue(tester);
      await validerBienvenue(tester);

      expect(find.text(RelioStrings.nameTitle), findsNothing,
          reason: 'l\'explication précède la saisie du prénom');

      await tester.tap(find.text(RelioStrings.entryIntroStart));
      await tester.pump();
      await laisserResoudre(tester);

      expect(find.text(RelioStrings.nameTitle), findsOneWidget);
      expect(find.text(RelioStrings.namePlaceholder), findsOneWidget);
    });

    testWidgets('un prénom déjà connu saute l\'explication ET le prénom',
        (WidgetTester tester) async {
      await settings.setName('Awa');
      await settings.markEntryScreenSeen();

      await monter(tester);
      await laisserResoudre(tester);

      expect(find.text(RelioStrings.entryIntroTitle), findsNothing,
          reason: 'l\'explication ne sert qu\'à annoncer une étape à venir');
      expect(find.text(RelioStrings.nameTitle), findsNothing);
      expect(find.text('1 sur 5'), findsOneWidget,
          reason: 'le test d\'entrée démarre directement');
    });
  });

  group('Reprise', () {
    testWidgets('un parcours déjà terminé ouvre directement sur l\'accueil',
        (WidgetTester tester) async {
      await settings.markEntryScreenSeen();
      await settings.markFirstLaunchCompleted();

      await monter(tester);
      await laisserResoudre(tester);

      expect(find.text(RelioStrings.welcomeTitle), findsNothing,
          reason: 'ni l\'ouverture ni la Bienvenue ne doivent être rejouées');
      expect(find.byType(OnboardingFlow), findsNothing);
    });

    testWidgets('écran vu mais parcours en cours : on reprend le parcours',
        (WidgetTester tester) async {
      // C'est l'état de REPRISE : l'écran a été vu, le parcours non terminé,
      // et aucun prénom n'a encore été saisi.
      await settings.markEntryScreenSeen();

      await monter(tester);
      await laisserResoudre(tester);

      expect(find.text(RelioStrings.welcomeStart), findsNothing,
          reason: 'entryScreenSeen suffit à sauter ouverture et Bienvenue');

      // Le parcours REPREND : il n'est ni soldé, ni renvoyé à l'accueil. Il
      // repasse par l'introduction, qui annonce une étape qui n'a pas encore
      // eu lieu, puis par le prénom.
      expect(find.text(RelioStrings.entryIntroTitle), findsOneWidget);
      expect(await settings.hasCompletedFirstLaunch(), isFalse);

      await tester.tap(find.text(RelioStrings.entryIntroStart));
      await tester.pump();
      await laisserResoudre(tester);

      expect(find.text(RelioStrings.nameTitle), findsOneWidget,
          reason: 'le parcours n\'est pas terminé : il reprend');
    });

    testWidgets('abandon avant le tap : l\'ouverture sera rejouée',
        (WidgetTester tester) async {
      // L'élève quitte l'application pendant l'ouverture. Rien n'a été écrit.
      await monter(tester);
      await allerABienvenue(tester);
      await laisserResoudre(tester);

      expect(await settings.hasSeenEntryScreen(), isFalse);
      expect(find.text(RelioStrings.welcomeStart), findsOneWidget);

      // Relance : l'ouverture est de nouveau proposée. On avance de la SEULE durée
      // de la révélation : le contrôleur démarre au pump suivant la
      // construction, la Bienvenue ne peut donc pas encore être affichée.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await monter(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(RelioStrings.welcomeStart), findsNothing,
          reason: 'l\'ouverture est en cours, la Bienvenue pas encore');
      expect(find.byType(OpeningPage), findsOneWidget);
    });
  });
}