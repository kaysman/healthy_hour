import 'package:flutter/material.dart';

/// Brand and semantic colors for Healthy Hour. Values are sampled from the
/// reference designs (lime primary, orange "have a walk" CTA, soft tinted
/// backgrounds for working / walking states).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.brandOn,
    required this.accent,
    required this.accentOn,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.workingTint,
    required this.walkingTint,
    required this.water,
    required this.walking,
    required this.danger,
    required this.success,
    required this.divider,
  });

  final Color brand;
  final Color brandOn;
  final Color accent;
  final Color accentOn;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color workingTint;
  final Color walkingTint;
  final Color water;
  final Color walking;
  final Color danger;
  final Color success;
  final Color divider;

  static const light = AppColors(
    brand: Color(0xFFA6F234),
    brandOn: Color(0xFF0B1A06),
    accent: Color(0xFFE85A2A),
    accentOn: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    surfaceMuted: Color(0xFFEDEDED),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6B6B6B),
    textTertiary: Color(0xFF9A9A9A),
    workingTint: Color(0xFFE8F6D6),
    walkingTint: Color(0xFFFAF1D2),
    water: Color(0xFF4FA8FF),
    walking: Color(0xFF4CC38A),
    danger: Color(0xFFE85A2A),
    success: Color(0xFF34C759),
    divider: Color(0xFFE5E5E5),
  );

  static const dark = AppColors(
    brand: Color(0xFFA6F234),
    brandOn: Color(0xFF0B1A06),
    accent: Color(0xFFE85A2A),
    accentOn: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    surface: Color(0xFF1B1B1B),
    surfaceMuted: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8B8B8),
    textTertiary: Color(0xFF7A7A7A),
    workingTint: Color(0xFF15240A),
    walkingTint: Color(0xFF24210A),
    water: Color(0xFF4FA8FF),
    walking: Color(0xFF4CC38A),
    danger: Color(0xFFE85A2A),
    success: Color(0xFF34C759),
    // Slightly lighter than `surfaceMuted` so borders are visible.
    divider: Color(0xFF3A3A3A),
  );

  @override
  AppColors copyWith({
    Color? brand,
    Color? brandOn,
    Color? accent,
    Color? accentOn,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? workingTint,
    Color? walkingTint,
    Color? water,
    Color? walking,
    Color? danger,
    Color? success,
    Color? divider,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      brandOn: brandOn ?? this.brandOn,
      accent: accent ?? this.accent,
      accentOn: accentOn ?? this.accentOn,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      workingTint: workingTint ?? this.workingTint,
      walkingTint: walkingTint ?? this.walkingTint,
      water: water ?? this.water,
      walking: walking ?? this.walking,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandOn: Color.lerp(brandOn, other.brandOn, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      workingTint: Color.lerp(workingTint, other.workingTint, t)!,
      walkingTint: Color.lerp(walkingTint, other.walkingTint, t)!,
      water: Color.lerp(water, other.water, t)!,
      walking: Color.lerp(walking, other.walking, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
