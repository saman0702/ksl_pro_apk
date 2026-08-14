import 'package:flutter/material.dart';

@immutable
class KatianThemeExtension extends ThemeExtension<KatianThemeExtension> {
  const KatianThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.navBarBackground,
    required this.headerBackground,
    required this.headerForeground,
    required this.shadowColor,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color navBarBackground;
  final Color headerBackground;
  final Color headerForeground;
  final Color shadowColor;

  static const light = KatianThemeExtension(
    background: Color(0xFFF7F7F7),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F0F0),
    textPrimary: Color(0xFF1F1F1F),
    textSecondary: Color(0xFF6E6E6E),
    border: Color(0xFFE5E5E5),
    navBarBackground: Color(0xFFFFFFFF),
    headerBackground: Color(0xFFE30613),
    headerForeground: Color(0xFFFFFFFF),
    shadowColor: Color(0x14000000),
  );

  static const dark = KatianThemeExtension(
    background: Color(0xFF111111),
    surface: Color(0xFF1C1C1E),
    surfaceVariant: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFF8E8E93),
    border: Color(0xFF38383A),
    navBarBackground: Color(0xFF1C1C1E),
    headerBackground: Color(0xFFE30613),
    headerForeground: Color(0xFFFFFFFF),
    shadowColor: Color(0x40000000),
  );

  @override
  KatianThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? navBarBackground,
    Color? headerBackground,
    Color? headerForeground,
    Color? shadowColor,
  }) {
    return KatianThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      headerBackground: headerBackground ?? this.headerBackground,
      headerForeground: headerForeground ?? this.headerForeground,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  KatianThemeExtension lerp(
    covariant ThemeExtension<KatianThemeExtension>? other,
    double t,
  ) {
    if (other is! KatianThemeExtension) return this;
    return KatianThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      navBarBackground:
          Color.lerp(navBarBackground, other.navBarBackground, t)!,
      headerBackground:
          Color.lerp(headerBackground, other.headerBackground, t)!,
      headerForeground:
          Color.lerp(headerForeground, other.headerForeground, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

extension KatianThemeContext on BuildContext {
  KatianThemeExtension get katian =>
      Theme.of(this).extension<KatianThemeExtension>() ??
      KatianThemeExtension.light;
}
