/// Les trois onglets de l'application.
///
/// ÉNUMÉRATION FERMÉE : c'est la façon la plus simple de garantir qu'aucun
/// quatrième onglet ne puisse être ajouté par accident. Les destinations
/// « Révisions », « Progression » et « Paramètres » n'existent pas en V1.
library;

import 'package:flutter/material.dart';

import '../strings/relio_strings.dart';

enum RelioTab {
  home(RelioStrings.tabHome, Icons.home_outlined, Icons.home),
  learn(RelioStrings.tabLearn, Icons.menu_book_outlined, Icons.menu_book),
  profile(RelioStrings.tabProfile, Icons.person_outline, Icons.person);

  const RelioTab(this.label, this.icon, this.selectedIcon);

  /// Libellé affiché sous l'icône.
  final String label;

  /// Icône d'état inactif — style outline.
  final IconData icon;

  /// Icône d'état actif.
  final IconData selectedIcon;
}

/// Libellés des onglets, exposés pour les tests.
List<String> get relioTabLabels =>
    <String>[for (final tab in RelioTab.values) tab.label];