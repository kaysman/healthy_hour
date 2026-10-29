import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/app.dart';
import 'package:healthy_hour/src/domain/domain.dart';

class _FakeSessionRepo implements SessionRepository {
  Session? _current;
  final _list = <Session>[];

  @override
  Future<Session?> currentSession() async => _current;

  @override
  Future<void> deleteSession(String id) async =>
      _list.removeWhere((s) => s.id == id);

  @override
  Future<Session> endSession(String id, {required DateTime endedAt}) async {
    final i = _list.indexWhere((s) => s.id == id);
    final s = _list[i].copyWith(endedAt: endedAt);
    _list[i] = s;
    if (_current?.id == id) _current = null;
    return s;
  }

  @override
  Future<Session> startSession(Session session) async {
    _list.add(session);
    _current = session;
    return session;
  }

  @override
  Future<Session> updateSession(Session session) async {
    final i = _list.indexWhere((s) => s.id == session.id);
    if (i >= 0) _list[i] = session;
    return session;
  }

  @override
  Stream<List<Session>> watchSessions({DateTime? from, DateTime? to}) =>
      Stream.value(List.unmodifiable(_list));
}

class _FakeSettingsRepo implements SettingsRepository {
  WorkingWindow _w = WorkingWindow.defaultWindow;
  TimerConfig _water = TimerConfig.water;
  TimerConfig _walk = TimerConfig.walking;

  @override
  Future<TimerConfig> getWalkingConfig() async => _walk;

  @override
  Future<TimerConfig> getWaterConfig() async => _water;

  @override
  Future<WorkingWindow> getWorkingWindow() async => _w;

  @override
  Future<void> setWalkingConfig(TimerConfig c) async => _walk = c;

  @override
  Future<void> setWaterConfig(TimerConfig c) async => _water = c;

  @override
  Future<void> setWorkingWindow(WorkingWindow w) async => _w = w;

  @override
  Stream<TimerConfig> watchWalkingConfig() => Stream.value(_walk);

  @override
  Stream<TimerConfig> watchWaterConfig() => Stream.value(_water);

  @override
  Stream<WorkingWindow> watchWorkingWindow() => Stream.value(_w);
}

void main() {
  testWidgets('App boots and shows the Home brand', (tester) async {
    await tester.pumpWidget(
      HealthyHourApp(
        sessions: _FakeSessionRepo(),
        settings: _FakeSettingsRepo(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('healthy-hour-brand')), findsOneWidget);
    expect(find.text('Healthy Hour'), findsNothing);
  });
}
