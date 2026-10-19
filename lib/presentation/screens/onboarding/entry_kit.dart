/// Parcours d'entrée — kit de composition partagé.
///
/// Refonte UX/UI : les six écrans du parcours partagent la même grille, le
/// même bouton et les mêmes transitions. Ce fichier regroupe ce qui est
/// COMMUN, pour qu'un ajustement ne se fasse pas à six endroits.
///
/// Grille (dp) :
///  - horizontal 24, bas 24 (+ safe area) ;
///  - haut → logo 32, logo → titre 32 ;
///  - titre → sous-titre 12, sous-titre → corps 12, corps → champ 32 ;
///  - bouton ancré en bas, jamais dans un `spaceBetween`.
///
/// Niveaux de présence de la marque (taille du mark) :
///  - signature pleine : ouverture 160, clôture 120 ;
///  - présence discrète : bienvenue 100, explication 80, prénom 64 ;
///  - en retrait : test 24, coin supérieur gauche.
library;

import 'package:flutter/material.dart';

import '../../branding/relio_mark.dart';
import '../../theme/relio_theme.dart';
import 'onboarding_metrics.dart';

/// Fond commun des six écrans du parcours.
abstract final class EntryColors {
  static const Color background = Color(0xFFEEF2FA);
}

/// Grille verticale commune, en dp.
abstract final class EntryGaps {
  /// Marge horizontale des écrans du parcours.
  static const double horizontal = 24;

  /// Marge basse, ajoutée à la safe area.
  static const double bottom = 24;

  /// Bord supérieur → logo.
  static const double topToLogo = 32;

  /// Logo → titre.
  static const double logoToTitle = 32;

  /// Titre → sous-titre, et sous-titre → corps.
  static const double textGap = 12;

  /// Question de bienvenue sous le sous-titre, et phrase de fin de
  /// l'explication sous le paragraphe.
  static const double beforeFinal = 24;

  /// Corps → champ de saisie.
  static const double bodyToField = 32;

  /// Carte de question sous l'indicateur de progression.
  static const double aboveCard = 24;
}

/// Taille du mark par écran, en dp.
abstract final class EntryBrand {
  static const double opening = 160;
  static const double welcome = 100;
  static const double intro = 80;
  static const double name = 64;
  static const double test = 24;
  static const double closing = 120;
}

/// Cinq points de progression du test d'entrée.
///
/// Ils REMPLACENT « N sur 5 » comme indicateur principal : le texte reste,
/// en dessous, en Caption. Sur l'écran d'explication, ils sont tous vides :
/// ils promettent une durée courte, ils ne mesurent rien.
class EntryDots extends StatelessWidget {
  /// Crée les points de progression.
  const EntryDots({super.key, this.filled = 0});

  /// Nombre de points remplis : réponses déjà enregistrées.
  final int filled;

  @override
  Widget build(BuildContext context) {
    final palette = RelioPaletteScope.of(context);
    return Semantics(
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < OnboardingMetrics.introChipCount; i++) ...<Widget>[
            if (i > 0)
              const SizedBox(width: OnboardingMetrics.introChipGap),
            Container(
              width: OnboardingMetrics.introChipSize,
              height: OnboardingMetrics.introChipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? palette.primary : Colors.transparent,
                border: i < filled
                    ? null
                    : Border.all(
                        color: palette.primary,
                        width: RelioSizes.fieldBorderWidth,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton principal du parcours : navy solide, sans contour, pleine largeur.
///
/// États :
///  - normal : fond navy, texte blanc, ombre légère ;
///  - pressé : fond navy d'appui, échelle 0,98 ;
///  - désactivé : fond navy à 40 %, texte blanc à 60 % ;
///  - chargement : fond navy, indicateur blanc à la place du texte.
///
/// Hauteur 52 dp, rayon 12, texte Body 16 / SemiBold.
///
/// C'est un [FilledButton] : les tests et l'accessibilité le voient comme
/// le bouton principal, avec son libellé hors chargement.
class EntryButton extends StatelessWidget {
  /// Crée le bouton du parcours.
  const EntryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  /// Libellé affiché hors chargement.
  final String label;

  /// Action, ou `null` pour l'état désactivé.
  final VoidCallback? onPressed;

  /// Écriture en cours : indicateur blanc, action neutralisée.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    return _PressScale(
      enabled: enabled,
      child: FilledButton(
        style: _style(RelioPaletteScope.of(context)),
        onPressed: enabled ? onPressed : null,
        child: loading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }

  static ButtonStyle _style(RelioPalette palette) {
    final ButtonStyle base = FilledButton.styleFrom(
      minimumSize:
          const Size.fromHeight(RelioSizes.primaryButtonHeight),
      textStyle: const TextStyle(
        fontFamily: RelioTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: Colors.white,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: RelioRadius.cardAll,
      ),
      elevation: 2,
      shadowColor: const Color(0x26000000),
    );
    return base.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.primary.withValues(alpha: 0.4);
        }
        if (states.contains(WidgetState.pressed)) {
          return palette.primaryPressed;
        }
        return palette.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white.withValues(alpha: 0.6);
        }
        return Colors.white;
      }),
      // Jamais de contour, dans aucun état.
      side: WidgetStateProperty.all(BorderSide.none),
    );
  }
}

/// Échelle 0,98 à l'appui, sans voler le geste au bouton.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.enabled && !_pressed) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// Fondu croisé entre les écrans du parcours, 250–300 ms.
///
/// Aucun glissement, aucune mise à l'échelle d'écran : seul un fondu.
/// Interruptible par construction — un nouvel enfant relance le fondu — et
/// le logo ne « vole » jamais : chaque écran pose le sien, sans animation
/// partagée.
class EntryTransition extends StatelessWidget {
  /// Crée la transition du parcours.
  const EntryTransition({super.key, required this.child});

  /// Écran courant, avec une clé qui change à chaque étape.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: OnboardingMetrics.entryTransitionMs,
      ),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }
}

/// Marge du bouton ancré en bas : 24 dp horizontaux, 24 dp bas.
class EntryAction extends StatelessWidget {
  /// Crée la marge du bouton du parcours.
  const EntryAction({super.key, required this.child});

  /// Le bouton, déjà en pleine largeur.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EntryGaps.horizontal,
        EntryGaps.textGap,
        EntryGaps.horizontal,
        EntryGaps.bottom,
      ),
      child: child,
    );
  }
}

/// Le mark seul, à la taille du niveau de présence de l'écran.
class EntryMark extends StatelessWidget {
  /// Crée le mark du parcours.
  const EntryMark({super.key, required this.size});

  /// Côté du mark, en dp.
  final double size;

  @override
  Widget build(BuildContext context) {
    return RelioMark(size: size);
  }
}
