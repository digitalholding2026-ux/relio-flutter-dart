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
import '../../domain/curriculum/rich_hint.dart';
import '../../domain/curriculum/rich_hint_adapter.dart';
import '../rules/feedback_selection.dart';
import '../rules/v1_screen_rules.dart';
import '../strings/relio_strings.dart';
import '../theme/relio_theme.dart';
import '../widgets/answer_field.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/hint_area.dart';
import '../widgets/math_text.dart';
import '../widgets/rich_hint_sheet.dart';

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
    this.onFullscreenChanged,
    this.reviewConsumedHints = false,
    this.onBackFromReview,
    this.returnLabel,
    this.reviewOrigin,
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

  /// Signale que S2 occupe tout l'espace, barre de navigation basse masquée.
  ///
  /// S2 est un espace dédié à l'exercice : la barre d'action fixe
  /// (champ + « Valider ») doit rester seule, sans barre d'onglets en dessous.
  ///
  /// L'écran lève le signal à son ouverture et le rend à sa fermeture. Sans ce
  /// paramètre, aucun masquage n'est demandé — l'écran reste utilisable seul,
  /// ce qui permet de le tester isolément.
  final ValueChanged<bool>? onFullscreenChanged;

  /// Ouvrir immediatement, au montage, la fiche EMPILANT tous les indices
  /// deja consommes sur cet exercice.
  ///
  /// Vrai uniquement en relecture (« Revoir l'exercice N ») : l'eleve veut
  /// relire ses explications, pas avancer. Faux sur toute ouverture ordinaire,
  /// ou une fiche automatique masquerait l'enonce a l'arrivee sur S2.
  final bool reviewConsumedHints;

  /// « Retour a l'exercice en cours » : sort de la relecture.
  final VoidCallback? onBackFromReview;

  /// Libelle du bouton de retour, affiche seulement en relecture.
  final String? returnLabel;

  /// Exercice depuis lequel la relecture a ete ouverte, ou `null`.
  ///
  /// Sert au bandeau (« Voici les explications de l'exercice N ») et a savoir
  /// que cet ecran est une consultation, non une progression.
  final Exercise? reviewOrigin;

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

    // S2 occupe tout l'espace : la barre basse est masquée dès l'ouverture.
    //
    // NOTIFICATION DIFFÉRÉE : `initState` s'exécute pendant la phase de
    // construction. Notifier un `ValueNotifier` à cet instant rebuild est
    // interdit : la notification part donc en post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFullscreenChanged?.call(true);
    });

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

    // Relecture (« Revoir l'exercice N ») : la fiche s'ouvre seule, une fois
    // l'ecran monte et la premiere frame peinte.
    //
    // L'eleve a demande a RELIRE : afficher l'enonce seul lui ferait croire
    // qu'il doit refaire l'exercice. La fiche empilee s'y ajoute donc
    // immediatement — mais elle ne consomme RIEN : ce sont des indices deja
    // consultes, et rien n'est enregistre ici.
    if (widget.reviewConsumedHints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openReviewSheet();
      });
    }
  }

  /// Ouvre la fiche EMPILANT tous les indices deja consommes sur cet exercice.
  ///
  /// Une seule fiche, pas une par indice : l'eleve veut l'ensemble de ses
  /// explications relues d'un coup, pas une serie de panneaux a faire
  /// defiler. Aucun indice n'est enregistre — ce sont des fiches DEJA
  /// consommees.
  Future<void> _openReviewSheet() async {
    final consumed = _draft.consumedHintOrders;
    final hints = richHintsOf(widget.exercise, consumedOrders: consumed);
    if (hints.isEmpty) return;

    // Tous les fragments des fiches consumed, dans l'ordre de la banque.
    final blocks = <HintBlock>[
      for (final hint in hints) ...hint.blocks,
    ];

    final origin = widget.reviewOrigin;
    final originNumber =
        origin == null ? null : V1ScreenRules.positionOf(origin.id);

    await showRichHintSheet(
      context,
      hint: RichHint(
        order: 0,
        title: RelioStrings.richHintTitle,
        blocks: blocks,
        isFinal: true,
      ),
      reviewBanner: originNumber == null
          ? null
          : RelioStrings.richHintReviewBanner(originNumber),
      backToCurrentLabel: widget.returnLabel,
      onBackToCurrent: widget.onBackFromReview,
    );
  }

  @override
  void dispose() {
    // Derniere sauvegarde : garantit la saisie meme si `onChanged` n'a pas
    // ete declenche (controle programme, restauration de session).
    _draft.answer = _controller.text;

    // La barre basse revient des que l'on quitte l'exercice.
    //
    // `dispose` peut s'exécuter pendant une reconstruction : la notification
    // est donc reportée elle aussi, sinon elle déclencherait un rebuild
    // interdit.
    final onFullscreenChanged = widget.onFullscreenChanged;
    if (onFullscreenChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onFullscreenChanged(false);
      });
    }

    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  /// Demande l'indice suivant au moteur, et ouvre la fiche correspondante.
  ///
  /// Ne modifie NI la saisie, NI le focus, NI la position de defilement.
  ///
  /// La fiche s'OUVRE d'abord, l'enregistrement vient apres : l'eleve voit ce
  /// qu'il a demande. L'enregistrement est lui-meme asynchrone et ne doit
  /// jamais bloquer l'affichage.
  Future<void> _askForHint() async {
    // Aucune action d'aide apres validation : demander un indice sous un
    // panneau transforme une reussite assistee en indichee, et le brouillon
    // ne le saurait plus.
    if (_locked) return;

    final hint =
        widget.service.nextHint(widget.exercise, _draft.consumedHintOrders);
    if (hint == null) return; // Plus d'indice : le bouton disparait.

    // Budget AVANT ouverture : sert a savoir si la fiche qu'on va ouvrir est
    // la derniere, et a pouvoir redemander le budget au moteur apres coup.
    final budgetBefore = _budget();

    await showRichHintSheet(
      context,
      hint: hint.asRichHint(
        isFinal: budgetBefore.remaining == 1,
      ),
      // La consommation est notifiee AU MOMENT DE L'AFFICHAGE, pas a la
      // fermeture : ouvrir puis refermer sans lire consomme l'indice.
      //
      // L'enregistrement passe par le service : l'interface ne decremente donc
      // jamais le budget elle-meme, elle redemande ensuite le budget au
      // moteur et affiche le libelle qu'il renvoie.
      onShown: () => _recordHintConsumed(hint.order),
    );
  }

  /// Notifie le coeur qu'un indice a ete affiche.
  ///
  /// L'ecran ne fait qu'appeler le moteur et redemander le budget. Aucune
  /// valeur n'est comptee ici.
  Future<void> _recordHintConsumed(int hintOrder) async {
    try {
      await widget.service.recordHintRequested(
        attemptKey: _draft.answerKey,
        exercise: widget.exercise,
        hintOrder: hintOrder,
      );
    } catch (_) {
      // L'historique est une garantie, pas un confort : un echec
      // d'enregistrement ne doit pas bloquer l'eleve sur sa fiche. L'indice
      // reste affiche ; seule la trace dans l'historique est perdue.
    }

    if (!mounted) return;
    setState(() {
      _draft.consumedHintOrders.add(hintOrder);
      final hint = widget.exercise.orderedHints
          .where((h) => h.order == hintOrder)
          .firstOrNull;
      if (hint != null && !_draft.shownHints.contains(hint)) {
        _draft.shownHints.add(hint);
      }
    });
  }

  /// Budget d'aide demande au moteur.
  HintBudget _budget() => widget.service.hintBudget(
        widget.exercise,
        _draft.consumedHintOrders,
        previousExerciseId: _previous?.id,
      );

  /// Exercice de reference, propose une fois le budget epuise.
  Exercise? get _previous => V1ScreenRules.previousBefore(widget.exercise);

  /// « Revoir l'exercice N » : ouvre l'exercice precedent et y empile les
  /// fiches deja consommees.
  Future<void> _reviewPreviousExercise() async {
    final previous = _previous;
    if (previous == null) return;

    final origin = widget.exercise;

    // La pile REFLECTE le parcours : l'exercice consulte est empile au-dessus
    // de l'exercice en cours, et « Retour a l'exercice en cours » redescend
    // dessus. La saisie de l'exercice en cours n'est donc jamais perdue.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ExercisePage(
          service: widget.service,
          exercise: previous,
          drafts: widget.drafts,
          onExit: () => Navigator.of(context).pop(),
          // L'exercice consulte ne fait PAS partie de la progression : il ne
          // peut pas mener a « Exercice suivant », sinon l'eleve pourrait
          // valider l'exercice precedent et perdre sa place dans le parcours.
          onGoToNext: () => Navigator.of(context).pop(),
          onFullscreenChanged: widget.onFullscreenChanged,
          // Ouverture immediate de la fiche, en mode EMPILAGE.
          reviewConsumedHints: true,
          onBackFromReview: () => Navigator.of(context).pop(),
          returnLabel: RelioStrings.richHintBackToCurrent,
          // L'exercice consulte est-il une relecture ? On le dit, pour que le
          // bandeau et le bouton de retour ne s'affichent pas sur une ouverture
          // ordinaire du parcours.
          reviewOrigin: origin,
        ),
      ),
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
    final palette = RelioPaletteScope.of(context);
    final keyboard = V1ScreenRules.keyboardFor(exercise.id);
    final transparency = V1ScreenRules.transparencyNote(exercise.id);

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
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: RelioTheme.fontFamily,
            color: palette.textPrimary,
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
            _bottomBar(keyboard),
          ],
        ),
      ),
    );
  }

  Widget _statementCard(String statement) {
    final palette = RelioPaletteScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RelioSpacing.cardInner),
        child: MathText(
          text: statement,
          // Le formateur ne change que l'italique et les chiffres : la
          // hauteur de ligne reste celle du corps de texte.
          style: RelioType.body(palette).copyWith(height: 1.5),
        ),
      ),
    );
  }

  /// Mention de transparence : Caption, secondaire, sans icone ni encadre.
  Widget _transparencyNote(String text) {
    final palette = RelioPaletteScope.of(context);

    return Text(
      text,
      style: RelioType.caption(palette).copyWith(height: 1.4),
    );
  }

  /// Barre d'action fixee : champ, indice, validation.
  ///
  /// Hors de la zone defilante : le champ reste visible au-dessus du
  /// clavier et « Valider » n'est jamais masque.
  Widget _bottomBar(AnswerKeyboard keyboard) {
    final palette = RelioPaletteScope.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.outline, width: 1),
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
          if (_hintButton() != null) ...<Widget>[
            const SizedBox(height: 4),
            _hintButton()!,
          ],
          const SizedBox(height: 8),
          FilledButton(
            // Neutralise pendant l'envoi, ET une fois le panneau affiche :
            // sans cela, un eleve presse sur « Valider » plusieurs fois et
            // empile des tentatives identiques dans un historique qui ne
            // peut plus etre nettoye. Repasser par « Réessayer » est la
            // seule voie pour soumettre une nouvelle tentative.
            onPressed: (_submitting || _feedback != null) ? null : _submit,
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

  /// Bouton d'aide, ou `null` s'il n'a rien a offrir.
///
/// LE LIBELLE VIENT DU BUDGET, PAS DE L'ECRAN.
///
/// `HintBudget.cta` est un enonce ferme : le bouton ne peut donc pas
/// inventer un cas, ni diverger du compte rendu du moteur. L'ecran ne
/// recompte rien — il lit le budget, affiche le libelle correspondant.
///
/// Le bouton RESTE VISIBLE s'il etait affiche au moment de la validation :
/// seule sa disponibilite change. Le retirer modifierait la hauteur de la barre
/// d'action apres chaque reponse, ce qui serait plus derangeant qu'un bouton
/// inactif.
Widget? _hintButton() {
    final budget = _budget();
    final previous = _previous;

    if (budget.cta == HintCta.none) return null;

    final previousNumber = previous == null
        ? null
        : V1ScreenRules.positionOf(previous.id);
    final label = RelioStrings.hintCta(budget.cta, previousExerciseNumber: previousNumber);

    // Budget epuise : on ne demande plus un indice, on propose de relire.
    final isReview = budget.cta == HintCta.reviewPrevious;

    return TextButton(
      onPressed: _locked
          ? null
          : (isReview ? _reviewPreviousExercise : _askForHint),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (isReview) ...<Widget>[
            const Icon(Icons.arrow_back, size: 18),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  /// Bannière dismissible d'erreur d'envoi.
  Widget _errorBanner() {
    final palette = RelioPaletteScope.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.errorBackground,
        borderRadius: BorderRadius.circular(RelioRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline,
              color: palette.errorText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  RelioStrings.submitErrorBanner,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: RelioTheme.fontFamily,
                    color: palette.errorText,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.errorText,
                    minimumSize: const Size.fromHeight(36),
                  ),
                  child: const Text(RelioStrings.retry),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSubmitError = false),
            icon: const Icon(Icons.close, size: 18),
            color: palette.errorText,
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
    final palette = RelioPaletteScope.of(context);

    return Semantics(
      liveRegion: true,
      child: Text(
        RelioStrings.emptyAnswerInline,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: RelioTheme.fontFamily,
          color: palette.errorText,
        ),
      ),
    );
  }
}
