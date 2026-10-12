/// S2 — Exercice.
///
/// ECRAN PRINCIPAL DU PARCOURS. Il CONSOMME le moteur : il n'invente aucune
/// regle pedagogique.
///
/// Structure imposee par la specification :
///  - zone defilante : enonce, mention de transparence, indices, panneau ;
///  - barre d'action FIXE en bas : champ, bouton d'indice, bouton Valider.
///
/// La barre est fixee hors de la zone defilante afin que le champ reste
/// visible au-dessus du clavier et que « Valider » ne soit jamais masque.
///
/// Brouillon conserve EN MEMOIRE D'ECRAN, par identifiant d'exercice. Une
/// fermeture forcee de l'application perd la saisie : limite acceptee en V1,
/// assumee et non masquee.
library;

import 'package:flutter/material.dart';

import '../../core/id.dart';
import '../../domain/curriculum/chapter1_service.dart';
import '../../domain/curriculum/exercise.dart';
import '../rules/feedback_selection.dart';
import '../rules/v1_screen_rules.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import '../widgets/answer_field.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/hint_area.dart';
import '../widgets/math_text.dart';

/// Brouillon d'une tentative en cours.
///
/// Conserve en memoire uniquement : aucun evenement de persistance, donc
/// aucune trace dans l'historique d'apprentissage.
class ExerciseDraft {
  ExerciseDraft({required this.answerKey});

  /// Cible du brouillon : « tentative-1 » ou l'identifiant de verification.
  final String answerKey;

  String answer = '';
  final Set<int> consumedHintOrders = <int>{};
  final List<ExerciseHint> shownHints = <ExerciseHint>[];

  /// Panneau de retour affiche, conserve pour la session.
  ///
  /// Conserve AU MEME TITRE que la saisie et les indices : si l'eleve quitte
  /// S2 par la fleche retour alors qu'un panneau est affiche, il doit le
  /// retrouver intact. Perdre le retour alors que la reponse, elle, est
  /// conservee, laisserait l'eleve deviner pourquoi il ne peut plus ecrire.
  ///
  /// Etat d'INTERFACE : il ne modifie ni le moteur, ni l'historique
  /// d'apprentissage. « Exercice suivant » et « Ressayer » remplacent le
  /// brouillon, donc le panneau disparait avec eux.
  FeedbackSelection? feedback;
}

