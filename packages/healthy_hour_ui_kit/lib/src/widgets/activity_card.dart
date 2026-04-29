import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/icons/app_icons.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_radii.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_spacing.dart';

/// Wrapper card used for the Water and Walking timers on Home — rounded card
/// with a circular timer body, a settings icon bottom-left and an action
/// (typically `+`) bottom-right.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.body,
    super.key,
    this.onConfigure,
    this.onAdd,
  });

  final Widget body;
  final VoidCallback? onConfigure;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: body),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CornerIconButton(
                onPressed: onConfigure,
                child: AppIcons.settings(size: 18, color: c.textSecondary),
              ),
              _CornerIconButton(
                onPressed: onAdd,
                child: Icon(Icons.add, size: 20, color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerIconButton extends StatelessWidget {
  const _CornerIconButton({required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceMuted,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: child),
        ),
      ),
    );
  }
}
