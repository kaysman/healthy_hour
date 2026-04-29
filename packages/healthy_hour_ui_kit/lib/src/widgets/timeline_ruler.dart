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
  static const double _hourTick = 14;
  static const double _quarterTick = 9;
  static const double _fiveTick = 5;

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

    final hourPaint = Paint()
      ..color = tickColorStrong
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final hourPaintDim = Paint()
      ..color = tickColorStrong.withValues(alpha: 0.3)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final quarterPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final quarterPaintDim = Paint()
      ..color = tickColor.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final fivePaint = Paint()
      ..color = tickColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    final fivePaintDim = Paint()
      ..color = tickColor.withValues(alpha: 0.18)
      ..strokeWidth = 0.6;

    final totalMinutes = end.difference(start).inMinutes;
    final dimFromMinutes = futureFrom == null
        ? totalMinutes + 1
        : futureFrom!.difference(start).inMinutes;

    // Step in 5-minute increments — every step we know which tier (hour /
    // quarter / five) it belongs to, so we can pick the right paint and
    // length without iterating minute-by-minute.
    for (var m = 0; m <= totalMinutes; m += 5) {
      final x = m / minutesPerPixel;
      final dim = m >= dimFromMinutes;

      double tickLen;
      Paint paint;
      if (m % 60 == 0) {
        tickLen = _hourTick;
        paint = dim ? hourPaintDim : hourPaint;
      } else if (m % 15 == 0) {
        tickLen = _quarterTick;
        paint = dim ? quarterPaintDim : quarterPaint;
      } else {
        tickLen = _fiveTick;
        paint = dim ? fivePaintDim : fivePaint;
      }
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(x, baselineY + tickLen),
        paint,
      );

      if (m % 60 == 0 && !dim) {
        final t = start.add(Duration(minutes: m));
        final label = '${t.hour.toString().padLeft(2, '0')}:00';
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
