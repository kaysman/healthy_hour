import 'package:flutter/material.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// Today's working hours as a row of cells: a blue dot for water, a green
/// dot for a walk, and a lime cell when the hour got both.
///
/// Read in half a second, no gestures. Tapping an hour that has started
/// opens what was logged in it.
class HourGrid extends StatelessWidget {
  const HourGrid({required this.hours, required this.onHourTap, super.key});

  final List<HealthyHour> hours;
  final ValueChanged<HealthyHour> onHourTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final healthy = hours.where((h) => h.isHealthy).length;
    // Past a dozen cells the hour labels collide, so only every other one
    // is printed.
    final sparseLabels = hours.length > 12;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Today', style: text.titleSmall),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$healthy',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    TextSpan(text: ' / ${hours.length} healthy hours'),
                  ],
                ),
                key: const ValueKey('healthy-hour-score'),
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hours.isEmpty)
            Text(
              'Set your working hours to see your day.',
              style: text.bodySmall,
            )
          else
            Row(
              children: [
                for (final (i, hour) in hours.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: _HourCell(
                      key: ValueKey('hour-${hour.start.hour}'),
                      hour: hour,
                      showLabel: !sparseLabels || i.isEven,
                      onTap: hour.phase == HourPhase.upcoming
                          ? null
                          : () => onHourTap(hour),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _Legend(color: c.water, label: 'Water'),
              const SizedBox(width: AppSpacing.md),
              _Legend(color: c.walking, label: 'Walk'),
              const SizedBox(width: AppSpacing.md),
              _Legend(color: c.brand, label: 'Both', square: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  const _HourCell({
    required this.hour,
    required this.showLabel,
    required this.onTap,
    super.key,
  });

  final HealthyHour hour;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final upcoming = hour.phase == HourPhase.upcoming;
    final current = hour.phase == HourPhase.current;
    final off = c.textTertiary.withValues(alpha: 0.35);
    const radius = BorderRadius.all(AppRadii.xs);

    return Semantics(
      button: onTap != null,
      label: _describe(),
      excludeSemantics: true,
      child: Column(
        children: [
          Material(
            // Upcoming hours are hollow: the page color inside a hairline,
            // so the whole day is visible before it starts.
            color: upcoming
                ? c.background
                : hour.isHealthy
                    ? c.brand
                    : c.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: current
                  ? BorderSide(color: c.textPrimary, width: 1.5)
                  : upcoming
                      ? BorderSide(color: c.divider)
                      : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              // Full width of the slot: without it the cell shrinks to its
              // dots, and an upcoming cell (no dots) to nothing at all.
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: upcoming
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Dot(color: hour.drank ? c.water : off),
                          const SizedBox(height: AppSpacing.xxs),
                          _Dot(color: hour.walked ? c.walking : off),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            height: 14,
            child: showLabel
                ? Text(
                    '${hour.start.hour}',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 11,
                      fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      color: current ? c.textPrimary : c.textTertiary,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  String _describe() {
    final time = DurationFormatter.hhmm(hour.start);
    if (hour.phase == HourPhase.upcoming) return '$time, upcoming';
    final walk = hour.walked ? 'walked' : 'no walk';
    final water = hour.drank ? 'drank water' : 'no water';
    final now = hour.phase == HourPhase.current ? ', this hour' : '';
    return '$time$now: $walk, $water';
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.square = false,
  });

  final Color color;
  final String label;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: square ? BoxShape.rectangle : BoxShape.circle,
            borderRadius:
                square ? const BorderRadius.all(Radius.circular(2)) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs + 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
