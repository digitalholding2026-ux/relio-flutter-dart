/// Tests de la police embarquée et du formateur typographique.
///
/// Deux objets distincts sont verifies :
///  - la police : presence, poids, licence, et présence des accents ;
///  - le formateur : variables en italique, chiffres tabulaires, et surtout
///    l'ABSENCE d'italique là où il n'y en a pas lieu.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relio/domain/curriculum/chapter1_bank.dart';
import 'package:relio/presentation/theme/relio_theme.dart';
import 'package:relio/presentation/widgets/math_text.dart';

/// Fragments en italique dans un texte rendu.
List<String> italicsOf(WidgetTester tester) {
  final texte = tester.widget<RichText>(find.byType(RichText)).text;
  final resultats = <String>[];

  void visiter(InlineSpan span) {
    if (span is TextSpan) {
      if (span.style?.fontStyle == FontStyle.italic) {
        resultats.add(span.text ?? '');
      }
      for (final enfant in span.children ?? const <InlineSpan>[]) {
        visiter(enfant);
      }
    }
  }

  visiter(texte);
  return resultats;
}

/// La caractéristique de chiffres tabulaires attendue dans les fragments.
const FontFeature _tabulaire = FontFeature.tabularFigures();

/// Fragments rendus en chiffres tabulaires.
List<String> tabularOf(WidgetTester tester) {
  final texte = tester.widget<RichText>(find.byType(RichText)).text;
  final resultats = <String>[];

  void visiter(InlineSpan span) {
    if (span is TextSpan) {
      final features = span.style?.fontFeatures;
      if (features != null && features.contains(_tabulaire)) {
        resultats.add(span.text ?? '');
      }
      for (final enfant in span.children ?? const <InlineSpan>[]) {
        visiter(enfant);
      }
    }
  }

  visiter(texte);
  return resultats;
}

Widget afficher(String texte) => MaterialApp(
      home: Scaffold(
        body: MathText(text: texte, style: const TextStyle(fontSize: 16)),
      ),
    );

