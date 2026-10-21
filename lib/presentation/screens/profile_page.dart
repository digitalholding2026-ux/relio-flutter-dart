/// Écran Profil — onglet 3.
///
/// OBJECTIF : regrouper ce qui concerne l'élève et son confort d'usage, dans
/// le même langage visuel que les onglets Accueil et Apprendre : fond indigo
/// pâle, cartes blanches à coins arrondis, accent orange.
///
/// STRUCTURE, dans l'ordre :
///  1. l'en-tête « Profil » ;
///  2. la carte d'identité — avatar, prénom, classe, bouton « Modifier » ;
///  3. la carte « Mon parcours » — deux faits affichés ;
///  4. la carte « Affichage » — taille du texte, contraste renforcé ;
///  5. la carte « Accessibilité » — réduction des animations.
///
/// DONNÉES FACTICES : les deux décomptes de « Mon parcours » sont des valeurs
/// d'attente (12 exercices, 3 notions), pas des faits lus en base. Elles sont
/// regroupées ici pour être remplacées en un point le jour où le moteur les
/// fournira. Aucune note, aucun score, aucun pourcentage n'est affiché.
///
/// La règle 5 d'`AGENTS.md` interdit d'introduire un champ de maîtrise, de
/// score ou de niveau dans le MODÈLE et le SCHÉMA : ces valeurs n'existent
/// dans aucune table, et [LearnerSettings] ne les contient pas.
///
/// PERSISTANCE : locale, immédiate, sans bouton « Enregistrer ». La perte des
/// préférences à la désinstallation est ACCEPTÉE en V1.
library;

import 'package:flutter/material.dart';

