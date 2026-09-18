import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale (doc §4.3) built on Inter via google_fonts.
/// NOTE: GoogleFonts.* returns a non-const TextStyle — never wrap these in a
/// `const TextTheme(...)`. See AppTheme._base for correct (non-const) usage.
class AppTypography {
  AppTypography._();

  /// Display 28 / Bold
  static TextStyle display({Color? color}) =>
      GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, height: 1.3, color: color);

  /// Title 20 / SemiBold
  static TextStyle title({Color? color}) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: color);

  /// Body 15 / Regular
  static TextStyle body({Color? color}) =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5, color: color);

  /// Caption 12 / Medium
  static TextStyle caption({Color? color}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, color: color);
}