void main() {
  // =====================================================================
  group('Police Inter — fichiers embarqués', () {
    test('les cinq fichiers sont versionnés', () {
      const attendus = <String>[
        'Inter-Regular.ttf',
        'Inter-Medium.ttf',
        'Inter-SemiBold.ttf',
        'Inter-Bold.ttf',
        'Inter-Italic-Regular.ttf',
      ];
      for (final nom in attendus) {
        expect(File('assets/fonts/$nom').existsSync(), isTrue,
            reason: '$nom absent : le theme retomberait silencieusement sur '
                'la police du systeme');
      }
    });

    test('la licence SIL OFL accompagne la police', () {
      final licence = File('assets/fonts/Inter-OFL.txt');
      expect(licence.existsSync(), isTrue);
      expect(licence.readAsStringSync(), contains('SIL OPEN FONT LICENSE'));
    });

    test('le budget des quatre poids est respecte', () {
      var total = 0;
      for (final nom in const <String>[
        'Inter-Regular.ttf',
        'Inter-Medium.ttf',
        'Inter-SemiBold.ttf',
        'Inter-Bold.ttf',
      ]) {
        total += File('assets/fonts/$nom').lengthSync();
      }
      // Budget cible : environ 300 Ko.
      expect(total, lessThan(330 * 1024),
          reason: 'quatre poids à ${total ~/ 1024} Ko');
    });

    test('les accents français sont bien présents dans les fichiers', () {
      // Un sous-ensemble mal borné supprimerait les accents du texte.
      // Ce test est un garde-fou : il vérifie la TAILLE, et le contenu
      // lui-même est vérifié à la génération (docs/inter_build.py).
      for (final nom in const <String>[
        'Inter-Regular.ttf',
        'Inter-Bold.ttf',
      ]) {
        expect(File('assets/fonts/$nom').lengthSync(), greaterThan(50 * 1024),
            reason: '$nom trop petit : le sous-ensemble a probablement perdu '
                'des glyphes');
      }
    });

    test('le thème annonce Inter', () {
      expect(RelioTheme.fontFamily, 'Inter');
      expect(RelioTheme.build().textTheme.bodyMedium!.fontFamily, 'Inter');
    });

    test('l\'échelle 28/22/17/16/13 est respectée', () {
      final theme = RelioTheme.build();
      expect(theme.textTheme.displaySmall!.fontSize, 28);
      expect(theme.textTheme.titleLarge!.fontSize, 22);
      expect(theme.textTheme.titleMedium!.fontSize, 17);
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
      expect(theme.textTheme.bodyMedium!.fontSize, 16);
      expect(theme.textTheme.labelMedium!.fontSize, 13);
    });

    test('les quatre poids sont déclarés dans le thème', () {
      final theme = RelioTheme.build();
      expect(theme.textTheme.displaySmall!.fontWeight, FontWeight.w700);
      expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyMedium!.fontWeight, FontWeight.w400);
      expect(theme.textTheme.labelMedium!.fontWeight, FontWeight.w500);
    });

    test('aucun style ne force plus un axe de police variable', () {
      // Les fichiers ont wght épinglé : un fontVariations serait inutile,
      // et surtout trompeur, puisque le poids est porté par le fichier.
      final theme = RelioTheme.build();
      for (final style in <TextStyle>[
        theme.textTheme.displaySmall!,
        theme.textTheme.titleLarge!,
        theme.textTheme.titleMedium!,
        theme.textTheme.bodyLarge!,
        theme.textTheme.bodyMedium!,
        theme.textTheme.labelMedium!,
      ]) {
        expect(style.fontVariations, isNull);
      }
    });
  });

  // =====================================================================
  group('Formateur — points de vérification imposés', () {
    testWidgets('« Calcule le PGCD de 18 et 12 » : aucun italique',
        (tester) async {
      await tester.pumpWidget(afficher('Calcule le PGCD de 18 et 12'));

      expect(italicsOf(tester), isEmpty);
      expect(tabularOf(tester), isNotEmpty);
      expect(
        tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
        'Calcule le PGCD de 18 et 12',
      );
    });

    testWidgets('« a = 8 et b = 12 » : a et b en italique, rien d\'autre',
        (tester) async {
      await tester.pumpWidget(afficher('a = 8 et b = 12'));

      expect(italicsOf(tester), <String>['a', 'b']);
      expect(tabularOf(tester), <String>['8', '12']);
      expect(
        tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
        'a = 8 et b = 12',
      );
    });

    testWidgets('« (8 × 12) ÷ 4 » : opérateurs et parenthèses inchangés',
        (tester) async {
      await tester.pumpWidget(afficher('(8 × 12) ÷ 4'));

      expect(italicsOf(tester), isEmpty);
      final texte = tester.widget<RichText>(find.byType(RichText)).text;
      expect(texte.toPlainText(), '(8 × 12) ÷ 4');
      // Les opérateurs restent dans des fragments NON tabulaires et NON
      // italiques : ils sont donc bien restés uprights.
      for (final span in _fragments(texte)) {
        for (final caractere in ['×', '÷', '(', ')', ' ']) {
          if (span.text.contains(caractere)) {
            expect(span.italic, isFalse, reason: 'opérateur mis en italique');
          }
        }
      }
    });

    testWidgets('indice : « Après 18 − 12, travaille avec 12 et 6. »',
        (tester) async {
      const indice = 'Après 18 − 12, travaille avec 12 et 6.';
      await tester.pumpWidget(afficher(indice));

      expect(italicsOf(tester), isEmpty,
          reason: 'aucune lettre isolée dans ce texte');
      expect(tabularOf(tester), <String>['18', '12', '12', '6']);
      expect(
        tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
        indice,
        reason: 'aucun caractère ne doit être ajouté ni retiré',
      );
    });

    testWidgets('« PGCD(12,18) = 6 » : PGCD upright, aucun italique parasite',
        (tester) async {
      await tester.pumpWidget(afficher('PGCD(12,18) = 6'));

      expect(italicsOf(tester), isEmpty);
      expect(tabularOf(tester), <String>['12', '18', '6']);
    });

    testWidgets('« PPCM » n\'est jamais italique', (tester) async {
      await tester.pumpWidget(afficher('PPCM de 10 et 15, avec PGCD 5.'));

      expect(italicsOf(tester), isEmpty);
    });
  });

  // =====================================================================
  group('Formateur — aucune régression sur les mots', () {
    testWidgets('aucune lettre d\'un mot n\'est italicisée', (tester) async {
      const textes = <String>[
        'Calcule le PGCD de 18 et 12 avec des soustractions successives.',
        'Soustrais le plus petit nombre du plus grand.',
        'Divise le plus grand nombre par le plus petit et note le reste.',
        'À quel moment t’arrêtes-tu ?',
        'Souviens-toi que le couple est le diviseur et le reste.',
        'Tu connais leur produit et leur PGCD.',
      ];

      for (final texte in textes) {
        await tester.pumpWidget(afficher(texte));
        expect(italicsOf(tester), isEmpty, reason: 'texte : $texte');
      }
    });

    test('la détection d\'une variable isolée est explicite', () {
      // Vrai : lettre entre deux délimiteurs.
      expect(isIsolatedVariable('a', null, ' '), isTrue);
      expect(isIsolatedVariable('a', ' ', '='), isTrue);
      expect(isIsolatedVariable('b', ',', ' '), isTrue);
      expect(isIsolatedVariable('x', '(', ')'), isTrue);

      // Faux : à l'intérieur d'un mot.
      expect(isIsolatedVariable('e', ' ', 't'), isFalse);
      expect(isIsolatedVariable('i', 't', ' '), isFalse);
      // Faux : l'apostrophe et la tiret ne sont pas des délimiteurs.
      expect(isIsolatedVariable('l', null, "'"), isFalse);
      expect(isIsolatedVariable('i', '-', ' '), isFalse);

      // Faux : majuscule, chiffre.
      expect(isIsolatedVariable('A', null, ' '), isFalse);
      expect(isIsolatedVariable('1', null, ' '), isFalse);
    });

    test('« PGDC » est conservé tel quel, jamais italique', () {
      final fragments = formatMathText('« PGDC » : algorithme d’Euclide');
      expect(fragments.map((f) => f.text).join(), '« PGDC » : algorithme d’Euclide');
      expect(fragments.where((f) => f.italic), isEmpty);
    });

    test('les acronymes du programme sont déclarés explicitement', () {
      // Garde-fou : même si la règle des lettres minuscules les rend déjà
      // inatteignables, ils sont nommés.
      expect(kProgrammeAcronyms, containsAll(<String>['PGCD', 'PPCM', 'PGDC']));
    });
  });

  // =====================================================================
  group('Formateur — robustesse', () {
    test('une notation non reconnue est laissée telle quelle', () {
      const exotiques = <String>[
        'PGCD(12,18) = 6',
        '12 × 18 = 216 ÷ 6',
        'a = 8, b = 12',
        'x⁻¹',
        '√144',
        '∑',
        '3,5',
        '',
      ];

      for (final texte in exotiques) {
        final rendu = formatMathText(texte).map((f) => f.text).join();
        expect(rendu, texte,
            reason: 'le formateur ne doit JAMAIS réécrire un caractère');
      }
    });

    test('aucun texte de la banque ne perd un caractère', () {
      final textes = <String>[
        ...Chapter1Bank.exercises.map((e) => e.statement),
        ...Chapter1Bank.exercises.expand((e) => e.hints.map((h) => h.text)),
        ...Chapter1Bank.verificationTasks.map((t) => t.statement),
      ];

      for (final texte in textes) {
        final rendu = formatMathText(texte).map((f) => f.text).join();
        expect(rendu, texte, reason: texte);
      }
    });

    test('aucune variable parasite dans les 11 énoncés', () {
      for (final exercise in Chapter1Bank.exercises) {
        final variables = formatMathText(exercise.statement)
            .where((f) => f.italic)
            .map((f) => f.text)
            .toList();
        // Seul l'exercice 9 déclare des variables (a = 8 et b = 12).
        expect(variables, exercise.id == Chapter1Bank.exercises[8].id
            ? <String>['a', 'b']
            : <String>[],
            reason: exercise.id);
      }
    });

    test('aucune variable parasite dans les indices', () {
      for (final exercise in Chapter1Bank.exercises) {
        for (final hint in exercise.hints) {
          final variables =
              formatMathText(hint.text).where((f) => f.italic).toList();
          expect(variables, isEmpty, reason: '${exercise.id} : ${hint.text}');
        }
      }
    });

    test('les mots du texte sont préservés à l\'identique', () {
      const texte = 'Calcule le PGCD de 18 et 12';
      expect(formatMathText(texte).map((f) => f.text).join(), texte);
    });
  });

  // =====================================================================
  group('Formateur — périmètre', () {
    test('la documentation interne pose les limites', () {
      // Le fichier doit porter ses limites : elles font partie de la
      // décision, pas d'un commentaire facultatif.
      final source = File('lib/presentation/widgets/math_text.dart')
          .readAsStringSync();
      expect(source, contains('fractions'));
      expect(source, contains('exposants'));
      expect(source, contains('racines'));
      expect(source, contains('bibliothèque externe'));
    });

    test('aucune dépendance de rendu mathématique n\'est ajoutée', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final interdite in <String>[
        'flutter_math',
        'math_expressions',
        'katex',
        'mathjax',
        'flutter_html',
      ]) {
        expect(pubspec, isNot(contains(interdite)), reason: interdite);
      }
    });
  });
}

/// Fragments d'un texte rendu.
List<MathFragment> _fragments(InlineSpan texte) {
  final resultats = <MathFragment>[];
  void visiter(InlineSpan span) {
    if (span is TextSpan) {
      resultats.add(MathFragment(
        text: span.text ?? '',
        italic: span.style?.fontStyle == FontStyle.italic,
      ));
      for (final enfant in span.children ?? const <InlineSpan>[]) {
        visiter(enfant);
      }
    }
  }

  visiter(texte);
  return resultats;
}