import '../../domain/settings/learner_settings.dart';
import '../home/pressable_scale.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

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
  // ---------------------------------------------------------------------
  // Données factices de « Mon parcours ».
  //
  // À BRANCHER : ces deux décomptes seront lus depuis le moteur. Ils sont
  // volontairement regroupés ici, et nulle part ailleurs dans l'écran.
  // ---------------------------------------------------------------------
  static const int _completedExercises = 12;
  static const int _masteredNotions = 3;

  late final TextEditingController _nameController = TextEditingController(
    text: widget.settings.name,
  );

  bool _editingName = false;

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pendant la saisie, le contrôleur est la source de vérité : le réécrire
    // à chaque frappe replacerait le curseur au début. Hors saisie, un prénom
    // modifié ailleurs (parcours d'entrée) doit se refléter ici.
    if (!_editingName && widget.settings.name != _nameController.text) {
      _nameController.text = widget.settings.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Sauvegarde automatique du prénom : pas de bouton, pas de validation.
  void _onNameChanged(String value) {
    widget.onChanged(widget.settings.copyWith(name: value));
  }

  /// Ouvre le champ de saisie du prénom.
  void _beginEditing() {
    if (_editingName) return;
    setState(() => _editingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
  }

  /// Referme le champ de saisie. La valeur est déjà persistée à la frappe.
  void _endEditing() {
    if (!_editingName) return;
    FocusScope.of(context).unfocus();
    setState(() => _editingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final settings = widget.settings;

    return Scaffold(
      // Même teinte que l'accueil et Apprendre : les cartes blanches se
      // détachent sans qu'on ajoute une bordure à chacune.
      backgroundColor: palette.homeBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            RelioSpacing.horizontal,
            RelioSpacing.xl,
            RelioSpacing.horizontal,
            RelioSpacing.xxxl,
          ),
          children: <Widget>[
            Text(
              RelioStrings.profileTitle,
              style: RelioType.display(palette)
                  .copyWith(color: palette.primary),
            ),
            const SizedBox(height: RelioSpacing.xxl),
            _IdentityCard(
              name: settings.name,
              controller: _nameController,
              editing: _editingName,
              reduceAnimations: settings.reduceAnimations,
              onBeginEditing: _beginEditing,
              onEndEditing: _endEditing,
              onNameChanged: _onNameChanged,
            ),
            const SizedBox(height: RelioSpacing.sectionGap),
            _JourneyCard(
              completedExercises: _completedExercises,
              masteredNotions: _masteredNotions,
            ),
            const SizedBox(height: RelioSpacing.sectionGap),
            _DisplayCard(
              textScale: settings.textScale,
              highContrast: settings.highContrast,
              onTextScaleChanged: (value) =>
                  widget.onChanged(widget.settings.copyWith(textScale: value)),
              onHighContrastChanged: (value) => widget.onChanged(
                widget.settings.copyWith(highContrast: value),
              ),
            ),
            const SizedBox(height: RelioSpacing.cardGap),
            _AccessibilityCard(
              reduceAnimations: settings.reduceAnimations,
              onReduceAnimationsChanged: (value) => widget.onChanged(
                widget.settings.copyWith(reduceAnimations: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte d'identité
// ---------------------------------------------------------------------------

/// Carte principale : avatar, prénom, classe et accès à la modification.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.controller,
    required this.editing,
    required this.reduceAnimations,
    required this.onBeginEditing,
    required this.onEndEditing,
    required this.onNameChanged,
  });

  final String name;
  final TextEditingController controller;
  final bool editing;
  final bool reduceAnimations;
  final VoidCallback onBeginEditing;
  final VoidCallback onEndEditing;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final trimmed = name.trim();
    final displayName = trimmed.isEmpty ? RelioStrings.nameHint : trimmed;
    final initial = trimmed.isEmpty
        ? null
        : String.fromCharCode(trimmed.runes.first).toUpperCase();

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: RelioRadius.bannerAll,
        border: Border.all(
          color: palette.brand,
          width: RelioSizes.heroBorderWidth,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _InitialAvatar(initial: initial),
          const SizedBox(width: RelioSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (editing)
                  _NameField(
                    controller: controller,
                    onChanged: onNameChanged,
                    onSubmitted: onEndEditing,
                  )
                else
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RelioType.chapterTitle(palette)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: RelioSpacing.xs),
                Text(
                  RelioStrings.classLine(RelioStrings.classValue),
                  style: RelioType.body(palette)
                      .copyWith(fontSize: 14, color: palette.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: RelioSpacing.sm),
          PressableScale(
            onTap: editing ? onEndEditing : onBeginEditing,
            reduceAnimations: reduceAnimations,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: RelioSizes.minTouchTarget,
                minHeight: RelioSizes.minTouchTarget,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RelioSpacing.sm,
                  ),
                  child: Text(
                    editing
                        ? RelioStrings.profileDone
                        : RelioStrings.profileModify,
                    style: RelioType.caption(palette).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // En saisie, la carte n'est plus un bouton : un appui dans le champ doit
    // placer le curseur, pas refermer la modification.
    if (editing) return content;

    return PressableScale(
      onTap: onBeginEditing,
      reduceAnimations: reduceAnimations,
      child: content,
    );
  }
}

/// Cercle indigo portant la première lettre du prénom.
///
/// Sans prénom, le cercle reste présent et porte une silhouette neutre : la
/// carte garde sa structure, sans inventer de texte.
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  /// Première lettre du prénom, `null` si le prénom est vide.
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle),
      child: initial == null
          ? Icon(Icons.person_outline, size: 32, color: palette.onPrimary)
          : Text(
              initial!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1,
                fontFamily: RelioTheme.fontFamily,
                color: palette.onPrimary,
              ),
            ),
    );
  }
}

/// Champ de saisie du prénom, ouvert par « Modifier ».
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      textInputAction: TextInputAction.done,
      style: RelioType.chapterTitle(palette)
          .copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        hintText: RelioStrings.nameHint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RelioSpacing.md,
          vertical: RelioSpacing.sm,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Carte « Mon parcours »
// ---------------------------------------------------------------------------

/// Carte des deux faits affichés : exercices terminés et notions maîtrisées.
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.completedExercises,
    required this.masteredNotions,
  });

  final int completedExercises;
  final int masteredNotions;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            RelioStrings.profileJourneyTitle,
            style: RelioType.sectionTitle(palette),
          ),
          const SizedBox(height: RelioSpacing.lg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _JourneyStat(
                    icon: Icons.check_circle_outline,
                    iconColor: palette.primary,
                    label: RelioStrings.completedExercises(completedExercises),
                  ),
                ),
                VerticalDivider(
                  width: RelioSpacing.xxl,
                  thickness: 1,
                  color: palette.outline,
                ),
                Expanded(
                  child: _JourneyStat(
                    icon: Icons.flag_outlined,
                    iconColor: palette.brand,
                    label: RelioStrings.masteredNotions(masteredNotions),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une colonne de la carte « Mon parcours » : icône, puis fait affiché.
class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(height: RelioSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: RelioType.body(
            palette,
          ).copyWith(fontSize: 14, height: 1.35, color: palette.textSecondary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cartes de réglages
// ---------------------------------------------------------------------------

/// Carte « Affichage » : taille du texte et contraste renforcé.
class _DisplayCard extends StatelessWidget {
  const _DisplayCard({
    required this.textScale,
    required this.highContrast,
    required this.onTextScaleChanged,
    required this.onHighContrastChanged,
  });

  final TextScalePreference textScale;
  final bool highContrast;
  final ValueChanged<TextScalePreference> onTextScaleChanged;
  final ValueChanged<bool> onHighContrastChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            RelioStrings.sectionDisplay,
            style: RelioType.sectionTitle(palette),
          ),
          const SizedBox(height: RelioSpacing.lg),
          // Libellé sur toute la largeur, au-dessus du sélecteur : c'est ce
          // qui empêche « Taille du texte » d'être comprimé et coupé.
          Text(
            RelioStrings.textSizeLabel,
            style: RelioType.body(palette)
                .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: RelioSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: _TextScaleSelector(
              value: textScale,
              onChanged: onTextScaleChanged,
            ),
          ),
          const SizedBox(height: RelioSpacing.lg),
          Divider(height: 1, thickness: 1, color: palette.outline),
          const SizedBox(height: RelioSpacing.xs),
          _SwitchRow(
            label: RelioStrings.highContrastLabel,
            value: highContrast,
            onChanged: onHighContrastChanged,
          ),
        ],
      ),
    );
  }
}

