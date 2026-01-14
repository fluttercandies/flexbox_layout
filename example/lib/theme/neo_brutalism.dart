import 'package:flutter/material.dart';

/// Neo-Brutalism design system constants and utilities.
///
/// Neo-Brutalism is characterized by:
/// - Bold, thick black borders
/// - Vibrant, saturated colors
/// - Hard drop shadows with offset
/// - Simple, geometric shapes
/// - High contrast between elements
abstract final class NeoBrutalism {
  // ============================================================================
  // Color Palette
  // ============================================================================

  /// Primary colors - bright and saturated
  static const Color yellow = Color(0xFFFFE156);
  static const Color pink = Color(0xFFFF6B9D);
  static const Color blue = Color(0xFF4ECDC4);
  static const Color purple = Color(0xFFA855F7);
  static const Color orange = Color(0xFFFF8A50);
  static const Color green = Color(0xFF7FE86F);
  static const Color red = Color(0xFFFF5252);
  static const Color cyan = Color(0xFF00D4FF);

  /// Neutral colors
  static const Color black = Color(0xFF1A1A2E);
  static const Color white = Color(0xFFFFFDF0);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color grey = Color(0xFFE5E5E5);

  /// All accent colors for easy cycling
  static const List<Color> accentColors = [
    yellow,
    pink,
    blue,
    purple,
    orange,
    green,
    red,
    cyan,
  ];

  // ============================================================================
  // Border & Shadow Constants
  // ============================================================================

  /// Standard border width for Neo-Brutalism style
  static const double borderWidth = 3.0;

  /// Shadow offset for the characteristic drop shadow effect
  static const Offset shadowOffset = Offset(4, 4);

  /// Larger shadow for emphasis
  static const Offset shadowOffsetLarge = Offset(6, 6);

  /// Border radius for rounded corners (Neo-Brutalism often uses slight rounding)
  static const double borderRadius = 20.0;

  /// Smaller border radius
  static const double borderRadiusSmall = 8.0;

  // ============================================================================
  // Decorations
  // ============================================================================

  /// Standard Neo-Brutalism box decoration
  static ShapeDecoration shapeDecoration({
    Color? color,
    Color borderColor = black,
    double? radius,
    bool hasShadow = true,
    Offset? offset,
  }) {
    return ShapeDecoration(
      color: color ?? white,
      shape: RoundedSuperellipseBorder(
        side: BorderSide(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius ?? borderRadius),
      ),
      shadows: hasShadow
          ? [
              BoxShadow(
                color: borderColor,
                offset: offset ?? shadowOffset,
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  /// Circle decoration for avatars/icons
  static BoxDecoration circleDecoration({
    Color? color,
    Color borderColor = black,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? white,
      border: Border.all(color: borderColor, width: borderWidth),
      shape: BoxShape.circle,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: borderColor,
                offset: shadowOffset,
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  // ============================================================================
  // Theme Data
  // ============================================================================

  /// Generate MaterialApp theme data with Neo-Brutalism style
  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.light(
        primary: black,
        secondary: pink,
        surface: white,
        onPrimary: white,
        onSecondary: black,
        onSurface: black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: yellow,
        foregroundColor: black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: black, width: borderWidth),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
            side: const BorderSide(color: black, width: borderWidth),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: black,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: white,
        selectedColor: yellow,
        disabledColor: grey,
        labelStyle: const TextStyle(color: black, fontWeight: FontWeight.w600),
        side: const BorderSide(color: black, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: pink,
        inactiveTrackColor: grey,
        thumbColor: yellow,
        overlayColor: yellow.withValues(alpha: 0.2),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return yellow;
          }
          return white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return pink;
          }
          return grey;
        }),
        trackOutlineColor: WidgetStateProperty.all(black),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: black, width: borderWidth),
        ),
        titleTextStyle: const TextStyle(
          color: black,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: black,
        contentTextStyle: const TextStyle(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: black,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: black,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: black,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: black,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: black,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: black,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: black,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: black,
        ),
      ),
    );
  }

  /// Get accent color by index (cycles through available colors)
  static Color getAccentColor(int index) {
    return accentColors[index % accentColors.length];
  }
}
