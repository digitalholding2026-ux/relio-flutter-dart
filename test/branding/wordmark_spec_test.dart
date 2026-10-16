/// La geometrie du wordmark vient-elle encore de la specification livree ?
///
/// Meme mecanisme que `brand_spec_test.dart` pour le mark : ce test relit
/// `docs/brand/relio_logo_principal.svg` — specification validee, produite
/// par l'import mecanique `tool/brand_wordmark.py` — rejoue la normalisation
/// et compare aux constantes de `RelioWordmarkGeometry`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relio/presentation/branding/relio_lockup.dart';
import 'package:relio/presentation/branding/relio_mark.dart';

/// Grille de reference : doit rester celle de la geometrie.
const double kGrid = 100;

/// Precision de comparaison.
const double kTolerance = 0.002;

/// Un point de la specification d'origine.
class _Pt {
  const _Pt(this.x, this.y);
  final double x;
  final double y;
}

/// Lit `d`, le reecrit avec les memes commandes absolues que la geometrie, et
/// renvoie tous ses points — points de controle compris.
({String d, List<_Pt> points}) _analyser(String d) {
  final re = RegExp(r'([MLQZ])([^MLQZ]*)');
  final List<_Pt> points = <_Pt>[];
  final StringBuffer out = StringBuffer();

  void point(double x, double y) {
    points.add(_Pt(x, y));
  }

  for (final Match m in re.allMatches(d)) {
    final List<double> nums = m
        .group(2)!
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .map(double.parse)
        .toList();

    switch (m.group(1)) {
      case 'M':
      case 'L':
        for (int i = 0; i + 1 < nums.length; i += 2) {
          point(nums[i], nums[i + 1]);
          out.write('${m.group(1)}${nums[i]} ${nums[i + 1]}');
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

/// Rejoue la normalisation : le mot est centre dans la grille, et cale sur sa
/// plus grande dimension.
List<String> _importer(String svg) {
  final List<String> ds = RegExp(r'<path [^>]*d="([^"]+)"')
      .allMatches(svg)
      .map((Match m) => m.group(1)!)
      .toList();

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

  return traces.map((trace) {
    final List<_Pt> depart = trace.points;
    final StringBuffer out = StringBuffer();
    final List<double> valeurs = <double>[];
    for (final _Pt p in depart) {
      valeurs
        ..add(fx(ox + (p.x - l) * s))
        ..add(fx(oy + (p.y - t) * s));
    }

    final re = RegExp(r'([MLQZ])([^MLQZ]*)');
    int i = 0;
    for (final Match m in re.allMatches(trace.d)) {
      final String cmd = m.group(1)!;
      final int nombres = m.group(2)!.trim().split(RegExp(r'\s+')).length;
      if (cmd == 'Z') {
        out.write('Z');
        continue;
      }
      final int paires = nombres ~/ 2;
      if (cmd == 'Q') {
        final List<String> pairesQ = <String>[];
        for (int k = 0; k < paires; k++) {
          pairesQ.add('${nx(valeurs[i++])} ${nx(valeurs[i++])}');
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
}

/// Identifiants des six lettres, dans l'ordre de lecture.
const List<String> kLettres = <String>[
  'word-r',
  'word-e',
  'word-l',
  'word-i',
  'word-o',
  'word-odot',
];

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

void main() {
  final File spec = File('docs/brand/relio_logo_principal.svg');

  group('Specification source du mot', () {
    test('elle est presente dans le depot', () {
      expect(spec.existsSync(), isTrue,
          reason: 'la specification du mot doit etre versionnee');
    });

    test('elle contient les six lettres tracees', () {
      final String svg = spec.readAsStringSync();
      for (final String id in kLettres) {
        expect(svg, contains('id="$id"'),
            reason: 'lettre $id absente de la specification');
      }
    });
  });

  group('La geometrie du mot n\'a pas derive', () {
    late List<String> import;

    setUpAll(() => import = _importer(spec.readAsStringSync()));

    test('le mot tient dans la grille de reference', () {
      expect(kGrid, RelioWordmarkGeometry.grid);
      expect(RelioWordmarkGeometry.inkWidth, closeTo(kGrid, kTolerance));
      expect(RelioWordmarkGeometry.inkHeight, lessThanOrEqualTo(kGrid));
    });

    test('le nombre de lettres n\'a pas change', () {
      expect(import, hasLength(RelioWordmarkGeometry.parts.length));
      expect(
        RelioWordmarkGeometry.parts.map((RelioMarkPart p) => p.id).toList(),
        kLettres,
      );
    });

    test('chaque lettre correspond, coordonnee par coordonnee', () {
      for (int i = 0; i < RelioWordmarkGeometry.parts.length; i++) {
        final RelioMarkPart part = RelioWordmarkGeometry.parts[i];
        expect(
          _dNormalise(part.nodes),
          import[i],
          reason: 'la lettre « ${part.id} » a ete modifiee a la main',
        );
      }
    });

    test('le mot commence par le r et finit par le repere', () {
      expect(RelioWordmarkGeometry.wordBox.left, closeTo(0, kTolerance));
      expect(RelioWordmarkGeometry.wordBox.right, closeTo(100, kTolerance));
      expect(RelioWordmarkGeometry.wordO.box.right,
          closeTo(RelioWordmarkGeometry.wordBox.right, kTolerance));
    });

    test('le rapport mark / mot est celui du logo livre', () {
      expect(kMarkToWordmarkRatio, closeTo(1.637, 0.002));
    });
  });
}
