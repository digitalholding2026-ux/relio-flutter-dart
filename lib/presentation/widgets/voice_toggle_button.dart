/// Icône globale de la voix : couper ou rétablir toutes les lectures.
///
/// L'icône ne connaît ni la base ni les écrans : elle bascule
/// [AudioService.toggle], et c'est l'application qui persiste le choix. Elle
/// est posée en haut à droite de chaque écran principal.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/audio/audio_service.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Bouton haut-parleur « muet / actif ».
class VoiceToggleButton extends StatelessWidget {
  /// Crée le bouton.
  const VoiceToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final RelioPalette palette = RelioPaletteScope.of(context);

    return ListenableBuilder(
      listenable: AudioService.instance,
      builder: (BuildContext context, Widget? _) {
        final bool enabled = AudioService.instance.enabled;

        return IconButton(
          onPressed: () => unawaited(AudioService.instance.toggle()),
          icon: Icon(
            enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
          tooltip: enabled ? RelioStrings.voiceDisable : RelioStrings.voiceEnable,
          color: enabled ? palette.primary : palette.textSecondary,
          constraints: const BoxConstraints(
            minWidth: RelioSizes.minTouchTarget,
            minHeight: RelioSizes.minTouchTarget,
          ),
        );
      },
    );
  }
}
