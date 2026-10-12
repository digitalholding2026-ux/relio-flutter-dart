/// Écran Profil — onglet 3.
///
/// OBJECTIF : regrouper ce qui concerne l'élève et son confort d'usage. Rien de
/// plus.
///
/// CE QUE L'ÉCRAN N'AFFICHE PAS, et n'affichera pas en V1 :
///  - aucune photo de profil, aucun avatar ;
///  - aucune section « Progression », aucune statistique, aucun score ;
///  - aucune synchronisation, aucun compte ;
///  - aucune préférence de langue, aucun thème sombre.
///
/// La règle 5 d'`AGENTS.md` interdit d'introduire un champ de maîtrise, de
/// score ou de niveau dans le MODÈLE et le SCHÉMA : aucune de ces notions
/// n'existe dans [LearnerSettings].
///
/// PERSISTANCE : locale, immédiate, sans bouton « Enregistrer ». La perte des
/// préférences à la désinstallation est ACCEPTÉE en V1.
library;

import 'package:flutter/material.dart';

import '../../domain/settings/learner_settings.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import 'app_shell.dart';

/// Écran Profil.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  /// Préférences courantes.
  final LearnerSettings settings;

  /// Notifie toute modification : l'application reconstruit le thème.
  final ValueChanged<LearnerSettings> onChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.settings.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Sauvegarde automatique du prénom : pas de bouton, pas de validation.
  void _onNameChanged(String value) {
    widget.onChanged(widget.settings.copyWith(name: value));
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final settings = widget.settings;

    return Scaffold(
      // Racine d'onglet : pas de flèche de retour.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          RelioStrings.profileTitle,
          style: RelioType.title(palette),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: RelioSpacing.xxl),
          children: <Widget>[
            const SettingsSectionTitle(title: RelioStrings.sectionIdentity),
            SettingsRow(
              label: RelioStrings.nameLabel,
              onTap: null,
              trailing: _NameField(
                controller: _nameController,
                onChanged: _onNameChanged,
              ),
            ),
            SettingsRow(
              label: RelioStrings.classLabel,
              onTap: null,
              trailing: Text(
                RelioStrings.classValue,
                style: RelioType.body(palette).copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),

            const SettingsSectionTitle(title: RelioStrings.sectionDisplay),
            SettingsRow(
              label: RelioStrings.textSizeLabel,
              onTap: null,
              trailing: _TextScaleSelector(
                value: settings.textScale,
                onChanged: (value) => widget.onChanged(
                  widget.settings.copyWith(textScale: value),
                ),
              ),
            ),
            SettingsRow(
              label: RelioStrings.highContrastLabel,
              onTap: () => widget.onChanged(
                widget.settings.copyWith(
                  highContrast: !widget.settings.highContrast,
                ),
              ),
              trailing: _Toggle(
                value: settings.highContrast,
                onChanged: (value) => widget.onChanged(
                  widget.settings.copyWith(highContrast: value),
                ),
              ),
            ),

            const SettingsSectionTitle(title: RelioStrings.sectionAccessibility),
            SettingsRow(
              label: RelioStrings.reduceAnimationsLabel,
              onTap: () => widget.onChanged(
                widget.settings.copyWith(
                  reduceAnimations: !widget.settings.reduceAnimations,
                ),
              ),
              trailing: _Toggle(
                value: settings.reduceAnimations,
                onChanged: (value) => widget.onChanged(
                  widget.settings.copyWith(reduceAnimations: value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ de saisie du prénom.
class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.end,
        textInputAction: TextInputAction.done,
        style: RelioType.body(palette),
        decoration: InputDecoration(
          isDense: true,
          hintText: RelioStrings.nameHint,
          filled: true,
          fillColor: palette.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: RelioSpacing.md,
            vertical: RelioSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: RelioRadius.cardAll,
            borderSide: BorderSide(color: palette.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: RelioRadius.cardAll,
            borderSide: BorderSide(color: palette.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: RelioRadius.cardAll,
            borderSide: BorderSide(color: palette.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

/// Interrupteur d'une preference booleenne.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: palette.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: palette.outline,
    );
  }
}

/// Selecteur de taille de texte : Normal / Grand / Très grand.
///
/// Trois options, jamais plus. Chaque option applique IMMÉDIATEMENT son
/// multiplicateur : l'élève voit le résultat sans quitter l'écran.
class _TextScaleSelector extends StatelessWidget {
  const _TextScaleSelector({required this.value, required this.onChanged});

  final TextScalePreference value;
  final ValueChanged<TextScalePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return SegmentedButton<TextScalePreference>(
      segments: <ButtonSegment<TextScalePreference>>[
        for (final option in TextScalePreference.values)
          ButtonSegment<TextScalePreference>(
            value: option,
            // L'étiquette rend l'état lisible SANS dépendre de la seule
            // couleur du segment sélectionné.
            label: Text(option.label),
          ),
      ],
      selected: <TextScalePreference>{value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll<TextStyle>(
          RelioType.caption(palette).copyWith(fontWeight: FontWeight.w600),
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: palette.outline),
        ),
      ),
    );
  }
}