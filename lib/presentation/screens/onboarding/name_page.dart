/// Onboarding — étape Prénom.
///
/// Écran sans AppBar, contenu centré verticalement. Il ne demande qu'une
/// chose : le prénom de l'élève.
///
/// AUCUNE VALIDATION BLOQUANTE : pas de message d'erreur, pas de condition de
/// forme, pas de commentaire du personnage. Le bouton est simplement actif ou
/// non, et le prénom est capitalisé au passage.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../strings/relio_strings.dart';
import '../../theme/relio_theme.dart';
import '../../branding/relio_character.dart';
import 'name_input.dart';
import 'onboarding_metrics.dart';

/// Demande le prénom de l'élève.
class NamePage extends StatefulWidget {
  /// Crée l'écran Prénom.
  const NamePage({
    super.key,
    required this.onSubmit,
    this.reduceAnimations = false,
  });

  /// Appelée avec le prénom capitalisé, une fois le bouton pressé.
  ///
  /// La page ne décide pas de la suite : elle rend la main dès que l'élève a
  /// donné son nom. L'écriture elle-même est faite par l'appelant, via
  /// l'orchestrateur — cet écran ne connaît aucun dépôt.
  final Future<void> Function(String name) onSubmit;

  /// L'élève a demandé la réduction des animations.
  final bool reduceAnimations;

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// Le prénom peut-il être validé ?
  bool _canSubmit = false;

  /// Une écriture est-elle en cours ?
  bool _submitting = false;

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: widget.reduceAnimations
        ? Duration.zero
        : const Duration(milliseconds: OnboardingMetrics.nameShrinkMs),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _exit.dispose();
    super.dispose();
  }

  void _onChanged() {
    final bool can = _controller.text.trim().isNotEmpty;
    if (can != _canSubmit) setState(() => _canSubmit = can);
  }

  void _onFocusChanged() => setState(() {});

  /// Filtre de frappe : caractères autorisés uniquement.
  ///
  /// Appliqué À LA FRAPPE : un caractère refusé ne s'inscrit jamais, donc
  /// l'élève n'a rien à corriger et aucun message n'est nécessaire.
  static final TextInputFormatter _formatter = TextInputFormatter.withFunction(
    (TextEditingValue oldValue, TextEditingValue newValue) {
      final String sanitized = sanitizeName(newValue.text);
      // Troncature à 24 caractères : une borne de saisie, pas une règle.
      final String capped = sanitized.length > OnboardingMetrics.nameMaxLength
          ? sanitized.substring(0, OnboardingMetrics.nameMaxLength)
          : sanitized;
      if (capped == newValue.text) return newValue;
      return newValue.copyWith(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
        // La composition en cours est annulée : elle contenait forcément un
        // caractère refusé.
        composing: TextRange.empty,
      );
    },
  );

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;

    setState(() => _submitting = true);

    // Le nom est capitalisé AVANT l'écriture : l'écran de clôture le relit
    // tel quel, et il doit donc déjà être dans sa forme finale.
    final String name = capitalizeName(_controller.text.trim());

    // Fondu sortant du titre, du champ et du bouton, pendant que le
    // personnage se réduit. Les deux avancent ensemble : l'élève ne voit pas
    // un écran à moitié effacé.
    await _exit.forward();
    if (!mounted) return;

    await widget.onSubmit(name);
  }

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    // L'écran s'abonne à sa sortie. SANS cet abonnement, `build` ne serait
    // rejoué que si un AUTRE élément de l'arbre le demandait : le contrôleur
    // tournerait, mais le rétrécissement du personnage et le fondu du contenu
    // resteraient peints à leur état initial. L'écran resterait figé.
    return AnimatedBuilder(
      animation: _exit,
      builder: (BuildContext context, _) => Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
            // Le personnage se réduit de 140 à 80 à la validation, pour
            // laisser la place à la première question.
            final double from = OnboardingMetrics.characterSize(
              width: constraints.maxWidth,
              large: true,
            );
            final double to = OnboardingMetrics.characterSize(
              width: constraints.maxWidth,
              large: false,
            );
            final double size = Tween<double>(
              begin: from,
              end: to,
            ).evaluate(_exit);

            // Le contenu suit la sortie : il s'efface pendant le rétrécissement.
            //
            // AVEC animations réduites, le contenu est visible d'emblée et le
            // reste : il valait 0, ce qui rendait l'écran INUTILISABLE — pas de
            // titre, pas de champ, pas de bouton — pour tout élève ayant
            // demandé à limiter les animations. Réduire les animations doit
            // retirer le mouvement, jamais l'information.
            final double contentOpacity =
                widget.reduceAnimations ? 1 : (1 - _exit.value);

            // MISE EN PAGE EN COLONNE, et non en `Stack`.
            //
            // Le `Stack` superposait le personnage et le contenu : les deux
            // enfants se partageaient le meme rectangle, et le titre venait
            // CHEVAUCHER le personnage — 50 px de recouvrement mesure a
            // 360 x 640. Aucun test ne l'avait vu : un `Stack` ne leve
            // rien quand deux enfants se marchent dessus, seul un debordement
            // de `Flex` signale.
            //
            // La colonne rend ce defaut IMPOSSIBLE : chaque element recoit la
            // place restante. C'est la meme correction que celle deja appliquee
            // a `closing_page.dart`, qui portait le meme commentaire.
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: RelioSpacing.xxl),
                  child: RelioCharacter(
                    size: size,
                    animate: !widget.reduceAnimations,
                  ),
                ),
                // Le titre et le champ occupent toute la place restante et se
                // centrent dedans : ils s'ecartent du personnage au lieu de
                // le traverser.
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RelioSpacing.horizontal,
                        vertical: RelioSpacing.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Opacity(
                            opacity: contentOpacity,
                            child: Text(
                              RelioStrings.nameTitle,
                              textAlign: TextAlign.center,
                              style: RelioType.title(palette),
                            ),
                          ),
                          const SizedBox(height: RelioSpacing.xxl),
                          Opacity(
                            opacity: contentOpacity,
                            child: _NameField(
                              controller: _controller,
                              focusNode: _focus,
                              formatter: _formatter,
                              enabled: !_submitting,
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
                  child: Opacity(
                    opacity: contentOpacity,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        // Le bouton est absent du geste tant que le champ
                        // est vide : il ne s'agit pas de le « désactiver »,
                        // mais de ne pas proposer une action sans effet.
                        onPressed: _canSubmit && !_submitting ? _submit : null,
                        child: const Text(RelioStrings.nameContinue),
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

/// Champ de saisie du prénom.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.formatter,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputFormatter formatter;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);

    return SizedBox(
      height: OnboardingMetrics.nameFieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        inputFormatters: <TextInputFormatter>[formatter],
        // `capitalizeWords` est un indice de clavier, pas une règle : il ne
        // modifie pas ce qui est tapé, il oriente l'élève vers la bonne
        // touche. La capitalisation réelle est faite par [prepareName].
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        style: RelioType.body(palette),
        decoration: InputDecoration(
          hintText: RelioStrings.namePlaceholder,
          hintStyle: RelioType.body(palette).copyWith(
            color: palette.textSecondary,
          ),
        ),
      ),
    );
  }
}