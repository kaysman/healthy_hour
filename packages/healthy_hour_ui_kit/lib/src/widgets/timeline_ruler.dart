import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';

/// Pure painted ruler — no scrolling, fixed pixel dimensions. Use this when
/// the parent owns scrolling (e.g. inside `TimelineTrack`).
///
/// The ruler draws three tick weights, like a real ruler:
///   - **hour** ticks are tall and labelled `HH:00`
///   - **15-minute** ticks are medium height
///   - **5-minute** ticks are short
///
/// If [futureFrom] is non-null, every tick or label whose time is at or after
/// it is rendered in a muted "locked" tone, and the hour label is suppressed.
/// This lets a parent visually communicate that the area to the right of
/// `now` is unreachable (you can't have done something in the future).
class TimelineRulerCanvas extends StatelessWidget {
  const TimelineRulerCanvas({
    required this.start,
    required this.end,
    required this.now,
    super.key,
    this.height = 56,
    this.minutesPerPixel = 1.2,
    this.showNowMarker = true,
    this.futureFrom,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;
  final double height;
  final double minutesPerPixel;

  /// Whether to paint the green "now" marker on the ruler. Disable when the
  /// parent already shows a "Now" pill above the ruler.
  final bool showNowMarker;

  /// Time at and after which ticks/labels are dimmed. Defaults to `null`
  /// (no dimming). Pass `now` to mark the future as locked.
  final DateTime? futureFrom;

  /// Total painted width for the given time range.
  double get width => end.difference(start).inMinutes / minutesPerPixel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _RulerPainter(
          start: start,
          end: end,
          now: now,
          tickColor: c.textTertiary,
          tickColorStrong: c.textSecondary,
          labelColor: c.textSecondary,
          nowColor: c.success,
          minutesPerPixel: minutesPerPixel,
          showNowMarker: showNowMarker,
          futureFrom: futureFrom,
        ),
      ),
    );
  }
}

/// Horizontally-scrolling ruler. Useful in isolation; for the marker-aware
/// version use `TimelineTrack`.
class TimelineRuler extends StatelessWidget {
  const TimelineRuler({
    required this.start,
    required this.end,
    required this.now,
    super.key,
    this.height = 56,
    this.minutesPerPixel = 1.2,
    this.futureFrom,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;
  final double height;
  final double minutesPerPixel;
  final DateTime? futureFrom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: TimelineRulerCanvas(
        start: start,
        end: end,
        now: now,
        height: height,
        minutesPerPixel: minutesPerPixel,
        futureFrom: futureFrom,
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.start,
    required this.end,
    required this.now,
    required this.tickColor,
    required this.tickColorStrong,
    required this.labelColor,
    required this.nowColor,
    required this.minutesPerPixel,
    required this.showNowMarker,
    required this.futureFrom,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;
  final Color tickColor;
  final Color tickColorStrong;
  final Color labelColor;
  final Color nowColor;
  final double minutesPerPixel;
  final bool showNowMarker;
  final DateTime? futureFrom;

  // Tick lengths from baseline.
  static const double _majorTick = 14;
  static const double _midTick = 9;
  static const double _minorTick = 5;

  @override
  void paint(Canvas canvas, Size size) {
    // Baseline sits in the upper third so labels have room above and the
    // tallest tick still ends comfortably inside the canvas.
    final baselineY = (size.height * 0.4).roundToDouble();

    // Horizontal baseline line — a faint hairline that ties all the ticks
    // together, like the metal edge of a ruler.
    final baselinePaint = Paint()
      ..color = tickColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );

    final majorPaint = Paint()
      ..color = tickColorStrong
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final majorPaintDim = Paint()
      ..color = tickColorStrong.withValues(alpha: 0.3)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final midPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final midPaintDim = Paint()
      ..color = tickColor.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = tickColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    final minorPaintDim = Paint()
      ..color = tickColor.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;

    final totalMinutes = end.difference(start).inMinutes;
    final dimFromMinutes = futureFrom == null
        ? totalMinutes + 1
        : futureFrom!.difference(start).inMinutes;

    final tiers = _pickTiers(minutesPerPixel);

    // Wall-clock minute-of-day for `start`. We align ticks to clock
    // boundaries (e.g. HH:00, HH:15) rather than to `start` itself, so
    // labels read "14:00" at the actual top of the hour even when the
    // ruler begins mid-hour.
    final startWallMin = start.hour * 60 + start.minute;
    // Offset to the first wall-aligned tick (≥ start).
    final firstM = (tiers.step - (startWallMin % tiers.step)) % tiers.step;

    for (var m = firstM; m <= totalMinutes; m += tiers.step) {
      final x = m / minutesPerPixel;
      final dim = m >= dimFromMinutes;
      final wallMin = (startWallMin + m) % 1440;

      final isMajor = wallMin % tiers.major == 0;
      final isMid = !isMajor && wallMin % tiers.mid == 0;

      double tickLen;
      Paint paint;
      if (isMajor) {
        tickLen = _majorTick;
        paint = dim ? majorPaintDim : majorPaint;
      } else if (isMid) {
        tickLen = _midTick;
        paint = dim ? midPaintDim : midPaint;
      } else {
        tickLen = _minorTick;
        paint = dim ? minorPaintDim : minorPaint;
      }
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(x, baselineY + tickLen),
        paint,
      );

      if (isMajor && !dim) {
        final hh = (wallMin ~/ 60).toString().padLeft(2, '0');
        final mm = (wallMin % 60).toString().padLeft(2, '0');
        final label = tiers.minutePrecision ? '$hh:$mm' : '$hh:00';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, baselineY - tp.height - 4));
      }
    }

