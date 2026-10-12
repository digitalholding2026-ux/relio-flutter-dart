/// Prechargement SILENCIEUX de l'accueil.
///
/// La mission 2 exige que l'eleve ne voie RIEN : ni spinner, ni barre de
/// progression, ni texte de chargement. Les 5,3 secondes de la sequence
/// d'entree servent exactement a cela.
///
/// ECHEC : journalise, jamais affiche. L'eleve arrive de toute facon a
/// l'accueil ; une erreur de prechargement ne doit pas devenir un ecran
/// d'erreur que personne n'a demande.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/db/app_database.dart';

/// Charge en arriere-plan ce dont l'accueil aura besoin.
///
/// Volontairement tolerant : toute erreur est absorbee. Le retour est
///IgnoreSignals pour que l'appelant n'ait pas a gerer d'erreur.
class IntroPreloader {
  /// Cree un prechargeur.
  IntroPreloader(this._database);

  final AppDatabase _database;

  /// Lance le prechargement et absorbe toute erreur.
  ///
  /// L'interface peut appeler cela sans `await` : rien ne peut remonter
  /// jusqu'a l'eleve.
  Future<void> run() async {
    try {
      // Ouvrir la base : le premier acces peut declencher la creation du
      // fichier et, au besoin, une migration. C'est le poste le plus long.
      await _database.customSelect('SELECT 1').get();

      // Les preferences sont lues par l'accueil et par le Profil. Les charger
      // maintenant evite un second aller-retour base quand l'eleve y arrive.
      await _database.select(_database.appSettings).get();
    } catch (error, stack) {
      // Journalise en mode debug uniquement : une trace en production
      // encombrerait les journaux sans rien apporter a l'eleve.
      assert(() {
        debugPrint('Prechargement de l\'accueil ignore : $error');
        debugPrintStack(stackTrace: stack);
        return true;
      }());
    }
  }
}
