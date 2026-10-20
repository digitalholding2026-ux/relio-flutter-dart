/// Jetons de design de Relio — couleurs, espacements, rayons, typographie.
///
/// FONDEATION DE TOUT L'AUTRE : aucun écran ne doit contenir une valeur
/// littérale de couleur, d'espacement ou de rayon. Un ajustement de design se
/// fait ici, et nulle part ailleurs.
///
/// CONTRASTE : deux palettes coexistent, pas deux systèmes.
///  - [RelioPalette.standard] : la palette de référence ;
///  - [RelioPalette.contrast]  : contraste renforcé, choisi par l'élève sur
///    l'écran Profil.
///
/// La palette renforcée n'ajoute AUCUNE information : elle renforce seulement
/// ce qui existe déjà. Aucune couleur ne porte seule un sens — chaque état
/// coloré est doublé d'un libellé (voir `RelioStrings` et les panneaux).
library;

import 'package:flutter/material.dart';

import '../../domain/settings/learner_settings.dart';

/// Palette de l'application.
///
/// instance unique, immuable. Le choix se fait à la construction :
/// `RelioPalette.of(highContrast: true)`.
@immutable
class RelioPalette {
  const RelioPalette._({
    required this.primary,
    required this.primaryContainer,
    required this.brand,
    required this.hintText,
    required this.hintBackground,
    required this.successText,
    required this.successBackground,
    required this.errorText,
    required this.errorBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.background,
    required this.homeBackground,
    required this.surface,
    required this.shadow,
    required this.onPrimary,
    required this.hintMathBackground,
    required this.hintHighlightBackground,
    required this.hintHighlightAccent,
    required this.hintHandoffText,
  });

  /// Palette de référence.
  factory RelioPalette.standard() => const RelioPalette._(
        primary: Color(0xFF1F3A6E),
        primaryContainer: Color(0xFFE7E8E9),
        brand: Color(0xFFF56207),
        hintText: Color(0xFFB45309),
        hintBackground: Color(0xFFFEF3C7),
        successText: Color(0xFF15803D),
        successBackground: Color(0xFFDCFCE7),
        errorText: Color(0xFFB91C1C),
        errorBackground: Color(0xFFFEE2E2),
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF4B5563),
        outline: Color(0xFFE4E7EC),
        background: Color(0xFFFAFBFC),
        homeBackground: Color(0xFFEEF2FA),
        surface: Color(0xFFFFFFFF),
        shadow: Color(0x0F000000),
        onPrimary: Color(0xFFFFFFFF),
        hintMathBackground: Color(0xFFF3F4F6),
        hintHighlightBackground: Color(0xFFFEF0E6),
        hintHighlightAccent: Color(0xFFF56207),
        hintHandoffText: Color(0xFF1F3A6E),
      );

  /// Palette à contraste renforcé.
  ///
  /// Seule la bordure et le texte secondaire sont renforcés : ce sont les
  /// deux éléments dont le contraste standard est le plus faible. Le texte
  /// principal et les couleurs sémantiques sont déjà au-dessus d'AA et ne
  /// changent pas — les foncer davantage dégraderait la lecture.
  factory RelioPalette.contrast() => const RelioPalette._(
        primary: Color(0xFF12264C),
        primaryContainer: Color(0xFFD4D6D9),
        brand: Color(0xFFB34500),
        hintText: Color(0xFF7C3D06),
        hintBackground: Color(0xFFFCE9B6),
        successText: Color(0xFF14532D),
        successBackground: Color(0xFFCEF5DA),
        errorText: Color(0xFF7F1414),
        errorBackground: Color(0xFFFBD5D5),
        textPrimary: Color(0xFF000000),
        textSecondary: Color(0xFF1F2937),
        outline: Color(0xFF6B7280),
        background: Color(0xFFFFFFFF),
        homeBackground: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        shadow: Color(0x1F000000),
        onPrimary: Color(0xFFFFFFFF),
        // Palette a contraste renforce : les fonds sont eclaircis, les textes
        // fonces. Meme separation de sens, contraste superieur.
        hintMathBackground: Color(0xFFEBEEF2),
        hintHighlightBackground: Color(0xFFFBE3D2),
        hintHighlightAccent: Color(0xFFB34500),
        hintHandoffText: Color(0xFF12264C),
      );

  /// Palette correspondant à la préférence [highContrast] de l'élève.
  factory RelioPalette.of({required bool highContrast}) =>
      highContrast ? RelioPalette.contrast() : RelioPalette.standard();

  /// Indigo principal : barre de navigation active, bouton principal, focus.
  ///
  /// COULEUR D'INTERFACE, PAS COULEUR DE MARQUE. Les couleurs du logo vivent
  /// dans `RelioBrand` et n'ont pas à être alignées sur celles-ci : l'écran
  /// et la marque sont deux usages distincts du même nom de couleur.
  final Color primary;

  /// Variante pressée de [primary] : même teinte, simplement assombrie.
  ///
  /// DÉRIVÉE, jamais saisie. Un second bleu écrit à la main finirait par
  /// diverger de celui qu'il doit décliner.
  Color get primaryPressed =>
      Color.lerp(primary, const Color(0xFF000000), 0.12)!;

  /// Fond des zones sélectionnées.
  final Color primaryContainer;

  /// Orange d'accentuation.
  ///
  /// Même règle que [primary] : c'est un jeton d'INTERFACE. Le mark du logo
  /// garde sa propre couleur, mesurée sur le visuel livré et figée par la
  /// règle 9. Ne jamais confondre les deux usages.
  final Color brand;

  /// Texte des indices, sur fond ambre.
  final Color hintText;

  /// Fond des indices.
  final Color hintBackground;

  /// Texte de réussite.
  final Color successText;

  /// Fond de réussite.
  final Color successBackground;

  /// Texte d'erreur.
  final Color errorText;

  /// Fond d'erreur.
  final Color errorBackground;

  /// Texte principal.
  final Color textPrimary;

  /// Texte secondaire : libellés, légendes.
  final Color textSecondary;

  /// Bordure de carte et de champ.
  final Color outline;

  /// Fond général des écrans.
  final Color background;

  /// Fond de l'écran d'accueil : indigo très pâle, pour détacher les cartes
  /// blanches du fond sans les cerner d'un trait.
  ///
  /// Jeton DISTINCT de [background] : l'accueil est le seul écran à porter une
  /// teinte, et cette teinte doit rester réglable en un point. En contraste
  /// renforcé, le fond redevient blanc — c'est la lisibilité qui prime.
  final Color homeBackground;

  /// Fond des cartes et des barres.
  final Color surface;

  /// Ombre portée des cartes, en alpha.
  final Color shadow;

  /// Texte et icônes posés sur [primary].
  ///
  /// Jeton plutôt que `Colors.white` dans les écrans : le jour où le contraste
  /// renforcé voudra un fond d'action différent, un seul point change.
  final Color onPrimary;

  /// Fond de l'encadre d'un bloc mathematique.
  final Color hintMathBackground;

  /// Fond du bloc « point a retenir ».
  final Color hintHighlightBackground;

  /// Liseré gauche du bloc « point a retenir ».
  final Color hintHighlightAccent;

  /// Texte du bloc de retour vers l'eleve.
  final Color hintHandoffText;
}

