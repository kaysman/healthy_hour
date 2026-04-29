import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/bloc/home_event.dart';
import 'package:healthy_hour/src/features/home/bloc/home_state.dart';

typedef IdGenerator = String Function();
typedef Clock = DateTime Function();

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required SessionRepository sessions,
    required SettingsRepository settings,
    required SwitchActivity switchActivity,
    required GetTodaySessions getTodaySessions,
    required UpdateSession updateSession,
    required DeleteSession deleteSession,
    required IdGenerator idGenerator,
    Clock? clock,
  })  : _sessions = sessions,
        _settings = settings,
        _switchActivity = switchActivity,
        _getTodaySessions = getTodaySessions,
        _updateSession = updateSession,
        _deleteSession = deleteSession,
        _idGenerator = idGenerator,
        _clock = clock ?? DateTime.now,
        super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeTicked>(_onTicked);
    on<HomeSwitchActivityRequested>(_onSwitchRequested);
    on<HomeSessionSelected>(_onSessionSelected);
    on<HomeSessionEdited>(_onSessionEdited);
    on<HomeSessionDeleted>(_onSessionDeleted);
    on<HomeDataLoaded>(
      (e, emit) => emit(
        state.copyWith(
          todaysSessions: e.sessions,
          current: e.current,
          clearCurrent: e.current == null,
        ),
      ),
    );
    on<HomeWindowChanged>(
      (e, emit) => emit(state.copyWith(workingWindow: e.window)),
    );
    on<HomeWaterChanged>((e, emit) => emit(state.copyWith(water: e.config)));
    on<HomeWalkingChanged>(
      (e, emit) => emit(state.copyWith(walking: e.config)),
    );
  }

  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final SwitchActivity _switchActivity;
  final GetTodaySessions _getTodaySessions;
  final UpdateSession _updateSession;
  final DeleteSession _deleteSession;
  final IdGenerator _idGenerator;
  final Clock _clock;

  StreamSubscription<List<Session>>? _sessionsSub;
  StreamSubscription<WorkingWindow>? _windowSub;
  StreamSubscription<TimerConfig>? _waterSub;
  StreamSubscription<TimerConfig>? _walkingSub;
  Timer? _ticker;

  Future<void> _onStarted(HomeStarted e, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.ready, now: _clock()));

    await _sessionsSub?.cancel();
    _sessionsSub = _getTodaySessions(now: _clock()).listen((sessions) async {
      final current = await _sessions.currentSession();
      add(HomeDataLoaded(sessions: sessions, current: current));
    });

    await _windowSub?.cancel();
    _windowSub =
        _settings.watchWorkingWindow().listen((w) => add(HomeWindowChanged(w)));

    await _waterSub?.cancel();
    _waterSub =
        _settings.watchWaterConfig().listen((c) => add(HomeWaterChanged(c)));

    await _walkingSub?.cancel();
    _walkingSub = _settings
        .watchWalkingConfig()
        .listen((c) => add(HomeWalkingChanged(c)));

    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(HomeTicked(_clock())),
    );
  }

  void _onTicked(HomeTicked e, Emitter<HomeState> emit) {
    emit(state.copyWith(now: e.now));
  }

  Future<void> _onSwitchRequested(
    HomeSwitchActivityRequested e,
    Emitter<HomeState> emit,
  ) async {
    await _switchActivity(now: _clock(), idGenerator: _idGenerator());
    final current = await _sessions.currentSession();
    emit(state.copyWith(current: current, clearCurrent: current == null));
  }

  void _onSessionSelected(HomeSessionSelected e, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedId: e.id, clearSelection: e.id == null));
  }

  Future<void> _onSessionEdited(
    HomeSessionEdited e,
    Emitter<HomeState> emit,
  ) async {
    await _updateSession(e.session);
  }

  Future<void> _onSessionDeleted(
    HomeSessionDeleted e,
    Emitter<HomeState> emit,
  ) async {
    await _deleteSession(e.id);
    if (state.selectedId == e.id) {
      emit(state.copyWith(clearSelection: true));
    }
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _sessionsSub?.cancel();
    await _windowSub?.cancel();
    await _waterSub?.cancel();
    await _walkingSub?.cancel();
    return super.close();
  }
}

final class HomeDataLoaded extends HomeEvent {
  const HomeDataLoaded({required this.sessions, required this.current});
  final List<Session> sessions;
  final Session? current;

  @override
  List<Object?> get props => [sessions, current];
}

final class HomeWindowChanged extends HomeEvent {
  const HomeWindowChanged(this.window);
  final WorkingWindow window;

  @override
  List<Object?> get props => [window];
}

final class HomeWaterChanged extends HomeEvent {
  const HomeWaterChanged(this.config);
  final TimerConfig config;

  @override
  List<Object?> get props => [config];
}

final class HomeWalkingChanged extends HomeEvent {
  const HomeWalkingChanged(this.config);
  final TimerConfig config;

  @override
  List<Object?> get props => [config];
}
