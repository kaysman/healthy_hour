import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final text = AppTypography.buildTextTheme(c.textPrimary, c.textSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.brand,
        onPrimary: c.brandOn,
        secondary: c.accent,
        onSecondary: c.accentOn,
        error: c.danger,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      textTheme: text,
      iconTheme: IconThemeData(color: c.textPrimary),
      dividerColor: c.divider,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
