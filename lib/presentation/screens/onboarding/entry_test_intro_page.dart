/// Onboarding — introduction au questionnaire d'entrée.
///
/// L'écran explique l'étape qui vient. Il ne la prépare pas à un examen : il
/// annonce cinq questions courtes, et dit qu'on avance pas à pas.
///
/// AUCUNE INFORMATION SUR LA PERFORMANCE. Ni score, ni pourcentage, ni
/// difficulté annoncée, ni aperçu d'un résultat. L'élève ne doit pas pouvoir
/// croire qu'il va être évalué avant de l'être — et ce qu'il écrit ensuite
/// ne lui en dira rien non plus.
///
/// LA VISUALISATION EST UNE PROMESSE DE DURÉE, PAS UNE PROGRESSION. Les cinq
/// pastilles sont vides : elles disent « cinq questions », pas « zéro fait ».
/// Un indicateur à moitié rempli serait déjà une évaluation.
library;

import 'package:flutter/material.dart';

import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import 'onboarding_metrics.dart';

/// Explication de l'étape questionnaire, avant le prénom.
class EntryTestIntroPage extends StatefulWidget {
  /// Crée l'écran d'introduction au questionnaire.
  const EntryTestIntroPage({
    super.key,
    required this.onStart,
    this.reduceAnimations = false,
  });

  /// Appelé au tap sur « C'est parti ! ».
  final VoidCallback onStart;

  /// L'élève a demandé la réduction des animations.
  final bool reduceAnimations;

  @override
  State<EntryTestIntroPage> createState() => _EntryTestIntroPageState();
}

class _EntryTestIntroPageState extends State<EntryTestIntroPage>
    with SingleTickerProviderStateMixin {
  /// Arrivée décalée : pastilles, texte, bouton.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : Duration(milliseconds: _totalMs),
  );

  static int get _totalMs =>
      OnboardingMetrics.welcomeRevealMs * 3 +
      OnboardingMetrics.staggerMs * 2;

  @override
  void initState() {
    super.initState();
    if (widget.reduceAnimations) {
      _reveal.value = 1;
      return;
    }
    _reveal.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  double _block(int index) {
    if (_reveal.value >= 1) return 1;
    final int start =
        index * (OnboardingMetrics.welcomeRevealMs + OnboardingMetrics.staggerMs);
    final int end = start + OnboardingMetrics.welcomeRevealMs;
    return ((_reveal.value * _totalMs - start) / (end - start)).clamp(0.0, 1.0);
  }

  Widget _arriving(int index, Widget child) {
    final double t = Curves.easeOut.transform(_block(index));
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, OnboardingMetrics.slideOffset * (1 - t)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    // L'écran s'abonne à l'animation. SANS cet abonnement, `build` ne serait
    // rejoué que si un AUTRE élément de l'arbre le demandait : le contrôleur
    // tournerait, mais l'écran resterait peint tel qu'il l'était à la première
    // image — c'est-à-dire entièrement transparent. Un `AnimatedBuilder` qui
    // n'écoute rien ne redessine rien ; c'est tout le sujet.
    return AnimatedBuilder(
      animation: _reveal,
      builder: (BuildContext context, _) => Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: RelioSpacing.xxl),
              _arriving(0, _chips(palette)),
              const SizedBox(height: RelioSpacing.xl),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RelioSpacing.horizontal,
                      vertical: RelioSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _arriving(
                          1,
                          Text(
                            RelioStrings.entryIntroMessage,
                            textAlign: TextAlign.center,
                            style: RelioType.title(palette),
                          ),
                        ),
                        const SizedBox(height: RelioSpacing.md),
                        _arriving(
                          1,
                          Text(
                            RelioStrings.entryIntroCaption,
                            textAlign: TextAlign.center,
                            style: RelioType.caption(palette),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  RelioSpacing.horizontal,
                  RelioSpacing.md,
                  RelioSpacing.horizontal,
                  RelioSpacing.xl,
                ),
                child: _arriving(
                  2,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onStart,
                      child: const Text(RelioStrings.entryIntroStart),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Les cinq pastilles : une par question, toutes vides.
  ///
  /// Elles ne se remplissent JAMAIS. Les remplir reviendrait à afficher une
  /// progression dans une étape où aucune réponse n'est encore attendue — et
  /// à suggérer un décompte.
  Widget _chips(RelioPalette palette) {
    return Semantics(
      // Les pastilles sont purement décoratives : la légende ci-dessous en
      // dit déjà « cinq questions, une par une ». Les annoncer une par une
      // ferait entendre cinq fois la même chose.
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < OnboardingMetrics.introChipCount; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: OnboardingMetrics.introChipGap),
            Container(
              width: OnboardingMetrics.introChipSize,
              height: OnboardingMetrics.introChipSize,
              decoration: BoxDecoration(
                color: i.isEven ? palette.brand : palette.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}