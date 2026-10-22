/// Fraction empilée : numérateur, barre horizontale, dénominateur.
///
/// NOTATION SCOLAIRE. Un élève de 3e lit `1/2` comme une barre de fraction,
/// pas comme deux nombres séparés par une barre oblique. Ce composant rend la
/// fraction telle qu'elle s'écrit sur un cahier.
///
/// Ce widget ne décide rien : il ne reçoit que deux chaînes déjà validées par
/// le formateur ([formatMathText] dans `math_text.dart`). Il n'interprète pas
/// le texte, il l'empile.
///
/// TAILLE : aucune taille propre. Le style reçu est celui du texte environnant,
/// donc une fraction dans un petit bouton reste petite et une fraction dans un
/// grand énoncé reste grande.
///
/// ALIGNEMENT : le widget est destiné à un [WidgetSpan] aligné sur le milieu
/// de la ligne (`PlaceholderAlignment.middle`). La ligne de base du texte qui
/// l'entoure n'est donc pas déplacée : la fraction pousse la hauteur de ligne,
/// jamais le texte vers le haut ou vers le bas.
library;

import 'package:flutter/material.dart';

/// Fraction empilée, centrée horizontalement.
class FractionSpan extends StatelessWidget {
  /// Crée une fraction.
  const FractionSpan({
    super.key,
    required this.numerator,
    required this.denominator,
    this.style,
  });

  /// Numérateur, écrit au-dessus de la barre.
  final String numerator;

  /// Dénominateur, écrit sous la barre.
  final String denominator;

  /// Style du texte environnant. `null` : hérite du [DefaultTextStyle].
  final TextStyle? style;

  /// Épaisseur de la barre de fraction.
  static const double barThickness = 1.2;

  /// Respiration demandée autour de la barre : 2 dp en haut et en bas.
  static const EdgeInsets barMargin = EdgeInsets.symmetric(vertical: 2);

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ?? DefaultTextStyle.of(context).style;

    // La barre prend la couleur du texte. Si le style n'en porte pas, on
    // retombe sur la couleur ambiante, puis sur l'encre par défaut : la barre
    // ne doit jamais être invisible.
    final Color encre = base.color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF000000);

    // Chiffres tabulaires : deux fractions voisines gardent la même largeur.
    // Hauteur de ligne resserrée : la pile reste compacte dans une phrase.
    final TextStyle chiffres = base.copyWith(
      height: 1.1,
      fontFeatures: <FontFeature>[
        ...?base.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    final Widget visuel = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            numerator,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: chiffres,
          ),
          // La barre occupe toute la largeur de la fraction : celle du plus
          // large des deux nombres, jamais celle de l'un seulement.
          Container(
            height: barThickness,
            margin: barMargin,
            color: encre,
          ),
          Text(
            denominator,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: chiffres,
          ),
        ],
      ),
    );

    // Lecture vocal : « 1 sur 2 ». Les deux nombres ne sont pas lus comme deux
    // nombres indépendants, ce qui changerait le sens de la phrase.
    return Semantics(
      label: '$numerator sur $denominator',
      child: ExcludeSemantics(child: visuel),
    );
  }
}
