import 'package:healthy_hour/src/domain/entities/activity_kind.dart';
import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/entities/working_window.dart';

/// Where the water countdown runs from: the last logged drink, but never
/// earlier than the opening of today's working window, so every day starts
/// with a full ring instead of inheriting yesterday's.
DateTime waterCountdownStart({
  required DateTime now,
  required WorkingWindow window,
  DateTime? lastDrinkAt,
}) {
  final opening = window.startOn(now);
  if (lastDrinkAt == null || lastDrinkAt.isBefore(opening)) return opening;
  return lastDrinkAt;
}

/// Where the walking countdown runs from: the start of the ongoing Working
/// session. `null` while walking or idle — there is nothing to count down to.
DateTime? walkingCountdownStart(Session? current) {
  if (current == null || current.kind != ActivityKind.working) return null;
  return current.startedAt;
}

/// What is left of [interval] once [start] has passed, clamped to
/// `[0, interval]`. A [start] in the future leaves the full interval.
Duration remainingOf(
  Duration interval, {
  required DateTime start,
  required DateTime now,
}) {
  final left = interval - now.difference(start);
  if (left.isNegative) return Duration.zero;
  if (left > interval) return interval;
  return left;
}
