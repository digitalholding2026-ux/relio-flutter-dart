/// Fiche d'aide riche — panneau glissant du bas.
///
/// AFFICHAGE SEULEMENT.
///
/// Ce composant ne calcule rien et ne decide rien : il rend les blocs que le
/// cœur fournit, et se ferme. Le libellé du bouton d'aide, le budget et la
/// navigation vers un exercice précédent sont décidés ailleurs (voir
/// `exercise_page.dart`).
///
/// CONTRASTE AVEC [HintArea] : la zone d'indices de S2 empile des phrases
/// courtes ; ce composant affiche une FICHE, faite de blocs de natures
/// différentes. Les deux lisent les mêmes données — `HintArea` sert encore
/// l'historique de session, `RichHintSheet` sert la consultation courante.
library;

import 'package:flutter/material.dart';

import '../../domain/curriculum/rich_hint.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import 'math_text.dart';

/// Fraction de la hauteur d'ecran occupee par la fiche.
///
/// 75 %, pas davantage : l'enonce doit rester visible au-dessus. Une fiche qui
/// couvrirait tout l'ecran empecherait l'eleve de relire la question en meme
/// temps qu'il la decompose.
const double kRichHintSheetHeightFactor = 0.75;

/// Ouvre la fiche d'aide et attend sa fermeture.
///
/// [onShown] est appele AU MOMENT DE L'AFFICHAGE, pas a la fermeture.
///
/// C'est la regle du fondateur : ouvrir puis fermer sans lire consomme
/// l'indice. Le signal part donc a l'ouverture, pour que la fermeture — quelle
/// qu'elle soit, y compris un swipe — ne puisse l'annuler.
///
/// [onBackToCurrent] n'est non nul que pour la relecture d'un exercice
/// precedent : il ajoute alors le bouton de retour.
Future<void> showRichHintSheet(
  BuildContext context, {
  required RichHint hint,
  String? reviewBanner,
  String? backToCurrentLabel,
  VoidCallback? onShown,
  VoidCallback? onBackToCurrent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // La fiche est BLANCHE et opaque : elle doit lire comme une fiche de
    // cours posee sur l'ecran, pas comme une surcouche de verre.
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    // 75 % de la hauteur de l'ecran, moins la poignee.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * kRichHintSheetHeightFactor,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _RichHintSheet(
      hint: hint,
      reviewBanner: reviewBanner,
      backToCurrentLabel: backToCurrentLabel,
      onShown: onShown,
      onBackToCurrent: onBackToCurrent,
    ),
  );
}

class _RichHintSheet extends StatefulWidget {
  const _RichHintSheet({
    required this.hint,
    required this.reviewBanner,
    required this.backToCurrentLabel,
    required this.onShown,
    required this.onBackToCurrent,
  });

  final RichHint hint;

  /// Bandeau de relecture, ou `null` hors mode « Revoir l'exercice N ».
  final String? reviewBanner;

  /// Libelle du bouton de retour, ou `null` hors mode relecture.
  final String? backToCurrentLabel;

  final VoidCallback? onShown;
  final VoidCallback? onBackToCurrent;

  @override
  State<_RichHintSheet> createState() => _RichHintSheetState();
}

