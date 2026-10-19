/// Onboarding — écran de bienvenue.
///
/// L'élève entre dans Relio. Le mark (100 dp) en haut, le titre en Display,
/// le sous-titre et la question en Body, puis le bouton ancré en bas.
///
/// AUCUN PERSONNAGE. L'écran montre la marque et du texte. Il n'introduit ni
/// avatar, ni mascotte, ni figure : ce sujet est suspendu.
///
/// LE TEXTE EST EXACT. Titre, sous-titre et question vivent dans
/// `RelioStrings` et ne sont ni raccourcis, ni reformulés. C'est la mise en
/// page qui s'adapte, jamais la phrase.
///
/// LE TEXTE NE DÉBORDE JAMAIS. La zone médiane est défilable : le bouton
/// reste atteignable, y compris avec la police système agrandie à 1,3.
library;

import 'package:flutter/material.dart';


import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import 'entry_kit.dart';
import 'onboarding_metrics.dart';

/// Accueil de l'élève, et entrée dans le parcours.
class WelcomePage extends StatefulWidget {
  /// Crée l'écran de bienvenue.
  const WelcomePage({
    super.key,
    required this.onStart,
    this.reduceAnimations = false,
  });

  /// Appelé au tap sur « Commencer ».
  ///
  /// L'appelant écrit `entryScreenSeen`. Cet écran ne connaît aucun dépôt.
  final Future<void> Function() onStart;

  /// L'élève a demandé la réduction des animations.
  final bool reduceAnimations;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  /// Arrivée progressive du contenu : logo, titre, texte, bouton.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : Duration(milliseconds: _totalMs),
  );

  /// Durée totale : quatre blocs, trois décalages.
  static int get _totalMs =>
      OnboardingMetrics.welcomeRevealMs * 4 +
      OnboardingMetrics.staggerMs * 3;

  bool _busy = false;

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

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onStart();
    } catch (_) {
      // Écriture du marqueur échouée : l'écran reste affiché et son bouton
      // redevient actif. Aucun message — l'élève n'a rien à corriger, et
      // l'ouverture sera simplement rejouée au prochain lancement.
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Progression du bloc [index] sur l'animation globale.
  double _block(int index) {
    if (_reveal.value >= 1) return 1;
    final int start =
        index * (OnboardingMetrics.welcomeRevealMs + OnboardingMetrics.staggerMs);
    final int end = start + OnboardingMetrics.welcomeRevealMs;
    return ((_reveal.value * _totalMs - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Un bloc qui arrive : fondu + glissement de 8 dp vers le haut.
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
              _arriving(
                0,
                const EntryMark(size: EntryBrand.welcome),
              ),
              const SizedBox(height: EntryGaps.logoToTitle),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EntryGaps.horizontal,
                ),
                child: _arriving(
                  1,
                  Text(
                    RelioStrings.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: RelioType.display(palette).copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
              // Le texte médian prend TOUTE la place restante : il ne peut ni
              // pousser le bouton hors de l'écran, ni remonter sur le logo,
              // quel que soit le nombre de lignes.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EntryGaps.horizontal,
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: EntryGaps.textGap),
                      _arriving(
                        2,
                        Text(
                          RelioStrings.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: RelioType.body(palette).copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: EntryGaps.beforeFinal),
                      _arriving(
                        2,
                        Text(
                          RelioStrings.welcomeQuestion,
                          textAlign: TextAlign.center,
                          style: RelioType.body(palette),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              EntryAction(
                child: SizedBox(
                  width: double.infinity,
                  child: _arriving(
                    3,
                    EntryButton(
                      label: RelioStrings.welcomeStart,
                      loading: _busy,
                      onPressed: _busy ? null : () => _start(),
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
