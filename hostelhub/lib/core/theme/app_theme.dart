import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Light + dark ThemeData. Glass surfaces are transparent (scaffold background
/// is transparent) so the GlassBackground gradient shows through and the
/// BackdropFilter cards have something to refract.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    return _base(scheme, isDark: false);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
    );
    return _base(scheme, isDark: true);
  }

  static ThemeData _base(ColorScheme scheme, {required bool isDark}) {
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.baseDarkA : AppColors.baseLightA,
      // iOS falls back to Flutter's native Cupertino swipe-back by default.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
      // NOT const — the styles are built on GoogleFonts (runtime-resolved).
      textTheme: TextTheme(
        displayLarge: AppTypography.display(color: text),
        displayMedium: AppTypography.display(color: text),
        titleLarge: AppTypography.title(color: text),
        titleMedium: AppTypography.title(color: text),
        bodyLarge: AppTypography.body(color: text),
        bodyMedium: AppTypography.body(color: muted),
        bodySmall: AppTypography.caption(color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: AppTypography.caption(color: muted),
        hintStyle: AppTypography.body(color: muted),
      ),
    );
  }
}
