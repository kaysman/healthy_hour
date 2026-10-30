import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/data/data.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:hive_ce/hive.dart';

void main() {
  final t0 = DateTime(2026, 10, 29, 9);

  late Directory dir;
  late Box<SessionModel> box;
  late HiveSessionRepository repo;

  Session work(String id, DateTime at, {DateTime? endedAt}) => Session(
        id: id,
        kind: ActivityKind.working,
        startedAt: at,
        endedAt: endedAt,
      );

  setUpAll(() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionModelAdapter());
    }
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hh_sessions_');
    Hive.init(dir.path);
    box = await Hive.openBox<SessionModel>('sessions');
    repo = HiveSessionRepository(box);
  });

  tearDown(() async {
    await repo.close();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('start, end, update and delete round-trip through Hive', () async {
    await repo.startSession(work('a', t0));
    expect(await repo.currentSession(), work('a', t0));

    final ended = await repo.endSession(
      'a',
      endedAt: t0.add(const Duration(minutes: 90)),
    );
    expect(ended.isOngoing, isFalse);
    expect(await repo.currentSession(), isNull);

    final moved = ended.copyWith(
      startedAt: t0.subtract(const Duration(minutes: 10)),
    );
    await repo.updateSession(moved);
    expect(box.get('a')!.toEntity(), moved);

    await repo.deleteSession('a');
    expect(box.isEmpty, isTrue);
  });

  test('ending an unknown session throws', () {
    expect(
      () => repo.endSession('missing', endedAt: t0),
      throwsStateError,
    );
  });

  test('currentSession is the latest session without endedAt', () async {
    await repo.startSession(work('old', t0));
    await repo.startSession(work('new', t0.add(const Duration(hours: 1))));

    expect((await repo.currentSession())?.id, 'new');
  });

  test('watchSessions filters by startedAt and sorts oldest first', () async {
    await repo.startSession(work('late', t0.add(const Duration(hours: 3))));
    await repo.startSession(
      work(
        'yesterday',
        t0.subtract(const Duration(days: 1)),
        endedAt: t0.subtract(const Duration(hours: 23)),
      ),
    );
    await repo.startSession(work('early', t0));

    final today = await repo
        .watchSessions(
          from: DateTime(2026, 10, 29),
          to: DateTime(2026, 10, 29, 23, 59),
        )
        .firstWhere((list) => list.length == 2);

    expect(today.map((s) => s.id), ['early', 'late']);
  });
}
