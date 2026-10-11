// Material themes for Bolt Scan. Light = paper background, dark = ink.
// Scan screen itself always paints cameraBlack regardless of theme.
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Mono text style for all scanned data, numbers and badges.
class AppText {
  const AppText._();

  static TextStyle mono(
    BuildContext context, {
    double fontSize = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: 'JetBrainsMono',
        fontWeight: weight,
        fontSize: fontSize,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        height: 1.35,
      );
}

const String _uiFont = 'Manrope';

TextTheme _textTheme(ColorScheme scheme) {
  final TextStyle base = TextStyle(
    fontFamily: _uiFont,
    color: scheme.onSurface,
  );
  TextStyle w(int weight, double size, double height) => base.copyWith(
        fontWeight: FontWeight.values
            .firstWhere((FontWeight f) => f.value == weight * 100),
        fontSize: size,
        height: height,
      );
  return TextTheme(
    displayLarge: w(8, 32, 1.2),
    displayMedium: w(8, 28, 1.25),
    headlineSmall: w(7, 22, 1.3),
    titleLarge: w(7, 20, 1.3),
    titleMedium: w(6, 17, 1.35),
    titleSmall: w(6, 15, 1.4),
    bodyLarge: w(5, 16, 1.45),
    bodyMedium: w(5, 14.5, 1.45),
    bodySmall: w(5, 13, 1.45),
    labelLarge: w(7, 15, 1.3),
    labelMedium: w(6, 13, 1.35),
    labelSmall: w(6, 12, 1.35),
  );
}

ButtonStyle _pillButtonStyle(ColorScheme scheme) => const ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(Size(48, 52)),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28))),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontFamily: _uiFont,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );

ThemeData _baseTheme(ColorScheme scheme, {required bool dark}) {
  final ThemeData t = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: _textTheme(scheme),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
  return t.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _textTheme(scheme).titleLarge,
    ),
    cardTheme: CardThemeData(
      color: dark ? AppColors.darkCard : AppColors.cardWhite,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? AppColors.darkLine : AppColors.line,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _pillButtonStyle(scheme).copyWith(
        backgroundColor: const WidgetStatePropertyAll<Color>(
          AppColors.voltYellow,
        ),
        foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.ink),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _pillButtonStyle(scheme).copyWith(
        backgroundColor: const WidgetStatePropertyAll<Color>(
          AppColors.voltYellow,
        ),
        foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.ink),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _pillButtonStyle(scheme).copyWith(
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: scheme.outline),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(scheme.onSurface),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll<Size>(Size(48, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: _uiFont,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? AppColors.darkCard : AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
    ),
    chipTheme: t.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      labelStyle: const TextStyle(
        fontFamily: _uiFont,
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.darkCard : AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark ? AppColors.darkLine : AppColors.line,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: dark ? AppColors.darkLine : AppColors.line,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: dark ? AppColors.darkLine : AppColors.line,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? AppColors.darkCard : AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: _uiFont,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? AppColors.darkCard : AppColors.cardWhite,
      indicatorColor: AppColors.voltYellow,
      iconTheme: WidgetStatePropertyAll<IconThemeData>(
        IconThemeData(color: dark ? Colors.white : AppColors.ink),
      ),
      labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontFamily: _uiFont,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
  );
}

/// Light theme: paper background, ink text.
ThemeData buildLightTheme() => _baseTheme(
      const ColorScheme.light(
        primary: AppColors.voltYellow,
        onPrimary: AppColors.ink,
        secondary: AppColors.electricBlue,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.cardWhite,
        outline: AppColors.line,
        error: AppColors.danger,
      ),
      dark: false,
    );

/// Dark theme: ink background #0B0A12, darkCard cards, darkLine dividers.
ThemeData buildDarkTheme() => _baseTheme(
      const ColorScheme.dark(
        primary: AppColors.voltYellow,
        onPrimary: AppColors.ink,
        secondary: AppColors.electricBlue,
        surface: AppColors.cameraBlack,
        onSurface: Colors.white,
        surfaceContainerHighest: AppColors.darkCard,
        outline: AppColors.darkLine,
        error: AppColors.danger,
      ),
      dark: true,
    );
