import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color backgroundStart = Color(0xFF0E0E12); // Deep dark
  static const Color backgroundEnd = Color(0xFF161622); // Slightly lighter dark
  static const Color accentPurple = Color(0xFF7C3AED); // Neon Purple
  static const Color accentPurpleLight = Color(0xFF9F67FF); // Lighter purple for glow
  static const Color textMain = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;
  static const Color glassBackground = Colors.white10; // Semi-transparent
  static const Color glassBorder = Colors.white12;
  static const Color errorRed = Color(0xFFFF4C4C);
  static const Color successGreen = Color(0xFF00D97E);

  // Gradients
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    colors: [backgroundStart, backgroundEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accentPurple, accentPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle heading(BuildContext context) {
    return GoogleFonts.inter(
      color: textMain,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );
  }

  static TextStyle subheading(BuildContext context) {
    return GoogleFonts.inter(
      color: textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle body(BuildContext context) {
    return GoogleFonts.inter(
      color: textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle title(BuildContext context) {
    return GoogleFonts.inter(
      color: textMain,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle price(BuildContext context) {
    return GoogleFonts.inter(
      color: textMain,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }
}
