/// Ouverture de Relio — révélation de la marque.
///
/// L'ouverture ne RACONTE rien. Elle montre le logo — le mark seul, 160 dp,
/// centré, sans aucun texte — le laisse se poser, puis s'efface vers l'écran
/// Bienvenue. Durée 1,8 s. Un tap n'importe où saute à l'écran suivant.
///
/// AUCUN PERSONNAGE. L'ouverture montre la marque et rien d'autre.
///
/// L'ANIMATION N'EST JAMAIS UNE CONDITION DE NAVIGATION. Le passage à
/// l'étape suivante est déclenché par une minuterie bornée, pas par la fin
/// d'une animation : une animation avortée, une prefs « réduire les
/// animations », ou un retour au premier plan ne peuvent pas bloquer l'élève.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../onboarding/entry_kit.dart';
import '../onboarding/onboarding_metrics.dart';

/// Écran d'ouverture : le logo, puis l'écran Bienvenue.
class OpeningPage extends StatefulWidget {
  /// Crée l'écran d'ouverture.
  const OpeningPage({
    super.key,
    required this.onFinished,
    this.reduceAnimations = false,
    this.preload,
  });

  /// Appelé une fois l'écran passé. Rend la main à l'appelant.
  final Future<void> Function() onFinished;

  /// L'élève a demandé la réduction des animations.
  ///
  /// Le logo apparaît alors immédiatement, et l'écran enchaîne après un délai
  /// court mais non nul : sans cela, la Bienvenue s'afficherait dans la même
  /// image que l'ouverture, et l'élève ne verrait pas qu'il y a deux étapes.
  final bool reduceAnimations;

  /// Préchargement silencieux de l'accueil, lancé en arrière-plan.
  ///
  /// Injectable pour les tests ; en production, c'est la charge utile d'accueil.
  /// Son échec est absorbé : rien de ce qui précède l'accueil ne doit
  /// pouvoir afficher une erreur.
  final Future<void> Function()? preload;

  @override
  State<OpeningPage> createState() => OpeningPageState();
}

class OpeningPageState extends State<OpeningPage>
    with SingleTickerProviderStateMixin {
  /// Le logo apparaît, se pose, puis l'écran s'efface.
  ///
  /// UN SEUL contrôleur : la révélation est un mouvement unique, et trois
  /// contrôleurs qui s'enchaineraient introduiraient trois fenêtres où
  /// l'écran pourrait rester figé.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : const Duration(milliseconds: OnboardingMetrics.openingTotalMs),
  );

  Timer? _exit;

  /// L'écran a-t-il déjà rendu la main ? Empêche un double appel.
  bool _done = false;

  @override
  void initState() {
    super.initState();

    // Le préchargement démarre AVANT la révélation : il a toute la durée du
    // mouvement pour dériver. Rien n'est affiché, rien ne bloque.
    final preload = widget.preload;
    if (preload != null) {
      preload().catchError((Object _) {});
    }

    _play();
  }

  Future<void> _play() async {
    if (widget.reduceAnimations) {
      // Le logo est déjà à sa place ; seule l'attente de bascule subsiste.
      _reveal.value = 1;
    } else {
      await _reveal.forward();
    }
    if (!mounted) return;
    _scheduleExit();
  }

  /// Programme le passage à l'étape Bienvenue.
  ///
  /// Le délai est borné et court : il laisse le logo se poser, il ne retient
  /// personne. Une réduction des animations le raccourcit sans le supprimer.
  void _scheduleExit() {
    _exit?.cancel();
    _exit = Timer(
      widget.reduceAnimations
          ? const Duration(milliseconds: OnboardingMetrics.openingExitFadeMs)
          : const Duration(milliseconds: OnboardingMetrics.openingExitMs),
      _finish,
    );
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    await widget.onFinished();
  }

  /// Retour Android : on n'est pas enfermé dans cet écran.
  ///
  /// L'écran d'ouverture est le PREMIER de l'application : le laisser
  /// sans issue, c'est interdire à l'élève de sortir. On rend donc la main
  /// comme si le logo s'était joué — c'est l'appelant qui décide de la suite.
  void _onBack() {
    _exit?.cancel();
    _finish();
  }

  @override
  void dispose() {
    _exit?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _onBack();
      },
      // Un tap n'importe où saute à l'écran suivant : la transition est
      // interruptible, et personne n'attend 1,8 s contre son gré.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _finish(),
        child: Scaffold(
          backgroundColor: EntryColors.background,
          body: SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _reveal,
                builder: (BuildContext context, Widget? child) {
                  final double t = _reveal.value;
                  final double fade = Curves.easeOut.transform(
                    Curves.easeOut.transform(_interval(
                      t,
                      0,
                      OnboardingMetrics.openingFadeMs,
                      OnboardingMetrics.openingTotalMs,
                    )),
                  );
                  final double scale = Curves.easeOutBack.transform(
                    Curves.easeOut.transform(_interval(
                      t,
                      OnboardingMetrics.openingScaleDelayMs,
                      OnboardingMetrics.openingScaleMs,
                      OnboardingMetrics.openingTotalMs,
                    )),
                  );

                  return Opacity(
                    opacity: fade,
                    child: Transform.translate(
                      // Le logo descend de `openingRise` dp vers sa place :
                      // le « mouvement graphique subtil » de l'ouverture. Il
                      // n'a lieu qu'une fois, à l'arrivée — aucun mouvement
                      // permanent.
                      offset: Offset(
                        0,
                        OnboardingMetrics.openingRise * (1 - scale),
                      ),
                      child: Transform.scale(
                        scale: OnboardingMetrics.openingScaleFrom +
                            (1 - OnboardingMetrics.openingScaleFrom) * scale,
                        child: child,
                      ),
                    ),
                  );
                },
                // Le mark est construit UNE FOIS, hors du builder :
                // l'animer ne doit pas le reconstruire à chaque image.
                child: const EntryMark(size: EntryBrand.opening),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progression de l'animation globale [t] sur un intervalle donné, bornée à 1.
///
/// Sans cette borne, une interpolation qui dépasse la fin de son intervalle
/// continuerait de progresser. C'est notamment le cas de `easeOutBack`, qui
/// passe volontairement au-delà de 1 pour produire son léger rebond : sans
/// bornage, le logo deborderait de l'écran.
double _interval(double t, int startMs, int durationMs, int totalMs) {
  final double from = startMs / totalMs;
  final double to = (startMs + durationMs) / totalMs;
  final double local = ((t - from) / (to - from)).clamp(0.0, 1.0);
  return local;
}