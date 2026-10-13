/// Onboarding — écran du test d'entrée (cinq questions).
///
/// Cet écran pose CINQ questions et enregistre CINQ réponses. Il ne dit
/// jamais si une réponse est juste ou fausse.
///
/// INTERDITS, tenus par construction :
///  - aucun feedback de correction, aucun indice, aucun chiffre autre que
///    la progression « N sur 5 » ;
///  - aucun score, pourcentage ou diagnostic ;
///  - aucun chronomètre ;
///  - aucun retour vers une question déjà soumise ;
///  - aucune réaction du personnage.
///
/// La correction est faite par le cœur ([EntryTestOnboarding]) et n'est
/// JAMAIS lue ici : l'écran ne connaît que la persistance.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entrytest/entry_test_onboarding.dart';
import '../../../domain/entrytest/entry_test_question.dart';
import '../../../domain/entrytest/entry_test_session.dart';
import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import '../../branding/relio_character.dart';
import '../../widgets/math_text.dart';
import 'onboarding_metrics.dart';

/// Phase d'affichage d'une question.
///
/// L'écran ne passe jamais à la suivante avant la confirmation de l'écriture :
/// la phase [submitting] est donc une phase à part entière, pas un simple
/// drapeau.
enum _QuestionPhase {
  /// Aucune réponse fournie : le bouton est inactif.
  ready,

  /// Une réponse est fournie, le bouton est actif.
  filled,

  /// L'écriture est en cours. Le champ est verrouillé, la saisie reste
  /// visible, rien ne bouge.
  submitting,

  /// L'écriture a échoué. La saisie est CONSERVÉE et l'écran ne bouge pas.
  errorSaving,
}

/// Affiche et fait saisir les cinq questions du test d'entrée.
class EntryTestPage extends StatefulWidget {
  /// Crée l'écran de test.
  const EntryTestPage({
    super.key,
    required this.onboarding,
    required this.session,
    required this.onFinished,
    this.reduceAnimations = false,
  });

  /// Passage par l'orchestrateur : aucun accès direct au dépôt.
  final EntryTestOnboarding onboarding;

  /// Session en cours — reprise si elle existait.
  final EntryTestSession session;

  /// La session est terminée : passer à la clôture.
  final VoidCallback onFinished;

  /// L'élève a demandé la réduction des animations.
  final bool reduceAnimations;

  @override
  State<EntryTestPage> createState() => _EntryTestPageState();
}