/// Diffusion de la palette courante dans l'arbre des widgets.
///
/// POURQUOI : la palette dépend d'une préférence de l'élève, elle ne peut donc
/// pas être une constante statique. Un widget lit sa couleur via
/// `RelioPalette.of(context)`, ce qui rend le changement de contraste
/// effectif sur TOUS les écrans sans les reconstruire un par un.
///
/// Une palette absente du contexte n'est pas une erreur fatale : on retombe
/// sur la palette standard, pour qu'un widget reste testable isolément.
class RelioPaletteScope extends InheritedWidget {
  const RelioPaletteScope({
    super.key,
    required this.palette,
    required super.child,
  });

  /// Palette à diffuser.
  final RelioPalette palette;

  /// Palette applicable sous [context].
  static RelioPalette of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<RelioPaletteScope>()
            ?.palette ??
        RelioPalette.standard();
  }

  @override
  bool updateShouldNotify(RelioPaletteScope oldWidget) =>
      oldWidget.palette != palette;
}

/// Espacements de la mise en page.
///
/// Échelle de 4 : 4 / 8 / 12 / 16 / 20 / 24 / 32. Aucune autre valeur.
abstract final class RelioSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Marge horizontale des écrans.
  static const double horizontal = xl;

  /// Marge intérieure des cartes.
  static const double cardInner = xl;

  /// Écart entre deux cartes d'une même liste.
  static const double cardGap = lg;

  /// Écart entre deux sections d'écran.
  static const double sectionGap = xxl;

  /// Hauteur de capitale du lockup « Relio » en en-tête.
  ///
  /// Elle commande la taille de tout le lockup, mark compris : le rapport entre
  /// les deux est fixe par [RelioBrand], le mot sert donc de reference.
  static const double logoCapHeight = 22;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: horizontal);

  static const EdgeInsets cardPadding = EdgeInsets.all(cardInner);
}

