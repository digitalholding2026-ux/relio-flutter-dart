/// Un message de la conversation avec le tuteur.
///
/// Ce type vit dans le domaine : il traverse le client HTTP et l'interface
/// sans dépendre de Flutter. Rien n'est persisté — la conversation reste en
/// mémoire d'écran et disparaît à sa fermeture.
library;

import 'package:flutter/foundation.dart';

/// Message échangé avec le tuteur.
@immutable
class TutorMessage {
  /// Crée un message.
  const TutorMessage({required this.text, required this.fromRelio});

  /// Contenu affiché et transmis au modèle.
  final String text;

  /// `true` : message du tuteur ; `false` : message de l'élève.
  final bool fromRelio;

  /// Rôle attendu par l'API de conversation.
  String get role => fromRelio ? 'assistant' : 'user';

  @override
  String toString() => 'TutorMessage($role, ${text.length} caractères)';
}
