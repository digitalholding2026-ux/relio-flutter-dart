/// Test d'intégration de l'écran d'accueil contre une vraie base locale.
///
/// Vérifie que l'application affiche ses compteurs en s'appuyant
/// exclusivement sur la persistance locale (aucun réseau requis).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/app.dart';
import 'package:relio/domain/catalog/notion_catalog.dart';
import 'package:relio/domain/learning/learning_event_repository.dart';
import 'package:relio/domain/notion/notion.dart';

import 'helpers/event_factory.dart';
import 'helpers/test_database.dart';

void main() {
  testWidgets('affiche les compteurs depuis la base locale', (tester) async {
    final db = await openTestDatabase();
    registerTestDatabase(db);

    await NotionRepository(db).upsertAll(<Notion>[
      const Notion(id: 'n-1', label: 'Fractions'),
      const Notion(id: 'n-2', label: 'Géométrie'),
    ]);
    await LearningEventRepository(db).record(
      sampleEvent(id: 'e-1', notionIds: <String>['n-1']),
    );

    await tester.pumpWidget(RelioApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('Socle Relio'), findsOneWidget);
    expect(find.text('Fonctionnement hors ligne actif.'), findsOneWidget);
    expect(find.text('Notions au catalogue'), findsOneWidget);
    expect(find.text("Événements d'apprentissage"), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('affiche un état de chargement tant que la lecture n’a pas '
      'terminé', (tester) async {
    final db = await openTestDatabase();
    registerTestDatabase(db);

    await tester.pumpWidget(RelioApp(database: db));
    await tester.pumpAndSettle();

    // Après stabilisation, le compteur doit être visible et le spinner
    // disparaît sans laisser l'interface bloquée.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Socle Relio'), findsOneWidget);
  });

  testWidgets('supporte l’absence totale de données', (tester) async {
    final db = await openTestDatabase();
    registerTestDatabase(db);

    await tester.pumpWidget(RelioApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('Socle Relio'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
}
