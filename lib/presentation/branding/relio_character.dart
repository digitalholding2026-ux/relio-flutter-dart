/// Personnage de l'ecran d'entree — le mark Relio anime.
///
/// Le personnage EST le mark. Meme geometrie, meme couleur, meme source de
/// verite (`relio_mark_geometry.dart`). Aucune forme nouvelle n'est introduite :
/// ni visage, ni membre, ni decoration.
///
/// REGLE DE RETENUE (mission 2, note 10) : un mouvement qui ne peut pas etre
/// decrit en une phrase simple est trop complexe. Ici, il n'y en a que trois :
///   - le grand point respire ;
///   - le petit point pulse, synchronise mais independant ;
///   - la courbe ondule comme sous un souffle.
///
/// Aucun saut, aucun retournement, aucun changement de couleur, aucun son.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'relio_mark_geometry.dart';

/// Timings du personnage.
///
/// Les cycles sont LENTS par construction : une pulsation trop rapide
/// transformerait le mark en element nerveux, ce que la specification exclut.
abstract final class RelioCharacterTiming {
  /// Cycle de la respiration, en secondes.
  static const double breathePeriod = 4.0;

  /// Cycle de l'ondulation de la courbe, en secondes.
  static const double wavePeriod = 3.0;

  /// Amplitude de l'ondulation, en unites de grille.
  ///
  /// La profondeur oscille entre 4 et 8 unites de profondeur, soit y = 54 a
  /// y = 58 : le point de repos (y = 56) est respecte.
  static const double waveAmplitude = 2.0;

  /// Amplitude de la respiration, en fraction du rayon.
  ///
  /// 1,5 % : perceptible comme vivant, invisible comme changement de forme.
  static const double breatheAmplitude = 0.015;

