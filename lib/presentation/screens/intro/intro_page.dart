/// Ecran d'entree â€” premiere ouverture uniquement.
///
/// Le personnage est le MARK anime, pas une mascotte. Aucun visage, aucun
/// membre, aucun son, aucun confetti.
///
/// La chronologie vit dans [IntroSequenceState] : cet ecran ne fait que
/// l'appliquer. Aucun temps n'y est invente.
///
/// L'ecran ne montre aucun indicateur de chargement : le prechargement se
/// fait en silence (voir [IntroPreloader]).
library;

import 'package:flutter/material.dart';

import '../../branding/relio_character.dart';
import '../../branding/relio_mark.dart';
import '../../theme/relio_theme.dart';
import 'intro_sequence.dart';

/// Ecran d'entree anime.
class IntroPage extends StatefulWidget {
  /// Cree l'ecran d'entree.
  const IntroPage({
    super.key,
    required this.onFinished,
    this.reduceAnimations = false,
    this.preload,
  });

  /// Appele quand l'eleve termine l'ecran (bouton ou retour Android).
  final Future<void> Function() onFinished;

  /// L'eleve a demande la reduction des animations.
  ///
  /// La sequence reste identique â€” les textes et le bouton apparaissent aux
  /// memes instants â€” mais le personnage reste FIGE. Reduire les animations
  /// ne doit pas supprimer l'information : sans le personnage anime, l'eleve
  /// ne voit plus de quoi parle l'ecran.
  final bool reduceAnimations;

  /// Prechargement silencieux, lance en arriere-plan.
  ///
  /// Injectable pour les tests ; en production, c'est la charge utile
  /// d'accueil.
  final Future<void> Function()? preload;

  @override
  State<IntroPage> createState() => IntroPageState();
}

class IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  /// Portee du controller : une valeur normalisee de 0 a 1 sur [kTimelineSpan].
  ///
  /// On ne fait pas durer le controller d'un jour entier : la sequence dure
  /// 5,3 s. Passer d'une valeur normalisee a un temps relu passe par une
  /// constante unique, ce qui evite de dependre d'une conversion obscure.
  static const int kTimelineSpanMs = 6000;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: kTimelineSpanMs),
  );

  /// Instant de depart de la sequence.
  Duration _elapsed = Duration.zero;

  /// Instant du tap d'acceleration, s'il y en a eu un.
  Duration? _acceleratedAt;

  /// L'eleve a-t-il appuye sur Â« Commencer Â» ?
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    // Le prechargement demarre AVANT la sequence : il a 5,3 secondes pour
    // deriver. Rien n'est affiche, rien ne bloque.
    final preload = widget.preload;
    if (preload != null) {
      // L'echec est silencieux : l'eleve va de toute facon vers l'accueil.
      preload().catchError((Object _) {});
    }

    _controller.addListener(_tick);
    _controller.repeat();
  }

  void _tick() {
    final Duration total = Duration(
      milliseconds: (_controller.value * kTimelineSpanMs).round(),
    );
    final Duration? accel = _acceleratedAt;

    final Duration next = accel == null
        ? total
        : (total > accel ? total - accel : Duration.zero);

    if (next != _elapsed && mounted) {
      setState(() => _elapsed = next);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  /// Etat courant de la sequence.
  IntroSequenceState get _state {
    final Duration? accel = _acceleratedAt;
    return accel == null
        ? IntroSequenceState.at(_elapsed)
        : IntroSequenceState.accelerated(_elapsed);
  }

  /// Un tap n'importe ou ACCELERE la sequence.
  ///
  /// Aucun effet visuel immediat : ni ripple, ni halo, ni reaction du
  /// personnage. Le seul signe est l'arrivee du bouton.
  ///
  /// Une fois le bouton visible, le tap ne fait RIEN : c'est le bouton, et lui
  /// seul, qui confirme.
  void _onTap() {
    final IntroSequenceState state = _state;
    if (_confirmed || !state.accelerates) return;

    setState(() {
      _acceleratedAt = Duration(
        milliseconds: (_controller.value * kTimelineSpanMs).round(),
      );
      _elapsed = Duration.zero;
    });
  }

  Future<void> _confirm() async {
    if (_confirmed) return;
    setState(() => _confirmed = true);
    await widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final IntroSequenceState state = _state;
    final String? text = IntroTexts.forStage(state.stage);

    return Scaffold(
      backgroundColor: RelioBrand.splashBackground,
      // Bouton retour Android : saut direct a l'accueil, sans confirmation.
      // `true` signifie Â« l'application n'est pas fermee Â» : on abandonne
      // l'ecran d'entree, on ne quitte pas.
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (!didPop) _confirm();
        },
        child: GestureDetector(
          // `opaque` rend le tap fiable meme sur fond blanc.
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Le personnage s'adapte a l'espace disponible SANS jamais
              // pousser le texte hors ecran : sa taille est bornee, et c'est
              // l'espace restant qui commande.
              final double available = constraints.maxHeight;
              final double markSize = _markSizeFor(available);

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RelioSpacing.xl,
                    vertical: RelioSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Le personnage : centre, taille bornee.
                      SizedBox(
                        height: markSize,
                        child: Opacity(
                          opacity: state.characterOpacity,
                          child: Transform.scale(
                            scale: state.characterScale,
                            child: RelioCharacter(
                              size: markSize,
                              animate: !widget.reduceAnimations,
                              lean: state.leanDegrees,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: RelioSpacing.xxl),

                      // Le texte : un seul a la fois, le precedent s'efface.
                      SizedBox(
                        height: _textHeight(context),
                        child: Center(
                          child: AnimatedOpacity(
                            // L'opacite est calculee, pas animee par
                            // `AnimatedOpacity` : la sequence maitrise le
                            // rythme, le widget ne fait qu'appliquer.
                            opacity: state.textOpacity,
                            duration: const Duration(milliseconds: 120),
                            child: text == null
                                ? const SizedBox.shrink()
                                : Text(
                                    text,
                                    textAlign: TextAlign.center,
                                    style: RelioType.title(palette),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: RelioSpacing.xl),

                      // Le bouton : 300 ms apres la question.
                      //
                      // Il n'est PAS dans l'arbre avant d'etre visible : un
                      // bouton simplement transparent resterait atteignable au
                      // toucher, et l'eleve pourrait le declencher avant que la
                      // sequence soit terminee.
                      SizedBox(
                        height: RelioSizes.primaryButtonHeight,
                        child: state.buttonVisible
                            // Le fondu d'apparition est porte par la cle :
                            // le bouton n'existe qu'a partir de 5,3 s, et son
                            // opacite suit `buttonOpacity`.
                            ? _StartButton(
                                key: ValueKey<int>(state.stage.index),
                                opacity: state.buttonOpacity,
                                onPressed: _confirm,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Taille du personnage, bornee pour qu'aucun texte ne sorte de l'ecran.
  ///
  /// La specification demande environ 140 dp. On respecte cette valeur
  /// quand la place le permet, et on reduit au-dela plutot que de pousser le
  /// texte hors ecran.
  static double _markSizeFor(double availableHeight) {
    const double ideal = 140;
    // Le personnage ne doit jamais depasser un tiers de la hauteur : sinon il
    // vole la place du texte sur un petit telephone.
    final double bounded = availableHeight * 0.33;
    return ideal < bounded ? ideal : bounded;
  }

  /// Hauteur reservee au texte, calee sur deux lignes.
  ///
  /// Reserver la hauteur evite que l'ecran Â« saute Â» a chaque changement de
  /// phrase. La hauteur est celle de deux lignes de style Title : le texte le
  /// plus long tient sur deux lignes a l'echelle d'accessibilite maximale de
  /// 1,3.
  static double _textHeight(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    final TextStyle style = RelioType.title(palette);
    return style.fontSize! * style.height! * 2 + RelioSpacing.sm;
  }
}

/// Bouton « Commencer ».
///
/// N'est construit que lorsque la sequence le declare visible : l'animation
/// d'apparition (fondu + glissement de 8 dp) est portee par ce widget, qui
/// n'existe qu'a partir de 5,3 s.
class _StartButton extends StatelessWidget {
  const _StartButton({super.key, required this.opacity, required this.onPressed});

  /// Opacite d'apparition, de 0 a 1, fournie par la sequence.
  final double opacity;

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          child: const Text(IntroTexts.startButton),
        ),
      ),
    );
  }
}

