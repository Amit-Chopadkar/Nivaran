import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors (Constant)
  static const Color primaryPurple = Color(0xFF6D28D9); // Violet 700 for a richer look
  static const Color primaryPink = Color(0xFFE9D5FF); // Soft lavender/purple accent
  static const Color primaryRose = Color(0xFFF3E8FF); // Very soft lavender
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF7C3AED); // Violet 600
  static const Color gradientMiddle = Color(0xFF8B5CF6); // Violet 500
  static const Color gradientEnd = Color(0xFFA78BFA); // Violet 400
  
  // Risk Colors
  static const Color safeGreen = Color(0xFF22C55E); // Green 500
  static const Color cautionYellow = Color(0xFFF59E0B);
  static const Color dangerOrange = Color(0xFFF97316);
  static const Color dangerRed = Color(0xFFF15C5C); // Matched to vibrant red in image
  static const Color criticalRed = Color(0xFFEF4444); // Standard red
  
  // Accent Colors
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentViolet = Color(0xFF8B5CF6);

  // Dynamic Colors (Not const anymore)
  static Color darkBg = const Color(0xFF0F0F1A);
  static Color darkSurface = const Color(0xFF1A1A2E);
  static Color darkCard = const Color(0xFF16213E);
  static Color darkCardLight = const Color(0xFF1E2D4A);
  
  static Color textPrimary = const Color(0xFFF1F5F9);
  static Color textSecondary = const Color(0xFF94A3B8);
  static Color textMuted = const Color(0xFF64748B);
  
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [gradientStart, gradientMiddle, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get cardGradient => LinearGradient(
    colors: [darkCard, darkCardLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get sosGradient => const LinearGradient(
    colors: [Color(0xFFF15C5C), Color(0xFFEF4444), Color(0xFFDC2626)], // Updated to match dangerRed
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static void setLightMode() {
    darkBg = const Color(0xFFFAF5FF); // Very light lavender instead of plain white
    darkSurface = const Color(0xFFFFFFFF);
    darkCard = const Color(0xFFFFFFFF);
    darkCardLight = const Color(0xFFF3E8FF); // Soft lavender for cards
    
    textPrimary = const Color(0xFF0F172A);
    textSecondary = const Color(0xFF334155);
    textMuted = const Color(0xFF64748B);
  }

  static void setDarkMode() {
    darkBg = const Color(0xFF0F0F1A);
    darkSurface = const Color(0xFF1A1A2E);
    darkCard = const Color(0xFF16213E);
    darkCardLight = const Color(0xFF1E2D4A);
    
    textPrimary = const Color(0xFFF1F5F9);
    textSecondary = const Color(0xFF94A3B8);
    textMuted = const Color(0xFF64748B);
  }

  static BoxDecoration glassDecoration({
    Color? color,
    double opacity = 0.1,
    double borderRadius = 20,
    bool withBorder = true,
  }) {
    // Determine context based on current darkBg. If darkBg is bright, we are in light mode.
    final bool isLight = darkBg.computeLuminance() > 0.5;
    final Color baseColor = color ?? (isLight ? Colors.black : Colors.white);
    
    return BoxDecoration(
      color: baseColor.withValues(alpha: isLight ? opacity * 0.5 : opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder
          ? Border.all(
              color: baseColor.withValues(alpha: 0.08),
              width: 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration gradientCardDecoration({
    List<Color>? colors,
    double borderRadius = 20,
  }) {
    final bool isLight = darkBg.computeLuminance() > 0.5;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? [darkCard, darkCardLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: primaryPink,
        surface: Color(0xFFFFFFFF),
        error: dangerRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -1,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF334155),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF334155),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: primaryPurple,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPink,
        surface: Color(0xFF1A1A2E),
        error: dangerRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF1F5F9),
            letterSpacing: -1,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF1F5F9),
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF1F5F9),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFF1F5F9),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF94A3B8),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF94A3B8),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF1F5F9),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: primaryPurple,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E2D4A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