    if (showNowMarker && !now.isBefore(start) && !now.isAfter(end)) {
      final nowMinutes = now.difference(start).inMinutes;
      final x = nowMinutes / minutesPerPixel;

      // Vertical line spanning the full ruler height so it reads as a
      // boundary, not just a tick.
      final nowPaint = Paint()
        ..color = nowColor
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        nowPaint,
      );

      // Small downward triangle pinned to the baseline — points to the exact
      // current minute.
      final triangle = Path()
        ..moveTo(x, baselineY + 0.5)
        ..lineTo(x - 4, baselineY - 5)
        ..lineTo(x + 4, baselineY - 5)
        ..close();
      canvas.drawPath(triangle, Paint()..color = nowColor);
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.start != start ||
      old.end != end ||
      old.now != now ||
      old.tickColor != tickColor ||
      old.tickColorStrong != tickColorStrong ||
      old.labelColor != labelColor ||
      old.nowColor != nowColor ||
      old.minutesPerPixel != minutesPerPixel ||
      old.showNowMarker != showNowMarker ||
      old.futureFrom != futureFrom;
}

/// Tick / label intervals (in minutes) used by the ruler at a given zoom.
/// `step` divides `mid` divides `major`, so a single iteration at `step`
/// can decide each tick's tier with a couple of modulos.
class _RulerTiers {
  const _RulerTiers({
    required this.step,
    required this.mid,
    required this.major,
    required this.minutePrecision,
  });

  final int step;
  final int mid;
  final int major;
  final bool minutePrecision;
}

/// Pick the tier set whose label spacing reads cleanly at the given zoom.
/// The thresholds target ~24+ px between minor ticks and ~50+ px between
/// labels at typical viewport widths.
_RulerTiers _pickTiers(double minutesPerPixel) {
  final pxPerMin = 1 / minutesPerPixel;
  if (pxPerMin >= 24) {
    // Each minute is ≥24 px wide — label every minute.
    return const _RulerTiers(
      step: 1,
      mid: 1,
      major: 1,
      minutePrecision: true,
    );
  }
  if (pxPerMin >= 8) {
    // Tick every minute; label every 5 minutes.
    return const _RulerTiers(
      step: 1,
      mid: 5,
      major: 5,
      minutePrecision: true,
    );
  }
  if (pxPerMin >= 3) {
    // Tick every 5 min; label every 15 min.
    return const _RulerTiers(
      step: 5,
      mid: 15,
      major: 15,
      minutePrecision: true,
    );
  }
  if (pxPerMin >= 1) {
    // Default working zoom — tick every 5 min, mid every 15, label hourly.
    return const _RulerTiers(
      step: 5,
      mid: 15,
      major: 60,
      minutePrecision: false,
    );
  }
  if (pxPerMin >= 0.4) {
    // Tick every 15 min; label hourly.
    return const _RulerTiers(
      step: 15,
      mid: 30,
      major: 60,
      minutePrecision: false,
    );
  }
  // Sparsest — half-day overview.
  return const _RulerTiers(
    step: 30,
    mid: 60,
    major: 120,
    minutePrecision: false,
  );
}
