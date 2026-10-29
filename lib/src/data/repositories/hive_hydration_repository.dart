import 'dart:async';

import 'package:healthy_hour/src/domain/domain.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';

/// Stores the last drink as epoch milliseconds in the settings box, next to
/// the intervals it is measured against.
class HiveHydrationRepository implements HydrationRepository {
  HiveHydrationRepository(this._box) {
    _subject = BehaviorSubject.seeded(_read());
    _changes =
        _box.watch(key: _kLastDrink).listen((_) => _subject.add(_read()));
  }

  final Box<dynamic> _box;
  late final BehaviorSubject<DateTime?> _subject;
  late final StreamSubscription<BoxEvent> _changes;

  static const _kLastDrink = 'last_drink_at_ms';

  DateTime? _read() {
    final ms = _box.get(_kLastDrink) as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Stream<DateTime?> watchLastDrink() => _subject.stream;

  @override
  Future<void> logDrink(DateTime at) =>
      _box.put(_kLastDrink, at.millisecondsSinceEpoch);

  Future<void> close() async {
    await _changes.cancel();
    await _subject.close();
  }
}
