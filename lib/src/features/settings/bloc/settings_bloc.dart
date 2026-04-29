import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/settings/bloc/settings_event.dart';
import 'package:healthy_hour/src/features/settings/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepository repository})
      : _repo = repository,
        super(const SettingsState()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsWindowChanged>(_onWindow);
    on<SettingsWaterChanged>(_onWater);
    on<SettingsWalkingChanged>(_onWalking);
    on<_SettingsHydrated>((e, emit) => emit(e.state));
  }

  final SettingsRepository _repo;
  StreamSubscription<WorkingWindow>? _windowSub;
  StreamSubscription<TimerConfig>? _waterSub;
  StreamSubscription<TimerConfig>? _walkingSub;

  Future<void> _onStarted(
    SettingsStarted e,
    Emitter<SettingsState> emit,
  ) async {
    final window = await _repo.getWorkingWindow();
    final water = await _repo.getWaterConfig();
    final walking = await _repo.getWalkingConfig();
    emit(SettingsState(window: window, water: water, walking: walking));

    _windowSub = _repo.watchWorkingWindow().listen(
          (w) => add(_SettingsHydrated(state.copyWith(window: w))),
        );
    _waterSub = _repo.watchWaterConfig().listen(
          (c) => add(_SettingsHydrated(state.copyWith(water: c))),
        );
    _walkingSub = _repo.watchWalkingConfig().listen(
          (c) => add(_SettingsHydrated(state.copyWith(walking: c))),
        );
  }

  Future<void> _onWindow(
    SettingsWindowChanged e,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(window: e.window));
    await _repo.setWorkingWindow(e.window);
  }

  Future<void> _onWater(
    SettingsWaterChanged e,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(water: e.config));
    await _repo.setWaterConfig(e.config);
  }

  Future<void> _onWalking(
    SettingsWalkingChanged e,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(walking: e.config));
    await _repo.setWalkingConfig(e.config);
  }

  @override
  Future<void> close() async {
    await _windowSub?.cancel();
    await _waterSub?.cancel();
    await _walkingSub?.cancel();
    return super.close();
  }
}

final class _SettingsHydrated extends SettingsEvent {
  const _SettingsHydrated(this.state);
  final SettingsState state;

  @override
  List<Object?> get props => [state];
}
