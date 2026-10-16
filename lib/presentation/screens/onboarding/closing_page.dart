/// Onboarding — écran de clôture.
///
/// Le personnage (120 dp), puis Relio remercie l'élève par son prénom :
/// titre en Display, corps centré, bouton ancré en bas.
///
/// AUCUN BILAN. Ni score, ni « tu as réussi », ni nombre de bonnes réponses :
/// le test d'entrée a enregistré des faits, et la clôture ne les restitue
/// pas. L'élève ne repart pas avec une note — il repart avec un tuteur.
///
/// MISE EN PAGE EN COLONNE, jamais en `Stack` superposé : chaque élément
/// reçoit la place restante, et le texte ne peut pas remonter sur le
/// personnage quel que soit le nombre de lignes.
library;

import 'package:flutter/material.dart';

import '../../branding/relio_character.dart';
import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import 'entry_kit.dart';
import 'name_input.dart';
import 'onboarding_metrics.dart';

/// Remercie l'élève et propose de découvrir Relio.
class ClosingPage extends StatefulWidget {
  /// Crée l'écran de clôture.
  const ClosingPage({
    super.key,
    required this.name,
    required this.onConfirm,
    this.reduceAnimations = false,
  });

  /// Prénom de l'élève, déjà capitalisé par l'étape Prénom.
  final String name;

  /// Appelé au tap sur « Découvrir Relio ».
  ///
  /// L'appelant écrit le marqueur de fin de parcours. Cet écran ne connaît
  /// aucun dépôt : il rend la main et attend la confirmation.
  final Future<void> Function() onConfirm;

  /// L'élève a demandé la réduction des animations.
  final bool reduceAnimations;

  @override
  State<ClosingPage> createState() => _ClosingPageState();
}

class _ClosingPageState extends State<ClosingPage>
    with TickerProviderStateMixin {
  /// Apparition du texte, puis du bouton.
  ///
  /// Les deux temps sont SÉQUENTIELS : le personnage s'installe avant que
  /// Relio ne parle. Sans cette attente, la phrase arriverait par-dessus une
  /// forme encore en mouvement.
  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : const Duration(milliseconds: OnboardingMetrics.slideFadeMs),
  );

  late final AnimationController _button = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : const Duration(milliseconds: OnboardingMetrics.slideFadeMs),
  );

  /// Une écriture est-elle en cours ?
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    // Réduction des animations : les deux éléments apparaissent
    // IMMÉDIATEMENT, sans aucune temporisation.
    //
    // Aucune temporisation n'est même planifiée dans ce cas : un
    // `Future.delayed(Duration.zero)` planifierait un timer, et un test qui
    // détruit l'arbre le trouverait encore en attente. Les delays sont donc
    // carrément absents, pas réduits à zéro.
    if (widget.reduceAnimations) {
      _text.value = 1;
      _button.value = 1;
      return;
    }

    // Le personnage s'installe avant que le texte arrive.
    await Future<void>.delayed(
      const Duration(milliseconds: OnboardingMetrics.closingTextDelayMs),
    );
    if (!mounted) return;
    await _text.forward();
    if (!mounted) return;
    // 300 ms après le texte.
    await Future<void>.delayed(
      const Duration(milliseconds: OnboardingMetrics.closingButtonDelayMs),
    );
    if (!mounted) return;
    await _button.forward();
  }

  @override
  void dispose() {
    _text.dispose();
    _button.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);

    // L'écriture du marqueur est faite par l'appelant. En cas d'échec, il
    // rend la main sans passer à l'accueil : le bouton redevient actif et
    // l'élève reste ici. Aucune advancements forcée, aucun message.
    try {
      await widget.onConfirm();
    } catch (_) {
      // Aucun message visible : l'élève n'a rien à corriger, et une erreur
      // technique ne se répare pas en la lui racontant. Le bouton redevient
      // simplement actif.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    // L'écran s'abonne à ses deux animations. SANS cet abonnement, `build`
    // ne serait rejoué que si un AUTRE élément de l'arbre le demandait : les
    // contrôleurs tourneraient, mais le texte et le bouton resteraient peints
    // à leur état INITIAL — donc transparents. Un élève aurait vu le
    // personnage seul, sans phrase ni bouton, et n'aurait pas pu sortir.
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_text, _button]),
      builder: (BuildContext context, _) => Scaffold(
        backgroundColor: EntryColors.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: EntryGaps.topToLogo),
              RelioCharacter(
                size: EntryBrand.closing,
                animate: !widget.reduceAnimations,
              ),
              const SizedBox(height: EntryGaps.logoToTitle),
              // Le texte occupe toute la place restante et se centre dedans :
              // il s'écarte du personnage au lieu de le traverser.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EntryGaps.horizontal,
                    ),
                    child: Opacity(
                      opacity: _text.value,
                      child: Column(
                        children: <Widget>[
                          Text(
                            RelioStrings.closingTitle(
                              // Le prénom est capitalisé ici aussi : une
                              // installation antérieure, ou une saisie passée
                              // par l'écran Profil, peut l'avoir laissé en
                              // minuscules.
                              capitalizeName(widget.name),
                            ),
                            textAlign: TextAlign.center,
                            style: RelioType.display(palette),
                          ),
                          const SizedBox(height: EntryGaps.textGap),
                          Text(
                            RelioStrings.closingBody(),
                            textAlign: TextAlign.center,
                            style: RelioType.body(palette),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              EntryAction(
                child: Opacity(
                  opacity: _button.value,
                  child: Transform.translate(
                    // Glissement vertical de 8 dp à l'apparition.
                    offset: Offset(
                      0,
                      OnboardingMetrics.slideOffset * (1 - _button.value),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: EntryButton(
                        label: RelioStrings.closingDiscover,
                        loading: _busy,
                        onPressed: _busy ? null : () => _confirm(),
                      ),
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
