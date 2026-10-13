/// Onboarding — écran de clôture.
///
/// Le personnage grandit de 80 à 140 dp, se repose, puis Relio remercie
/// l'élève par son prénom.
///
/// AUCUN BILAN. Ni score, ni « tu as réussi », ni nombre de bonnes réponses :
/// le test d'entrée a enregistré des faits, et la clôture ne les restitue
/// pas. L'élève ne repart pas avec une note — il repart avec un tuteur.
library;

import 'package:flutter/material.dart';

import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import '../../branding/relio_character.dart';
import 'name_input.dart';
import 'onboarding_metrics.dart';

/// Remercie l'élève et propose de découvrir Relio.
///
/// `TickerProviderStateMixin` et NON `SingleTickerProviderStateMixin` : cette
/// page anime TROIS séquence (croissance du personnage, texte, bouton). Un
/// `SingleTickerProvider` n'autorise qu'un contrôleur et aurait levé à la
/// construction.
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
  /// Croissance du personnage, puis apparition du texte, puis du bouton.
  ///
  /// Les trois temps sont SÉQUENTIELS : le personnage se redresse avant que
  /// Relio ne parle. Sans cette attente, la phrase arriverait par-dessus une
  /// forme encore en mouvement.
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : const Duration(milliseconds: OnboardingMetrics.closingGrowMs),
  );

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
    // Réduction des animations : les trois éléments apparaissent
    // IMMÉDIATEMENT, sans aucune temporisation.
    //
    // Aucune temporisation n'est même planifiée dans ce cas : un
    // `Future.delayed(Duration.zero)` planifierait un timer, et un test qui
    // détruit l'arbre le trouverait encore en attente. Les delays sont donc
    // carrément absents, pas réduits à zéro.
    if (widget.reduceAnimations) {
      _grow.value = 1;
      _text.value = 1;
      _button.value = 1;
      return;
    }

    await _grow.forward();
    if (!mounted) return;
    // 1,5 s de pause : le personnage s'installe avant que le texte arrive.
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
    _grow.dispose();
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

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double from = OnboardingMetrics.characterSize(
              width: constraints.maxWidth,
              large: false,
            );
            final double to = OnboardingMetrics.characterSize(
              width: constraints.maxWidth,
              large: true,
            );
            final double size = Tween<double>(
              begin: from,
              end: to,
            ).evaluate(_grow);

            // MISE EN PAGE EN COLONNE, et non en `Stack` superpose.
            //
            // Le `Stack` positionnait le personnage et le texte par des
            // decalages ABSOLUS, chacun ignorant l'autre. Sur un petit ecran
            // (360 x 640) avec la police a 1,3, la phrase de cloture occupe
            // quatre lignes et venaiT CHEVAUCHER le personnage : les deux se
            // trouvaient dans la meme bande verticale.
            //
            // La colonne rend ce defaut IMPOSSIBLE : chaque element recoit la
            // place restante, et le texte ne peut pas remonter sur le
            // personnage quel que soit le nombre de lignes.
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: RelioSpacing.xxl),
                  child: RelioCharacter(
                    size: size,
                    animate: !widget.reduceAnimations,
                  ),
                ),
                // Le texte occupe toute la place restante et se centre dedans :
                // il s'ecarte du personnage au lieu de le traverser.
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RelioSpacing.horizontal,
                        vertical: RelioSpacing.md,
                      ),
                      child: Opacity(
                        opacity: _text.value,
                        child: Text(
                          RelioStrings.closingMessage(
                            // Le prénom est capitalisé ici aussi : une
                            // installation antérieure, ou une saisie passée
                            // par l'écran Profil, peut l'avoir laissé en
                            // minuscules.
                            capitalizeName(widget.name),
                          ),
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
                        child: FilledButton(
                          onPressed: _busy ? null : _confirm,
                          child: const Text(RelioStrings.closingDiscover),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}