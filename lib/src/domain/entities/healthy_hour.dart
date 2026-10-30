import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/entities/activity_kind.dart';
import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/entities/working_window.dart';

/// Where an hour sits relative to now.
enum HourPhase { past, current, upcoming }

/// One clock hour of the working day, scored on the two habits: did you
/// walk, and did you drink. An hour with both is a *healthy hour*.
class HealthyHour extends Equatable {
  const HealthyHour({
    required this.start,
    required this.phase,
    required this.walked,
    required this.drank,
  });

  /// The top of the hour, e.g. 14:00.
  final DateTime start;
  final HourPhase phase;
  final bool walked;
  final bool drank;

  DateTime get end => start.add(const Duration(hours: 1));

  bool get isHealthy => walked && drank;

  @override
  List<Object?> get props => [start, phase, walked, drank];
}

/// Scores every clock hour that overlaps [window] on [now]'s date.
///
/// Whole clock hours rather than slices of the window: "the 14:00 hour" is
/// how people think about their day, and a 09:30 opening still gets its
/// 09:00 cell. An hour counts as walked when any walk overlaps it, so one
/// walk across 14:55–15:05 earns both hours.
List<HealthyHour> healthyHours({
  required DateTime now,
  required WorkingWindow window,
  required Iterable<Session> sessions,
  required Iterable<DateTime> drinks,
}) {
  if (window.endMinutes <= window.startMinutes) return const [];

  final firstHour = window.startMinutes ~/ 60;
  final lastHour = (window.endMinutes - 1) ~/ 60;
  final walks = sessions.where((s) => s.kind == ActivityKind.walking);

  return [
    for (var h = firstHour; h <= lastHour; h++)
      _score(
        DateTime(now.year, now.month, now.day, h),
        now: now,
        walks: walks,
        drinks: drinks,
      ),
  ];
}

HealthyHour _score(
  DateTime start, {
  required DateTime now,
  required Iterable<Session> walks,
  required Iterable<DateTime> drinks,
}) {
  final end = start.add(const Duration(hours: 1));
  return HealthyHour(
    start: start,
    phase: now.isBefore(start)
        ? HourPhase.upcoming
        : now.isBefore(end)
            ? HourPhase.current
            : HourPhase.past,
    walked: walks.any(
      (s) => s.startedAt.isBefore(end) && (s.endedAt ?? now).isAfter(start),
    ),
    drank: drinks.any((d) => !d.isBefore(start) && d.isBefore(end)),
  );
}