  /// Phase de decalage du petit point, en fraction de cycle.
  ///
  /// Le petit point pulse « de facon independante mais synchronisee » : meme
  /// cycle, mais decale, pour que les deux points ne battent jamais a
  /// l'unisson.
  static const double smallDotPhaseShift = 0.25;

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
    required this.breathe,
    required this.breatheSmall,
    required this.wave,
    required this.leanDegrees,
  });

  /// Zero au repos : ni gonflement, ni ondulation, ni inclinaison.
  static const RelioCharacterState rest = RelioCharacterState(
    breathe: 1,
    breatheSmall: 1,
    wave: RelioMarkGeometry.curveDepth,
    leanDegrees: 0,
  );

  /// Multiplicateur de rayon du GRAND cercle : 1 au repos, legerement au-dessus
  /// en fin d'inspiration. Vaut 1 +/- `breatheAmplitude`.
  final double breathe;

  /// Multiplicateur de rayon du PETIT cercle.
  ///
  /// Meme cycle que [breathe], mais DECALE : les deux points ne battent donc
  /// jamais a l'unisson. C'est ce qui rend la pulsation lisible sans etre
  /// nerveuse.
  final double breatheSmall;

  /// Profondeur de la courbe en unites de grille, MESUREE depuis la ligne des
  /// centres. Vaut `curveDepth` au repos, +/- `waveAmplitude`.
  final double wave;

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
    final double breathe = 1 +
        RelioCharacterTiming.breatheAmplitude * math.sin(2 * math.pi * breathePhase);

    // Le petit point suit le meme cycle, decale d'un quart de periode : il
    // finit sa respiration quand le grand commence.
    final double breatheSmall = 1 +
        RelioCharacterTiming.breatheAmplitude *
            math.sin(
              2 * math.pi * (breathePhase + RelioCharacterTiming.smallDotPhaseShift),
            );

    // Ondulation : sinus plein, soit +/- 2 autour du repos.
    final double wave = RelioMarkGeometry.curveDepth +
        RelioCharacterTiming.waveAmplitude * math.sin(2 * math.pi * wavePhase);

    return RelioCharacterState(
      breathe: breathe,
      breatheSmall: breatheSmall,
      wave: wave,
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
    this.color = const Color(0xFFF56207),
    this.stroke = RelioMarkGeometry.strokePrimary,
  });

  /// Etat anime courant.
  final RelioCharacterState state;

  /// Couleur unique du personnage.
  final Color color;

  /// Epaisseur du trait, en unites de grille.
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    if (side <= 0) return;

    // Au repos, la boite englobante est celle du mark statique. L'ondulation
    // descend de 2 unites au maximum : on reserve cette place en permanence,
    // sinon le personnage « sauterait » d'une image a l'autre.
    const double reserveWave = RelioCharacterTiming.waveAmplitude;
    final double boxHeight =
        RelioMarkGeometry.boundingHeight(stroke) + reserveWave;
    final double boxWidth = RelioMarkGeometry.boundingWidth(stroke);
    final double factor = side / boxWidth;

    canvas.save();
    canvas.translate((size.width - boxWidth * factor) / 2, (size.height - boxHeight * factor) / 2);
    canvas.scale(factor);

    final box = RelioMarkGeometry.boundingBox(stroke);

    // Inclinaison : pivot sur le milieu de la ligne des centres, pour que le
    // personnage bascule sur lui-meme et non autour d'un bord.
    canvas.translate(
      (box.left + box.right) / 2,
      RelioMarkGeometry.centerLineY,
    );
    canvas.rotate(state.leanDegrees * math.pi / 180);
    canvas.translate(
      -(box.left + box.right) / 2,
      -RelioMarkGeometry.centerLineY,
    );

    // Recalage vertical : la boite reservee au repos laisse le bas libre, on
    // centre donc sur la boite REELLE du mark et on translate de la reserve.
    canvas.translate(-box.left, -(box.top + reserveWave / 2));

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Les deux cercles respirent. Le petit point a sa propre phase : meme
    // cycle, decale.
    canvas.drawCircle(
      Offset(
        RelioMarkGeometry.centerRightX,
        RelioMarkGeometry.centerRightY,
      ),
      RelioMarkGeometry.radiusRight * state.breathe,
      fill,
    );

    canvas.drawCircle(
      Offset(
        RelioMarkGeometry.centerLeftX,
        RelioMarkGeometry.centerLeftY,
      ),
      RelioMarkGeometry.radiusLeft * state.breatheSmall,
      fill,
    );

    // La courbe ondule : sa profondeur est mesuree depuis la ligne des
    // centres, et son amplitude vaut +/- `waveAmplitude` autour du repos.
    final double depth = state.wave;
    // Pour une cubique dont le point bas vaut `depth`, le decalage vertical
    // des points de controle vaut (depth / 0.75). C'est la meme relation que
    // pour le mark statique — la courbe reste la meme courbe, elle respire.
    final double controlOffset = depth / 0.75;

    final Path curve = Path()
      ..moveTo(RelioMarkGeometry.curveStartX, RelioMarkGeometry.centerLineY)
      ..cubicTo(
        RelioMarkGeometry.curveControl1X,
        RelioMarkGeometry.centerLineY + controlOffset,
        RelioMarkGeometry.curveControl2X,
        RelioMarkGeometry.centerLineY + controlOffset,
        RelioMarkGeometry.curveEndX,
        RelioMarkGeometry.centerLineY,
      );

    canvas.drawPath(
      curve,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(RelioCharacterPainter old) =>
      old.state != state ||
      old.color != color ||
      old.stroke != stroke;
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
    this.color = const Color(0xFFF56207),
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

  /// Couleur unique du personnage.
  final Color color;

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
              breathe: 1,
              breatheSmall: 1,
              wave: RelioMarkGeometry.curveDepth,
              leanDegrees: widget.lean,
            ),
            color: widget.color,
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
            painter: RelioCharacterPainter(state: state, color: widget.color),
          ),
        );
      },
    );
  }
}
