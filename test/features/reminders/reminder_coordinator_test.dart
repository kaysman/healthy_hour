import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/reminders/reminder_coordinator.dart';

import '../../helpers/fakes.dart';

class _RecordingScheduler implements ReminderScheduler {
  final plans = <List<Reminder>>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> replaceAll(List<Reminder> plan) async => plans.add(plan);
}

void main() {
  final now = DateTime(2026, 10, 29, 10);

  late FakeSessionRepository sessions;
  late FakeSettingsRepository settings;
  late FakeHydrationRepository hydration;
  late _RecordingScheduler scheduler;
  late ReminderCoordinator coordinator;

  List<ReminderKind> kinds(List<Reminder> plan) =>
      plan.map((r) => r.kind).toSet().toList()
        ..sort((a, b) => a.index - b.index);

  setUp(() {
    sessions = FakeSessionRepository();
    settings = FakeSettingsRepository();
    hydration = FakeHydrationRepository();
    scheduler = _RecordingScheduler();
    coordinator = ReminderCoordinator(
      sessions: sessions,
      settings: settings,
      hydration: hydration,
      scheduler: scheduler,
      clock: () => now,
    )..start();
  });

  tearDown(() => coordinator.stop());

  test('schedules a plan as soon as it starts', () async {
    await pumpEventQueue();

    expect(scheduler.plans, hasLength(1));
    expect(kinds(scheduler.plans.single), [ReminderKind.water]);
  });

  test('starting work adds walking reminders', () async {
    await pumpEventQueue();
    await SwitchActivity(sessions).call(now: now, idGenerator: 'w');
    await pumpEventQueue();

    expect(
      kinds(scheduler.plans.last),
      [ReminderKind.water, ReminderKind.walking],
    );
  });

  test('starting a walk drops them again', () async {
    await SwitchActivity(sessions).call(now: now, idGenerator: 'w');
    await pumpEventQueue();
    await SwitchActivity(sessions).call(
      now: now.add(const Duration(minutes: 40)),
      idGenerator: 'k',
    );
    await pumpEventQueue();

    expect(kinds(scheduler.plans.last), [ReminderKind.water]);
  });

  test('logging a drink reschedules water from the drink', () async {
    await pumpEventQueue();
    await hydration.logDrink(now);
    await pumpEventQueue();

    final water =
        scheduler.plans.last.where((r) => r.kind == ReminderKind.water).first;
    expect(water.at, now.add(TimerConfig.water.interval));
  });

  test('a settings change reschedules', () async {
    await pumpEventQueue();
    await settings.setWaterConfig(
      const TimerConfig(interval: Duration(minutes: 5)),
    );
    await pumpEventQueue();

    expect(scheduler.plans, hasLength(2));
  });

  test('an unchanged plan is not rescheduled', () async {
    await pumpEventQueue();
    await settings.setWaterConfig(TimerConfig.water);
    await pumpEventQueue();

    expect(scheduler.plans, hasLength(1));
  });
}
