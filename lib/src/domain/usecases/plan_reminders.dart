import 'package:healthy_hour/src/domain/entities/countdowns.dart';
import 'package:healthy_hour/src/domain/entities/reminder.dart';
import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/entities/timer_config.dart';
import 'package:healthy_hour/src/domain/entities/working_window.dart';

/// iOS keeps at most 64 pending local notifications per app and silently
/// drops the rest. Staying under it leaves headroom; a fresh plan is made on
/// every input change and every launch, so the tail is never needed.
const maxPlannedReminders = 60;

/// Every reminder that should fire from [now] on, nearest first.
///
/// A pure function of the same timestamps the rings are drawn from, so what
/// the notifications say and what Home shows cannot disagree:
///
/// - Water repeats every `water.interval` from [waterCountdownStart] until
///   the window closes, then again from tomorrow's opening — so tomorrow
///   morning is covered even if the app is never opened.
/// - Walking repeats every `walking.interval` from the start of the ongoing
///   Working session, today only. Starting a walk ends that session and the
///   next plan simply has no walking reminders.
///
/// Nothing fires outside the working window.
List<Reminder> planReminders({
  required DateTime now,
  required WorkingWindow window,
  required TimerConfig water,
  required TimerConfig walking,
  Session? current,
  DateTime? lastDrinkAt,
}) {
  if (window.endMinutes <= window.startMinutes) return const [];

  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final due = <(ReminderKind, DateTime, Duration)>[
    ..._chain(
      ReminderKind.water,
      from: waterCountdownStart(
        now: now,
        window: window,
        lastDrinkAt: lastDrinkAt,
      ),
      every: water.interval,
      day: now,
      window: window,
      now: now,
    ),
    ..._chain(
      ReminderKind.water,
      from: window.startOn(tomorrow),
      every: water.interval,
      day: tomorrow,
      window: window,
      now: now,
    ),
  ];

  final walkFrom = walkingCountdownStart(current);
  if (walkFrom != null) {
    due.addAll(
      _chain(
        ReminderKind.walking,
        from: walkFrom,
        every: walking.interval,
        day: now,
        window: window,
        now: now,
      ),
    );
  }

  due.sort((a, b) => a.$2.compareTo(b.$2));
  return [
    for (final (i, (kind, at, overdueBy))
        in due.take(maxPlannedReminders).indexed)
      Reminder(id: i, kind: kind, at: at, overdueBy: overdueBy),
  ];
}

/// `from + k·every` for k ≥ 1, kept when it falls inside [day]'s window and
/// after [now].
Iterable<(ReminderKind, DateTime, Duration)> _chain(
  ReminderKind kind, {
  required DateTime from,
  required Duration every,
  required DateTime day,
  required WorkingWindow window,
  required DateTime now,
}) sync* {
  if (every <= Duration.zero) return;
  final opens = window.startOn(day);
  final closes = window.endOn(day);
  for (var at = from.add(every); !at.isAfter(closes); at = at.add(every)) {
    if (at.isAfter(now) && !at.isBefore(opens)) {
      yield (kind, at, at.difference(from));
    }
  }
}
