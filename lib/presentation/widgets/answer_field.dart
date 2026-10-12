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
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Type de clavier a utiliser.
  final AnswerKeyboard keyboard;

  /// Notifie la premiere frappe, pour effacer le message inline.
  final VoidCallback onChanged;

  /// Soumission clavier.
  final VoidCallback? onSubmitted;

  @override
  State<AnswerField> createState() => _AnswerFieldState();
}

class _AnswerFieldState extends State<AnswerField> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: RelioStrings.answerFieldLabel,
      textField: true,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: (_) => widget.onChanged(),
        onSubmitted: (_) => widget.onSubmitted?.call(),
        keyboardType: _keyboardType,
        inputFormatters: _formatters,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontVariations: RelioTheme.w500,
          fontFamily: RelioTheme.fontFamily,
          // Chiffres tabulaires : les valeurs s'alignent verticalement.
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          color: RelioColors.text,
        ),
        decoration: InputDecoration(
          labelText: RelioStrings.answerFieldLabel,
          hintText: _hint,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: RelioSpacing.cardInner,
            vertical: 16,
          ),
          border: _border(RelioColors.border),
          enabledBorder: _border(RelioColors.border),
          focusedBorder: _border(RelioColors.primary, width: 2),
          errorBorder: _border(RelioColors.errorText),
          focusedErrorBorder: _border(RelioColors.errorText, width: 2),
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
      borderRadius: BorderRadius.circular(RelioSizes.fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
