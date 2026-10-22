/// Onboarding — ecran du test d'entree.
///
/// Ce que l'eleve VIT pendant les cinq questions, et surtout ce qu'il ne
/// voit PAS : aucun retour sur la justesse d'une reponse, aucun score, aucune
/// correction.
///
/// Le parcours est monte sur une BASE REELLE : les tests doivent prouver que
/// l'ecran n'avance pas avant la confirmation de l'ecriture, ce qui suppose
/// une persistance authentique.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/entrytest/entry_test_onboarding.dart';
import 'package:relio/domain/entrytest/entry_test_question.dart';
import 'package:relio/domain/entrytest/entry_test_repository.dart';
import 'package:relio/domain/entrytest/entry_test_session.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/settings/learner_settings.dart';
import 'package:relio/presentation/branding/relio_character.dart';
import 'package:relio/presentation/screens/onboarding/entry_kit.dart';
import 'package:relio/presentation/screens/onboarding/entry_test_page.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/math_text.dart';

import '../helpers/fraction_finders.dart';
import '../helpers/test_database.dart';

/// Orchestrateur dont l'ecriture echoue TOUJOURS.
///
/// Simule une base indisponible sans toucher au domaine : le defi de
/// l'interface est de ne pas avancer, pas de savoir pourquoi.
///
/// Seule `submitAnswer` est remplacee — tout le reste, y compris
/// `openSession`, reste le vrai parcours. C'est ce qui rend le test
/// honnete : seul l'echec d'ecriture est simule.
class _OnboardingEnPanne extends EntryTestOnboarding {
  _OnboardingEnPanne(super.entries, super.settings);

  @override
  Future<EntryTestAnswer> submitAnswer({
    required EntryTestSession session,
    required EntryTestQuestion question,
    required String rawAnswer,
  }) {
    throw StateError('base indisponible');
  }
}

