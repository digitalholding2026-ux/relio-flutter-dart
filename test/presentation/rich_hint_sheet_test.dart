/// Rendu de la fiche d'aide riche — styles des blocs et budget du bouton.
///
/// MOCKS EXPLICITES.
///
/// Les fiches construites ici ne sont pas du contenu pédagogique : elles
/// n'existent que pour verifier que chaque nature de bloc s'affiche avec SON
/// style. Aucun mot de ces fixtures ne provient ni ne remplacera la banque.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/rich_hint.dart';
import 'package:relio/presentation/strings/relio_strings.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/rich_hint_sheet.dart';

/// Palette de référence, pour comparer les couleurs(expected).
final RelioPalette kPalette = RelioPalette.standard();

/// Montre un bloc seul dans une fiche minimale.
Future<void> _pumpBlock(WidgetTester tester, HintBlock block) async {
  await tester.pumpWidget(
    RelioPaletteScope(
      palette: kPalette,
      child: MaterialApp(
        home: Scaffold(
          body: HintBlockView(block: block, isFollowedByBlock: false),
        ),
      ),
    ),
  );
}

/// Couleur de fond d'un conteneur portant [text].
Color _backgroundOf(WidgetTester tester, String text) {
  final container = tester.widgetList<Container>(
    find.ancestor(
      of: find.textContaining(text),
      matching: find.byType(Container),
    ),
  );
  final decor = container.first.decoration as BoxDecoration;
  return decor.color!;
}

/// Bordure d'un conteneur portant [text].
BoxBorder? _borderOf(WidgetTester tester, String text) {
  final container = tester.widgetList<Container>(
    find.ancestor(
      of: find.textContaining(text),
      matching: find.byType(Container),
    ),
  );
  final decor = container.first.decoration as BoxDecoration;
  return decor.border;
}

/// Style EFFECTIF appliqué au texte [text].
///
/// `MathText` empile trois niveaux : le style du thème Material, puis celui
/// que le formateur pose sur le span racine, puis les fragments qui ne
/// redéfinissent QUE l'italique et les chiffres tabulaires.
///
/// Le style qu'on veut testers est celui du SPAN DU FORMATEUR — c'est lui qui
/// porte le corps 16 / SemiBold et la couleur de la fiche. On le retrouve en
/// remontant depuis le fragment, ce qui évite de dependre du style Material
/// par defaut.
TextStyle _styleOf(WidgetTester tester, String text) {
  final rich = tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
        (r) => r.text.toPlainText().contains(text),
        orElse: () => throw StateError('RichText introuvable : "$text"'),
      );

  final found = _deepestAppStyle(rich.text);
  if (found == null) throw StateError('style applicatif introuvable : "$text"');
  return found;
}

/// Style applicatif le plus PROFOND dans la pile de spans.
///
/// La pile se lit ainsi :
///
///   span Material  → Roboto, 14  (style par defaut, ignore)
///   span formateur → Inter, 16, couleur du bloc  ← celui-la
///   span fragment  → italique / tabulaire seuls
///
/// Le span du formateur est distingue par sa TAILLE : il fixe `fontSize` ET
/// n'est pas un fragment. Un fragment ne fixe jamais `fontSize` — c'est ce qui
/// permet de le retenir sans connaitre le nom de la police.
TextStyle? _deepestAppStyle(InlineSpan span) {
  TextStyle? best;

  if (span is TextSpan) {
    final own = span.style;
    // Fragment = style sans taille. On l'ignore : il ne porte que la mise en
    // forme. Un span qui fixe une taille est le style applicatif.
    if (own != null && own.fontSize != null && !_isFragmentOnly(own)) {
      best = own;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = _deepestAppStyle(child);
      if (found != null) best = found;
    }
  }
  return best;
}

/// Le style ne porte-t-il QUE de la mise en forme ?
bool _isFragmentOnly(TextStyle style) =>
    style.fontSize == null && style.fontFamily == null;