/// Carte « Accessibilité » : réduction des animations.
class _AccessibilityCard extends StatelessWidget {
  const _AccessibilityCard({
    required this.reduceAnimations,
    required this.onReduceAnimationsChanged,
  });

  final bool reduceAnimations;
  final ValueChanged<bool> onReduceAnimationsChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            RelioStrings.sectionAccessibility,
            style: RelioType.sectionTitle(palette),
          ),
          const SizedBox(height: RelioSpacing.sm),
          _SwitchRow(
            label: RelioStrings.reduceAnimationsLabel,
            value: reduceAnimations,
            onChanged: onReduceAnimationsChanged,
          ),
        ],
      ),
    );
  }
}

/// Sélecteur segmenté de taille de texte : Normal / Grand / Très grand.
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
            label: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: <TextScalePreference>{value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      // Étire les trois segments sur toute la largeur disponible.
      expandedInsets: EdgeInsets.zero,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(0, RelioSizes.minTouchTarget),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: RelioSpacing.xs),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          RelioType.caption(palette)
              .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: palette.outline),
        ),
      ),
    );
  }
}

/// Ligne de réglage : libellé à gauche, interrupteur à droite.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: RelioSizes.minTouchTarget,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: RelioType.body(palette).copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(width: RelioSpacing.md),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: palette.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: palette.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conteneur commun
// ---------------------------------------------------------------------------

/// Carte blanche à coins arrondis (16) et ombre douce.
///
/// Toutes les cartes de l'écran passent par ce conteneur : le rayon et
/// l'ombre ne sont donc définis qu'une fois.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RelioSpacing.cardInner),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: RelioRadius.bannerAll,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
