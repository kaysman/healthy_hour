import 'dart:async';

import 'package:healthy_hour/src/domain/domain.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box) {
    _windowSubject = BehaviorSubject.seeded(_readWindow());
    _waterSubject = BehaviorSubject.seeded(_readTimer(_kWater, _defaultWater));
    _walkingSubject =
        BehaviorSubject.seeded(_readTimer(_kWalking, _defaultWalking));

    _box.watch().listen((event) {
      _windowSubject.add(_readWindow());
      _waterSubject.add(_readTimer(_kWater, _defaultWater));
      _walkingSubject.add(_readTimer(_kWalking, _defaultWalking));
    });
  }

  final Box<dynamic> _box;
  late final BehaviorSubject<WorkingWindow> _windowSubject;
  late final BehaviorSubject<TimerConfig> _waterSubject;
  late final BehaviorSubject<TimerConfig> _walkingSubject;

  static const _kWindowStart = 'window_start';
  static const _kWindowEnd = 'window_end';
  static const _kWater = 'water_interval_seconds';
  static const _kWalking = 'walking_interval_seconds';

  static const _defaultWater = TimerConfig.water;
  static const _defaultWalking = TimerConfig.walking;

  WorkingWindow _readWindow() {
    final start = _box.get(_kWindowStart) as int? ??
        WorkingWindow.defaultWindow.startMinutes;
    final end =
        _box.get(_kWindowEnd) as int? ?? WorkingWindow.defaultWindow.endMinutes;
    return WorkingWindow(startMinutes: start, endMinutes: end);
  }

  TimerConfig _readTimer(String key, TimerConfig fallback) {
    final seconds = _box.get(key) as int?;
    if (seconds == null) return fallback;
    return TimerConfig(interval: Duration(seconds: seconds));
  }

  @override
  Stream<WorkingWindow> watchWorkingWindow() => _windowSubject.stream;

  @override
  Future<WorkingWindow> getWorkingWindow() async => _readWindow();

  @override
  Future<void> setWorkingWindow(WorkingWindow window) async {
    await _box.put(_kWindowStart, window.startMinutes);
    await _box.put(_kWindowEnd, window.endMinutes);
  }

  @override
  Stream<TimerConfig> watchWaterConfig() => _waterSubject.stream;

  @override
  Future<TimerConfig> getWaterConfig() async =>
      _readTimer(_kWater, _defaultWater);

  @override
  Future<void> setWaterConfig(TimerConfig config) =>
      _box.put(_kWater, config.interval.inSeconds);

  @override
  Stream<TimerConfig> watchWalkingConfig() => _walkingSubject.stream;

  @override
  Future<TimerConfig> getWalkingConfig() async =>
      _readTimer(_kWalking, _defaultWalking);

  @override
  Future<void> setWalkingConfig(TimerConfig config) =>
      _box.put(_kWalking, config.interval.inSeconds);
}