/// Rayons d'arrondi.
///
/// 8 petit / 12 cartes, champs, boutons / 16 bandeaux / 999 pastilles.
abstract final class RelioRadius {
  static const double small = 8;
  static const double card = 12;
  static const double banner = 16;
  static const double pill = 999;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius bannerAll =
      BorderRadius.all(Radius.circular(banner));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Dimensions des composants.
abstract final class RelioSizes {
  /// Hauteur du bouton principal.
  static const double primaryButtonHeight = 52;

  /// Hauteur du bouton secondaire.
  static const double secondaryButtonHeight = 48;

  /// Cible tactile minimale imposée par la spécification.
  static const double minTouchTarget = 48;

  /// Hauteur du champ de saisie.
  static const double fieldHeight = 56;

  /// Hauteur de la barre de navigation basse.
  static const double bottomNavHeight = 56;

  /// Épaisseur de bordure des champs.
  static const double fieldBorderWidth = 1.5;

  /// Épaisseur de bordure des cartes.
  static const double cardBorderWidth = 1;

  /// Épaisseur de la bordure orange de la carte « Reprendre ».
  ///
  /// Plus épaisse que celle des cartes ordinaires : c'est ce trait qui désigne
  /// la carte principale, sans ajouter d'ombre supplémentaire.
  static const double heroBorderWidth = 1.5;

  /// Diamètre de la pastille d'état d'une leçon.
  static const double statusDot = 8;

  /// Hauteur de la barre de progression d'une leçon.
  static const double lessonBarHeight = 6;

  /// Épaisseur de trait des icônes de la barre basse.
  static const double iconStrokeWidth = 1.75;
}

/// Échelle typographique.
///
/// Le passage par des STYLEScentralisés évite qu'un écran redéfnisse un
/// poids ou une taille : la règle « 16 partout pour le corps » tient alors par
/// construction.
abstract final class RelioType {
  /// Display — 28 / Bold.
  static TextStyle display(RelioPalette p) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// Title — 22 / SemiBold.
  static TextStyle title(RelioPalette p) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// TitleBold — 22 / Bold.
  ///
  /// Réservé aux titres qui doivent porter la hiérarchie à eux seuls : titre
  /// de la carte « Reprendre », où aucun autre signal ne désigne l'élément
  /// principal de l'écran.
  static TextStyle titleBold(RelioPalette p) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// SectionTitle — 18 / SemiBold.
  static TextStyle sectionTitle(RelioPalette p) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// Badge — 12 / SemiBold, pour les pastilles d'état.
  static TextStyle badge(RelioPalette p) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        fontFamily: RelioTheme.fontFamily,
        color: p.textSecondary,
      );

  /// Overline — 12 / Bold, capitales espacées.
  ///
  /// Utilisé pour l'étiquette « REPRENDRE » : un repère de section, pas un
  /// titre. L'interlettrage est porté ici, jamais dans l'écran.
  static TextStyle overline(RelioPalette p) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 1.2,
        fontFamily: RelioTheme.fontFamily,
        color: p.textSecondary,
      );

  /// Subtitle — 17 / SemiBold.
  static TextStyle subtitle(RelioPalette p) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// Body — 16 / Regular.
  static TextStyle body(RelioPalette p) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// BodyStrong — 16 / SemiBold.
  static TextStyle bodyStrong(RelioPalette p) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
      );

  /// Caption — 13 / Medium, texte secondaire.
  static TextStyle caption(RelioPalette p) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        fontFamily: RelioTheme.fontFamily,
        color: p.textSecondary,
      );

  /// Numeric — 20 / Medium, chiffres tabulaires.
  ///
  /// Utilisé pour les valeurs chiffrées alignées verticalement.
  static TextStyle numeric(RelioPalette p) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.2,
        fontFamily: RelioTheme.fontFamily,
        color: p.textPrimary,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
}

/// Police de l'application.
///
/// Quatre poids droits + un italique, déclarés dans `pubspec.yaml`, sous-ensemble
/// latin et latin étendu. Licence SIL OFL 1.1 dans `assets/fonts/Inter-OFL.txt`.
///
/// NOTE : les fichiers portent `wght` ÉPINGLÉ. Le poids est donc porté par le
/// fichier lui-même, et `fontWeight` suffit à le sélectionner. Aucun
/// `fontVariations` n'est nécessaire.
abstract final class RelioTheme {
  /// Nom de la famille déclarée dans `pubspec.yaml`.
  static const String fontFamily = 'Inter';

