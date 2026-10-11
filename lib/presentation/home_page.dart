/// Écran d'accueil du socle.
///
/// Affiche uniquement des compteurs techniques : le nombre de notions du
/// catalogue et le nombre d'événements d'apprentissage enregistrés.
/// Aucun contenu pédagogique n'est produit ici.
library;

import 'package:flutter/material.dart';

import '../domain/catalog/notion_catalog.dart';
import '../domain/learning/learning_event_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.notionRepository,
    required this.eventRepository,
  });

  final NotionRepository notionRepository;
  final LearningEventRepository eventRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<({int notions, int events})> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  /// Lit les compteurs depuis la base LOCALE.
  ///
  /// Aucune requête réseau n'est émise : l'écran fonctionne intégralement
  /// hors ligne.
  Future<({int notions, int events})> _loadStats() async {
    final results = await Future.wait(<Future<int>>[
      widget.notionRepository.findAll().then((v) => v.length),
      widget.eventRepository.count(),
    ]);
    return (notions: results[0], events: results[1]);
  }

  Future<void> _refresh() async {
    setState(() => _stats = _loadStats());
    await _stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relio'),
        actions: <Widget>[
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger les données locales',
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<({int notions, int events})>(
          future: _stats,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur de lecture locale :\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final stats = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Socle Relio',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fonctionnement hors ligne actif.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _StatTile(
                    label: 'Notions au catalogue',
                    value: stats.notions,
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  _StatTile(
                    label: "Événements d'apprentissage",
                    value: stats.events,
                    icon: Icons.history_outlined,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
