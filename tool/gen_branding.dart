/// Generateur des SVG de marque Relio.
///
/// Le SVG est GENERE, jamais ecrit a la main : toutes les valeurs viennent de
/// `RelioMarkGeometry`, source de verite unique. Apres toute modification de la
/// geometrie :
///
/// ```
/// dart run tool/gen_branding.dart
/// ```
///
/// Les SVG servent a l'impression, au web et a toute sortie hors Flutter. Le
/// rendu a l'ecran passe par `RelioMarkPainter`. Le test
/// `test/branding/mark_geometry_test.dart` compare les deux et interdit qu'ils
/// divergent.
library;

import 'dart:io';

import 'package:relio/presentation/branding/relio_mark_geometry.dart';

/// Nombre de decimales conserve dans les SVG.
///
/// Les valeurs de la specification sont donnees a une ou deux decimales ;
/// arrondir a 3 evite d'ecrire `31.700000000000003`, tout en gardant une
/// precision tres superieure au pixel au plus grand rendu.
String n(double v) {
  final double r = (v * 1000).roundToDouble() / 1000;
  return r == r.roundToDouble() ? r.toStringAsFixed(1) : r.toString();
}

/// Les deux points de controle de la cubique, formates pour le `C` d'un SVG.
String controlPoints() =>
    '${n(RelioMarkGeometry.curveControl1X)},${n(RelioMarkGeometry.curveControlY)} '
    '${n(RelioMarkGeometry.curveControl2X)},${n(RelioMarkGeometry.curveControlY)}';

/// Le groupement SVG du mark, seul, aux coordonnees de la grille.
///
/// [color] est ecrit en hexadecimal exact, jamais par un nom : la
/// specification l'exige.
String markBody(String color, double stroke) => '''
    <circle cx="${n(RelioMarkGeometry.centerRightX)}" cy="${n(RelioMarkGeometry.centerRightY)}" r="${n(RelioMarkGeometry.radiusRight)}" fill="$color"/>
    <circle cx="${n(RelioMarkGeometry.centerLeftX)}" cy="${n(RelioMarkGeometry.centerLeftY)}" r="${n(RelioMarkGeometry.radiusLeft)}" fill="$color"/>
    <path d="M ${n(RelioMarkGeometry.curveStartX)},${n(RelioMarkGeometry.centerLineY)} C ${controlPoints()} ${n(RelioMarkGeometry.curveEndX)},${n(RelioMarkGeometry.centerLineY)}" stroke="$color" stroke-width="${n(stroke)}" stroke-linecap="round"/>''';

/// Le mark seul, en SVG.
///
/// Le `viewBox` est la boite englobante reelle, trait compris : le fichier est
/// donc rogne au plus juste, sans transparence peripherique inutile.
String markSvg({
  required String color,
  double stroke = RelioMarkGeometry.strokePrimary,
  String title = 'Relio',
  String variant = 'principale',
}) {
  final box = RelioMarkGeometry.boundingBox(stroke);
  final double w = box.right - box.left;
  final double h = box.bottom - box.top;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(w)} ${n(h)}" width="${n(w)}" height="${n(h)}" role="img" aria-label="$title">
  <title>$title</title>
  <desc>Mark Relio, variante $variant. Grille de reference 100 x 100 ; boite englobante ${n(w)} x ${n(h)} unites, trait de ${n(stroke)} unites compris.</desc>
  <g fill="none" fill-rule="evenodd">${markBody(color, stroke)}
  </g>
</svg>
''';
}

/// Lockup horizontal : mark a gauche, wordmark a droite.
///
/// Le geometrie du mark est ici ; le wordmark est pose par l'application en
/// Inter SemiBold. Embedder les glyphes dans chaque fichier gonflerait chaque
/// SVG de dizaines de kilo-octets sans gain : la police est deja embarquee.
String lockupHorizontalSvg({
  required String markColor,
  required String wordmarkColor,
  double stroke = RelioMarkGeometry.strokePrimary,
}) {
  final box = RelioMarkGeometry.boundingBox(stroke);
  final double w = box.right - box.left;
  final double h = box.bottom - box.top;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(w)} ${n(h)}" width="${n(w)}" height="${n(h)}" role="img" aria-label="Relio">
  <title>Relio — lockup horizontal</title>
  <desc>Geometrie du mark. Le wordmark "Relio" est pose par l'application en Inter SemiBold 600, interlettrage -1.5 %, couleur $wordmarkColor, a ${relioLockupGapHorizontal.toStringAsFixed(0)} unites du bord droit du mark, centre verticalement sur la ligne des centres (y = ${n(RelioMarkGeometry.centerLineY)}).</desc>
  <g fill="none" fill-rule="evenodd">${markBody(markColor, stroke)}
  </g>
</svg>
''';
}

