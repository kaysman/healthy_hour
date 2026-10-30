import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/data/data.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;
  late Box<dynamic> box;
  late HiveHydrationRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hh_hydration_');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('settings');
    repo = HiveHydrationRepository(box);
  });

  tearDown(() async {
    await repo.close();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('starts with no drink logged', () async {
    expect(await repo.watchLastDrink().first, isNull);
  });

  test('a logged drink is emitted and survives a reopen', () async {
    final at = DateTime(2026, 10, 29, 10, 15);

    await repo.logDrink(at);
    expect(await repo.watchLastDrink().firstWhere((d) => d != null), at);

    final reopened = HiveHydrationRepository(box);
    expect(await reopened.watchLastDrink().first, at);
    await reopened.close();
  });

  test('keeps every drink, and lists them from a given moment', () async {
    final morning = DateTime(2026, 10, 29, 9, 5);
    final noon = DateTime(2026, 10, 29, 12);

    await repo.logDrink(noon);
    await repo.logDrink(morning);

    expect(await repo.watchDrinks().first, [morning, noon]);
    expect(
      await repo.watchDrinks(from: DateTime(2026, 10, 29, 10)).first,
      [noon],
    );
    expect(await repo.watchLastDrink().first, noon);
  });

  test('removing a drink falls back to the one before it', () async {
    final first = DateTime(2026, 10, 29, 9);
    final second = DateTime(2026, 10, 29, 10);
    await repo.logDrink(first);
    await repo.logDrink(second);

    await repo.removeDrink(second);

    expect(await repo.watchDrinks().first, [first]);
    expect(await repo.watchLastDrink().first, first);
  });

  test('reads the pre-log last drink and folds it into the log', () async {
    final legacy = DateTime(2026, 10, 29, 8);
    await repo.close();
    await box.put('last_drink_at_ms', legacy.millisecondsSinceEpoch);
    repo = HiveHydrationRepository(box, clock: () => legacy);

    expect(await repo.watchDrinks().first, [legacy]);

    final next = legacy.add(const Duration(minutes: 30));
    await repo.logDrink(next);

    expect(box.get('last_drink_at_ms'), isNull);
    expect(await repo.watchDrinks().first, [legacy, next]);
  });

  test('forgets drinks older than two days on the next write', () async {
    final now = DateTime(2026, 10, 29, 12);
    await repo.close();
    repo = HiveHydrationRepository(box, clock: () => now);

    await repo.logDrink(now.subtract(const Duration(days: 3)));
    await repo.logDrink(now);

    expect(await repo.watchDrinks().first, [now]);
  });
}