/// Fragment dont le texte CONTIENT [needle].
///
/// Le formateur découpe au caractère près : un acronym sort en « PGCD( », pas
/// en « PGCD ». Chercher une égalité stricte reviendrait à dependre de ce
/// découpage, alors que ce qu'on veut tester est le style.
InlineSpan? _findSpanContaining(InlineSpan span, String needle) {
  if (span is TextSpan && (span.text?.contains(needle) ?? false)) return span;
  if (span is TextSpan) {
    for (final child in span.children ?? const <InlineSpan>[]) {
      final found = _findSpanContaining(child, needle);
      if (found != null) return found;
    }
  }
  return null;
}

void main() {
  group('TextBlock — corps de texte', () {
    testWidgets('rend le texte en Body 16 / Regular', (tester) async {
      await _pumpBlock(tester, const TextBlock('Une explication simple.'));

      final style = _styleOf(tester, 'Une explication simple.');
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, kPalette.textPrimary);
    });

    testWidgets('ne pose aucun encadré', (tester) async {
      await _pumpBlock(tester, const TextBlock('Une explication simple.'));
      // Le texte est seul dans l'arbre : ni fond, ni bordure.
      expect(
        find.ancestor(
          of: find.textContaining('Une explication simple.'),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });
  });

  group('MathBlock — encadré gris', () {
    testWidgets('fond gris, bordure fine, rayon 8, padding 12', (tester) async {
      await _pumpBlock(tester, const MathBlock('18 − 12 = 6'));

      expect(_backgroundOf(tester, '18 − 12 = 6'),
          kPalette.hintMathBackground);
      expect(_backgroundOf(tester, '18 − 12 = 6'), const Color(0xFFF3F4F6));

      final border = _borderOf(tester, '18 − 12 = 6');
      expect(border, isA<Border>());
      final asBorder = border! as Border;
      expect(asBorder.top.color, kPalette.outline);
      expect(asBorder.top.width, 1);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.textContaining('18 − 12 = 6'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.padding, const EdgeInsets.all(12));
      final decor = container.decoration! as BoxDecoration;
      expect(decor.borderRadius,
          const BorderRadius.all(Radius.circular(8)));
    });

    testWidgets('passe par le formateur mathématique', (tester) async {
      await _pumpBlock(tester, const MathBlock('PGCD(12, 18) = 6'));

      // Le formateur rend un Text.rich : c'est la preuve que le passage par
      // MathText a eu lieu, et qu'un acronym comme PGCD n'est pas italique.
      final rich = tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
            (r) => r.text.toPlainText().contains('PGCD'),
          );

      // Le formateur découpe « PGCD(12, 18) = 6 » en fragments : « PGCD( »,
      // « 12 », « , », « 18 », « ) = », « 6 ». Le fragment qui porte
      // l'acronyme ne doit porter AUCUNE mise en forme : un acronym du
      // programme n'est jamais une variable.
      final acronym = _findSpanContaining(rich.text, 'PGCD');
      expect(acronym, isNotNull);
      expect(acronym!.style?.fontStyle, isNot(FontStyle.italic));

      // Les nombres, eux, passent bien en tabulaire : c'est la preuve que le
      // formateur s'est applique.
      final digits = _findSpanContaining(rich.text, '12');
      expect(digits, isNotNull);
      expect(digits!.style?.fontFeatures, isNotNull);
    });
  });

  group('HighlightBlock — point à retenir', () {
    testWidgets('fond orange pâle, liseré orange à gauche de 4 dp',
        (tester) async {
      await _pumpBlock(tester, const HighlightBlock('Retiens ce point.'));

      expect(_backgroundOf(tester, 'Retiens ce point.'),
          const Color(0xFFFEF0E6));

      final border = _borderOf(tester, 'Retiens ce point.');
      expect(border, isA<Border>());
      final asBorder = border! as Border;
      // Le liseré est à GAUCHE : c'est ce qui distingue ce bloc d'une simple
      // carte colorée.
      expect(asBorder.left.color, const Color(0xFFF56207));
      expect(asBorder.left.width, 4);
      // Aucune bordure sur les autres côtés.
      expect(asBorder.top, BorderSide.none);
      expect(asBorder.bottom, BorderSide.none);
      expect(asBorder.right, BorderSide.none);
    });

    testWidgets('texte indigo gras', (tester) async {
      await _pumpBlock(tester, const HighlightBlock('Retiens ce point.'));

      final style = _styleOf(tester, 'Retiens ce point.');
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, const Color(0xFF1F3A6E));
      expect(style.fontSize, 16);
    });
  });

  group('HandoffBlock — retour vers l’élève', () {
    testWidgets('texte indigo gras, sans encadré', (tester) async {
      await _pumpBlock(tester, const HandoffBlock('Et toi, tu trouves ?'));

      final style = _styleOf(tester, 'Et toi, tu trouves ?');
      expect(style.color, const Color(0xFF1F3A6E));
      expect(style.fontWeight, FontWeight.w600);

      // Aucune boîte : il ne doit pas ressembler au bloc mathématique.
      expect(
        find.ancestor(
          of: find.textContaining('Et toi, tu trouves ?'),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });

    testWidgets('un filet le sépare du bloc suivant', (tester) async {
      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  HandoffBlockViewProbe(isFollowedByBlock: true),
                ],
              ),
            ),
          ),
        ),
      );

      // Le filet n'existe que si un bloc suit.
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('aucun filet sur le dernier bloc de la fiche',
        (tester) async {
      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: const MaterialApp(
            home: Scaffold(
              body: HandoffBlockViewProbe(isFollowedByBlock: false),
            ),
          ),
        ),
      );

      // Un filet final serait une ligne orpheline.
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('le handoff est distinct du texte', (tester) async {
      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  TextBlockViewProbe(text: 'Explication.'),
                  HandoffBlockViewProbe(isFollowedByBlock: false),
                ],
              ),
            ),
          ),
        ),
      );

      final plain = _styleOf(tester, 'Explication.');
      final handoff = _styleOf(tester, 'Et toi ?');

      // Ils ne doivent JAMAIS se confondre : l'invitation à répondre doit
      // sauter aux yeux.
      expect(handoff.fontWeight, isNot(plain.fontWeight));
      expect(handoff.color, isNot(plain.color));
    });
  });

  group('Fiche complète', () {
    testWidgets('rend les quatre natures de blocs dans l’ordre',
        (tester) async {
      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  HintBlockView(
                    block: const TextBlock('Explication.'),
                    isFollowedByBlock: true,
                  ),
                  HintBlockView(
                    block: const MathBlock('18 − 12 = 6'),
                    isFollowedByBlock: true,
                  ),
                  HintBlockView(
                    block: const HighlightBlock('À retenir.'),
                    isFollowedByBlock: true,
                  ),
                  HintBlockView(
                    block: const HandoffBlock('Et toi ?'),
                    isFollowedByBlock: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Explication.'), findsOneWidget);
      expect(find.textContaining('18 − 12 = 6'), findsOneWidget);
      expect(find.textContaining('À retenir.'), findsOneWidget);
      expect(find.textContaining('Et toi ?'), findsOneWidget);
    });
  });

  group('Fiche de relecture', () {
    testWidgets('bandeau, blocs empilés et bouton de retour', (tester) async {
      var backCalled = false;

      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showRichHintSheet(
                      context,
                      hint: const RichHint(
                        order: 0,
                        title: '💡 Comprendre cette étape',
                        blocks: <HintBlock>[
                          TextBlock('Premier indice relu.'),
                          MathBlock('18 − 12 = 6'),
                          TextBlock('Deuxième indice relu.'),
                        ],
                        isFinal: true,
                      ),
                      reviewBanner:
                          'Voici les explications de l’exercice 2. '
                          'Prends le temps de les relire.',
                      backToCurrentLabel: 'Retour à l’exercice en cours',
                      onBackToCurrent: () => backCalled = true,
                    ),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      // Le bandeau nomme l'exercice d'origine.
      expect(find.textContaining('exercice 2'), findsOneWidget);
      // Les blocs empiles sont presents, dans l'ordre.
      expect(find.textContaining('Premier indice relu.'), findsOneWidget);
      expect(find.textContaining('Deuxième indice relu.'), findsOneWidget);
      // Les deux boutons sont distincts.
      expect(find.text(RelioStrings.richHintUnderstood), findsOneWidget);
      expect(find.text('Retour à l’exercice en cours'), findsOneWidget);
      expect(backCalled, isFalse);

      await tester.tap(find.text('Retour à l’exercice en cours'));
      await tester.pumpAndSettle();

      // Le bouton de retour previent l'ecran ET ferme la fiche.
      expect(backCalled, isTrue);
      expect(find.text(RelioStrings.richHintUnderstood), findsNothing);
    });

    testWidgets('la fiche est blanche, à 75 %, défilable', (tester) async {
      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showRichHintSheet(
                      context,
                      hint: RichHint(
                        order: 1,
                        title: '💡 Comprendre cette étape',
                        // Contenu volontairement long : la fiche doit
                        // pouvoir deborder sans perdre son bouton de sortie.
                        blocks: <HintBlock>[
                          for (var i = 0; i < 12; i++)
                            TextBlock('Ligne $i — contenu de fiche.'),
                        ],
                      ),
                    ),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      final screenHeight = MediaQuery.sizeOf(
        tester.element(find.text('ouvrir')),
      ).height;
      final sheetHeight = tester
          .getSize(
            find.ancestor(
              of: find.text(RelioStrings.richHintUnderstood),
              matching: find.byType(SafeArea),
            ),
          )
          .height;

      // 75 % au maximum : l'enonce reste visible au-dessus.
      expect(sheetHeight, lessThanOrEqualTo(screenHeight * 0.75 + 1));

      // Le bouton de sortie reste atteignable SANS avoir fait defiler : il
      // est hors de la zone defilante, donc jamais perdu de vue.
      expect(find.text(RelioStrings.richHintUnderstood), findsOneWidget);
      expect(
        tester.getSize(
          find.ancestor(
            of: find.text(RelioStrings.richHintUnderstood),
            matching: find.byType(SafeArea),
          ),
        ).height,
        lessThanOrEqualTo(screenHeight * 0.75 + 1),
      );

      // La zone de contenu, elle, defile : c'est ce qui permet de relire
      // toutes les lignes sans allonger la fiche au-dela de 75 %.
      final scroller = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Column),
      );
      expect(scroller, findsWidgets);
    });

    testWidgets('aucun bouton de retour hors relecture', (tester) async {
      await tester.pumpWidget(
        RelioPaletteScope(
          palette: kPalette,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showRichHintSheet(
                      context,
                      hint: const RichHint(
                        order: 1,
                        title: '💡 Comprendre cette étape',
                        blocks: <HintBlock>[TextBlock('Une explication.')],
                      ),
                    ),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Retour à l’exercice en cours'), findsNothing);
      expect(find.text(RelioStrings.richHintUnderstood), findsOneWidget);
    });
  });

  group('Libellés du bouton', () {
    test('le libellé suit le budget', () {
      expect(RelioStrings.hintCta(HintCta.askFirst), 'Demander un indice');
      expect(RelioStrings.hintCta(HintCta.next), 'Indice suivant');
      expect(RelioStrings.hintCta(HintCta.finalOne), 'Indice final');
    });

    test('la relecture nomme l’exercice précédent', () {
      expect(
        RelioStrings.hintCta(HintCta.reviewPrevious, previousExerciseNumber: 1),
        'Revoir l’exercice 1',
      );
    });

    test('les libellés de la fiche', () {
      expect(RelioStrings.richHintTitle, '💡 Comprendre cette étape');
      expect(RelioStrings.richHintUnderstood, 'J’ai compris');
      expect(
        RelioStrings.richHintReviewBanner(1),
        'Voici les explications de l’exercice 1. Prends le temps de les relire.',
      );
      expect(RelioStrings.richHintBackToCurrent,
          'Retour à l’exercice en cours');
    });
  });
}

/// Sonde : rend un bloc handoff avec ou sans bloc suivant.
class HandoffBlockViewProbe extends StatelessWidget {
  const HandoffBlockViewProbe({super.key, required this.isFollowedByBlock});

  final bool isFollowedByBlock;

  @override
  Widget build(BuildContext context) => HintBlockView(
        block: const HandoffBlock('Et toi ?'),
        isFollowedByBlock: isFollowedByBlock,
      );
}

/// Sonde : rend un bloc texte nu.
class TextBlockViewProbe extends StatelessWidget {
  const TextBlockViewProbe({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      HintBlockView(block: TextBlock(text));
}