import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';

void main() {
  // 09:00–18:00, 60-minute water and 50-minute walking intervals.
  const window = WorkingWindow.defaultWindow;
  const hourly = TimerConfig(interval: Duration(hours: 1));
  const fiftyMinutes = TimerConfig(interval: Duration(minutes: 50));

  DateTime at(int hour, [int minute = 0, int day = 29]) =>
      DateTime(2026, 10, day, hour, minute);

  List<Reminder> plan({
    required DateTime now,
    Session? current,
    DateTime? lastDrinkAt,
    WorkingWindow window = window,
    TimerConfig water = hourly,
    TimerConfig walking = fiftyMinutes,
  }) =>
      planReminders(
        now: now,
        window: window,
        water: water,
        walking: walking,
        current: current,
        lastDrinkAt: lastDrinkAt,
      );

  Iterable<DateTime> timesOf(List<Reminder> r, ReminderKind kind) =>
      r.where((x) => x.kind == kind).map((x) => x.at);

  Session working(DateTime from) =>
      Session(id: 'w', kind: ActivityKind.working, startedAt: from);

  group('water', () {
    test('runs hourly from the window opening when nothing is logged', () {
      final r = plan(now: at(7));

      expect(timesOf(r, ReminderKind.water).take(3), [at(10), at(11), at(12)]);
    });

    test('a drink restarts the chain from the drink', () {
      final r = plan(now: at(10, 40), lastDrinkAt: at(10, 30));

      expect(
        timesOf(r, ReminderKind.water).take(2),
        [at(11, 30), at(12, 30)],
      );
    });

    test('stops at the window close and resumes tomorrow morning', () {
      final r = plan(now: at(16, 10), lastDrinkAt: at(16));

      expect(
        timesOf(r, ReminderKind.water).take(4),
        [at(17), at(18), at(10, 0, 30), at(11, 0, 30)],
      );
    });

    test('never schedules anything in the past', () {
      final now = at(13, 15);

      expect(plan(now: now).every((r) => r.at.isAfter(now)), isTrue);
    });

    test('overdueBy is how long the countdown has run', () {
      final r = plan(now: at(10, 40), lastDrinkAt: at(10, 30));

      expect(r.first.overdueBy, const Duration(hours: 1));
      expect(r[1].overdueBy, const Duration(hours: 2));
    });

    test('a shorter interval means more reminders', () {
      final r = plan(
        now: at(9),
        water: const TimerConfig(interval: Duration(minutes: 30)),
      );

      expect(timesOf(r, ReminderKind.water).take(2), [at(9, 30), at(10)]);
    });
  });

  group('walking', () {
    test('repeats from the start of the working session', () {
      final r = plan(now: at(9, 5), current: working(at(9)));

      expect(
        timesOf(r, ReminderKind.walking).take(3),
        [at(9, 50), at(10, 40), at(11, 30)],
      );
    });

    test('only today: an overnight session does not nag tomorrow', () {
      final r = plan(now: at(17, 30), current: working(at(9)));

      expect(
        timesOf(r, ReminderKind.walking).every((t) => t.day == 29),
        isTrue,
      );
    });

    test('nothing while walking', () {
      final r = plan(
        now: at(11),
        current: Session(
          id: 'k',
          kind: ActivityKind.walking,
          startedAt: at(10, 50),
        ),
      );

      expect(timesOf(r, ReminderKind.walking), isEmpty);
    });

    test('nothing with no session running', () {
      expect(timesOf(plan(now: at(11)), ReminderKind.walking), isEmpty);
    });
  });

  group('the plan as a whole', () {
    test('is sorted nearest first with unique ids', () {
      final r = plan(now: at(9, 5), current: working(at(9)));

      final times = r.map((x) => x.at).toList();
      expect(times, [...times]..sort());
      expect(r.map((x) => x.id).toSet(), hasLength(r.length));
    });

    test('nothing falls outside the working window', () {
      final r = plan(now: at(6), current: working(at(6)));

      for (final x in r) {
        expect(x.at.isBefore(window.startOn(x.at)), isFalse);
        expect(x.at.isAfter(window.endOn(x.at)), isFalse);
      }
    });

    test('is capped under the iOS pending-notification limit', () {
      const every5 = TimerConfig(interval: Duration(minutes: 5));
      final r = plan(
        now: at(9),
        current: working(at(9)),
        water: every5,
        walking: every5,
      );

      expect(r, hasLength(maxPlannedReminders));
      expect(r.last.at.day, 29);
    });

    test('an empty or inverted window plans nothing', () {
      expect(
        plan(
          now: at(10),
          current: working(at(9)),
          window: const WorkingWindow(startMinutes: 600, endMinutes: 600),
        ),
        isEmpty,
      );
    });

    test('a zero interval plans nothing instead of looping', () {
      expect(
        plan(
          now: at(10),
          current: working(at(9)),
          water: const TimerConfig(interval: Duration.zero),
          walking: const TimerConfig(interval: Duration.zero),
        ),
        isEmpty,
      );
    });
  });
}
