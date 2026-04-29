import 'package:flutter/material.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// The big avatar+title+timer cluster at the top of Home.
class ActivityHero extends StatelessWidget {
  const ActivityHero({
    required this.kind,
    required this.duration,
    super.key,
  });

  final ActivityKind kind;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (emoji, title) = switch (kind) {
      ActivityKind.working => ('🧑‍💻', 'Working'),
      ActivityKind.walking => ('👟', 'Walking'),
    };
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          DurationFormatter.hms(duration),
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: c.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
