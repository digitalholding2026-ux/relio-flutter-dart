import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait : usage scolaire, pas de mise en page à reconstruire.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // La base est LOCALE et fonctionne SANS réseau : aucune dépendance réseau
  // n'est initialisée ici, volontairement.
  final database = await AppDatabase.openLocal();

  runApp(RelioApp(database: database));
}
