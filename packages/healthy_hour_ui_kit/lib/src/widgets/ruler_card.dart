import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_spacing.dart';
import 'package:healthy_hour_ui_kit/src/widgets/timeline_ruler.dart';

/// Rounded surface card containing a non-scrolling, edge-to-edge ruler. Used
/// on Home as a glanceable timeline strip.
///
/// The ruler auto-fits its width — `start` to `end` always spans the full
/// available horizontal space, so the entire range is visible without
/// scrolling. For a scrollable, marker-aware version see `TimelineTrack`.
class RulerCard extends StatelessWidget {
  const RulerCard({
    required this.start,
    required this.end,
    required this.now,
    super.key,
    this.height = 56,
    this.showNowMarker = true,
    this.futureFrom,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;
  final double height;
  final bool showNowMarker;

  /// Optional moment from which ticks/labels are dimmed to indicate a
  /// locked / unreachable future. Pass [now] to dim everything to the right
  /// of the current time.
  final DateTime? futureFrom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalMinutes = end.difference(start).inMinutes;
        // Fit the entire range into the available width.
        final minutesPerPixel = totalMinutes / constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: ColoredBox(
            color: c.surfaceMuted,
            child: SizedBox(
              height: height,
              width: constraints.maxWidth,
              child: TimelineRulerCanvas(
                start: start,
                end: end,
                now: now,
                height: height,
                minutesPerPixel: minutesPerPixel,
                showNowMarker: showNowMarker,
                futureFrom: futureFrom,
              ),
            ),
          ),
        );
      },
    );
  }
}
