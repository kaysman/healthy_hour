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
}
