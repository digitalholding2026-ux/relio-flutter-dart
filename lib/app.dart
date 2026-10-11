/// Application Relio — racine de l'interface.
///
/// Affichage volontairement minimal : ce socle ne présente AUCUN contenu
/// pédagogique. Son unique rôle est de vérifier que la persistance locale
/// s'initialise et que l'historique est consultable hors ligne.
library;

import 'package:flutter/material.dart';

import 'data/db/app_database.dart';
import 'domain/catalog/notion_catalog.dart';
import 'domain/learning/learning_event_repository.dart';
import 'presentation/home_page.dart';

class RelioApp extends StatelessWidget {
  const RelioApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6C4A)),
        useMaterial3: true,
      ),
      home: HomePage(
        notionRepository: NotionRepository(database),
        eventRepository: LearningEventRepository(database),
      ),
    );
  }
}
