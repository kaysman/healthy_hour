import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/home.dart';

void main() {
  const twentyMinutes = TimerConfig(interval: Duration(minutes: 20));
  final now = DateTime(2026, 10, 29, 10);

  HomeState stateAt(
    DateTime now, {
    Session? current,
    DateTime? lastDrinkAt,
  }) =>
      HomeState(
        now: now,
        current: current,
        lastDrinkAt: lastDrinkAt,
        water: twentyMinutes,
        walking: twentyMinutes,
      );

  group('waterRemaining', () {
    test('counts down from the last drink', () {
      final state = stateAt(
        now,
        lastDrinkAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(state.waterRemaining, const Duration(minutes: 15));
    });

    test('is zero when a drink is overdue', () {
      // No drink logged; the default window opened at 09:00, an hour ago.
      expect(stateAt(now).waterRemaining, Duration.zero);
    });

    test('is full before the working window opens', () {
      expect(
        stateAt(DateTime(2026, 10, 29, 7)).waterRemaining,
        twentyMinutes.interval,
      );
    });

    test('moves with every tick without anything being stored', () {
      final drink = now.subtract(const Duration(minutes: 5));
      final later = stateAt(now, lastDrinkAt: drink)
          .copyWith(now: now.add(const Duration(minutes: 3)));

      expect(later.waterRemaining, const Duration(minutes: 12));
    });
  });

  group('walkingRemaining', () {
    test('counts down from the start of the working session', () {
      final state = stateAt(
        now,
        current: Session(
          id: 'w',
          kind: ActivityKind.working,
          startedAt: now.subtract(const Duration(minutes: 8)),
        ),
      );

      expect(state.walkingRemaining, const Duration(minutes: 12));
    });

    test('holds at the full interval while walking', () {
      final state = stateAt(
        now,
        current: Session(
          id: 'k',
          kind: ActivityKind.walking,
          startedAt: now.subtract(const Duration(minutes: 8)),
        ),
      );

      expect(state.walkingRemaining, twentyMinutes.interval);
    });

    test('holds at the full interval with nothing running', () {
      expect(stateAt(now).walkingRemaining, twentyMinutes.interval);
    });
  });
}
