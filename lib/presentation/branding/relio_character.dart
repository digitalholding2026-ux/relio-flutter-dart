/// Personnage de l'ecran d'entree — le mark Relio anime.
///
/// Le personnage EST le mark. Meme geometrie, meme couleur, meme source de
/// verite (`relio_mark_geometry.dart`). Aucune forme nouvelle n'est introduite :
/// ni visage, ni membre, ni decoration.
///
/// REGLE DE RETENUE (mission 2, note 10) : un mouvement qui ne peut pas etre
/// decrit en une phrase simple est trop complexe. Ici, il n'y en a que trois :
///   - le chapeau respire ;
///   - les pages pulsent, synchronisees mais independantes ;
///   - le gland ondule comme sous un souffle.
///
/// Le fût, la courbe et le balayage ne bougent pas : trois mouvements de plus
/// et le mark deviendrait un element nerveux, ce que la specification exclut.
///
/// Aucun saut, aucun retournement, aucun changement de couleur, aucun son.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'relio_mark.dart';

/// Timings du personnage.
///
/// Les cycles sont LENTS par construction : une pulsation trop rapide
/// transformerait le mark en element nerveux, ce que la specification exclut.
abstract final class RelioCharacterTiming {
  /// Cycle de la respiration, en secondes.
  static const double breathePeriod = 4.0;

  /// Cycle de l'ondulation du gland, en secondes.
  static const double wavePeriod = 3.0;

  /// Amplitude de l'ondulation, en unites de grille.
  ///
  /// Le gland se deplace de +/- 2 unites sur une hauteur de 100 : 2 % du
  /// mark. C'est un frémissement, pas un deplacement.
  static const double waveAmplitude = 2.0;

  /// Amplitude de la respiration, en fraction de la taille du chapeau.
  ///
  /// 1,5 % : perceptible comme vivant, invisible comme changement de forme.
  static const double breatheAmplitude = 0.015;

  /// Phase de decalage des pages, en fraction de cycle.
  ///
  /// Les pages pulsent « de facon independante mais synchronisee » : meme
  /// cycle, mais decale, pour que le chapeau et les pages ne battent jamais
  /// a l'unisson.
  static const double dotPhaseShift = 0.25;

  /// Inclinaison maximale, en degres.
  ///
  /// La specification autorise 2 a 3 degres ; on retient 2,5.
  static const double leanDegrees = 2.5;
}

/// Etat anime du personnage a un instant donne.
///
/// Les valeurs sont calculees, jamais lues dans un `AnimationController` par
/// ecran : la logique de la sequence ne connait que le temps, et le personnage
/// se deduit de [RelioCharacterState.at].
@immutable
class RelioCharacterState {
  /// Cree un etat.
  const RelioCharacterState({
    required this.glyphBreathe,
    required this.dotPulse,
    required this.accentWave,
    required this.leanDegrees,
  });

  /// Zero au repos : ni gonflement, ni ondulation, ni inclinaison.
  static const RelioCharacterState rest = RelioCharacterState(
    glyphBreathe: 1,
    dotPulse: 1,
    accentWave: 0,
    leanDegrees: 0,
  );

  /// Multiplicateur de taille du chapeau : 1 au repos, legerement au-dessus en
  /// fin d'inspiration. Vaut 1 +/- `breatheAmplitude`.
  ///
  /// La mise a l'echelle se fait sur le centre du chapeau, jamais sur un bord :
  /// une forme qui gonfle depuis sa gauche se deplacerait lateralement.
  final double glyphBreathe;

  /// Multiplicateur de taille des pages.
  ///
  /// Meme cycle que [glyphBreathe], mais DECALE : les deux ne battent donc
  /// jamais a l'unisson. C'est ce qui rend la pulsation lisible sans etre
  /// nerveuse.
  final double dotPulse;

  /// Decalage vertical du gland, en unites de grille.
  ///
  /// Vaut +/- [RelioCharacterTiming.waveAmplitude] autour de zero.
  final double accentWave;

  /// Inclinaison en degres. Positive : le personnage s'incline vers le texte.
  final double leanDegrees;

  /// Calcule l'etat du personnage a l'instant [elapsed].
  ///
  /// [lean] est l'inclinaison demandee par la sequence (0 quand le personnage
  /// doit rester droit) ; elle s'ajoute a l'inclinaison propre issue du
  /// cycle lent, qui reste negligeable.
  static RelioCharacterState at(Duration elapsed, {double lean = 0}) {
    final double breathePhase =
        elapsed.inMicroseconds / (RelioCharacterTiming.breathePeriod * 1e6);
    final double wavePhase =
        elapsed.inMicroseconds / (RelioCharacterTiming.wavePeriod * 1e6);

    // Respiration : sinus plein, donc alternance inspiration / expiration.
    final double glyphBreathe = 1 +
        RelioCharacterTiming.breatheAmplitude * math.sin(2 * math.pi * breathePhase);

    // Le point suit le meme cycle, decale d'un quart de periode : les pages
    // finissent leur pulsation quand le chapeau commence la sienne.
    final double dotPulse = 1 +
        RelioCharacterTiming.breatheAmplitude *
            math.sin(
              2 * math.pi * (breathePhase + RelioCharacterTiming.dotPhaseShift),
            );

    // Ondulation : sinus plein, soit +/- 2 autour du repos.
    final double accentWave =
        RelioCharacterTiming.waveAmplitude * math.sin(2 * math.pi * wavePhase);

    return RelioCharacterState(
      glyphBreathe: glyphBreathe,
      dotPulse: dotPulse,
      accentWave: accentWave,
      leanDegrees: lean,
    );
  }
}

