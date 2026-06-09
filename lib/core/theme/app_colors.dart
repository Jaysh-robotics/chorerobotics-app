import 'package:flutter/material.dart';

/// ChoreRobotics brand colors derived from the logo:
/// orange hex mark + vivid green scan + tan "ROBOTICS" wordmark on black.
class AppColors {
  AppColors._();

  // ── Brand Spectrum (sampled directly from logo image) ──
  static const Color brandOrange = Color(0xFFFC8502); // primary mark color
  static const Color brandGreen = Color(0xFF2DA801); // scan underline / live signal
  static const Color brandTan = Color(0xFFAD6C20); // "ROBOTICS" sub-wordmark
  static const Color brandAmber = Color(0xFFFFA940); // soft fade of orange
  static const Color brandRed = Color(0xFFEF3350); // safety / alerts
  static const Color brandSilver = Color(0xFFC8CDD5);

  // Legacy aliases — old call sites keep compiling, but render in new brand hues.
  static const Color brandBlue = brandOrange;
  static const Color brandPurple = brandGreen;
  static const Color brandMagenta = brandTan;
  static const Color brandPink = brandAmber;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandOrange, brandAmber, brandTan, brandGreen, brandSilver],
    stops: [0.0, 0.30, 0.55, 0.80, 1.0],
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    colors: [brandOrange, brandAmber, brandGreen],
    stops: [0.0, 0.55, 1.0],
  );

  // Primary "hero" gradient — used by progress bars, avatar chips, etc.
  static const LinearGradient bluePurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrange, brandAmber],
  );

  static const LinearGradient orangeGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrange, brandGreen],
  );

  // ── Backgrounds ──
  static const Color bgPrimary = Color(0xFF0A0C10);
  static const Color bgSecondary = Color(0xFF10131A);
  static const Color bgCard = Color(0xFF151820);
  static const Color bgCardHover = Color(0xFF1A1E28);
  static const Color bgSurface = Color(0xFF0D0F14);
  static const Color bgPage = Color(0xFF050608);

  // ── Text ──
  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF8B929E);
  static const Color textMuted = Color(0xFF555D6E);

  // ── Functional Status Colors ──
  // statusGreen now aligns with the brand green for consistency.
  static const Color statusGreen = brandGreen;
  static const Color accentYellow = Color(0xFFFFB300);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentOrange = brandOrange;
  static const Color accentCyan = Color(0xFF00BCD4);

  // ── Safety ──
  static const Color estopRed = Color(0xFFFF3B30);
  static const Color estopYellow = Color(0xFFFFD600);

  // ── Borders ──
  static const Color border = Color(0x0FFFFFFF); // 6% white
  static const Color borderActive = Color(0x24FFFFFF); // 14% white

  // ── Dim variants ──
  static Color orangeDim = brandOrange.withValues(alpha: 0.10);
  static Color greenDim = brandGreen.withValues(alpha: 0.10);
  static Color tanDim = brandTan.withValues(alpha: 0.10);
  static Color amberDim = brandAmber.withValues(alpha: 0.10);
  static Color yellowDim = accentYellow.withValues(alpha: 0.08);
  static Color redDim = accentRed.withValues(alpha: 0.10);

  // Legacy aliases
  static Color blueDim = orangeDim;
  static Color purpleDim = greenDim;
  static Color magentaDim = tanDim;
}
