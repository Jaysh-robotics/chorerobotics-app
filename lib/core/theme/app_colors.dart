import 'package:flutter/material.dart';

/// ChoreRobotics brand colors derived from logo spectrum.
/// Logo: blue → purple → magenta → red → pink → silver
class AppColors {
  AppColors._();

  // ── Brand Spectrum (from logo) ──
  static const Color brandBlue = Color(0xFF3B5EE8);
  static const Color brandPurple = Color(0xFF8B45B5);
  static const Color brandMagenta = Color(0xFFD63384);
  static const Color brandRed = Color(0xFFEF3350);
  static const Color brandPink = Color(0xFFF5758C);
  static const Color brandSilver = Color(0xFFC8CDD5);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandBlue, brandPurple, brandMagenta, brandRed, brandSilver],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const LinearGradient brandGradientHorizontal = LinearGradient(
    colors: [brandBlue, brandPurple, brandMagenta, brandRed, brandSilver],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const LinearGradient bluePurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandPurple],
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
  static const Color statusGreen = Color(0xFF00C853);
  static const Color accentYellow = Color(0xFFFFB300);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color accentCyan = Color(0xFF00BCD4);

  // ── Safety ──
  static const Color estopRed = Color(0xFFFF3B30);
  static const Color estopYellow = Color(0xFFFFD600);

  // ── Borders ──
  static const Color border = Color(0x0FFFFFFF); // 6% white
  static const Color borderActive = Color(0x24FFFFFF); // 14% white

  // ── Dim variants ──
  static Color blueDim = brandBlue.withValues(alpha: 0.10);
  static Color purpleDim = brandPurple.withValues(alpha: 0.10);
  static Color magentaDim = brandMagenta.withValues(alpha: 0.10);
  static Color greenDim = statusGreen.withValues(alpha: 0.08);
  static Color yellowDim = accentYellow.withValues(alpha: 0.08);
  static Color redDim = accentRed.withValues(alpha: 0.10);
  static Color orangeDim = accentOrange.withValues(alpha: 0.08);
}
