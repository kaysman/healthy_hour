import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';

import '../../helpers/fakes.dart';

void main() {
  final t0 = DateTime(2026, 10, 29, 9);

  late FakeSessionRepository repo;
  late SwitchActivity switchActivity;

  setUp(() {
    repo = FakeSessionRepository();
    switchActivity = SwitchActivity(repo);
  });

  test('with no current session, starts working', () async {
    final started = await switchActivity(now: t0, idGenerator: 'a');

    expect(started.kind, ActivityKind.working);
    expect(started.startedAt, t0);
    expect(await repo.currentSession(), started);
  });

  test('ends the current session and starts the opposite kind', () async {
    await switchActivity(now: t0, idGenerator: 'a');
    final t1 = t0.add(const Duration(minutes: 90));

    final walk = await switchActivity(now: t1, idGenerator: 'b');

    expect(walk.kind, ActivityKind.walking);
    expect(repo.all.first.endedAt, t1);
    expect(repo.all, hasLength(2));
    expect(await repo.currentSession(), walk);
  });

  test('discards a session shorter than a minute instead of ending it',
      () async {
    await switchActivity(now: t0, idGenerator: 'a');

    await switchActivity(
      now: t0.add(const Duration(seconds: 59)),
      idGenerator: 'b',
    );

    expect(repo.all.map((s) => s.id), ['b']);
  });

  test('keeps a session of exactly one minute', () async {
    await switchActivity(now: t0, idGenerator: 'a');

    await switchActivity(
      now: t0.add(const Duration(minutes: 1)),
      idGenerator: 'b',
    );

    expect(repo.all.map((s) => s.id), ['a', 'b']);
  });

  test('an explicit target kind overrides the toggle', () async {
    await switchActivity(now: t0, idGenerator: 'a');

    final next = await switchActivity(
      now: t0.add(const Duration(minutes: 30)),
      idGenerator: 'b',
      to: ActivityKind.working,
    );

    expect(next.kind, ActivityKind.working);
  });
}
