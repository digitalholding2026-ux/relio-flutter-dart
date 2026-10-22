/// Tuteur Relio — conversation dans l'écran d'exercice.
///
/// Le panneau ne connaît que le contrat [TutorClient] : le modèle réel
/// ([OpenAiTutorClient], configuré par `docs/TUTEUR_LLM.md`), un faux client
/// de test ou le mode repli sont interchangeables.
///
/// Le cerveau du tuteur est le prompt système officiel
/// ([kTutorSystemPrompt]) ; l'énoncé et la réponse attendue de l'exercice en
/// cours lui sont transmis, avec interdiction de révéler la réponse. Si
/// l'appel échoue, l'élève reçoit [RelioStrings.tutorBusyReply] et un bouton
/// « Réessayer » : aucun message d'erreur technique n'est affiché, et sa
/// question n'est pas perdue.
///
/// Sans clé compilée, le client est un `MockTutorClient` : le fil fonctionne
/// à l'identique, sans appel réseau (voir `docs/TUTEUR_LLM.md`).
///
/// Le panneau occupe 75 % de la hauteur : l'énoncé de l'exercice reste
/// partiellement visible derrière, et la conversation ne donne pas
/// l'impression d'avoir quitté l'exercice.
library;

import 'package:flutter/material.dart';

import '../../domain/tutor/tutor_client.dart';
import '../../domain/tutor/tutor_exercise_context.dart';
import '../../domain/tutor/tutor_message.dart';
import '../branding/relio_mark.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';

/// Fraction de la hauteur d'écran occupée par la conversation.
const double kRelioTutorSheetHeightFactor = 0.75;

/// Ouvre la conversation avec le tuteur et attend sa fermeture.
///
/// [client] est le tuteur partagé par l'application ; [exercise] est
/// l'exercice réellement ouvert, transmis au modèle.
Future<void> showRelioTutorSheet(
  BuildContext context, {
  required TutorClient client,
  required TutorExerciseContext exercise,
}) {
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
    builder: (BuildContext context) =>
        RelioTutorSheet(client: client, exercise: exercise),
  );
}

/// Panneau de conversation.
class RelioTutorSheet extends StatefulWidget {
  /// Crée le panneau.
  const RelioTutorSheet({
    super.key,
    required this.client,
    required this.exercise,
  });

  /// Tuteur chargé de répondre.
  final TutorClient client;

  /// Exercice en cours, transmis au modèle à chaque appel.
  final TutorExerciseContext exercise;

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

  /// Un appel est en cours : l'envoi est verrouillé et le fil l'annonce.
  bool _sending = false;

  /// Le dernier appel a échoué : le fil propose de réessayer.
  ///
  /// L'échec n'est jamais un cul-de-sac : la question de l'élève reste dans le
  /// fil, telle qu'il l'a écrite, et le bouton relance exactement cet appel.
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Envoie la saisie au tuteur, puis affiche sa réponse.
  ///
  /// Le message de l'élève apparaît immédiatement ; l'indicateur
  /// [RelioStrings.tutorThinking] reste affiché le temps de l'appel. En cas
  /// d'échec, une bulle [RelioStrings.tutorBusyReply] propose de réessayer.
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(TutorMessage(text: text, fromRelio: false));
      _sending = true;
      _failed = false;
    });
    _controller.clear();
    _scrollToBottom();

    await _requestReply();
  }

  /// Relance le dernier appel échoué, sans réécrire la question.
  Future<void> _retry() async {
    if (_sending || !_failed) return;

    setState(() {
      _sending = true;
      _failed = false;
    });
    _scrollToBottom();

    await _requestReply();
  }

  /// Appelle le tuteur sur le fil courant et range le résultat.
  ///
  /// Un échec (réseau, HTTP, réponse illisible) n'ajoute aucune réponse
  /// inventée : il bascule le fil en état « à réessayer ».
  Future<void> _requestReply() async {
    final history = List<TutorMessage>.unmodifiable(_messages);

    String? reply;
    try {
      reply = await widget.client.reply(
        exercise: widget.exercise,
        history: history,
      );
    } on Object {
      // Le client de test, le mode simulé et le client réel passent tous par
      // ici : quel que soit l'incident, l'élève garde la main.
      reply = null;
    }

    if (!mounted) return;
    setState(() {
      _sending = false;
      if (reply == null) {
        _failed = true;
      } else {
        _messages.add(TutorMessage(text: reply, fromRelio: true));
      }
    });
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
    final height = (size.height * kRelioTutorSheetHeightFactor).clamp(
      0.0,
      available <= 0 ? size.height : available,
    );

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
                  itemCount: _messages.length + (_sending || _failed ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == _messages.length) {
                      if (_sending) {
                        return _ThinkingBubble(palette: palette);
                      }
                      return _RetryBubble(palette: palette, onRetry: _retry);
                    }
                    final message = _messages[index];
                    return _MessageBubble(
                      message: message,
                      // Les messages du tuteur sont annoncés aux lecteurs
                      // d'écran : sans cela, une réponse arrivée en cours de
                      // lecture passerait inaperçue.
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
            // Pendant l'appel, le bouton est désactivé : deux envois
            // simultanés mélangeraient les réponses dans le fil.
            onPressed: _sending ? null : _send,
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

/// Bulle d'attente affichée pendant l'appel au modèle.
class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.palette});

  final RelioPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          liveRegion: true,
          label: RelioStrings.tutorThinking,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: RelioSpacing.md,
              vertical: RelioSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: palette.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: RelioSpacing.sm),
                Text(
                  RelioStrings.tutorThinking,
                  style: RelioType.body(palette).copyWith(
                    height: 1.45,
                    color: palette.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bulle d'échec : le tuteur n'a pas répondu, l'élève peut relancer.
///
/// Elle porte le texte de repli ET le bouton [RelioStrings.tutorRetry] :
/// relancer ne demande pas de retaper la question, qui est déjà dans le fil.
class _RetryBubble extends StatelessWidget {
  const _RetryBubble({required this.palette, required this.onRetry});

  final RelioPalette palette;

  /// Relance le dernier appel échoué.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          liveRegion: true,
          label: RelioStrings.tutorBusyReply,
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
                color: palette.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    RelioStrings.tutorBusyReply,
                    style: RelioType.body(palette).copyWith(
                      height: 1.45,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: RelioSpacing.xs),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(RelioStrings.tutorRetry),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: RelioSpacing.sm,
                      ),
                      minimumSize: const Size(
                        0,
                        RelioSizes.minTouchTarget,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
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
