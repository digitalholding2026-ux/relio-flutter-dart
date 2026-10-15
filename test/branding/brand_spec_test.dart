/// La geometrie du mark vient-elle encore de la specification livree ?
///
/// La regle 9 interdit qu'un SVG, un PNG ou un widget de marque s'edite a la
/// main. Cette regle ne se verifie pas a la lecture du code : elle se verifie
/// en REJOUANT l'import.
///
/// Ce test relit `docs/brand/relio_app_icon.svg` — la specification validee —
/// applique exactement la meme normalisation que celle utilisee lors de
/// l'import initial, puis compare le resultat aux constantes de
/// `RelioMarkGeometry`.
///
/// Si quelquun ajuste une coordonnee a la main dans la geometrie, ce test
/// echoue. C'est le garde-fou qui rend la regle 9 opposable et non
/// declarative.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_mark_geometry.dart';

/// Grille de reference : doit rester celle de la geometrie.
const double kGrid = 100;

/// Precision de comparaison.
///
/// La normalisation arrondit a trois decimales : c'est deja dix fois plus fin
/// que le pixel au plus grand rendu.
const double kTolerance = 0.002;

/// Un point de la specification d'origine.
class _Pt {
  const _Pt(this.x, this.y);
  final double x;
  final double y;
}

/// Les traces de la specification, traduites dans la grille de reference.
class _Imported {
  const _Imported({
    required this.chemins,
    required this.cercle,
    required this.echelle,
  });

  /// Les `d` normalises, dans l'ordre du fichier.
  final List<String> chemins;

  /// Centre et rayon normalises du point.
  final ({double cx, double cy, double r}) cercle;

  /// Facteur applique par la normalisation.
  final double echelle;
}

/// Lit `d`, le reecrit avec les memes commandes absolues que la geometrie, et
/// renvoie tous ses points — points de controle compris.
({String d, List<_Pt> points}) _analyser(String d) {
  final re = RegExp(r'([MLQCHVZ])([^MLQCHVZ]*)');
  final List<_Pt> points = <_Pt>[];
  final StringBuffer out = StringBuffer();
  double cx = 0, cy = 0;

  for (final Match m in re.allMatches(d)) {
    final List<double> nums = m
        .group(2)!
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .map(double.parse)
        .toList();

    void point(double x, double y) {
      points.add(_Pt(x, y));
      cx = x;
      cy = y;
    }

    switch (m.group(1)) {
      case 'M':
      case 'L':
        for (int i = 0; i + 1 < nums.length; i += 2) {
          point(nums[i], nums[i + 1]);
          out.write('${m.group(1)}${nums[i]} ${nums[i + 1]}');
        }
      case 'V':
        for (final double y in nums) {
          point(cx, y);
          out.write('L$cx $y');
        }
      case 'H':
        for (final double x in nums) {
          point(x, cy);
          out.write('L$x $cy');
        }
      case 'Q':
        for (int i = 0; i + 3 < nums.length; i += 4) {
          points.add(_Pt(nums[i], nums[i + 1]));
          out.write('Q${nums[i]} ${nums[i + 1]} ${nums[i + 2]} ${nums[i + 3]}');
          point(nums[i + 2], nums[i + 3]);
        }
      case 'Z':
        out.write('Z');
      default:
        fail('Commande SVG non prevue : ${m.group(1)}');
    }
  }
  return (d: out.toString(), points: points);
}

/// Rejoue la normalisation : le mark est centre dans la grille, et cale sur sa
/// plus grande dimension.
_Imported _importer(String svg) {
  // Le fond de l'icone est un `rect` : il ne fait pas partie du mark.
  final List<String> ds = RegExp(r'<path d="([^"]+)"')
      .allMatches(svg)
      .map((Match m) => m.group(1)!)
      .toList();
  final Match cercle = RegExp(
          r'<circle cx="([\d.]+)" cy="([\d.]+)" r="([\d.]+)"')
      .firstMatch(svg)!;

  double l = double.infinity, t = double.infinity;
  double r = double.negativeInfinity, b = double.negativeInfinity;

  final List<({String d, List<_Pt> points})> traces =
      ds.map(_analyser).toList();

  for (final trace in traces) {
    for (final _Pt p in trace.points) {
      l = p.x < l ? p.x : l;
      t = p.y < t ? p.y : t;
      r = p.x > r ? p.x : r;
      b = p.y > b ? p.y : b;
    }
  }

  final double dcx = double.parse(cercle.group(1)!);
  final double dcy = double.parse(cercle.group(2)!);
  final double dr = double.parse(cercle.group(3)!);
  l = dcx - dr < l ? dcx - dr : l;
  t = dcy - dr < t ? dcy - dr : t;
  r = dcx + dr > r ? dcx + dr : r;
  b = dcy + dr > b ? dcy + dr : b;

  final double w = r - l;
  final double h = b - t;
  final double s = kGrid / (w > h ? w : h);
  final double ox = (kGrid - w * s) / 2;
  final double oy = (kGrid - h * s) / 2;

  double fx(double v) => (v * 1000).roundToDouble() / 1000;
  String nx(double v) {
    final double q = fx(v);
    return q == q.roundToDouble() ? q.toStringAsFixed(1) : q.toString();
  }

  final List<String> normalises = traces.map((trace) {
    // On reapplique la meme transformation qu'a l'import, en relisant le `d`
    // normalise que [_analyser] a reconstruit.
    final List<_Pt> depart = trace.points;
    final StringBuffer out = StringBuffer();
    // Les positions du `d` reconstruit correspondent, dans l'ordre, aux points
    // de [depart] : les points de controle de Q sont presents deux fois, ce
    // qui reproduit exactement l'ordre de lecture de l'import d'origine.
    final List<double> valeurs = <double>[];
    for (final _Pt p in depart) {
      valeurs
        ..add(fx(ox + (p.x - l) * s))
        ..add(fx(oy + (p.y - t) * s));
    }

    // On rejoue la commande par commande sur la trace d'origine.
    final re = RegExp(r'([MLQZ])([^MLQZ]*)');
    int i = 0;
    for (final Match m in re.allMatches(trace.d)) {
      final String cmd = m.group(1)!;
      final int nombres = m.group(2)!.trim().split(RegExp(r'\s+')).length;
      if (cmd == 'Z') {
        out.write('Z');
        continue;
      }
      // `M` et `L` prennent un point, `Q` en prend deux : on restitue la
      // commande telle qu'elle apparait dans le fichier d'origine.
      final int paires = nombres ~/ 2;
      if (cmd == 'Q') {
        final List<String> pairesQ = <String>[];
        for (int k = 0; k < paires; k++) {
          pairesQ
              .add('${nx(valeurs[i++])} ${nx(valeurs[i++])}');
        }
        out.write('Q${pairesQ.join(' ')}');
        continue;
      }
      for (int k = 0; k < paires; k++) {
        out.write('$cmd${nx(valeurs[i++])} ${nx(valeurs[i++])}');
      }
    }
    return out.toString();
  }).toList();

  return _Imported(
    chemins: normalises,
    cercle: (
      cx: fx(ox + (dcx - l) * s),
      cy: fx(oy + (dcy - t) * s),
      r: fx(dr * s),
    ),
    echelle: s,
  );
}

