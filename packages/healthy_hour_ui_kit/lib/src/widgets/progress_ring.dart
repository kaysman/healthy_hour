import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:healthy_hour_ui_kit/src/theme/app_colors.dart';

/// A circular progress ring with arbitrary content in the middle — the
/// countdown at the top of Home.
///
/// [progress] runs from 0 (empty track) to 1 (closed ring), drawn clockwise
/// from twelve o'clock.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.color,
    required this.child,
    super.key,
    this.size = 220,
    this.strokeWidth = 10,
  });

  final double progress;
  final Color color;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          trackColor: context.colors.surfaceMuted,
          strokeWidth: strokeWidth,
        ),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth * 2),
          child: Center(child: child),
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
