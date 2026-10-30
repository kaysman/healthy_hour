import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_radii.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_spacing.dart';

enum AppButtonType { primary, secondary, tertiary }

enum AppButtonSize { small, medium, large }

enum AppButtonState { defaultState, disabled, error }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.large,
    this.state = AppButtonState.defaultState,
    this.leading,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final AppButtonState state;
  final Widget? leading;
  final Widget? trailing;

  bool get _disabled => state == AppButtonState.disabled || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final palette = _palette(c);

    final height = switch (size) {
      AppButtonSize.small => 32.0,
      AppButtonSize.medium => 44.0,
      AppButtonSize.large => 52.0,
    };
    final hPad = switch (size) {
      AppButtonSize.small => AppSpacing.md,
      AppButtonSize.medium => AppSpacing.lg,
      AppButtonSize.large => AppSpacing.xl,
    };
    final fontSize = switch (size) {
      AppButtonSize.small => 13.0,
      AppButtonSize.medium => 14.0,
      AppButtonSize.large => 16.0,
    };

    final fg = _disabled ? c.textTertiary : palette.fg;

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: label,
      child: SizedBox(
        height: height,
        child: Material(
          color: _disabled ? c.surfaceMuted : palette.bg,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.pillRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _disabled ? null : onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: fg, size: 18),
                      child: leading!,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    IconTheme.merge(
                      data: IconThemeData(color: fg, size: 18),
                      child: trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _Palette _palette(AppColors c) {
    if (state == AppButtonState.error) {
      return _Palette(bg: c.danger, fg: c.accentOn);
    }
    return switch (type) {
      AppButtonType.primary => _Palette(bg: c.brand, fg: c.brandOn),
      AppButtonType.secondary =>
        _Palette(bg: c.surfaceMuted, fg: c.textPrimary),
      AppButtonType.tertiary =>
        _Palette(bg: Colors.transparent, fg: c.textPrimary),
    };
  }
}

class _Palette {
  const _Palette({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}
