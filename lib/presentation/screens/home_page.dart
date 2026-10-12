/// Écran Accueil — onglet 1.
///
/// OBJECTIF : dire à l'élève, en trois secondes, ce qu'il peut faire
/// maintenant. Deux cartes, rien de plus.
///
/// V1 : aucun historique n'est exploitable, donc aucune carte « Reprendre »,
/// aucune progression, aucune recommandation, aucun message de félicitation.
/// La zone basse reste volontairement VIDE : elle est réservée pour une
/// future carte « À revoir », qui dépendra d'une capacité moteur qui n'existe
/// pas encore. L'afficher sans moteur serait simuler une capacité inexistante.
library;

import 'package:flutter/material.dart';

import '../branding/relio_lockup.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import 'app_shell.dart';

/// En-tête d'accueil : « Bonjour », suivi du prénom s'il est renseigné.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.name});

  /// Prénom de l'élève. Vide si non renseigné.
  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final trimmed = name.trim();

    // Sans prénom : « Bonjour » seul. On n'invente pas de texte d'attente.
    final text = trimmed.isEmpty
        ? RelioStrings.greeting
        : '${RelioStrings.greeting} $trimmed';

    return Text(text, style: RelioType.display(palette));
  }
}

/// Écran d'accueil.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.name,
    required this.onStartHere,
    required this.onOpenProgram,
  });

  /// Prénom de l'élève, éventuellement vide.
  final String name;

  /// Ouvre S1 du chapitre 1.
  final VoidCallback onStartHere;

  /// Bascule sur l'onglet Apprendre.
  final VoidCallback onOpenProgram;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Racine d'onglet : pas de flèche de retour.
      //
      // Le lockup horizontal remplace le titre vide : c'est la premiere
      // occurrence de la marque dans l'application (critère d'acceptation de
      // la mission logo).
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: RelioSpacing.horizontal,
        title: const RelioLockupHorizontal(
          markSize: RelioSpacing.logoCapHeight,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelioSpacing.horizontal,
            RelioSpacing.md,
            RelioSpacing.horizontal,
            RelioSpacing.xxl,
          ),
          children: <Widget>[
            GreetingHeader(name: name),
            const SizedBox(height: RelioSpacing.xl),

            // Carte principale : pleine largeur, hauteur généreuse, ombre légère.
            //
            // `ConstrainedBox(minHeight:)` et NON une hauteur fixe : la carte
            // reste généreuse, mais grandit si le contenu l'exige — échelle de
            // texte renforcée, ou libellé long. Une hauteur fixe ferait
            // déborder le contenu sur un petit écran ou en gros texte.
            ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: 132),
              child: NavCard(
                title: RelioStrings.startHereTitle,
                subtitle: RelioStrings.startHereSubtitle,
                onTap: onStartHere,
                elevated: true,
              ),
            ),
            const SizedBox(height: RelioSpacing.cardGap),

            // Carte secondaire : plate, sans ombre.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 104),
              child: NavCard(
                title: RelioStrings.programTitle,
                subtitle: RelioStrings.programSubtitle,
                onTap: onOpenProgram,
              ),
            ),

            // Zone basse volontairement vide en V1.
          ],
        ),
      ),
      );
  }
}