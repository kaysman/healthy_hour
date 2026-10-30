import 'dart:async';

import 'package:healthy_hour/src/domain/domain.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';

/// Stores drinks as a list of epoch milliseconds in the settings box, next to
/// the intervals they are measured against.
///
/// Only the last two days are kept: Home shows today, and nothing reads
/// further back, so the list never grows past a couple of dozen entries.
class HiveHydrationRepository implements HydrationRepository {
  HiveHydrationRepository(this._box, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _subject = BehaviorSubject.seeded(_read());
    _changes = _box
        .watch()
        .where((e) => e.key == _kDrinkLog || e.key == _kLegacyLastDrink)
        .listen((_) => _subject.add(_read()));
  }

  final Box<dynamic> _box;
  final DateTime Function() _clock;
  late final BehaviorSubject<List<DateTime>> _subject;
  late final StreamSubscription<BoxEvent> _changes;

  static const _kDrinkLog = 'drink_log_ms';

  /// Before the log existed only the last drink was stored, under this key.
  /// It is read as a one-entry log and folded into the real one on the next
  /// write.
  static const _kLegacyLastDrink = 'last_drink_at_ms';

  static const _retention = Duration(days: 2);

  List<DateTime> _read() {
    final log = (_box.get(_kDrinkLog) as List?)?.cast<int>();
    final legacy = _box.get(_kLegacyLastDrink) as int?;
    // A set, because between the two writes in [_write] the legacy drink
    // sits in both places for one box event.
    return {
      if (legacy != null) legacy,
      ...?log,
    }.map(DateTime.fromMillisecondsSinceEpoch).toList()
      ..sort();
  }

  Future<void> _write(List<DateTime> drinks) async {
    final cutoff = _clock().subtract(_retention);
    await _box.put(_kDrinkLog, [
      for (final d in drinks)
        if (!d.isBefore(cutoff)) d.millisecondsSinceEpoch,
    ]);
    await _box.delete(_kLegacyLastDrink);
  }

  @override
  Stream<DateTime?> watchLastDrink() =>
      _subject.stream.map((all) => all.isEmpty ? null : all.last).distinct();

  @override
  Stream<List<DateTime>> watchDrinks({DateTime? from}) => _subject.stream.map(
        (all) => [
          for (final d in all)
            if (from == null || !d.isBefore(from)) d,
        ],
      );

  @override
  Future<void> logDrink(DateTime at) => _write([..._subject.value, at]);

  @override
  Future<void> removeDrink(DateTime at) =>
      _write([..._subject.value]..remove(at));

  Future<void> close() async {
    await _changes.cancel();
    await _subject.close();
  }
}
