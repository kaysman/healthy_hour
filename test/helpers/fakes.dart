import 'package:healthy_hour/src/domain/domain.dart';
import 'package:rxdart/rxdart.dart';

/// In-memory [SessionRepository] with the same observable behaviour as the
/// Hive one: every write re-emits the sorted list, `watchSessions` filters by
/// `startedAt`, and `currentSession` is the latest session with no `endedAt`.
class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository([List<Session> initial = const []])
      : _sessions = [...initial] {
    _subject.add(_snapshot());
  }

  final List<Session> _sessions;
  final _subject = BehaviorSubject<List<Session>>();

  /// Every session currently stored, oldest first.
  List<Session> get all => _snapshot();

  List<Session> _snapshot() =>
      [..._sessions]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  void _emit() => _subject.add(_snapshot());

  @override
  Stream<List<Session>> watchSessions({DateTime? from, DateTime? to}) {
    return _subject.stream.map(
      (all) => all.where((s) {
        if (from != null && s.startedAt.isBefore(from)) return false;
        if (to != null && s.startedAt.isAfter(to)) return false;
        return true;
      }).toList(),
    );
  }

  @override
  Future<Session?> currentSession() async {
    final ongoing = _snapshot().where((s) => s.isOngoing).toList();
    return ongoing.isEmpty ? null : ongoing.last;
  }

  @override
  Future<Session> startSession(Session session) async {
    _sessions.add(session);
    _emit();
    return session;
  }

  @override
  Future<Session> endSession(String id, {required DateTime endedAt}) async {
    final i = _sessions.indexWhere((s) => s.id == id);
    if (i < 0) throw StateError('Session $id not found');
    final ended = _sessions[i].copyWith(endedAt: endedAt);
    _sessions[i] = ended;
    _emit();
    return ended;
  }

  @override
  Future<Session> updateSession(Session session) async {
    // An upsert, like Hive's `put`: undoing a switch writes back a session
    // the switch may have deleted.
    _sessions
      ..removeWhere((s) => s.id == session.id)
      ..add(session);
    _emit();
    return session;
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    _emit();
  }
}

/// In-memory [SettingsRepository]; each setter re-emits on its stream.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    WorkingWindow window = WorkingWindow.defaultWindow,
    TimerConfig water = TimerConfig.water,
    TimerConfig walking = TimerConfig.walking,
  })  : _window = BehaviorSubject.seeded(window),
        _water = BehaviorSubject.seeded(water),
        _walking = BehaviorSubject.seeded(walking);

  final BehaviorSubject<WorkingWindow> _window;
  final BehaviorSubject<TimerConfig> _water;
  final BehaviorSubject<TimerConfig> _walking;

  @override
  Stream<WorkingWindow> watchWorkingWindow() => _window.stream;

  @override
  Future<WorkingWindow> getWorkingWindow() async => _window.value;

  @override
  Future<void> setWorkingWindow(WorkingWindow window) async =>
      _window.add(window);

  @override
  Stream<TimerConfig> watchWaterConfig() => _water.stream;

  @override
  Future<TimerConfig> getWaterConfig() async => _water.value;

  @override
  Future<void> setWaterConfig(TimerConfig config) async => _water.add(config);

  @override
  Stream<TimerConfig> watchWalkingConfig() => _walking.stream;

  @override
  Future<TimerConfig> getWalkingConfig() async => _walking.value;

  @override
  Future<void> setWalkingConfig(TimerConfig config) async =>
      _walking.add(config);
}

/// In-memory [HydrationRepository]: a sorted log of drinks.
class FakeHydrationRepository implements HydrationRepository {
  FakeHydrationRepository([List<DateTime> drinks = const []])
      : _drinks = BehaviorSubject.seeded([...drinks]..sort());

  final BehaviorSubject<List<DateTime>> _drinks;

  /// Every drink logged, oldest first, read synchronously.
  List<DateTime> get drinks => _drinks.value;

  /// The last drink logged, read synchronously.
  DateTime? get lastDrinkAt => drinks.isEmpty ? null : drinks.last;

  @override
  Stream<DateTime?> watchLastDrink() =>
      _drinks.stream.map((all) => all.isEmpty ? null : all.last).distinct();

  @override
  Stream<List<DateTime>> watchDrinks({DateTime? from}) => _drinks.stream.map(
        (all) => [
          for (final d in all)
            if (from == null || !d.isBefore(from)) d,
        ],
      );

  @override
  Future<void> logDrink(DateTime at) async =>
      _drinks.add([...drinks, at]..sort());

  @override
  Future<void> removeDrink(DateTime at) async =>
      _drinks.add([...drinks]..remove(at));
}

/// Hands out `id-1`, `id-2`, … so tests can assert on generated ids.
class SequentialIds {
  int _next = 1;

  String call() => 'id-${_next++}';
}
