import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'katian_theme_extension.dart';

class KatianColors {
  KatianColors._();

  static const red = Color(0xFFE30613);
  static const redDark = Color(0xFFB8050F);
  static const redLight = Color(0xFFFDE8EA);

  static const orange = Color(0xFFF97316);
  static const blue = Color(0xFF2563EB);
  static const green = Color(0xFF16A34A);
  static const purple = Color(0xFF7C3AED);
  static const amber = Color(0xFFD97706);
  static const teal = Color(0xFF0D9488);
  static const brown = Color(0xFF92400E);
  static const statusGrey = Color(0xFF6B7280);

  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F7F7);
  static const border = Color(0xFFE5E5E5);
  static const darkText = Color(0xFF1F1F1F);
  static const greyText = Color(0xFF6E6E6E);
}

class KatianTheme {
  static const double buttonBorderRadius = 12;

  static RoundedRectangleBorder get buttonShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonBorderRadius),
      );

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final ext = isDark ? KatianThemeExtension.dark : KatianThemeExtension.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KatianColors.red,
        brightness: brightness,
        primary: KatianColors.red,
        onPrimary: KatianColors.white,
        surface: ext.surface,
      ),
      scaffoldBackgroundColor: ext.background,
      extensions: [ext],
      appBarTheme: const AppBarTheme(
        backgroundColor: KatianColors.red,
        foregroundColor: KatianColors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ext.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KatianColors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KatianColors.red,
          foregroundColor: KatianColors.white,
          minimumSize: const Size.fromHeight(48),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.surface,
        modalBackgroundColor: ext.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      cardTheme: CardThemeData(
        color: ext.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ext.border.withValues(alpha: 0.6)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ext.navBarBackground,
        selectedItemColor: KatianColors.red,
        unselectedItemColor: ext.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: ext.border,
        thickness: 1,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: isDark ? KatianColors.white : KatianColors.darkText,
        displayColor: isDark ? KatianColors.white : KatianColors.darkText,
      ),
    );
  }
}
