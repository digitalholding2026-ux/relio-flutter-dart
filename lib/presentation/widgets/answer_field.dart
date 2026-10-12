/// Champ de reponse reutilisable.
///
/// Gere les deux claviers de la V1 et les etats techniques associes :
/// message de saisie vide, banniere d'erreur d'envoi.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../rules/v1_screen_rules.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Champ de reponse unique.
///
/// Le champ conserve sa valeur et son focus : la saisie n'est jamais effacee
/// par une erreur d'envoi, conformement a la specification.
class AnswerField extends StatefulWidget {
  const AnswerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.keyboard,
    required this.onChanged,
    this.onSubmitted,
    this.locked = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Type de clavier a utiliser.
  final AnswerKeyboard keyboard;

  /// Notifie la premiere frappe, pour effacer le message inline.
  final VoidCallback onChanged;

  /// Soumission clavier.
  final VoidCallback? onSubmitted;

  /// Champ verrouille : lecture seule, sans focus, sans clavier.
  ///
  /// Regle d'INTERFACE, derivee de la seule presence d'un panneau de retour.
  /// Elle ne touche ni au moteur, ni au brouillon, ni au contenu.
  final bool locked;

  @override
  State<AnswerField> createState() => _AnswerFieldState();
}

class _AnswerFieldState extends State<AnswerField> {
  @override
  void initState() {
    super.initState();
    _applyLock();
  }

  @override
  void didUpdateWidget(covariant AnswerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked != widget.locked) _applyLock();
  }

  /// Un champ verrouille ne peut meme pas DEMANDER le focus.
  ///
  /// `readOnly` seul ne suffirait pas : le champ resterait focusable, donc
  /// selectionnable, et un clavier pourrait s'ouvrir sur un champ qu'il
  /// est interdit de modifier. Interdire la demande de focus ferme les trois
  /// portes d'un coup — focus, curseur, copier-coller.
  /// Un champ verrouille ne peut meme pas DEMANDER le focus.
  ///
  /// NOTE D'IMPLEMENTATION, learned the hard way : poser
  /// `focusNode.canRequestFocus = false` ici ne fonctionne PAS. Le widget
  /// `Focus` interne de `TextField` reassigne `canRequestFocus` a sa valeur
  /// par defaut a chaque rebuild — l'ecriture est donc silencieusement
  /// annulee, sans erreur ni avertissement. C'est pourquoi le verrouillage
  /// repose sur troisWritableExterieurs, aucun Framework ne peut les
  /// contourner :
  ///
  ///  - `readOnly` : ni clavier, ni edition ;
  ///  - `enableInteractiveSelection: false` : ni curseur, ni copier-coller ;
  ///  - `AbsorbPointer` : le tap n'atteint meme plus le champ.
  void _applyLock() {
    if (widget.locked) widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;
    final palette = RelioPaletteScope.of(context);

    return Semantics(
      label: RelioStrings.answerFieldLabel,
      textField: true,
      readOnly: locked,
      child: AbsorbPointer(
        // Absorbe le tap SANS masquer le champ ni sa valeur : l'eleve doit
        // pouvoir relire sa reponse. Le geste ne produit ni focus, ni
        // clavier, ni message.
        absorbing: locked,
        child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: (_) => widget.onChanged(),
        onSubmitted: (_) => widget.onSubmitted?.call(),
        keyboardType: _keyboardType,
        inputFormatters: _formatters,
        readOnly: locked,
        // Verrouille aussi le menu contextuel : sans cela, un appui long
        // proposerait encore « Copier ».
        enableInteractiveSelection: !locked,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: RelioTheme.fontFamily,
          // Chiffres tabulaires : les valeurs s'alignent verticalement.
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          // Valeur toujours relisible, mais clairement hors jeu : l'élève
          // doit VOIR ce qu'il a repondu pour comprendre le retour.
          color: locked
              ? palette.textPrimary.withValues(alpha: 0.72)
              : palette.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: RelioStrings.answerFieldLabel,
          hintText: _hint,
          filled: true,
          fillColor: palette.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: RelioSpacing.cardInner,
            vertical: 16,
          ),
          border: _border(palette.outline),
          // Verrouille : bordure « outline » sobre, jamais le trait bleu de
          // focus — un champ qu'on ne peut pas editer ne doit pas avoir
          // l'air d'en-etre un.
          enabledBorder: _border(palette.outline),
          focusedBorder:
              _border(locked ? palette.outline : palette.primary,
                  width: locked ? 1.5 : 2),
          errorBorder: _border(palette.errorText),
          focusedErrorBorder: _border(palette.errorText, width: 2),
        ),
        ),
      ),
    );
  }

  String get _hint => switch (widget.keyboard) {
        AnswerKeyboard.numeric => '123',
        AnswerKeyboard.alphanumeric => 'Ta réponse',
      };

  TextInputType get _keyboardType => switch (widget.keyboard) {
        AnswerKeyboard.numeric => TextInputType.number,
        AnswerKeyboard.alphanumeric => TextInputType.text,
      };

  /// Clavier numerique : seuls les chiffres et le signe moins sont admis.
  ///
  /// Cela evite de produire une saisie impossible a evaluer.
  List<TextInputFormatter> get _formatters => switch (widget.keyboard) {
        AnswerKeyboard.numeric => <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
          ],
        AnswerKeyboard.alphanumeric => const <TextInputFormatter>[],
      };

  OutlineInputBorder _border(Color color, {double width = RelioSizes.fieldBorderWidth}) {
    return OutlineInputBorder(
      borderRadius: RelioRadius.cardAll,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