  /// Construit le thème Material pour la préférence donnée.
  ///
  /// [settings] ne fournit QUE la palette : ni le nom de l'élève, ni aucune
  /// donnée d'apprentissage n'entrent dans le thème.
  static ThemeData build({
    LearnerSettings settings = LearnerSettings.defaults,
  }) {
    final palette = RelioPalette.of(highContrast: settings.highContrast);

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        primary: palette.primary,
        surface: palette.surface,
        error: palette.errorText,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, palette),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 1,
        shadowColor: palette.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: RelioRadius.cardAll,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: palette.outline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(palette),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(palette),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle(palette),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RelioSpacing.lg,
          vertical: RelioSpacing.md,
        ),
        border: _fieldBorder(palette),
        enabledBorder: _fieldBorder(palette),
        focusedBorder: _fieldBorder(palette, focused: true),
        hintStyle: RelioType.body(palette).copyWith(
          color: palette.textSecondary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(
    RelioPalette p, {
    bool focused = false,
  }) {
    return OutlineInputBorder(
      borderRadius: RelioRadius.cardAll,
      borderSide: BorderSide(
        color: focused ? p.primary : p.outline,
        width: focused ? 2 : RelioSizes.fieldBorderWidth,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, RelioPalette p) {
    return base.copyWith(
      displaySmall: RelioType.display(p),
      titleLarge: RelioType.title(p),
      titleMedium: RelioType.subtitle(p),
      bodyLarge: RelioType.body(p),
      bodyMedium: RelioType.body(p),
      labelMedium: RelioType.caption(p),
    );
  }

  static ButtonStyle _filledStyle(RelioPalette p) {
    return FilledButton.styleFrom(
      backgroundColor: p.primary,
      foregroundColor: Colors.white,
      // ÉTAT DÉSACTIVÉ — deux défauts qu'il faut corriger ensemble.
      //
      // 1. Le FOND par défaut de Material est `onSurface` à 12 % d'alpha.
      //    Sur un écran clair il donne un contraste de 1,1:1 : le bouton
      //    devient une tache quasi invisible, et l'élève ne voit plus du tout
      //    l'action qui l'attend.
      // 2. Le TEXTE par défaut est `onSurface` à 38 % : 2,4:1 sur fond clair,
      //    en dessous du seuil de 4,5:1 exigé pour du texte de 16 dp.
      //
      // On s'appuie donc sur des jetons EXISTANTS — `primaryContainer` et
      // `textSecondary` — qui donnent plus de 4,5:1 dans les deux palettes.
      // Un bouton désactivé doit rester identifiable : c'est lui qui dit à
      // l'élève ce qu'il peut faire ensuite.
      disabledBackgroundColor: p.primaryContainer,
      disabledForegroundColor: p.textSecondary,
      // Le fond désactivé (`primaryContainer`) et le fond d'écran ne se
      // distinguent qu'à 1,19:1 : le bouton garde bien son libellé lisible,
      // mais sa FORME disparaît. Une bordure, appliquée UNIQUEMENT dans cet
      // état, redessine le contour du bouton sans toucher à l'apparence des
      // boutons actifs.
      side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: p.textSecondary,
            width: RelioSizes.fieldBorderWidth,
          );
        }
        return BorderSide.none;
      }),
      minimumSize: const Size.fromHeight(RelioSizes.primaryButtonHeight),
      textStyle: RelioType.bodyStrong(p).copyWith(color: Colors.white),
      shape: const RoundedRectangleBorder(borderRadius: RelioRadius.cardAll),
    );
  }

  static ButtonStyle _outlinedStyle(RelioPalette p) {
    return OutlinedButton.styleFrom(
      foregroundColor: p.primary,
      minimumSize: const Size.fromHeight(RelioSizes.secondaryButtonHeight),
      side: BorderSide(color: p.primary, width: RelioSizes.fieldBorderWidth),
      textStyle: RelioType.bodyStrong(p).copyWith(color: p.primary),
      shape: const RoundedRectangleBorder(borderRadius: RelioRadius.cardAll),
    );
  }

  static ButtonStyle _textStyle(RelioPalette p) {
    return TextButton.styleFrom(
      foregroundColor: p.primary,
      minimumSize: const Size.fromHeight(RelioSizes.minTouchTarget),
      textStyle: RelioType.bodyStrong(p).copyWith(color: p.primary),
      shape: const RoundedRectangleBorder(borderRadius: RelioRadius.cardAll),
    );
  }
}