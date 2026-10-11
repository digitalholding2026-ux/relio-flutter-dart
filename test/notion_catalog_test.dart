/// Tests du catalogue de notions : création, lecture, mise à jour.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/core/clock.dart';
import 'package:relio/core/id.dart';
import 'package:relio/domain/catalog/notion_catalog.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/notion/notion.dart';
import 'package:relio/domain/notion/notion_status.dart';

import 'helpers/test_database.dart';
import 'helpers/event_factory.dart';
void main() {
  late NotionRepository repo;
  final t0 = DateTime.utc(2026, 3, 1, 8);

  setUp(() async {
    final db = await openTestDatabase();
    registerTestDatabase(db);
    repo = NotionRepository(db, clock: fixedClock(t0));
  });

  Notion notion({
    required String id,
    String label = 'Fractions',
    String? description,
    NotionLifecycle lifecycle = NotionLifecycle.draft,
    Set<String> prerequisites = const <String>{},
  }) =>
      Notion(
        id: id,
        label: label,
        description: description,
        lifecycle: lifecycle,
        prerequisiteIds: prerequisites,
      );

  group('Création', () {
    test('insère une notion et la relit à l’identique', () async {
      await repo.upsert(notion(id: 'n-fractions', label: 'Fractions'));

      final found = await repo.findById('n-fractions');

      expect(found, isNotNull);
      expect(found!.id, 'n-fractions');
      expect(found.label, 'Fractions');
      expect(found.lifecycle, NotionLifecycle.draft);
      expect(found.createdAt, t0, reason: 'createdAt est posné à l’écriture');
    });

    test('retourne null pour un identifiant inconnu', () async {
      expect(await repo.findById('inexistant'), isNull);
    });

    test('conserve les prérequis déclaratifs', () async {
      await repo.upsert(notion(id: 'n-1'));
      await repo.upsert(notion(id: 'n-2', prerequisites: {'n-1'}));

      final found = await repo.findById('n-2');

      expect(found!.prerequisiteIds, {'n-1'});
    });

    test('insertAll écrit tout le lot', () async {
      await repo.upsertAll(<Notion>[
        notion(id: 'a', label: 'Addition'),
        notion(id: 'b', label: 'Soustraction'),
      ]);

      expect(await repo.findAll(), hasLength(2));
    });
  });

  group('Mise à jour', () {
    test('upsert sur le même id met à jour sans dupliquer', () async {
      await repo.upsert(notion(id: 'n-1', label: 'Ancien'));
      await repo.upsert(
        notion(id: 'n-1', label: 'Nouveau', lifecycle: NotionLifecycle.published),
      );

      final all = await repo.findAll();

      expect(all, hasLength(1), reason: 'pas de doublon sur le même id');
      expect(all.single.label, 'Nouveau');
      expect(all.single.lifecycle, NotionLifecycle.published);
    });

    test('remplace intégralement l’ensemble des prérequis', () async {
      await repo.upsert(notion(id: 'n-1'));
      await repo.upsert(notion(id: 'n-2'));
      await repo.upsert(notion(id: 'n-3', prerequisites: {'n-1', 'n-2'}));
      await repo.upsert(notion(id: 'n-3', prerequisites: {'n-2'}));

      final found = await repo.findById('n-3');

      expect(found!.prerequisiteIds, {'n-2'}, reason: 'n-1 ne doit plus être lié');
    });

    test('les identifiants générés sont uniques', () {
      final ids = <String>{for (var i = 0; i < 1000; i++) newId()};
      expect(ids, hasLength(1000));
    });
  });

  group('Lecture et filtres', () {
    test('ne liste que les notions publiées avec findPublished', () async {
      await repo.upsert(notion(id: 'p', lifecycle: NotionLifecycle.published));
      await repo.upsert(notion(id: 'd', lifecycle: NotionLifecycle.draft));
      await repo.upsert(notion(id: 'a', lifecycle: NotionLifecycle.archived));

      final published = await repo.findPublished();

      expect(published.map((n) => n.id), ['p']);
    });

    test('trie les notions par libellé', () async {
      await repo.upsert(notion(id: '1', label: 'Zoom'));
      await repo.upsert(notion(id: '2', label: 'Air'));
      await repo.upsert(notion(id: '3', label: 'Moyenne'));

      final labels = (await repo.findAll()).map((n) => n.label).toList();

      expect(labels, ['Air', 'Moyenne', 'Zoom']);
    });
  });

  group('Suppression protégée', () {
    test('refuse de supprimer une notion référencée par un événement', () async {
      final db = await openTestDatabase();
      registerTestDatabase(db);
      final notions = NotionRepository(db);
      final events = LearningEventRepository(db);

      await notions.upsert(notion(id: 'n-1'));
      await events.record(sampleEvent(notionIds: <String>['n-1']));

      expect(
        () => notions.delete('n-1'),
        throwsA(isA<StateError>()),
        reason: 'supprimer casserait l’historique d’apprentissage',
      );
    });

    test('supprime une notion inutilisée', () async {
      await repo.upsert(notion(id: 'n-1', prerequisites: {'n-0'}));

      await repo.delete('n-1');

      expect(await repo.findById('n-1'), isNull);
    });
  });
}
