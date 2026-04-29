import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_radii.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_spacing.dart';

/// Pill-shaped badge used in the top-right of the Home screen
/// ("Working Time" / "Adjust").
class PillBadge extends StatelessWidget {
  const PillBadge({
    required this.label,
    super.key,
    this.leading,
    this.onTap,
    this.tone = PillTone.neutral,
  });

  final String label;
  final Widget? leading;
  final VoidCallback? onTap;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      PillTone.neutral => (c.surfaceMuted, c.textPrimary),
      PillTone.brand => (c.brand, c.brandOn),
    };
    return Material(
      color: bg,
      borderRadius: AppRadii.pillRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: fg, size: 16),
                  child: leading!,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PillTone { neutral, brand }
