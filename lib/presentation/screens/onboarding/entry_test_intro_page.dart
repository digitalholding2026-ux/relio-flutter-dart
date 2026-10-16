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

import '../../branding/relio_mark.dart';
import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import 'entry_kit.dart';
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
  /// Arrivée décalée : logo et pastilles, texte, bouton.
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
        backgroundColor: EntryColors.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: EntryGaps.topToLogo),
              _arriving(0, const EntryMark(size: EntryBrand.intro)),
              const SizedBox(height: EntryGaps.logoToTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EntryGaps.horizontal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _arriving(
                        1,
                        Text(
                          RelioStrings.entryIntroTitle,
                          textAlign: TextAlign.left,
                          style: RelioType.title(palette),
                        ),
                      ),
                      const SizedBox(height: EntryGaps.textGap),
                      _arriving(
                        1,
                        Text(
                          RelioStrings.entryIntroBody,
                          textAlign: TextAlign.left,
                          style: RelioType.body(palette),
                        ),
                      ),
                      const SizedBox(height: EntryGaps.beforeFinal),
                      _arriving(
                        1,
                        Text(
                          RelioStrings.entryIntroFinal,
                          textAlign: TextAlign.left,
                          style: RelioType.bodyStrong(palette).copyWith(
                            color: RelioBrand.wordmark,
                          ),
                        ),
                      ),
                      const SizedBox(height: EntryGaps.beforeFinal),
                      _arriving(
                        0,
                        const Center(child: EntryDots()),
                      ),
                    ],
                  ),
                ),
              ),
              EntryAction(
                child: SizedBox(
                  width: double.infinity,
                  child: _arriving(
                    2,
                    EntryButton(
                      label: RelioStrings.entryIntroStart,
                      onPressed: widget.onStart,
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
}
