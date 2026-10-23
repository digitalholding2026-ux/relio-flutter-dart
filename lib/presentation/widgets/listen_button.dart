/// Bouton « Écouter » d'un énoncé ou d'une fiche d'aide.
///
/// Le bouton ne lit rien lui-même : il confie le texte au [AudioService], qui
/// coupe la lecture précédente et respecte le mode muet. Quand la voix est
/// coupée, le bouton est inactif : l'élève voit que c'est la voix qui est
/// éteinte, et non la lecture qui a échoué.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/audio/audio_service.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Petit bouton d'écoute, discret, à poser près du texte concerné.
class ListenButton extends StatelessWidget {
  /// Crée le bouton pour [text].
  const ListenButton({
    super.key,
    required this.text,
    this.tooltip = RelioStrings.listenStatement,
    this.compact = false,
  });

  /// Texte à lire. Il est nettoyé par le service avant la synthèse.
  final String text;

  /// Infobulle : énoncé, indice ou réponse.
  final String tooltip;

  /// Version icône seule, pour les endroits où la hauteur est comptée.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return ListenableBuilder(
      listenable: AudioService.instance,
      builder: (BuildContext context, Widget? _) {
        final bool enabled = AudioService.instance.enabled;
        final String label = enabled ? tooltip : RelioStrings.voiceEnable;

        if (compact) {
          return IconButton(
            onPressed: enabled
                ? () => unawaited(AudioService.instance.speak(text))
                : null,
            icon: const Icon(Icons.volume_up_outlined, size: 20),
            tooltip: label,
            color: palette.primary,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          );
        }

        return Tooltip(
          message: label,
          child: TextButton.icon(
            onPressed: enabled
                ? () => unawaited(AudioService.instance.speak(text))
                : null,
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            label: const Text(RelioStrings.listen),
            style: TextButton.styleFrom(
              foregroundColor: palette.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: RelioSpacing.sm,
              ),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: RelioType.caption(palette).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
