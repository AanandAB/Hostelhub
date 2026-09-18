import 'package:flutter/material.dart';

/// HostelHub color tokens (product doc §4.2). One class holds light + dark.
class AppColors {
  AppColors._();

  // ── Brand (light / dark) ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF5B7FFF);
  static const Color primaryDark = Color(0xFF7C9BFF);

  static const Color accent = Color(0xFF00D9C0); // success, mess "Yes"
  static const Color accentDark = Color(0xFF33E6CF);

  static const Color warning = Color(0xFFFFB020); // due-soon
  static const Color warningDark = Color(0xFFFFC454);

  static const Color danger = Color(0xFFFF5C5C); // overdue, failed, SOS
  static const Color dangerDark = Color(0xFFFF7A7A);

  // ── Base backgrounds (gradient endpoints) ─────────────────────────────────
  static const Color baseLightA = Color(0xFFEAF0FF);
  static const Color baseLightB = Color(0xFFF7F5FF);
  static const Color baseDarkA = Color(0xFF0E0E16);
  static const Color baseDarkB = Color(0xFF1B1B2A);

  // ── Glass surfaces ────────────────────────────────────────────────────────
  /// rgba(255,255,255,0.55)
  static const Color glassLight = Color(0x8CFFFFFF);
  /// rgba(30,30,40,0.45)
  static const Color glassDark = Color(0x731E1E28);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textLight = Color(0xFF1B1B2A);
  static const Color textMutedLight = Color(0xFF5A6178);
  static const Color textDark = Color(0xFFF2F3F7);
  static const Color textMutedDark = Color(0xFF9AA0B4);
}