void main() {
  final File spec = File('docs/brand/relio_app_icon.svg');

  group('Specification source', () {
    test('elle est presente dans le depot', () {
      expect(spec.existsSync(), isTrue,
          reason: 'la specification de marque doit etre versionnee');
    });

    test('elle contient bien le « R », les deux zigzags et le point', () {
      final String svg = spec.readAsStringSync();
      expect('M'.allMatches(svg), isNotEmpty);
      expect('Q'.allMatches(svg), isNotEmpty);
      expect(RegExp(r'<circle').hasMatch(svg), isTrue);
    });
  });

  group('La geometrie n\'a pas derive de la specification', () {
    late _Imported import;

    setUpAll(() => import = _importer(spec.readAsStringSync()));

    test('le mark tient dans la grille de reference', () {
      expect(kGrid, RelioMarkGeometry.grid);
      expect(RelioMarkGeometry.inkHeight, closeTo(kGrid, kTolerance));
      expect(RelioMarkGeometry.inkWidth, lessThanOrEqualTo(kGrid));
    });

    test('le nombre de traces n\'a pas change', () {
      expect(import.chemins, hasLength(RelioMarkGeometry.parts.length));
    });

    test('chaque trace correspond, coordonnee par coordonnee', () {
      for (int i = 0; i < RelioMarkGeometry.parts.length; i++) {
        final RelioMarkPart part = RelioMarkGeometry.parts[i];
        expect(
          _dNormalise(part.nodes),
          import.chemins[i],
          reason: 'la trace « ${part.id} » a ete modifiee a la main',
        );
      }
    });

    test('le point est a sa place et de son rayon', () {
      expect(RelioMarkGeometry.dot.centerX,
          closeTo(import.cercle.cx, kTolerance));
      expect(RelioMarkGeometry.dot.centerY,
          closeTo(import.cercle.cy, kTolerance));
      expect(RelioMarkGeometry.dot.radius,
          closeTo(import.cercle.r, kTolerance));
    });

    test('la boite englobante decoule de la specification', () {
      expect(RelioMarkGeometry.boundingBox.left,
          closeTo(4.403, kTolerance));
      expect(RelioMarkGeometry.boundingBox.right,
          closeTo(95.597, kTolerance));
      expect(RelioMarkGeometry.boundingBox.top, closeTo(0, kTolerance));
      expect(RelioMarkGeometry.boundingBox.bottom, closeTo(100, kTolerance));
    });

    test('les boites des parties correspondent aux traces', () {
      // Le « R » est la partie la plus haute et la plus basse.
      expect(RelioMarkGeometry.glyph.box.top, closeTo(0, kTolerance));
      expect(RelioMarkGeometry.glyph.box.bottom,
          closeTo(96.541, kTolerance));
      expect(RelioMarkGeometry.glyph.box.left, closeTo(9.748, kTolerance));
      expect(RelioMarkGeometry.glyph.box.right, closeTo(83.019, kTolerance));

      // L'accent descend jusqu'au bas de la grille.
      expect(RelioMarkGeometry.zigzagAccent.box.bottom,
          closeTo(100, kTolerance));
      expect(RelioMarkGeometry.zigzagSecondary.box.right,
          closeTo(95.597, kTolerance));
    });
  });
}

/// Reproduit le `d` normalise de la geometrie, avec le meme arrondi que le
/// generateur.
String _dNormalise(List<RelioMarkNode> nodes) {
  String n(double v) {
    final double q = (v * 1000).roundToDouble() / 1000;
    return q == q.roundToDouble() ? q.toStringAsFixed(1) : q.toString();
  }

  final StringBuffer out = StringBuffer();
  for (final RelioMarkNode node in nodes) {
    switch (node) {
      case RelioMarkMoveTo(:final double x, :final double y):
        out.write('M${n(x)} ${n(y)}');
      case RelioMarkLineTo(:final double x, :final double y):
        out.write('L${n(x)} ${n(y)}');
      case RelioMarkQuadTo(
          :final double cx,
          :final double cy,
          :final double x,
          :final double y,
        ):
        out.write('Q${n(cx)} ${n(cy)} ${n(x)} ${n(y)}');
      case RelioMarkClose():
        out.write('Z');
    }
  }
  return out.toString();
}