/// La question affichee a l'instant present.
///
/// L'indicateur « N sur 5 » donne le rang, et le rang donne la question dans
/// [EntryTestBank]. On ne lit donc jamais l'etat interne du widget — le test
/// observe ce qui est affiche, comme l'eleve.
EntryTestQuestion? _questionAffichee(WidgetTester tester) {
  final Finder indicateur = find.textContaining('sur 5');
  if (indicateur.evaluate().isEmpty) return null;
  final String texte = tester.widget<Text>(indicateur.first).data!;
  final int rang = int.parse(texte.split(' ').first);
  for (final EntryTestQuestion q in EntryTestBank.questions) {
    if (q.order == rang) return q;
  }
  return null;
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late EntryTestRepository entries;
  late EntryTestOnboarding onboarding;
  late EntryTestSession session;

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    settings = SettingsRepository(db);
    entries = EntryTestRepository(LearningEventRepository(db));
    onboarding = EntryTestOnboarding(entries, settings);
    session = await onboarding.openSession();
  });

  /// Monte l'ecran de test sur [session].
  ///
  /// `reduceAnimations: true` par defaut : les fondus ne doivent pas ralentir
  /// les tests, et le comportement observable est le meme.
  Future<void> monterTest(
    WidgetTester tester, {
    EntryTestSession? sessionCourante,
    VoidCallback? onFinished,
    bool reduceAnimations = true,
    EntryTestOnboarding? flow,
  }) async {
    await tester.pumpWidget(
      RelioPaletteScope(
        palette: RelioPalette.standard(),
        child: MaterialApp(
          home: EntryTestPage(
            onboarding: flow ?? onboarding,
            session: sessionCourante ?? session,
            reduceAnimations: reduceAnimations,
            onFinished: onFinished ?? () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Repond juste a la question courante et passe a la suivante.
  Future<void> repondre(WidgetTester tester) async {
    // La question courante est lue depuis l'ECRAN, pas depuis la session du
    // test : apres une transition, c'est l'ecran qui fait foi.
    final EntryTestQuestion? question = _questionAffichee(tester);
    if (question == null) return;

    if (question.isChoice) {
      await tester.tap(fraction(question.expectedValue));
    } else {
      await tester.enterText(find.byType(TextField), question.expectedValue);
    }
    await tester.pump();

    await tester.tap(find.text(RelioStrings.entryContinue));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Progression', () {
    testWidgets('la premiere question affiche « 1 sur 5 »',
        (WidgetTester tester) async {
      await monterTest(tester);
      expect(find.text('1 sur 5'), findsOneWidget);
    });

    testWidgets('l\'indicateur suit le nombre de reponses enregistrees',
        (WidgetTester tester) async {
      await monterTest(tester);
      await repondre(tester);

      // La reponse est enregistree : l'indicateur avance d'un cran.
      expect(find.text('2 sur 5'), findsOneWidget);
    });
  });

  group('Questions', () {
    testWidgets('les cinq questions apparaissent dans l\'ordre valide',
        (WidgetTester tester) async {
      await monterTest(tester);

      // Question 1 — « 24 ÷ 6 + 3 », entier.
      expect(find.byType(MathText), findsOneWidget);
      expect(find.textContaining('24'), findsWidgets);

      for (int i = 0; i < 5; i++) {
        expect(find.text('${i + 1} sur 5'), findsOneWidget);
        if (i == 4) break;
        await repondre(tester);
      }
    });

    testWidgets('la question a choix propose les trois fractions',
        (WidgetTester tester) async {
      // Repond a la question 1 pour atteindre la question 2.
      await monterTest(tester);
      await repondre(tester);

      expect(find.text('2 sur 5'), findsOneWidget);
      // L'énoncé lui-même porte une fraction empilée (« 1/2 »).
      expect(fraction('1/2'), findsOneWidget);
      // Fractions EMPILÉES : numérateur, barre, dénominateur. La notation
      // source « 2/3 » n'est plus affichée telle quelle.
      expect(fraction('2/3'), findsOneWidget);
      expect(fraction('2/4'), findsOneWidget);
      expect(fraction('3/4'), findsOneWidget);
      expect(find.text('2/3'), findsNothing);
      expect(find.text('2/4'), findsNothing);
      expect(find.text('3/4'), findsNothing);
    });

    testWidgets('aucun AppBar sur l\'ecran de test', (WidgetTester tester) async {
      await monterTest(tester);
      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('Saisie', () {
    testWidgets('le bouton est inactif tant qu\'aucune reponse n\'est fournie',
        (WidgetTester tester) async {
      await monterTest(tester);

      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.entryContinue),
      );
      expect(bouton.onPressed, isNull,
          reason: 'aucune reponse : le bouton ne doit pas etre actionnable');
    });

    testWidgets('le bouton devient actif apres saisie',
        (WidgetTester tester) async {
      await monterTest(tester);

      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();

      final FilledButton bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.entryContinue),
      );
      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('les chiffres sont acceptes, les lettres refusees',
        (WidgetTester tester) async {
      await monterTest(tester);

      await tester.enterText(find.byType(TextField), '12abc');
      await tester.pump();

      // Le filtre laisse passer les chiffres et jette le reste.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '12',
      );
    });

    testWidgets('le signe moins n\'est accepte qu\'en premiere position',
        (WidgetTester tester) async {
      await monterTest(tester);

      await tester.enterText(find.byType(TextField), '3-5');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '35',
        reason: 'un tiret au milieu n\'est pas un signe',
      );

      await tester.enterText(find.byType(TextField), '-3');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '-3',
        reason: 'en tete de saisie, le tiret est un signe',
      );
    });
  });

  group('Choix', () {
    testWidgets('aucun radio ni coche n\'accompagne les cartes',
        (WidgetTester tester) async {
      await monterTest(tester);
      await repondre(tester);

      expect(find.byType(Radio), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Icon), findsNothing,
          reason: 'l\'etat se lit au trait et au fond, pas par une icone');
    });

    testWidgets('selectionner un choix rend le bouton actif',
        (WidgetTester tester) async {
      await monterTest(tester);
      await repondre(tester);

      FilledButton bouton() => tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, RelioStrings.entryContinue),
          );

      expect(bouton().onPressed, isNull);

      await tester.tap(fraction('2/4'));
      await tester.pump();

      expect(bouton().onPressed, isNotNull);
    });
  });

  group('Silence pedagogique', () {
    testWidgets('une reponse JUSTE ne declenche aucun retour',
        (WidgetTester tester) async {
      await monterTest(tester);

      // Question 1, reponse attendue 7 : on repond JUSTE.
      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.entryContinue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ni panneau, ni message, ni celebration : rien n'est dit sur la
      // justesse de la reponse.
      expect(find.textContaining('Bonne'), findsNothing);
      expect(find.textContaining('Bravo'), findsNothing);
      expect(find.textContaining('réussi'), findsNothing);
      // Et la question suivante s'affiche normalement.
      expect(find.text('2 sur 5'), findsOneWidget);
    });

    testWidgets('une reponse FAUSSE ne declenche aucun retour',
        (WidgetTester tester) async {
      await monterTest(tester);

      // Mauvaise reponse, volontairement.
      await tester.enterText(find.byType(TextField), '999');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.entryContinue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Exactement le meme ecran qu'apres une bonne reponse : l'eleve ne
      // peut pas deduire de l'affichage que sa reponse etait fausse.
      expect(find.text('2 sur 5'), findsOneWidget);
      expect(find.textContaining('faux'), findsNothing);
    });

    testWidgets('aucun score, pourcentage ni chronometre n\'est affiche',
        (WidgetTester tester) async {
      await monterTest(tester);

      // Les cinq questions, pour etre sur que rien ne fuit en cours de route.
      for (int i = 0; i < 4; i++) {
        await repondre(tester);
      }

      for (final String interdit in <String>['%', 'score', 'points', '/5']) {
        expect(find.textContaining(interdit), findsNothing,
            reason: '« $interdit » ne doit jamais apparaitre');
      }
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('aucun bouton de retour vers une question precedente',
        (WidgetTester tester) async {
      await monterTest(tester);
      await repondre(tester);

      expect(find.byType(BackButton), findsNothing);
      expect(find.text(RelioStrings.back), findsNothing);
    });
  });

  group('Persistance', () {
    testWidgets('l\'interface n\'avance pas sans reponse enregistree',
        (WidgetTester tester) async {
      await monterTest(tester);

      final EntryTestQuestion? premiere = session.nextQuestion;
      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.entryContinue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // La reponse EST enregistree : c'est la preuve que l'avancement suit
      // l'ecriture, et non l'inverse.
      final EntryTestSession? relue =
          await entries.loadSession(session.sessionId);
      expect(relue!.answeredCount, 1);
      expect(premiere!.id, 'entry-q1');
      expect(find.text('2 sur 5'), findsOneWidget);
    });

    testWidgets('cinq reponses enregistrees mènent a la cloture',
        (WidgetTester tester) async {
      var termine = false;
      await monterTest(tester, onFinished: () {
        termine = true;
      });

      for (int i = 0; i < 5; i++) {
        await repondre(tester);
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(termine, isTrue,
          reason: 'apres la cinquieme reponse, l\'ecran passe a la cloture');
    });
  });

  group('Echec d\'enregistrement', () {
    testWidgets('la saisie est conservee et l\'ecran n\'avance pas',
        (WidgetTester tester) async {
      var termine = false;
      await monterTest(
        tester,
        flow: _OnboardingEnPanne(entries, settings),
        onFinished: () {
          termine = true;
        },
      );

      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.entryContinue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // L'echec est NEUTRE : il ne dit rien de la reponse.
      expect(find.text(RelioStrings.entrySaveError), findsOneWidget);
      expect(find.text(RelioStrings.entryRetry), findsOneWidget);

      // La saisie n'est PAS effacee.
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '7',
          reason: 'l\'eleve ne doit pas perdre ce qu\'il a tape');

      // Et l'ecran n'a pas avance.
      expect(find.text('1 sur 5'), findsOneWidget);
      expect(termine, isFalse);
    });

    testWidgets('le reessai est possible', (WidgetTester tester) async {
      await monterTest(tester, flow: _OnboardingEnPanne(entries, settings));

      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      await tester.tap(find.text(RelioStrings.entryContinue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Le bouton « Reessayer » relance exactement le meme appel.
      final FilledButton reessai = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, RelioStrings.entryRetry),
      );
      expect(reessai.onPressed, isNotNull);
    });
  });

  group('Marque en retrait', () {
    testWidgets('le test affiche un mark de 24 dp', (WidgetTester tester) async {
      await monterTest(tester);
      final double taille = tester.getSize(find.byType(RelioCharacter)).width;
      expect(taille, EntryBrand.test);
    });
  });
}