class _EntryTestPageState extends State<EntryTestPage>
    with SingleTickerProviderStateMixin {
  late EntryTestSession _session = widget.session;

  final TextEditingController _answer = TextEditingController();

  /// Choix sélectionné, pour une question à choix multiple.
  String? _choice;

  _QuestionPhase _phase = _QuestionPhase.ready;

  /// Les éléments de la question sortent-ils en fondu ?
  bool _leaving = false;

  EntryTestQuestion? get _question => _session.nextQuestion;

  /// Combien de questions sont déjà derrière l'élève.
  int get _answered => _session.answeredCount;

  @override
  void initState() {
    super.initState();
    _answer.addListener(_onAnswerChanged);
    if (_question == null && _session.isReadyToComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished();
      });
    }
  }

  @override
  void dispose() {
    _answer
      ..removeListener(_onAnswerChanged)
      ..dispose();
    super.dispose();
  }

  void _onAnswerChanged() {
    // La phase ne bouge que si l'élève modifie sa saisie : pendant
    // l'écriture, le champ est verrouillé et la phase reste `submitting`.
    if (_phase != _QuestionPhase.ready &&
        _phase != _QuestionPhase.filled) {
      return;
    }
    final bool filled = _hasAnswer;
    setState(() {
      _phase = filled ? _QuestionPhase.filled : _QuestionPhase.ready;
    });
  }

  /// L'élève a-t-il fourni une réponse exploitable par le champ ?
  bool get _hasAnswer {
    final EntryTestQuestion? question = _question;
    if (question == null) return false;
    if (question.isChoice) return _choice != null;
    return _answer.text.trim().isNotEmpty;
  }

  /// Filtre du champ numérique : chiffres, et « - » seulement en tête.
  ///
  /// Le test d'entrée ne demande que des entiers ; un tiret au milieu d'un
  /// nombre n'en est pas un.
  static final TextInputFormatter _integerFormatter =
      TextInputFormatter.withFunction(
    (TextEditingValue oldValue, TextEditingValue newValue) {
      final String text = newValue.text;
      final StringBuffer buffer = StringBuffer();
      bool signConsumed = false;

      for (final int i in text.runes) {
        final String character = String.fromCharCode(i);
        if (character == '-' && !signConsumed && buffer.isEmpty) {
          buffer.write(character);
          signConsumed = true;
          continue;
        }
        if (character.codeUnitAt(0) >= 0x30 &&
            character.codeUnitAt(0) <= 0x39) {
          buffer.write(character);
        }
      }

      final String filtered = buffer.toString();
      if (filtered == text) return newValue;
      return newValue.copyWith(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
        composing: TextRange.empty,
      );
    },
  );

  /// Enregistre la réponse, puis passe à la question suivante.
  ///
  /// L'appel ne se termine qu'après l'écriture : c'est le cœur qui le
  /// garantit, et c'est ce qui empêche l'écran d'avancer sur une réponse
  /// non enregistrée.
  Future<void> _submit() async {
    final EntryTestQuestion? question = _question;
    if (question == null || !_hasAnswer || _phase == _QuestionPhase.submitting) {
      return;
    }

    final String raw = question.isChoice ? _choice! : _answer.text.trim();

    setState(() => _phase = _QuestionPhase.submitting);

    final EntryTestAnswer recorded;
    try {
      recorded = await widget.onboarding.submitAnswer(
        session: _session,
        question: question,
        rawAnswer: raw,
      );
    } catch (_) {
      // ÉCHEC D'ENREGISTREMENT.
      //
      // On n'avance PAS, on n'efface PAS la saisie, et on ne dit RIEN de la
      // réponse — juste qu'elle n'a pas pu être enregistrée. Le réessai
      // rappelle le même appel : l'identifiant étant déterministe, aucune
      // ligne ne peut être écrite deux fois.
      if (!mounted) return;
      setState(() => _phase = _QuestionPhase.errorSaving);
      return;
    }

    if (!mounted) return;

    final EntryTestSession updated = _session.withAnswer(recorded);

    // Aucune information ne filtre : ni justesse, ni évaluabilité. La réponse
    // est enregistrée, la question suivante s'affiche.
    if (!updated.isReadyToComplete) {
      await _leaveQuestion();
      if (!mounted) return;
      setState(() {
        _session = updated;
        _answer.clear();
        _choice = null;
        _phase = _QuestionPhase.ready;
        _leaving = false;
      });
      return;
    }

    // Les cinq réponses sont enregistrées : le parcours se termine.
    await widget.onboarding.finishSession(updated);
    if (!mounted) return;
    widget.onFinished();
  }

  /// Fondu de sortie avant d'afficher la question suivante (200 ms).
  Future<void> _leaveQuestion() async {
    if (widget.reduceAnimations) return;
    setState(() => _leaving = true);
    // Le clavier se ferme AVANT le fondu : le laisser ouvert ferait remonter
    // le bouton « Continuer » sous les doigts pendant la transition.
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(
      const Duration(milliseconds: OnboardingMetrics.questionFadeOutMs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final EntryTestQuestion? question = _question;

    // Cas théorique : plus aucune question, et pourtant la session n'est pas
    // prête à être terminée. On ne fabrique JAMAIS de question de
    // substitution : on le dit, et on laisse passer à la clôture.
    if (question == null) {
      return _noQuestion(palette);
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double size = OnboardingMetrics.characterSize(
                    width: constraints.maxWidth,
                    large: false,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RelioSpacing.horizontal,
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: size * OnboardingMetrics.characterTopRatio),
                        RelioCharacter(
                          size: size,
                          animate: !widget.reduceAnimations,
                        ),
                        const SizedBox(height: RelioSpacing.xl),

                        // SEULE progression visible : « N sur 5 ».
                        Text(
                          RelioStrings.entryProgress(
                            _answered + 1,
                            _session.questions.length,
                          ),
                          style: RelioType.caption(palette),
                        ),
                        const SizedBox(height: RelioSpacing.xl),

                        // `AnimatedOpacity` porte le fondu : l'écran NE FABRIQUE pas le délai —
// `_leaveQuestion` le fait, et attend qu'il soit écoulé. Un fondu ici
// suffirait, mais il rendrait l'état visible dépendant d'une frame.
                        AnimatedOpacity(
                          opacity: _leaving ? 0 : 1,
                          duration: widget.reduceAnimations
                              ? Duration.zero
                              : const Duration(
                                  milliseconds:
                                      OnboardingMetrics.questionFadeOutMs,
                                ),
                          child: Column(
                            children: <Widget>[
                              _statementCard(palette, question),
                              const SizedBox(height: RelioSpacing.xl),
                              _answerZone(palette, question),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _bottomBar(palette, question),
          ],
        ),
      ),
    );
  }

  /// Carte d'énoncé, identique en présentation à celle de S2.
  Widget _statementCard(RelioPalette palette, EntryTestQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RelioSpacing.cardInner),
        child: MathText(
          text: question.statement,
          style: RelioType.body(palette).copyWith(height: 1.5),
        ),
      ),
    );
  }

  /// Zone de réponse, selon le type de la question.
  Widget _answerZone(RelioPalette palette, EntryTestQuestion question) {
    if (question.isChoice) {
      return Column(
        children: <Widget>[
          for (int i = 0; i < question.choices.length; i++) ...<Widget>[
            if (i > 0)
              const SizedBox(height: OnboardingMetrics.choiceGap),
            _choiceCard(palette, question.choices[i]),
          ],
        ],
      );
    }

    return SizedBox(
      height: RelioSizes.fieldHeight,
      child: TextField(
        controller: _answer,
        enabled: _phase != _QuestionPhase.submitting,
        // Le champ se verrouille pendant l'écriture : la saisie reste
        // visible, mais n'est plus modifiable.
        readOnly: _phase == _QuestionPhase.submitting,
        inputFormatters: <TextInputFormatter>[_integerFormatter],
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: false,
        ),
        style: RelioType.numeric(palette).copyWith(fontSize: 16),
        decoration: const InputDecoration(hintText: ''),
      ),
    );
  }

  /// Carte de choix.
  ///
  /// Ni radio, ni coche : l'état se lit au trait et au fond, et le texte
  /// reste lisible dans les deux cas.
  Widget _choiceCard(RelioPalette palette, String choice) {
    final bool selected = _choice == choice;
    final bool locked = _phase == _QuestionPhase.submitting;

    return SizedBox(
      height: OnboardingMetrics.choiceHeight,
      width: double.infinity,
      child: Material(
        color: selected ? palette.primaryContainer : palette.surface,
        borderRadius: RelioRadius.cardAll,
        child: InkWell(
          borderRadius: RelioRadius.cardAll,
          onTap: locked
              ? null
              : () => setState(() {
                    _choice = choice;
                    _phase = _QuestionPhase.filled;
                  }),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: RelioRadius.cardAll,
              border: Border.all(
                color: selected ? palette.primary : palette.outline,
                width: selected
                    ? RelioSizes.fieldBorderWidth
                    : RelioSizes.cardBorderWidth,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              // Fractions en forme « slash » : jamais empilées.
              choice,
              style: selected
                  ? RelioType.bodyStrong(palette)
                  : RelioType.body(palette).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Barre basse : bouton « Continuer », ou bannière d'échec et réessai.
  Widget _bottomBar(RelioPalette palette, EntryTestQuestion question) {
    final bool failed = _phase == _QuestionPhase.errorSaving;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RelioSpacing.horizontal,
        RelioSpacing.md,
        RelioSpacing.horizontal,
        RelioSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (failed) ...<Widget>[
            _neutralBanner(palette),
            const SizedBox(height: RelioSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text(RelioStrings.entryRetry),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _hasAnswer &&
                        _phase != _QuestionPhase.submitting
                    ? _submit
                    : null,
                child: const Text(RelioStrings.entryContinue),
              ),
            ),
        ],
      ),
    );
  }

  /// Bannière d'échec — neutre, sans emoji ni icône alarmante.
  Widget _neutralBanner(RelioPalette palette) {
    return Container(
      padding: const EdgeInsets.all(RelioSpacing.md),
      decoration: BoxDecoration(
        color: palette.hintBackground,
        borderRadius: RelioRadius.cardAll,
      ),
      child: Text(
        RelioStrings.entrySaveError,
        style: RelioType.body(palette).copyWith(color: palette.hintText),
      ),
    );
  }

  /// Aucune question disponible, session pourtant incomplète.
  Widget _noQuestion(RelioPalette palette) {
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RelioSpacing.horizontal,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                RelioStrings.entryNoQuestion,
                textAlign: TextAlign.center,
                style: RelioType.title(palette),
              ),
              const SizedBox(height: RelioSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onFinished,
                  child: const Text(RelioStrings.entryContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}