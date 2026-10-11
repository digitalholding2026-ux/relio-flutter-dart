/// Utilitaires partagés par les tests : ouverture d'une base EN MÉMOIRE.
///
/// Les tests n'utilisent JAMAIS le fichier réel : ils valident la logique
/// sans toucher aux données d'un appareil réel.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/data/db/app_database.dart';

/// Crée une base Relio isolée, en mémoire, avec le schéma à jour.
Future<AppDatabase> openTestDatabase() async {
  // Chaque test ouvre sa propre base : l'avertissement drift de
  // « plusieurs bases » est donc sans objet ici.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  // Applique le schéma comme le ferait une installation neuve.
  await db.migrateForTesting();
  return db;
}

/// Ferme proprement la base de test.
Future<void> closeTestDatabase(AppDatabase db) async {
  await db.close();
}

/// Supprime la base de test et libère la mémoire.
void registerTestDatabase(AppDatabase db) {
  addTearDown(() async {
    await closeTestDatabase(db);
  });
}
