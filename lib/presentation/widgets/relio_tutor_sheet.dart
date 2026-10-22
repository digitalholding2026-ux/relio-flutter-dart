/// Tuteur Relio — conversation dans l'écran d'exercice.
///
/// INTERFACE SEULEMENT. Aucun appel réseau, aucun modèle : les réponses du
/// tuteur sont des MOCK explicitement marqués comme tels
/// ([RelioStrings.tutorMockReply]). Le jour où l'API existera, seule
/// [_RelioTutorSheetState._replyTo] changera — la mise en page, elle, ne
/// bougera pas.
///
/// Le panneau occupe 75 % de la hauteur : l'énoncé de l'exercice reste
/// partiellement visible derrière, et la conversation ne donne pas
/// l'impression d'avoir quitté l'exercice.
library;

import 'package:flutter/material.dart';

import '../branding/relio_mark.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Fraction de la hauteur d'écran occupée par la conversation.
const double kRelioTutorSheetHeightFactor = 0.75;

/// Ouvre la conversation avec le tuteur et attend sa fermeture.
Future<void> showRelioTutorSheet(BuildContext context) {
  final palette = RelioPaletteScope.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Le panneau est OPAQUE : c'est une conversation posée sur l'exercice,
    // pas une surcouche de verre.
    backgroundColor: palette.surface,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height * kRelioTutorSheetHeightFactor,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) => const RelioTutorSheet(),
  );
}

/// Un message de la conversation.
@immutable
class TutorMessage {
  /// Crée un message.
  const TutorMessage({required this.text, required this.fromRelio});

  /// Contenu affiché.
  final String text;

  /// `true` : message du tuteur ; `false` : message de l'élève.
  final bool fromRelio;
}

/// Panneau de conversation.
class RelioTutorSheet extends StatefulWidget {
  /// Crée le panneau.
  const RelioTutorSheet({super.key});

  @override
  State<RelioTutorSheet> createState() => _RelioTutorSheetState();
}

class _RelioTutorSheetState extends State<RelioTutorSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// Fil de discussion. Le premier message est le seul que le tuteur dit de
  /// lui-même : il ouvre la conversation sans attendre une question.
  final List<TutorMessage> _messages = <TutorMessage>[
    const TutorMessage(text: RelioStrings.tutorGreeting, fromRelio: true),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Envoie la saisie, puis affiche la réponse MOCK du tuteur.
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(TutorMessage(text: text, fromRelio: false));
      _messages.add(
        const TutorMessage(text: RelioStrings.tutorMockReply, fromRelio: true),
      );
    });
    _controller.clear();
    _scrollToBottom();
  }

  /// Amène le fil au dernier message, après la frame qui vient d'être bâtie.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    // La hauteur demandée est 75 % de l'écran, mais jamais plus que la place
    // réellement disponible au-dessus du clavier : un panneau plus haut que
    // l'espace libre serait coupé, et le champ de saisie deviendrait
    // inatteignable.
    final available = size.height - insets - MediaQuery.paddingOf(context).top;
    final height = (size.height * kRelioTutorSheetHeightFactor)
        .clamp(0.0, available <= 0 ? size.height : available);

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              const _DragHandle(),
              const SizedBox(height: 4),
              _header(palette),
              Divider(height: 1, color: palette.outline),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final message = _messages[index];
                    return _MessageBubble(
                      message: message,
                      // Les messages du tuteur sont annoncés aux lecteurs
                      // d'écran : sans cela, la réponse mock passerait
                      // inaperçue.
                      liveRegion: message.fromRelio && index > 0,
                    );
                  },
                ),
              ),
              Divider(height: 1, color: palette.outline),
              _composer(palette),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête : la marque désigne l'auteur, comme sur la carte d'accueil.
  Widget _header(RelioPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
      child: Row(
        children: <Widget>[
          const RelioMark(size: 28),
          const SizedBox(width: RelioSpacing.sm),
          Expanded(
            child: Text(
              RelioStrings.tutorTitle,
              style: RelioType.title(palette).copyWith(fontSize: 18),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: RelioStrings.back,
            color: palette.textSecondary,
            constraints: const BoxConstraints(
              minWidth: RelioSizes.minTouchTarget,
              minHeight: RelioSizes.minTouchTarget,
            ),
          ),
        ],
      ),
    );
  }

  /// Zone de saisie : champ pleine largeur et bouton d'envoi.
  Widget _composer(RelioPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: RelioType.body(palette),
              decoration: InputDecoration(
                hintText: RelioStrings.tutorInputHint,
                hintStyle: RelioType.body(palette)
                    .copyWith(color: palette.hintText),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: RelioSpacing.md,
                  vertical: RelioSpacing.sm,
                ),
                filled: true,
                fillColor: palette.inactiveSurface,
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
          ),
          const SizedBox(width: RelioSpacing.sm),
          IconButton.filled(
            onPressed: _send,
            icon: const Icon(Icons.send_rounded, size: 20),
            tooltip: RelioStrings.tutorSend,
            style: IconButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              minimumSize: const Size(
                RelioSizes.minTouchTarget,
                RelioSizes.minTouchTarget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulle d'un message : élève à droite, tuteur à gauche.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.liveRegion});

  final TutorMessage message;

  /// Annonce ce message aux lecteurs d'écran dès son apparition.
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final fromRelio = message.fromRelio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: fromRelio ? Alignment.centerLeft : Alignment.centerRight,
        child: Semantics(
          liveRegion: liveRegion,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RelioSpacing.md,
                vertical: RelioSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: fromRelio ? palette.primaryContainer : palette.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(fromRelio ? 4 : 16),
                  topRight: Radius.circular(fromRelio ? 16 : 4),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: RelioType.body(palette).copyWith(
                  height: 1.45,
                  color: fromRelio ? palette.textPrimary : palette.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Poignée de glissement grise, identique à celle des fiches d'aide.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD0D5DD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