/// Ecran d'exercice.
class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.service,
    required this.exercise,
    required this.drafts,
    required this.onExit,
    required this.onGoToNext,
    this.requestFocusOnOpen = false,
  });

  final Chapter1Service service;

  /// Exercice a presenter.
  final Exercise exercise;

  /// Brouillons conserves par identifiant d'exercice, pour la session.
  final Map<String, ExerciseDraft> drafts;

  /// Retour a S1.
  final VoidCallback onExit;

  /// Passage a l'exercice suivant, ou retour S1 si c'est le dernier.
  final VoidCallback onGoToNext;

  /// Reprendre le focus sur le champ a l'ouverture.
  ///
  /// Vrai apres « Exercice suivant » : l'eleve enchaîne, le champ doit
  /// être pret a ecrire. Faux a la premiere ouverture d'une lecon, ou
  /// lorsque le brouillon restaure un panneau — le clavier ne doit pas
  /// s'ouvrir tout seul sur un champ verrouille.
  final bool requestFocusOnOpen;

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  /// Identifiant de la tentative, genere AVANT toute demande d'indice.
  late ExerciseDraft _draft;

  FeedbackSelection? _feedback;
  bool _showEmptyMessage = false;
  bool _showSubmitError = false;
  bool _submitting = false;

  /// Le champ est-il verrouille ?
  ///
  /// REGLE D'INTERFACE, derivee de la seule presence d'un panneau de retour :
  /// rien d'autre ne la declenche. Ni le moteur, ni la classification, ni le
  /// contenu pedagogique n'interviennent.
  bool get _locked => _feedback != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    // La cle de tentative existe des l'ouverture de S2 : les indices doivent
    // pouvoir y etre rattaches avant toute soumission.
    _draft = widget.drafts[widget.exercise.id] ??
        (widget.drafts[widget.exercise.id] =
            ExerciseDraft(answerKey: 'tentative-${newId()}'));
    _controller.text = _draft.answer;

    // Retour par la fleche de l'AppBar : le panneau retrouve est restaure
    // tel quel, et le champ reste verrouille.
    _feedback = _draft.feedback;

    if (widget.requestFocusOnOpen && !_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_locked) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    // Derniere sauvegarde : garantit la saisie meme si `onChanged` n'a pas
    // ete declenche (controle programme, restauration de session).
    _draft.answer = _controller.text;
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  /// Demande l'indice suivant au moteur.
  ///
  /// Ne modifie NI la saisie, NI le focus, NI la position de defilement.
  void _askForHint() {
    // Aucune action d'aide apres validation : demander un indice sous un
    // panneau transforme une reussite assistee en indichee, et le brouillon
    // ne le saurait plus.
    if (_locked) return;

    final hint =
        widget.service.nextHint(widget.exercise, _draft.consumedHintOrders);
    if (hint == null) return; // Plus d'indice : le bouton disparait.

    setState(() {
      _draft.consumedHintOrders.add(hint.order);
      _draft.shownHints.add(hint);
    });

    // Enregistrement asynchrone : ne doit jamais bloquer l'affichage.
    widget.service.recordHintRequested(
      attemptKey: _draft.answerKey,
      exercise: widget.exercise,
      hintOrder: hint.order,
    );
  }

  Future<void> _submit() async {
    // Garde-fou de re-entree : le bouton est deja neutralise, mais une
    // soumission ne doit jamais partir en double meme si un autre
    // chemin l'atteint.
    if (_submitting) return;

    final raw = _controller.text;

    // Saisie vide : aucun appel moteur, message inline uniquement.
    if (raw.trim().isEmpty) {
      setState(() => _showEmptyMessage = true);
      return;
    }

    setState(() {
      _submitting = true;
      _showEmptyMessage = false;
    });

    try {
      final record = await widget.service.recordAttempt(
        exercise: widget.exercise,
        rawAnswer: raw,
        attemptKey: _draft.answerKey,
        hintOrders: _draft.consumedHintOrders,
      );

      if (!mounted) return;
      setState(() {
        _feedback = selectFeedback(
          record: record,
          exerciseId: widget.exercise.id,
          rawAnswer: raw,
        );
        // Le panneau fait partie du brouillon de session : il survit au
        // retour par la fleche de l'AppBar.
        _draft.feedback = _feedback;
        _showSubmitError = false;
        _submitting = false;
      });
      // Clavier ferme DES L'APPARITION du panneau : aucun etat intermediaire
      // ne doit montrer un clavier au-dessus d'un champ desormais verrouille.
      if (_locked) _focusNode.unfocus();
    } catch (_) {
      // La saisie n'est JAMAIS effacee en cas d'erreur d'envoi.
      if (!mounted) return;
      setState(() {
        _showSubmitError = true;
        _submitting = false;
      });
    }
  }

  /// « Réessayer » : meme exercice, panneau masque, champ vide.
  void _retry() {
    setState(() {
      _feedback = null;
      _showSubmitError = false;
      _showEmptyMessage = false;
      _draft.consumedHintOrders.clear();
      _draft.shownHints.clear();
      // Une nouvelle tentative necessite une nouvelle cle.
      widget.drafts[widget.exercise.id] = _draft =
          ExerciseDraft(answerKey: 'tentative-${newId()}');
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  /// « Exercice suivant » : le brouillon de l'exercice courant est efface.
  ///
  /// L'eleve a termine cet exercice : conserver son retour en memoire ferait
  /// reapparaitre un panneau et un champ verrouille s'il rouvrait la lecon.
  void _goToNextAndClearDraft() {
    widget.drafts.remove(widget.exercise.id);
    _goToNext();
  }

  /// « Exercice suivant », ou retour S1 si c'est le dernier.
  ///
  /// La navigation elle-meme est delegauee au parent, qui possede la pile :
  /// cet ecran ne decide pas de la suite du parcours.
  void _goToNext() => widget.onGoToNext();

  // ---------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final keyboard = V1ScreenRules.keyboardFor(exercise.id);
    final transparency = V1ScreenRules.transparencyNote(exercise.id);
    final canAskHint =
        widget.service.nextHint(exercise, _draft.consumedHintOrders) != null;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: IconButton(
              onPressed: widget.onExit,
              icon: const Icon(Icons.arrow_back),
              tooltip: RelioStrings.back,
              // La spec impose une cible tactile d'au moins 48 dp : l'icone
              // seule mesure 24 dp, la zone reelle doit etre elargie.
              constraints: const BoxConstraints(
                minWidth: RelioSizes.minTouchTarget,
                minHeight: RelioSizes.minTouchTarget,
              ),
            ),
          ),
        ),
        // Titre tronque : le titre de la lecon 3 est long.
        title: Text(
          exercise.lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: RelioTheme.fontFamily,
            color: RelioColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  RelioSpacing.horizontal,
                  8,
                  RelioSpacing.horizontal,
                  RelioSpacing.cardGap,
                ),
                children: <Widget>[
                  _statementCard(exercise.statement),
                  if (transparency != null) ...<Widget>[
                    const SizedBox(height: 12),
                    _transparencyNote(transparency),
                  ],
                  if (_draft.shownHints.isNotEmpty) ...<Widget>[
                    const SizedBox(height: RelioSpacing.cardGap),
                    HintArea(hints: _draft.shownHints),
                  ],
                  if (_feedback != null) ...<Widget>[
                    const SizedBox(height: RelioSpacing.cardGap),
                    FeedbackPanelView(
                      selection: _feedback!,
                      onRetry: _retry,
                      onNext: _goToNextAndClearDraft,
                      // « Continuer » (exercice 11) : destination non encore
                      // tranchee cote pedagogie. Elle reste S1 — elle n'est
                      // donc PAS desactivee, puisque S1 EST une destination.
                      // Voir docs/INTERFACE.md, limites.
                      onContinue: widget.onExit,
                    ),
                  ],
                ],
              ),
            ),
            _bottomBar(keyboard, canAskHint: canAskHint),
          ],
        ),
      ),
    );
  }

  Widget _statementCard(String statement) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RelioSpacing.cardInner),
        child: MathText(
          text: statement,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontFamily: RelioTheme.fontFamily,
            color: RelioColors.text,
          ),
        ),
      ),
    );
  }

  /// Mention de transparence : Caption, secondaire, sans icone ni encadre.
  Widget _transparencyNote(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamily: RelioTheme.fontFamily,
        color: RelioColors.textSecondary,
      ),
    );
  }

  /// Barre d'action fixee : champ, indice, validation.
  ///
  /// Hors de la zone defilante : le champ reste visible au-dessus du
  /// clavier et « Valider » n'est jamais masque.
  Widget _bottomBar(AnswerKeyboard keyboard, {required bool canAskHint}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: RelioColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        RelioSpacing.horizontal,
        12,
        RelioSpacing.horizontal,
        12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_showSubmitError) ...<Widget>[
            _errorBanner(),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: RelioSizes.fieldHeight,
            child: AnswerField(
              controller: _controller,
              focusNode: _focusNode,
              keyboard: keyboard,
              locked: _locked,
              onChanged: () {
                // La saisie est reportee dans le brouillon de session :
                // sans cela, un retour vers S1 la perdrait.
                _draft.answer = _controller.text;
                // Le message inline disparait a la premiere frappe.
                if (_showEmptyMessage) {
                  setState(() => _showEmptyMessage = false);
                }
              },
            ),
          ),
          if (_showEmptyMessage) ...<Widget>[
            const SizedBox(height: 8),
            _inlineMessage(),
          ],
          if (canAskHint) ...<Widget>[
            const SizedBox(height: 4),
            TextButton(
              // Le bouton RESTE VISIBLE s'il etait affiche au moment de la
              // validation : seule sa disponibilite change. Le retirer
              // modifierait la hauteur de la barre d'action apres chaque
              // reponse, ce qui serait plus derangeant qu'un bouton inactif.
              onPressed: _locked ? null : _askForHint,
              style: RelioButtons.text(),
              child: const Text(RelioStrings.askHint),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            // Neutralise pendant l'envoi, ET une fois le panneau affiche :
            // sans cela, un eleve presse sur « Valider » plusieurs fois et
            // empile des tentatives identiques dans un historique qui ne
            // peut plus etre nettoye. Repasser par « Réessayer » est la
            // seule voie pour soumettre une nouvelle tentative.
            onPressed: (_submitting || _feedback != null) ? null : _submit,
            style: RelioButtons.primary(),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                // Desactive si le champ est vide.
                : Text(
                    RelioStrings.validate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: RelioTheme.fontFamily,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Bannière dismissible d'erreur d'envoi.
  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RelioColors.errorBackground,
        borderRadius: BorderRadius.circular(RelioSizes.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline,
              color: RelioColors.errorText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  RelioStrings.submitErrorBanner,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: RelioTheme.fontFamily,
                    color: RelioColors.errorText,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _submit,
                  style: RelioButtons.text().copyWith(
                    foregroundColor: WidgetStatePropertyAll(RelioColors.errorText),
                    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(36)),
                  ),
                  child: const Text(RelioStrings.retry),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSubmitError = false),
            icon: const Icon(Icons.close, size: 18),
            color: RelioColors.errorText,
            tooltip: 'Fermer',
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineMessage() {
    return Semantics(
      liveRegion: true,
      child: Text(
        RelioStrings.emptyAnswerInline,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: RelioTheme.fontFamily,
          color: RelioColors.errorText,
        ),
      ),
    );
  }
}
