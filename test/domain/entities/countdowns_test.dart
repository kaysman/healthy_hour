import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';

void main() {
  const window = WorkingWindow.defaultWindow;
  final opening = DateTime(2026, 10, 29, 9);

  group('WorkingWindow', () {
    test('startOn / endOn land on the given calendar day', () {
      final day = DateTime(2026, 10, 29, 23, 30);

      expect(window.startOn(day), opening);
      expect(window.endOn(day), DateTime(2026, 10, 29, 18));
    });
  });

  group('waterCountdownStart', () {
    final now = DateTime(2026, 10, 29, 11);

    test('with no drink logged, runs from the window opening', () {
      expect(waterCountdownStart(now: now, window: window), opening);
    });

    test("a drink from today's window is the anchor", () {
      final drink = DateTime(2026, 10, 29, 10, 15);

      expect(
        waterCountdownStart(now: now, window: window, lastDrinkAt: drink),
        drink,
      );
    });

    test("yesterday's drink is ignored; each day starts fresh", () {
      final yesterday = DateTime(2026, 10, 28, 17);

      expect(
        waterCountdownStart(now: now, window: window, lastDrinkAt: yesterday),
        opening,
      );
    });
  });

  group('walkingCountdownStart', () {
    final start = DateTime(2026, 10, 29, 9, 30);

    test('is the start of an ongoing working session', () {
      final work =
          Session(id: 'w', kind: ActivityKind.working, startedAt: start);

      expect(walkingCountdownStart(work), start);
    });

    test('is null while walking or idle', () {
      final walk =
          Session(id: 'k', kind: ActivityKind.walking, startedAt: start);

      expect(walkingCountdownStart(walk), isNull);
      expect(walkingCountdownStart(null), isNull);
    });
  });

  group('remainingOf', () {
    const interval = Duration(minutes: 25);
    final start = DateTime(2026, 10, 29, 9);

    test('subtracts the elapsed time', () {
      expect(
        remainingOf(
          interval,
          start: start,
          now: start.add(const Duration(minutes: 10)),
        ),
        const Duration(minutes: 15),
      );
    });

    test('bottoms out at zero once overdue', () {
      expect(
        remainingOf(
          interval,
          start: start,
          now: start.add(const Duration(hours: 1)),
        ),
        Duration.zero,
      );
    });

    test('a start still in the future leaves the full interval', () {
      expect(
        remainingOf(
          interval,
          start: start,
          now: start.subtract(const Duration(hours: 1)),
        ),
        interval,
      );
    });
  });
}
