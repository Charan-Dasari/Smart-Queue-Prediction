import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ─── Dark Mode Constants (exposed for inline use) ─────────────────────────
  static const Color darkSurface = Color(0xFF1A1730);
  static const Color darkBg = Color(0xFF0D0B14);
  static const Color darkBorder = Color(0xFF2A2645);

  /// Returns the correct border color based on current theme brightness.
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : borderColor;
  }

  // ─── Primary Palette ───────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C5CE7);     // Vibrant Purple
  static const Color primaryLight = Color(0xFFA29BFE);     // Periwinkle
  static const Color accentColor = Color(0xFFFF6B81);      // Coral Pink
  static const Color accentLight = Color(0xFFFFB8C6);      // Light Coral

  // ─── Background & Surface ─────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFFF8F7FF);  // Lavender Tint
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // ─── Text Colors ──────────────────────────────────────────────────────────
  static const Color textDarkColor = Color(0xFF1A1533);    // Purple-Navy
  static const Color textMutedColor = Color(0xFF6B6588);   // Purple-Gray
  static const Color textLightColor = Color(0xFFA9A3C2);   // Lavender Muted

  /// Returns the primary text color based on current theme brightness.
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : textDarkColor;
  }

  /// Returns muted text color based on current theme brightness.
  static Color getMutedTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9E98B9)
        : textMutedColor;
  }

  /// Returns the card background color based on current theme brightness.
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : cardColor;
  }

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color errorColor = Color(0xFFFF4757);       // Soft Red
  static const Color successColor = Color(0xFF2ED573);     // Emerald Green
  static const Color warningColor = Color(0xFFFFA502);     // Warm Amber
  static const Color infoColor = Color(0xFF5B8DEF);        // Soft Blue

  // ─── Queue & AI Colors ────────────────────────────────────────────────────
  static const Color queueLow = Color(0xFF2ED573);         // Green — low crowd
  static const Color queueMedium = Color(0xFFFFA502);      // Amber — moderate
  static const Color queueHigh = Color(0xFFFF4757);        // Red — high crowd
  static const Color aiAccent = Color(0xFF6C5CE7);         // Purple — AI features
  static const Color aiAccentLight = Color(0xFFE8E5FF);    // Light Purple Tint

  // ─── Staff Panel Colors ─────────────────────────────────────────────────
  static const Color staffColor = Color(0xFF0891B2);        // Cyan
  static const Color staffLight = Color(0xFF22D3EE);        // Light Cyan

  // ─── Category Colors ──────────────────────────────────────────────────────
  static const Color hospitalColor = Color(0xFF5B8DEF);    // Blue
  static const Color bankColor = Color(0xFF2ED573);        // Green
  static const Color govtColor = Color(0xFFFFA502);        // Amber
  static const Color collegeColor = Color(0xFFA29BFE);     // Periwinkle
  static const Color restaurantColor = Color(0xFFFF6B81);  // Coral
  static const Color otherColor = Color(0xFF8B85A8);       // Muted Lavender

  // ─── Border & Divider ─────────────────────────────────────────────────────
  static const Color borderColor = Color(0xFFE8E5F0);
  static const Color dividerColor = Color(0xFFF3F1FA);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF5B8DEF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B81), Color(0xFFFF8E9E)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6C5CE7), Color(0xFF1A1533)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ED573), Color(0xFF05C46B)],
  );

  static const LinearGradient staffGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
  );

  // ─── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDarkColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // ── Plus Jakarta Sans — Professional Modern Dashboard Typography ──
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textDarkColor,
            letterSpacing: -0.8,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textDarkColor,
            letterSpacing: -0.4,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDarkColor,
            letterSpacing: -0.2,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textDarkColor,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: textDarkColor,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: textMutedColor,
            height: 1.5,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: textMutedColor,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: primaryColor,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: const BorderSide(color: borderColor, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: borderColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: borderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: errorColor, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textDarkColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDarkColor,
        ),
        shape: const Border(
          bottom: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLightColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F1FA),
        selectedColor: primaryColor.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: borderColor),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static Future<void> loadUserTheme(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode_$userId') ?? false;
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      themeNotifier.value = ThemeMode.light;
    }
  }

  static Future<void> setUserTheme(String? userId, bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    if (userId != null && userId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_dark_mode_$userId', isDark);
      } catch (_) {}
    }
  }

  static void resetToLight() {
    themeNotifier.value = ThemeMode.light;
  }

  static ThemeData get darkTheme {
    const darkAccent = Color(0xFFE8C547);    // Golden Yellow

    return ThemeData(
      useMaterial3: true,
      cardColor: darkSurface,
      dialogBackgroundColor: darkSurface,
      canvasColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C6FE4),          // Bright Purple
        secondary: darkAccent,
        surface: darkSurface,
        surfaceContainer: darkSurface,
        surfaceContainerHigh: darkSurface,
        surfaceContainerHighest: darkSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Color(0xFF1A1533),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBg,
      // ── Plus Jakarta Sans — Professional Dark Mode Typography ──
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: Colors.white,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF8B85A8),       // Muted Lavender
            height: 1.5,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF6B6588),
            height: 1.4,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: darkAccent,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFF7C6FE4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: errorColor, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C6FE4),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7C6FE4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.darkBorder, width: 1.0),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: const Border(
          bottom: BorderSide(color: darkBorder, width: 1.0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: Color(0xFFE8C547),   // Golden selected
        unselectedItemColor: Color(0xFF6B6588),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7C6FE4),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkBorder,
        selectedColor: const Color(0xFF7C6FE4).withValues(alpha: 0.25),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: darkBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: darkSurface,
      ),
    );
  }
}

class UserThemeWrapper extends StatelessWidget {
  final Widget child;
  const UserThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeMode, _) {
        return Theme(
          data: themeMode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          child: child,
        );
      },
    );
  }
}