class _RichHintSheetState extends State<_RichHintSheet> {
  @override
  void initState() {
    super.initState();

    // NOTIFICATION AU MOMENT DE L'AFFICHAGE, jamais de la lecture ni de la
    // fermeture.
    //
    // `initState` s'execute pendant la construction : notifier ici
    // declencherait un rebuild interdit. La notification part donc en
    // post-frame, c'est-a-dire a la premiere frame reellement peinte — donc
    // quand la fiche estVisible.
    final onShown = widget.onShown;
    if (onShown != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onShown();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 10),
          const _DragHandle(),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (widget.reviewBanner != null) ...<Widget>[
                  _ReviewBanner(text: widget.reviewBanner!),
                  const SizedBox(height: 16),
                ],
                // Titre 20 / SemiBold. L'emoji du libelle fait partie du
                // texte : il ne doit pas etre traite comme une icone distincte.
                Text(
                  widget.hint.title,
                  style: RelioType.title(palette).copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // La fiche est DEFILLABLE : sur un exercice long, les blocs
          // depassent la hauteur disponible. Le bouton, lui, reste fixe —
          // « J'ai compris » ne doit jamais.require un scroll pour etre
          // atteignable.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (var i = 0; i < widget.hint.blocks.length; i++)
                    HintBlockView(
                      block: widget.hint.blocks[i],
                      // Un bloc suivi d'un autre peut porter son filet de
                      // separation ; le dernier, non.
                      isFollowedByBlock: i + 1 < widget.hint.blocks.length,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: <Widget>[
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(RelioStrings.richHintUnderstood),
                ),
                if (widget.backToCurrentLabel != null &&
                    widget.onBackToCurrent != null) ...<Widget>[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      widget.onBackToCurrent!();
                      Navigator.of(context).pop();
                    },
                    child: Text(widget.backToCurrentLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Poignee de glissement grise.
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

/// Bandeau de relecture d'un exercice precedent.
class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.primaryContainer,
        borderRadius: RelioRadius.smallAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.menu_book_outlined,
              size: 20, color: palette.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: RelioType.caption(palette)),
          ),
        ],
      ),
    );
  }
}

/// Rend un fragment de fiche selon sa nature.
///
/// UN SEUL ENDROIT decide du style d'un bloc : c'est ce qui garantit qu'un
/// [MathBlock] se ressemble partout, et qu'un [HandoffBlock] ne peut pas
/// apparaitre discret dans une partie de l'interface et visible dans l'autre.
class HintBlockView extends StatelessWidget {
  const HintBlockView({
    super.key,
    required this.block,
    this.isFollowedByBlock = false,
  });

  final HintBlock block;

  /// Un bloc suit-il ce bloc dans la meme fiche ?
  ///
  /// Commande le filet de separation du bloc [HandoffBlock] : un filet apres
  /// le dernier bloc de la fiche serait une ligne orpheline.
  final bool isFollowedByBlock;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    final isHandoff = block is HandoffBlock;
    final last = !isFollowedByBlock;

    return Padding(
      padding: EdgeInsets.only(bottom: isHandoff && last ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          switch (block) {
            TextBlock() => MathText(
                text: block.text,
                // Body 16 / Regular.
                style: RelioType.body(palette).copyWith(height: 1.5),
              ),
            MathBlock() => _MathFrame(text: block.text),
            HighlightBlock() => _HighlightFrame(text: block.text),
            HandoffBlock() => _HandoffFrame(text: block.text),
          },
          if (isHandoff && isFollowedByBlock)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Divider(height: 1),
            ),
        ],
      ),
    );
  }
}

/// Encadre d'un bloc mathematique : fond gris, bordure fine, rayon 8.
class _MathFrame extends StatelessWidget {
  const _MathFrame({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.hintMathBackground,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: palette.outline, width: 1),
      ),
      // Le formateur mathématique existing : variables en italique, chiffres
      // tabulaires, operateurs inchanges.
      child: MathText(
        text: text,
        style: RelioType.body(palette).copyWith(height: 1.5),
      ),
    );
  }
}

/// Bloc « point a retenir » : fond orange pale, liseré orange, texte indigo
/// gras.
///
/// Le liseré est demande sur le BORD GAUCHE : c'est ce qui distingue ce bloc
/// d'une simple carte colorée, et le repere reste le même quel que soit le
/// texte.
class _HighlightFrame extends StatelessWidget {
  const _HighlightFrame({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.hintHighlightBackground,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border(
          left: BorderSide(color: palette.hintHighlightAccent, width: 4),
        ),
      ),
      child: MathText(
        text: text,
        style: RelioType.bodyStrong(palette).copyWith(
          color: palette.hintHandoffText,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Bloc de retour vers l'eleve : indigo gras, sans encadre.
///
/// VISUELLEMENT DISTINCT, et le plus possible des autres blocs : c'est une
/// invitation a repondre, pas une explication de plus. Le gras et l'indigo
/// suffisent a le separer sans ajouter de boite qui le ferait ressembler au
/// bloc mathématique.
class _HandoffFrame extends StatelessWidget {
  const _HandoffFrame({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return MathText(
      text: text,
      style: RelioType.bodyStrong(palette).copyWith(
        color: palette.hintHandoffText,
        height: 1.5,
      ),
    );
  }
}