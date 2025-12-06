import 'package:flutter/material.dart';

class VedcColors {
  // Primary teal/aqua used for buttons and accents
  static const Color primary = Color(0xFF2EC4B6);
  static const Color primaryLight = Color(0xFF9EEDE4);
  static const Color primaryLighter = Color(0xFFBFEFEA);
  static const Color primaryDark = Color(0xFF1BA89A);

  // Secondary / accent colors
  static const Color accent = Color(0xFF00BFA6);

  // Logo colors
  static const Color logoRed = Color(0xFFED1C24);
  static const Color logoBlue = Color(0xFF394B9A);

  // Greys / neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color disabled = Color(0xFFBDBDBD);

  // Surfaces
  static const Color background = white;
  static const Color surface = Color(0xFFF7F7F7);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFe74c3c);

  // Shadows
  static const Color shadow = Color(0x40000000); // 25% black

  // Small helpers
  static const Color inputUnderline = Color(0xFF8EE3DD);

  // Material swatch for primary
  static const MaterialColor primarySwatch =
      MaterialColor(_primaryValue, <int, Color>{
        50: Color(0xFFE8F8F6),
        100: Color(0xFFCAF2EE),
        200: Color(0xFF9EEDE4),
        300: Color(0xFF6EE8DA),
        400: Color(0xFF44E2D0),
        500: Color(_primaryValue),
        600: Color(0xFF27B39D),
        700: Color(0xFF1E8E7F),
        800: Color(0xFF176A61),
        900: Color(0xFF0F4440),
      });
  static const int _primaryValue = 0xFF2EC4B6;
}

extension VedcTheme on ThemeData {
  ThemeData applyVedcColors() {
    return copyWith(
      colorScheme: colorScheme.copyWith(
        primary: VedcColors.primary,
        secondary: VedcColors.accent,
        background: VedcColors.background,
        surface: VedcColors.surface,
      ),
      primaryColor: VedcColors.primary,
      scaffoldBackgroundColor: VedcColors.background,
      splashColor: VedcColors.primary.withOpacity(0.12),
    );
  }
}