/// Lockup vertical : mark au-dessus, wordmark en dessous.
///
/// Comme pour le lockup horizontal, seule la geometrie du mark est decrite ;
/// le wordmark est pose par l'application.
String lockupVerticalSvg({
  required String markColor,
  required String wordmarkColor,
  double stroke = RelioMarkGeometry.strokePrimary,
}) {
  const double g = RelioMarkGeometry.grid;
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n(g)} ${n(g)}" width="${n(g)}" height="${n(g)}" role="img" aria-label="Relio">
  <title>Relio — lockup vertical</title>
  <desc>Geometrie du mark, centre dans la grille 100 x 100. Le wordmark est pose par l'application en dessous, a ${relioLockupGapVertical.toStringAsFixed(0)} unites d'ecartement, centre horizontalement, Inter SemiBold 600, couleur $wordmarkColor.</desc>
  <g fill="none" fill-rule="evenodd">${markBody(markColor, stroke)}
  </g>
</svg>
''';
}

/// Ecartement mark ↔ wordmark du lockup horizontal, en unites de grille.
///
/// Repris de la specification. Le generateur ne peut pas importer la couche
/// Flutter, donc la valeur est re-declaree ici et verifiee par
/// `test/branding/mark_geometry_test.dart`, qui echoue des que les deux
/// divergent.
const double relioLockupGapHorizontal = 20;

/// Ecartement mark ↔ wordmark du lockup vertical, en unites de grille.
const double relioLockupGapVertical = 12;

void main() {
  const String orange = '#F56207';
  const String indigo = '#1F3A6E';
  const String black = '#000000';
  const String white = '#FFFFFF';

  const String br = 'assets/branding';

  void write(String path, String content) {
    File(path).writeAsStringSync(content);
    stdout.writeln('ecrit  $path');
  }

  // --- mark : principale, compacte, monochrome -------------------------
  write('$br/mark/mark-primary.svg',
      markSvg(color: orange, variant: 'principale, trait 4 u'));
  write('$br/mark/mark-primary-mono-black.svg',
      markSvg(color: black, variant: 'monochrome noir'));
  write('$br/mark/mark-primary-mono-white.svg',
      markSvg(color: white, variant: 'monochrome blanc'));
  write('$br/mark/mark-compact.svg',
      markSvg(color: orange, stroke: RelioMarkGeometry.strokeCompact, variant: 'compacte, trait 6.2 u'));
  write('$br/mark/mark-compact-mono-black.svg',
      markSvg(color: black, stroke: RelioMarkGeometry.strokeCompact, variant: 'compacte monochrome noir'));
  write('$br/mark/mark-compact-mono-white.svg',
      markSvg(color: white, stroke: RelioMarkGeometry.strokeCompact, variant: 'compacte monochrome blanc'));

  // --- lockups ----------------------------------------------------------
  write('$br/lockup/lockup-horizontal.svg',
      lockupHorizontalSvg(markColor: orange, wordmarkColor: indigo));
  write('$br/lockup/lockup-horizontal-mono-black.svg',
      lockupHorizontalSvg(markColor: black, wordmarkColor: black));
  write('$br/lockup/lockup-horizontal-mono-white.svg',
      lockupHorizontalSvg(markColor: white, wordmarkColor: white));
  write('$br/lockup/lockup-vertical.svg',
      lockupVerticalSvg(markColor: orange, wordmarkColor: indigo));
  write('$br/lockup/lockup-vertical-mono-black.svg',
      lockupVerticalSvg(markColor: black, wordmarkColor: black));
  write('$br/lockup/lockup-vertical-mono-white.svg',
      lockupVerticalSvg(markColor: white, wordmarkColor: white));

  stdout.writeln('\nGenerateur termine.');
}

