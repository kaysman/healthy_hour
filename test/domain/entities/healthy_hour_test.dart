import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';

void main() {
  final day = DateTime(2026, 10, 29);
  DateTime at(int h, [int m = 0]) => day.copyWith(hour: h, minute: m);

  Session walk(DateTime from, [DateTime? to]) => Session(
        id: '$from',
        kind: ActivityKind.walking,
        startedAt: from,
        endedAt: to,
      );

  List<HealthyHour> score({
    DateTime? now,
    WorkingWindow window = WorkingWindow.defaultWindow,
    List<Session> sessions = const [],
    List<DateTime> drinks = const [],
  }) =>
      healthyHours(
        now: now ?? at(12, 30),
        window: window,
        sessions: sessions,
        drinks: drinks,
      );

  test('one cell per clock hour of the window', () {
    final hours = score();

    expect(hours.map((h) => h.start.hour), [9, 10, 11, 12, 13, 14, 15, 16, 17]);
  });

  test('a window off the hour still gets its first and last hour', () {
    final hours = score(
      window: const WorkingWindow(
        startMinutes: 9 * 60 + 30,
        endMinutes: 17 * 60 + 15,
      ),
    );

    expect(hours.first.start, at(9));
    expect(hours.last.start, at(17));
  });

  test('an empty or inverted window has no hours', () {
    expect(
      score(window: const WorkingWindow(startMinutes: 600, endMinutes: 600)),
      isEmpty,
    );
  });

  test('phases split around now', () {
    final hours = score(now: at(10, 15));

    expect(hours[0].phase, HourPhase.past);
    expect(hours[1].phase, HourPhase.current);
    expect(hours[2].phase, HourPhase.upcoming);
  });

  test('an hour with a walk and a drink is healthy', () {
    final hours = score(
      sessions: [walk(at(9, 10), at(9, 20))],
      drinks: [at(9, 45)],
    );

    expect(hours.first.isHealthy, isTrue);
    expect(hours[1].walked || hours[1].drank, isFalse);
  });

  test('a walk across the hour earns both hours', () {
    final hours = score(sessions: [walk(at(9, 55), at(10, 5))]);

    expect(hours[0].walked, isTrue);
    expect(hours[1].walked, isTrue);
    expect(hours[2].walked, isFalse);
  });

  test('an ongoing walk counts up to now', () {
    final hours = score(now: at(10, 30), sessions: [walk(at(9, 50))]);

    expect(hours[0].walked, isTrue);
    expect(hours[1].walked, isTrue);
    expect(hours[2].walked, isFalse);
  });

  test('working sessions never count as walks', () {
    final hours = score(
      sessions: [
        Session(
          id: 'w',
          kind: ActivityKind.working,
          startedAt: at(9),
          endedAt: at(12),
        ),
      ],
    );

    expect(hours.any((h) => h.walked), isFalse);
  });

  test('a drink on the hour belongs to the hour it starts', () {
    final hours = score(drinks: [at(10)]);

    expect(hours[0].drank, isFalse);
    expect(hours[1].drank, isTrue);
  });
}
