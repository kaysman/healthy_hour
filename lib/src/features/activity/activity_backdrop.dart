import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/activity/activity_cubit.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

/// Full-screen background that tints with the current activity: green wash
/// while working, amber while walking, fading into the page background.
///
/// Wrap a screen's `Scaffold` (with a transparent background) in this so
/// every screen shows which mode you're in.
class ActivityBackdrop extends StatelessWidget {
  const ActivityBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kind = context.watch<ActivityCubit>().state;
    final tint = kind == ActivityKind.walking ? c.walkingTint : c.workingTint;
    // Screens without an AppBar (Home) still need the status-bar style.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tint, c.background],
            stops: const [0, 0.55],
          ),
        ),
        child: child,
      ),
    );
  }
}
