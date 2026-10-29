import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';

void main() {
  final start = DateTime(2026, 10, 29, 9);

  group('Session', () {
    test('an ongoing session measures up to the given moment', () {
      final s = Session(id: 'a', kind: ActivityKind.working, startedAt: start);

      expect(s.isOngoing, isTrue);
      expect(
        s.durationAt(start.add(const Duration(minutes: 42))),
        const Duration(minutes: 42),
      );
    });

    test('an ended session ignores the moment and uses endedAt', () {
      final s = Session(
        id: 'a',
        kind: ActivityKind.walking,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 20)),
      );

      expect(s.isOngoing, isFalse);
      expect(
        s.durationAt(start.add(const Duration(hours: 5))),
        const Duration(minutes: 20),
      );
    });

    test('moving startedAt changes the derived duration', () {
      final s = Session(id: 'a', kind: ActivityKind.working, startedAt: start);
      final moved =
          s.copyWith(startedAt: start.subtract(const Duration(minutes: 10)));
      final now = start.add(const Duration(minutes: 5));

      expect(moved.durationAt(now), const Duration(minutes: 15));
    });
  });

  group('ActivityKind.opposite', () {
    test('flips between working and walking', () {
      expect(ActivityKind.working.opposite, ActivityKind.walking);
      expect(ActivityKind.walking.opposite, ActivityKind.working);
    });
  });
}