/// Dessine le mark Relio anime.
///
/// Rendu identique au mark statique au repos : c'est verifie par test. Le
/// personnage n'est donc pas une VARIANTE du logo, c'est le logo qui bouge.
class RelioCharacterPainter extends CustomPainter {
  /// Cree le painter du personnage.
  const RelioCharacterPainter({
    required this.state,
    this.variant = RelioMarkVariant.onLight,
  });

  /// Etat anime courant.
  final RelioCharacterState state;

  /// Declinaison chromatique, comme le mark statique.
  final RelioMarkVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    if (side <= 0) return;

    // Le gland ondule : on reserve cette place en permanence, sinon le
    // personnage « sauterait » d'une image a l'autre. La reserve est
    // symetrique, pour que le repos soit centre.
    const double reserve = RelioCharacterTiming.waveAmplitude;
    final double boxHeight = RelioMarkGeometry.inkHeight + 2 * reserve;
    final double factor = side / RelioMarkGeometry.inkWidth;

    canvas.save();
    canvas.translate(
      (size.width - RelioMarkGeometry.inkWidth * factor) / 2,
      (size.height - boxHeight * factor) / 2,
    );
    canvas.scale(factor);
    canvas.translate(-RelioMarkGeometry.boundingBox.left, -RelioMarkGeometry.boundingBox.top);

    // Inclinaison : pivot sur le centre reel du mark, pour que le personnage
    // bascule sur lui-meme et non autour d'un bord.
    canvas.translate(RelioMarkGeometry.inkCenterX, RelioMarkGeometry.inkCenterY);
    canvas.rotate(state.leanDegrees * math.pi / 180);
    canvas.translate(-RelioMarkGeometry.inkCenterX, -RelioMarkGeometry.inkCenterY);

    final ({Color base, Color accent}) c = relioMarkColors(variant);

    void paintPart(RelioMarkPart part, Color color) => canvas.drawPath(
          relioMarkPath(part.nodes),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );

    // Le chapeau respire : echelle depuis son propre centre.
    canvas.save();
    canvas.translate(RelioMarkGeometry.cap.centerX, RelioMarkGeometry.cap.centerY);
    canvas.scale(state.glyphBreathe);
    canvas.translate(-RelioMarkGeometry.cap.centerX, -RelioMarkGeometry.cap.centerY);
    paintPart(RelioMarkGeometry.cap, c.base);
    canvas.restore();

    // Le fût, la courbe et le balayage sont immobiles : c'est eux qui donnent
    // son assiette au mark pendant que le chapeau bouge.
    paintPart(RelioMarkGeometry.stem, c.base);
    paintPart(RelioMarkGeometry.body, c.base);
    paintPart(RelioMarkGeometry.base, c.base);

    // Les pages pulsent, depuis leur propre centre.
    for (final RelioMarkPart part in <RelioMarkPart>[
      RelioMarkGeometry.pageUpper,
      RelioMarkGeometry.pageLower,
    ]) {
      canvas.save();
      canvas.translate(part.centerX, part.centerY);
      canvas.scale(state.dotPulse);
      canvas.translate(-part.centerX, -part.centerY);
      paintPart(part, c.accent);
      canvas.restore();
    }

    // Le gland ondule : un simple soulevement vertical.
    canvas.save();
    canvas.translate(0.0, state.accentWave);
    paintPart(RelioMarkGeometry.tassel, c.accent);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(RelioCharacterPainter old) =>
      old.state != state || old.variant != variant;
}

/// Le personnage Relio, anime en continu.
///
/// Expose l'etat courant pour que la sequence puisse l'incliner ; un widget
/// d'ecran ne pilote donc JAMAIS directement le painter.
class RelioCharacter extends StatefulWidget {
  /// Cree le personnage.
  const RelioCharacter({
    super.key,
    required this.size,
    this.animate = true,
    this.lean = 0,
    this.variant = RelioMarkVariant.onLight,
  });

  /// Cote du personnage, en pixels logiques.
  final double size;

  /// Si faux, le personnage reste immobile au repos.
  ///
  /// Sert au fallback : si l'animation est impossible, le mark statique
  /// s'affiche quand meme.
  final bool animate;

  /// Inclinaison demandee par la sequence, en degres.
  final double lean;

  /// Declinaison chromatique.
  final RelioMarkVariant variant;

  @override
  State<RelioCharacter> createState() => _RelioCharacterState();
}

class _RelioCharacterState extends State<RelioCharacter>
    with SingleTickerProviderStateMixin {
  /// Portee du controller, en microsecondes.
  ///
  /// Le personnage respire et ondule sans fin. Une minute de portee suffit
  /// largement : au-dela, le raccord serait imperceptible, l'amplitude de
  /// l'onde etant de l'ordre du centieme d'unite.
  static const int _kTimelineUs = 60 * 1000 * 1000;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(microseconds: _kTimelineUs),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(RelioCharacter old) {
    super.didUpdateWidget(old);
    if (widget.animate == old.animate) return;
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: RelioCharacterPainter(
            state: RelioCharacterState(
              glyphBreathe: 1,
              dotPulse: 1,
              accentWave: 0,
              leanDegrees: widget.lean,
            ),
            variant: widget.variant,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = RelioCharacterState.at(
          Duration(microseconds: (_controller.value * _kTimelineUs).round()),
          lean: widget.lean,
        );
        return SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: RelioCharacterPainter(state: state, variant: widget.variant),
          ),
        );
      },
    );
  }
}