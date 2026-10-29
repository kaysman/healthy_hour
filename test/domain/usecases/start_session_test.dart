import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';

import '../../helpers/fakes.dart';

void main() {
  final t0 = DateTime(2026, 10, 29, 9);

  late FakeSessionRepository repo;
  late StartSession startSession;

  setUp(() {
    repo = FakeSessionRepository();
    startSession = StartSession(repo);
  });

  test('starts a session of the requested kind', () async {
    final s = await startSession(
      kind: ActivityKind.walking,
      now: t0,
      idGenerator: 'a',
    );

    expect(s.kind, ActivityKind.walking);
    expect(await repo.currentSession(), s);
  });

  test('ends the current session before starting the next', () async {
    await startSession(kind: ActivityKind.working, now: t0, idGenerator: 'a');
    final t1 = t0.add(const Duration(minutes: 10));

    await startSession(kind: ActivityKind.working, now: t1, idGenerator: 'b');

    expect(repo.all.first.endedAt, t1);
    expect((await repo.currentSession())?.id, 'b');
  });

  test('discards a current session shorter than a minute', () async {
    await startSession(kind: ActivityKind.working, now: t0, idGenerator: 'a');

    await startSession(
      kind: ActivityKind.walking,
      now: t0.add(const Duration(seconds: 30)),
      idGenerator: 'b',
    );

    expect(repo.all.map((s) => s.id), ['b']);
  });
}
