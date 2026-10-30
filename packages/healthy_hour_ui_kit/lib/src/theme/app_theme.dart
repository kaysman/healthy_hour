import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Read by every AppBar, and by `AnnotatedRegion`s on screens without
      // one, so status-bar icons always contrast with the page.
      appBarTheme: AppBarTheme(systemOverlayStyle: _overlay(c, brightness)),
      snackBarTheme: _snackBar(c, brightness),
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// A dark toast in both themes with a lime action, so "Undo" reads at a
  /// glance. Material's default takes the action color from
  /// `inversePrimary`, which this scheme doesn't set — it came out as dark
  /// text on the dark toast.
  static SnackBarThemeData _snackBar(AppColors c, Brightness brightness) {
    final light = brightness == Brightness.light;
    return SnackBarThemeData(
      backgroundColor: light ? c.textPrimary : c.surfaceMuted,
      actionTextColor: c.brand,
      contentTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: light ? c.background : c.textPrimary,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    );
  }

  /// Transparent status bar so screen tints run edge to edge, with icons
  /// in the opposite brightness to the page: dark on light, light on dark.
  static SystemUiOverlayStyle _overlay(AppColors c, Brightness brightness) {
    final icons =
        brightness == Brightness.light ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons, // Android
      statusBarBrightness: brightness, // iOS: the bar's background
      systemNavigationBarColor: c.background,
      systemNavigationBarIconBrightness: icons,
    );
  }
}
