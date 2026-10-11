/// Système visuel de Relio.
///
/// Palette, typographie, espacements et composants définis par la
/// spécification d'interface. Centralisés ici pour qu'un ajustement de
/// design ne touche aucun écran.
///
/// ⚠️ Police : la spécification demande **Inter**. Le fichier de police n'est
/// pas embarqué dans le dépôt ; `fontFamily: 'Inter'` est donc déclaré, et
/// Flutter bascule silencieusement sur la police par défaut tant que
/// l'asset n'est pas ajouté. C'est une limite connue, signalée dans
/// `docs/INTERFACE.md`.
library;

import 'package:flutter/material.dart';

/// Palette de l'application.
abstract final class RelioColors {
  /// Primaire — barre haute, bouton principal, focus.
  static const Color primary = Color(0xFF1F3A6E);

  /// Conteneur primaire — fond des zones selections.
  static const Color primaryContainer = Color(0xFFE6ECF7);

  /// Texte des indices, sur fond ambre.
  static const Color hintText = Color(0xFFB45309);
  static const Color hintBackground = Color(0xFFFEF3C7);

  /// Texte de reussite, sur fond vert.
  static const Color successText = Color(0xFF15803D);
  static const Color successBackground = Color(0xFFDCFCE7);

  /// Texte d'erreur, sur fond rouge.
  static const Color errorText = Color(0xFFB91C1C);
  static const Color errorBackground = Color(0xFFFEE2E2);

  /// Texte principal.
  static const Color text = Color(0xFF111827);

  /// Texte secondaire.
  static const Color textSecondary = Color(0xFF4B5563);

  /// Contour.
  static const Color border = Color(0xFFE4E7EC);

  /// Fond general.
  static const Color background = Color(0xFFFAFBFC);
}

/// Espacements de la mise en page.
abstract final class RelioSpacing {
  static const double horizontal = 20;
  static const double cardInner = 20;
  static const double cardGap = 16;
  static const double sectionGap = 24;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: horizontal);

  static const EdgeInsets cardPadding =
      EdgeInsets.all(cardInner);
}

/// Dimensions des composants.
abstract final class RelioSizes {
  static const double primaryButtonHeight = 52;
  static const double secondaryButtonHeight = 48;
  static const double textButtonHeight = 44;

  /// Cible tactile minimale, imposee par la specification.
  static const double minTouchTarget = 48;

  static const double fieldHeight = 56;
  static const double fieldRadius = 12;
  static const double fieldBorderWidth = 1.5;

  static const double cardRadius = 12;
  static const double cardBorderWidth = 1;
}

/// Theme Material de Relio.
abstract final class RelioTheme {
  /// Police demandee par la specification.
  static const String fontFamily = 'Inter';

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: RelioColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RelioColors.primary,
        primary: RelioColors.primary,
        surface: Colors.white,
        error: RelioColors.errorText,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: RelioColors.background,
        foregroundColor: RelioColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RelioSizes.cardRadius),
          side: const BorderSide(
            color: RelioColors.border,
            width: RelioSizes.cardBorderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: RelioColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: RelioColors.text,
        height: 1.2,
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: RelioColors.text,
        height: 1.25,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: RelioColors.text,
        height: 1.3,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: RelioColors.text,
        height: 1.45,
      ),
      bodyMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: RelioColors.text,
        height: 1.45,
      ),
      labelMedium: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: RelioColors.textSecondary,
        height: 1.35,
      ),
    );
  }
}

/// Style du bouton primaire — 52 dp, rayon 12.
abstract final class RelioButtons {
  static ButtonStyle primary() {
    return FilledButton.styleFrom(
      backgroundColor: RelioColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(RelioSizes.primaryButtonHeight),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: RelioTheme.fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RelioSizes.fieldRadius),
      ),
    );
  }

  /// Bouton secondaire — 48 dp, bordure 1.5.
  static ButtonStyle secondary() {
    return OutlinedButton.styleFrom(
      foregroundColor: RelioColors.primary,
      minimumSize: const Size.fromHeight(RelioSizes.secondaryButtonHeight),
      side: const BorderSide(
        color: RelioColors.primary,
        width: RelioSizes.fieldBorderWidth,
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: RelioTheme.fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RelioSizes.fieldRadius),
      ),
    );
  }

  /// Bouton texte — 44 dp de hauteur, cible tactile elargie a 48 dp.
  static ButtonStyle text() {
    return TextButton.styleFrom(
      foregroundColor: RelioColors.primary,
      minimumSize: const Size.fromHeight(RelioSizes.minTouchTarget),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: RelioTheme.fontFamily,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RelioSizes.fieldRadius),
      ),
    );
  }
}
