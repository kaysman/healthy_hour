import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';
import 'package:healthy_hour_ui_kit/src/util/duration_formatter.dart';

/// Circular progress ring showing remaining time, like the Water/Walking
/// cards on Home.
class CircularTimer extends StatelessWidget {
  const CircularTimer({
    required this.remaining,
    required this.total,
    required this.label,
    required this.ringColor,
    super.key,
    this.icon,
    this.size = 120,
    this.strokeWidth = 6,
  });

  final Duration remaining;
  final Duration total;
  final String label;
  final Color ringColor;
  final Widget? icon;
  final double size;
  final double strokeWidth;

  double get _progress {
    if (total.inMilliseconds == 0) return 0;
    final p = remaining.inMilliseconds / total.inMilliseconds;
    return p.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: _progress,
          color: ringColor,
          trackColor: c.surfaceMuted,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                SizedBox(height: 22, child: icon),
                const SizedBox(height: 4),
              ],
              Text(
                DurationFormatter.ms(remaining),
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      ring,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
