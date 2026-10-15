/// Onboarding — écran de bienvenue.
///
/// L'élève entre dans Relio. L'écran est Composition : une forme géométrique
/// discrète, un lockup, le texte d'accueil, puis le bouton.
///
/// AUCUN PERSONNAGE. L'écran montre la marque et du texte. Il n'introduit ni
/// avatar, ni mascotte, ni figure : ce sujet est suspendu.
///
/// LE TEXTE EST EXACT. Il vit dans `RelioStrings.welcomeMessage` et n'est ni
/// raccourci, ni reformulé, ni décliné selon la taille de l'écran. C'est la
/// mise en page qui s'adapte, jamais la phrase.
///
/// LE TEXTE NE DÉBORDE JAMAIS. La zone de texte est défilable et occupe la
/// place restante entre le logo et le bouton : le bouton reste atteignable,
/// y compris avec la police système agrandie à 1,3.
library;

import 'package:flutter/material.dart';

import '../../branding/relio_lockup.dart';
import '../../branding/relio_mark.dart';
import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
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
  /// Arrivée progressive du contenu : forme, lockup, texte, bouton.
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
        backgroundColor: palette.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth <=
                  OnboardingMetrics.compactWidthThreshold;
              final double cap = compact
                  ? OnboardingMetrics.welcomeLockupCapHeightCompact
                  : OnboardingMetrics.welcomeLockupCapHeight;

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: RelioSpacing.xxl),
                    child: _arriving(
                      0,
                      _Composition(palette: palette),
                    ),
                  ),
                  const SizedBox(height: RelioSpacing.xl),
                  _arriving(
                    1,
                    RelioLockupHorizontal(markSize: cap),
                  ),
                  // Le texte prend TOUTE la place restante et se centre dedans.
                  // Il ne peut donc ni pousser le bouton hors de l'écran, ni
                  // chevaucher le logo, quel que soit le nombre de lignes.
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RelioSpacing.horizontal,
                          vertical: RelioSpacing.md,
                        ),
                        child: _arriving(
                          2,
                          Text(
                            RelioStrings.welcomeMessage,
                            textAlign: TextAlign.center,
                            style: RelioType.title(palette),
                          ),
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
                      3,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _start,
                          child: const Text(RelioStrings.welcomeStart),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Forme géométrique discrète, au-dessus du lockup.
///
/// Trois formes, deux couleurs de marque, aucune animation permanente :
/// l'écran d'entrée ne doit pas devenir un fond animé. Elles sont décoratives
/// et n'ont aucune fonction d'information — c'est pourquoi elles ne sont ni
/// annoncées ni exposées au lecteur d'écran.
class _Composition extends StatelessWidget {
  const _Composition({required this.palette});

  final RelioPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: _Shape(
              size: 40,
              color: palette.primary.withValues(alpha: 0.10),
              radius: 20,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _Shape(
              size: 24,
              color: palette.brand.withValues(alpha: 0.18),
              radius: 8,
            ),
          ),
          const _Shape(size: 10, color: RelioBrand.mark, radius: 5),
        ],
      ),
    );
  }
}

/// Une forme de la composition.
class _Shape extends StatelessWidget {
  const _Shape({
    required this.size,
    required this.color,
    required this.radius,
  });

  final double size;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}