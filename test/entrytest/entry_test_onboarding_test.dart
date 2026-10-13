/// Test d'entree — parcours d'entree et fin du premier lancement.
///
/// Couvre les decisions VALIDÉES :
///  1. le parcours enchaine ouverture -> reponses -> fin ;
///  2. un prenom deja stocke n'est pas perdu ;
///  3. un echec d'ecriture n'avance pas et se retente sans doublon ;
///  4. une session interrompue est reprise ;
///  5. une session terminee n'est pas relancee ;
///  6. `firstLaunchCompleted` n'est pose qu'a la fin REELLE du parcours.
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';
import 'package:relio/domain/entrytest/entry_test_onboarding.dart';
import 'package:relio/domain/entrytest/entry_test_question.dart';
import 'package:relio/domain/entrytest/entry_test_repository.dart';
import 'package:relio/domain/entrytest/entry_test_session.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/settings/learner_settings.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late EntryTestRepository entries;
  late EntryTestOnboarding onboarding;

  DateTime instant(int seconds) => DateTime.utc(2026, 1, 1, 9, 0, seconds);

  /// Identifiants de session previsibles : le test ne doit pas dependre
  /// d'un UUID.
  var compteur = 0;
  String prochainId() => 'session-${++compteur}';

  setUp(() async {
    db = await openTestDatabase();
    registerTestDatabase(db);
    settings = SettingsRepository(db);
    entries = EntryTestRepository(
      LearningEventRepository(db),
      clock: () => instant(10),
    );
    onboarding = EntryTestOnboarding(
      entries,
      settings,
      clock: () => instant(10),
      idGenerator: prochainId,
    );
  });

  /// Repond justement a toutes les questions de [session] ET persiste chaque
  /// reponse, en passant par le vrai parcours.
  Future<EntryTestSession> repondreTout(EntryTestSession session) async {
    EntryTestSession courante = session;
    for (final EntryTestQuestion q in EntryTestBank.questions) {
      courante = courante.withAnswer(
        await onboarding.submitAnswer(
          session: courante,
          question: q,
          rawAnswer: q.expectedValue,
        ),
      );
    }
    return courante;
  }

  group('Prenom', () {
    test('aucun prenom au depart', () async {
      expect(await onboarding.hasValidName(), isFalse);
      expect(await onboarding.storedName(), '');
    });

    test('le prenom enregistre est relu', () async {
      await settings.setName('Awa');
      expect(await onboarding.hasValidName(), isTrue);
      expect(await onboarding.storedName(), 'Awa');
    });

    test('un prenom vide n\'est pas valide', () async {
      await settings.setName('   ');
      expect(await onboarding.hasValidName(), isFalse);
    });

    test('le prenom survit a une fermeture', () async {
      await settings.setName('Awa');
      expect((await settings.load()).name, 'Awa');
    });

    // -------------------------------------------------------------------
    // Delegate d'ECRITURE — le seul des trois a avoir manque au premier
    // tour : `storedName` et `hasValidName` existaient deja.
    // -------------------------------------------------------------------

    test('setName ecrit le prenom et le rend lisible', () async {
      await onboarding.setName('Awa');

      expect(await onboarding.storedName(), 'Awa');
      expect(await onboarding.hasValidName(), isTrue);
    });

    test('un second prenom remplace le precedent', () async {
      await onboarding.setName('Awa');
      await onboarding.setName('Mariam');

      expect(await onboarding.storedName(), 'Mariam');
    });

    test('setName accepte un prenom court comme un prenom long', () async {
      // Aucune regle de forme : c'est la decision validee.
      await onboarding.setName('Jo');
      expect(await onboarding.storedName(), 'Jo');

      await onboarding.setName('Jean-Baptiste');
      expect(await onboarding.storedName(), 'Jean-Baptiste');
    });

    test('setName n\'ecrit aucun marqueur de parcours', () async {
      await onboarding.setName('Awa');

      // Le prenom n'est pas un etat du parcours : il ne solde ni l'ecran
      // d'entree, ni le parcours.
      expect(await onboarding.hasSeenEntryScreen(), isFalse);
      expect(await onboarding.hasCompletedFirstLaunch(), isFalse);
    });

    test('un prenom vide redevient non valide', () async {
      await onboarding.setName('Awa');
      await onboarding.setName('   ');

      expect(await onboarding.hasValidName(), isFalse,
          reason: 'un prenom blanc doit pouvoir effacer le precedent');
    });
  });

  group('Ouverture de session', () {
    test('une premiere ouverture cree une session', () async {
      final EntryTestSession session = await onboarding.openSession();

      expect(session.sessionId, 'session-1');
      expect(session.isInProgress, isTrue);
      expect(session.remainingCount, 5);
      expect(session.nextQuestion?.id, 'entry-q1');
    });

    test('ouvrir deux fois ne cree pas deux sessions', () async {
      final EntryTestSession premiere = await onboarding.openSession();
      final EntryTestSession seconde = await onboarding.openSession();

      expect(seconde.sessionId, premiere.sessionId);
    });

    test('l\'identifiant de session est memorise', () async {
      final EntryTestSession session = await onboarding.openSession();
      expect(await settings.entryTestSessionId(), session.sessionId);
    });
  });

  group('Reponse et progression', () {
    test('une reponse correcte est enregistree et fait avancer', () async {
      final EntryTestSession session = await onboarding.openSession();

      final EntryTestSession apres = session.withAnswer(
        await onboarding.submitAnswer(
          session: session,
          question: EntryTestBank.q1,
          rawAnswer: '7',
        ),
      );

      expect(apres.answerFor('entry-q1')!.correction.isCorrect, isTrue);
      expect(apres.nextQuestion?.id, 'entry-q2');
      expect(apres.remainingCount, 4);
    });

    test('une reponse non evaluable est enregistree sans bloquer', () async {
      final EntryTestSession session = await onboarding.openSession();

      final EntryTestSession apres = session.withAnswer(
        await onboarding.submitAnswer(
          session: session,
          question: EntryTestBank.q1,
          rawAnswer: 'sept',
        ),
      );

      // Elle avance comme les autres : c'est une observation, pas un blocage.
      // Aucune conclusion n'est tiree.
      expect(apres.answerFor('entry-q1')!.correction.isIndeterminate, isTrue);
      expect(apres.nextQuestion?.id, 'entry-q2');
    });

    test('une question hors session est refusee', () async {
      final EntryTestSession session = await onboarding.openSession();
      const EntryTestQuestion inconnue = EntryTestQuestion(
        id: 'fantome',
        order: 99,
        statement: 'inexistante',
        answerType: EntryTestAnswerType.integer,
        expectedValue: '1',
      );

      expect(
        () => onboarding.submitAnswer(
          session: session,
          question: inconnue,
          rawAnswer: '1',
        ),
        throwsStateError,
      );
    });
  });

  group('Echec d\'ecriture', () {
    test('une base fermee fait echouer l\'ecriture', () async {
      final EntryTestSession session = await onboarding.openSession();
      await db.close();

      // L'erreur REMONTE : l'appelant doit savoir que rien n'a ete ecrit.
      // Un echec silencieux donnerait l'illusion d'un succes.
      await expectLater(
        onboarding.submitAnswer(
          session: session,
          question: EntryTestBank.q1,
          rawAnswer: '7',
        ),
        throwsA(anything),
      );
    });

    test('apres un echec, une nouvelle tentative n\'echoue pas', () async {
      // On simule un echec puis un succes sur le MEME depot : l'identifiant
      // d'evenement est deterministe, donc la reecriture aboutit une fois.
      final Directory dossier = Directory.systemTemp.createTempSync('relio_onb');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final String chemin = '${dossier.path}/relio.sqlite';

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final AppDatabase base = AppDatabase.forTesting(NativeDatabase(File(chemin)));
      await base.migrateForTesting();
      registerTestDatabase(base);

      final SettingsRepository reglages = SettingsRepository(base);
      final EntryTestOnboarding parcours = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(base), clock: () => instant(1)),
        reglages,
        clock: () => instant(1),
        idGenerator: prochainId,
      );

      final EntryTestSession session = await parcours.openSession();

      // Deux appels successifs avec la MEME reponse : le second est un rejeu.
      await parcours.submitAnswer(
        session: session,
        question: EntryTestBank.q1,
        rawAnswer: '7',
      );
      final EntryTestAnswer rejeu = await parcours.submitAnswer(
        session: session,
        question: EntryTestBank.q1,
        rawAnswer: '7',
      );

      expect(rejeu.correction.isCorrect, isTrue);

      final EntryTestSession relue =
          (await parcours.openSession());
      expect(relue.answeredCount, 1, reason: 'aucun doublon apres rejeu');
    });
  });

  group('Reprise', () {
    test('la session interrompue est reprise la ou elle s\'est arretee',
        () async {
      final Directory dossier = Directory.systemTemp.createTempSync('relio_rpr');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final String chemin = '${dossier.path}/relio.sqlite';

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

      // Premiere session : deux reponses, puis coupure.
      AppDatabase base = AppDatabase.forTesting(NativeDatabase(File(chemin)));
      await base.migrateForTesting();
      SettingsRepository reglages = SettingsRepository(base);
      EntryTestOnboarding parcours = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(base), clock: () => instant(1)),
        reglages,
        clock: () => instant(1),
        idGenerator: prochainId,
      );

      final EntryTestSession session = await parcours.openSession();
      EntryTestSession courante = session;
      for (final EntryTestQuestion q in <EntryTestQuestion>[
        EntryTestBank.q1,
        EntryTestBank.q2,
      ]) {
        courante = courante.withAnswer(
          await parcours.submitAnswer(
            session: courante,
            question: q,
            rawAnswer: q.expectedValue,
          ),
        );
      }
      await base.close();

      // Relance complete : nouvelle base, nouveau depot.
      base = AppDatabase.forTesting(NativeDatabase(File(chemin)));
      await base.migrateForTesting();
      registerTestDatabase(base);
      parcours = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(base), clock: () => instant(1)),
        SettingsRepository(base),
        clock: () => instant(1),
        idGenerator: prochainId,
      );

      final EntryTestSession reprise = await parcours.openSession();

      expect(reprise.sessionId, session.sessionId);
      expect(reprise.answeredCount, 2);
      expect(reprise.nextQuestion?.id, 'entry-q3');
      expect(reprise.answerFor('entry-q1')!.rawAnswer, '7');
    });
  });

  group('Fin du parcours', () {
    test('une session incomplete ne peut pas etre terminee', () async {
      final EntryTestSession session = await onboarding.openSession();

      expect(
        () => onboarding.finishSession(session),
        throwsStateError,
      );
      expect(await settings.hasCompletedFirstLaunch(), isFalse,
          reason: 'un parcours incomplet ne marque PAS la fin');
    });

    test('une session complete se termine et marque le premier lancement',
        () async {
      final EntryTestSession session = await onboarding.openSession();
      // Les cinq reponses passent par le parcours metier : elles sont
      // reellement ecrites, pas seulement memorisees en RAM.
      final EntryTestSession completee = await repondreTout(session);

      expect(completee.isReadyToComplete, isTrue);

      final EntryTestSession finie = await onboarding.finishSession(completee);

      expect(finie.isCompleted, isTrue);
      expect(finie.state, EntryTestSessionState.completed);
      expect(finie.completedAt, isNotNull);
      expect(await settings.hasCompletedFirstLaunch(), isTrue);
    });

    test('terminer une session deja terminee est sans effet', () async {
      final EntryTestSession session = await onboarding.openSession();
      final EntryTestSession completee = await repondreTout(session);
      final EntryTestSession finie = await onboarding.finishSession(completee);

      expect(finie.isCompleted, isTrue);

      // Un second appel ne leve pas : la session est deja terminee.
      final EntryTestSession encore = await onboarding.finishSession(finie);
      expect(encore.isCompleted, isTrue);
      expect(encore.completedAt, finie.completedAt,
          reason: 'la date de fin reste la premiere');
    });

    test('une session terminee n\'est pas relancee automatiquement', () async {
      final EntryTestSession session = await onboarding.openSession();
      final EntryTestSession completee = await repondreTout(session);
      await onboarding.finishSession(completee);

      // Nouvelle ouverture : la session terminee est rendue telle quelle,
      // pas une nouvelle passation.
      final EntryTestSession reouverte = await onboarding.openSession();
      expect(reouverte.sessionId, session.sessionId);
      expect(reouverte.isCompleted, isTrue);
      expect(reouverte.answeredCount, 5);
    });

    test('aucune reponse ne peut etre ajoutee apres la fin', () async {
      final EntryTestSession session = await onboarding.openSession();
      final EntryTestSession completee = await repondreTout(session);
      final EntryTestSession finie = await onboarding.finishSession(completee);

      expect(
        () => onboarding.submitAnswer(
          session: finie,
          question: EntryTestBank.q1,
          rawAnswer: '7',
        ),
        throwsStateError,
      );
    });
  });

  group('Isolation du chapitre 1 pendant le parcours', () {
    test('aucune erreur pedagogique n\'est produite', () async {
      final EntryTestSession session = await onboarding.openSession();

      await onboarding.submitAnswer(
        session: session,
        question: EntryTestBank.q1,
        rawAnswer: '6',
      );
      await onboarding.submitAnswer(
        session: session,
        question: EntryTestBank.q2,
        rawAnswer: '2/3',
      );

      expect(await db.select(db.observedErrors).get(), isEmpty);
      expect(await db.select(db.exerciseAttempts).get(), isEmpty);
      expect(await db.select(db.offeredHints).get(), isEmpty);
    });

    test('la banque du chapitre 1 n\'est pas touchee', () {
      // Le module du test d'entree ne declare aucun exercice : il ne peut
      // donc rien ajouter au chapitre 1.
      expect(EntryTestBank.questions.length, 5);
      expect(
        EntryTestBank.questions.every(
          (EntryTestQuestion q) => q.id.startsWith('entry-'),
        ),
        isTrue,
      );
    });
  });

  // =====================================================================
  // Les deux marqueurs du parcours.
  //
  // `entryScreenSeen` (« l'ecran d'entree a ete vu ») et
  // `firstLaunchCompleted` (« le parcours est termine ») sont DEUX faits
  // distincts. Les confondre ferait perdre un test d'entree interrompu :
  // l'eleve a bien vu l'ecran, mais son parcours n'est pas solde.
  // =====================================================================

  group('Marqueurs — (a) indépendance des deux marqueurs', () {
    test('entryScreenSeen ne modifie pas firstLaunchCompleted', () async {
      await onboarding.markEntryScreenSeen();

      expect(await onboarding.hasSeenEntryScreen(), isTrue);
      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'voir l\'ecran ne solde pas le parcours',
      );
    });

    test('firstLaunchCompleted ne modifie pas entryScreenSeen', () async {
      await onboarding.markFirstLaunchCompleted();

      expect(await onboarding.hasCompletedFirstLaunch(), isTrue);
      expect(
        await onboarding.hasSeenEntryScreen(),
        isFalse,
        reason: 'le parcours ne se declenche pas de l\'ecran d\'entree',
      );
    });

    test('les deux marqueurs se lisent independamment', () async {
      // Les quatre etats significatifs doivent etre atteignables sans
      // qu'un marqueur implique l'autre.
      expect(await onboarding.hasSeenEntryScreen(), isFalse);
      expect(await onboarding.hasCompletedFirstLaunch(), isFalse);

      await onboarding.markEntryScreenSeen();
      expect(await onboarding.hasSeenEntryScreen(), isTrue);
      expect(await onboarding.hasCompletedFirstLaunch(), isFalse);

      await onboarding.markFirstLaunchCompleted();
      expect(await onboarding.hasSeenEntryScreen(), isTrue);
      expect(await onboarding.hasCompletedFirstLaunch(), isTrue);
    });

    test('marquer l\'ecran ne relance ni ne reinitialise aucune session',
        () async {
      final EntryTestSession session = await onboarding.openSession();

      await onboarding.markEntryScreenSeen();

      // Le parcours n'est pas solde, donc le test reste ouvert.
      expect(await onboarding.hasCompletedFirstLaunch(), isFalse);
      final EntryTestSession relue = await onboarding.openSession();
      expect(relue.sessionId, session.sessionId);
      expect(relue.isCompleted, isFalse);
      expect(relue.nextQuestion?.id, 'entry-q1');
    });
  });

  group('Marqueurs — (b) aucune écriture prématurée au démarrage', () {
    test('le tap sur Commencer marque l\'écran et NE solde pas le parcours',
        () async {
      // Ce que fait l'interface au tap sur « Commencer » : uniquement le
      // marqueur d'ecran.
      await onboarding.markEntryScreenSeen();

      expect(await onboarding.hasSeenEntryScreen(), isTrue);
      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'le parcours ne peut pas etre solde avant le test',
      );
    });

    test('aucune écriture de firstLaunchCompleted dans ce flux', () async {
      // Parcours complet de l'ecran d'entree, SANS la cloture.
      await onboarding.markEntryScreenSeen();
      final EntryTestSession session = await onboarding.openSession();

      EntryTestSession courante = session;
      for (final EntryTestQuestion q in <EntryTestQuestion>[
        EntryTestBank.q1,
        EntryTestBank.q2,
      ]) {
        courante = courante.withAnswer(
          await onboarding.submitAnswer(
            session: courante,
            question: q,
            rawAnswer: q.expectedValue,
          ),
        );
      }

      // Apres avoir vu l'ecran ET demarre le test, rien n'est solde.
      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'aucun appel a markFirstLaunchCompleted dans ce flux',
      );
    });

    test('marquer l\'écran ne crée aucune session de test', () async {
      await onboarding.markEntryScreenSeen();

      // L'ecran vu ne vaut pas session demarree : le parcours decide.
      expect(await settings.entryTestSessionId(), isNull);
    });
  });

  group('Marqueurs — (c) finalisation au clic final uniquement', () {
    test('firstLaunchCompleted ne passe à true qu\'à la clôture', () async {
      final EntryTestSession session = await onboarding.openSession();

      await onboarding.markEntryScreenSeen();
      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'le clic sur Commencer ne solde pas',
      );

      EntryTestSession courante = session;
      for (final EntryTestQuestion q in EntryTestBank.questions.take(4)) {
        courante = courante.withAnswer(
          await onboarding.submitAnswer(
            session: courante,
            question: q,
            rawAnswer: q.expectedValue,
          ),
        );
      }

      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'quatre reponses sur cinq ne soldent rien',
      );

      // Cinquieme reponse : le test est complet, mais PAS encore termine.
      courante = courante.withAnswer(
        await onboarding.submitAnswer(
          session: courante,
          question: EntryTestBank.q5,
          rawAnswer: EntryTestBank.q5.expectedValue,
        ),
      );
      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'avoir repondu n\'est pas avoir cloture',
      );

      // Le tap sur « Decouvrir Relio ».
      await onboarding.finishSession(courante);

      expect(
        await onboarding.hasCompletedFirstLaunch(),
        isTrue,
        reason: 'la cloture solde le parcours',
      );
    });

    test('une fermeture avant le clic final laisse le parcours ouvert',
        () async {
      final EntryTestSession session = await onboarding.openSession();
      await onboarding.markEntryScreenSeen();

      EntryTestSession courante = session;
      for (final EntryTestQuestion q in <EntryTestQuestion>[
        EntryTestBank.q1,
        EntryTestBank.q2,
        EntryTestBank.q3,
      ]) {
        courante = courante.withAnswer(
          await onboarding.submitAnswer(
            session: courante,
            question: q,
            rawAnswer: q.expectedValue,
          ),
        );
      }

      // Fermeture : ni finishSession, ni aucune autre ecriture.
      expect(await onboarding.hasCompletedFirstLaunch(), isFalse);
      expect(await onboarding.hasSeenEntryScreen(), isTrue);

      // Le test reste reprenable tel quel.
      final EntryTestSession reouverte = await onboarding.openSession();
      expect(reouverte.isCompleted, isFalse);
      expect(reouverte.nextQuestion?.id, 'entry-q4');
    });
  });

  group('Marqueurs — (d) reprise d\'une session inachevée', () {
    test('la reprise survit à la fermeture, marqueurs compris', () async {
      final Directory dossier = Directory.systemTemp.createTempSync('relio_mrq');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final String chemin = '${dossier.path}/relio.sqlite';

      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

      // --- Premiere ouverture : ecran vu, puis deux reponses. ---
      AppDatabase base = AppDatabase.forTesting(NativeDatabase(File(chemin)));
      await base.migrateForTesting();
      EntryTestOnboarding parcours = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(base), clock: () => instant(1)),
        SettingsRepository(base),
        clock: () => instant(1),
        idGenerator: prochainId,
      );

      // Tap sur « Commencer ».
      await parcours.markEntryScreenSeen();

      final EntryTestSession session = await parcours.openSession();
      EntryTestSession courante = session;
      for (final EntryTestQuestion q in <EntryTestQuestion>[
        EntryTestBank.q1,
        EntryTestBank.q2,
      ]) {
        courante = courante.withAnswer(
          await parcours.submitAnswer(
            session: courante,
            question: q,
            rawAnswer: q.expectedValue,
          ),
        );
      }
      await base.close();

      // --- Reprise : nouvelle base, meme fichier. ---
      base = AppDatabase.forTesting(NativeDatabase(File(chemin)));
      await base.migrateForTesting();
      registerTestDatabase(base);
      parcours = EntryTestOnboarding(
        EntryTestRepository(LearningEventRepository(base), clock: () => instant(1)),
        SettingsRepository(base),
        clock: () => instant(1),
        idGenerator: prochainId,
      );

      // L'ecran d'entree ne doit plus etre rejoue…
      expect(
        await parcours.hasSeenEntryScreen(),
        isTrue,
        reason: 'l\'ecran d\'entree ne se rejoue pas',
      );
      // …mais le parcours n'est PAS termine.
      expect(
        await parcours.hasCompletedFirstLaunch(),
        isFalse,
        reason: 'le parcours reste ouvert tant que la cloture n\'a pas eu lieu',
      );

      final EntryTestSession reprise = await parcours.openSession();
      expect(reprise.sessionId, session.sessionId);
      expect(reprise.answeredCount, 2);
      expect(
        reprise.nextQuestion?.id,
        'entry-q3',
        reason: 'la reprise se fait a la question 3, pas au debut',
      );

      // Et le parcours peut encore etre solde.
      EntryTestSession finie = reprise;
      for (final EntryTestQuestion q in EntryTestBank.questions.skip(2)) {
        finie = finie.withAnswer(
          await parcours.submitAnswer(
            session: finie,
            question: q,
            rawAnswer: q.expectedValue,
          ),
        );
      }
      await parcours.finishSession(finie);

      expect(await parcours.hasCompletedFirstLaunch(), isTrue);
    });
  });
}