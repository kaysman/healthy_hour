import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:healthy_hour/src/core/core.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/bloc/home_event.dart';
import 'package:healthy_hour/src/features/home/bloc/home_state.dart';

typedef IdGenerator = String Function();

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required SessionRepository sessions,
    required SettingsRepository settings,
    required HydrationRepository hydration,
    required SwitchActivity switchActivity,
    required GetTodaySessions getTodaySessions,
    required UpdateSession updateSession,
    required DeleteSession deleteSession,
    required LogDrink logDrink,
    required RemoveDrink removeDrink,
    required UndoSwitchActivity undoSwitchActivity,
    required IdGenerator idGenerator,
    Clock? clock,
  })  : _sessions = sessions,
        _settings = settings,
        _hydration = hydration,
        _switchActivity = switchActivity,
        _getTodaySessions = getTodaySessions,
        _updateSession = updateSession,
        _deleteSession = deleteSession,
        _logDrink = logDrink,
        _removeDrink = removeDrink,
        _undoSwitchActivity = undoSwitchActivity,
        _idGenerator = idGenerator,
        _clock = clock ?? DateTime.now,
        super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeTicked>(_onTicked);
    on<HomeSwitchActivityRequested>(_onSwitchRequested);
    on<HomeSessionEdited>(_onSessionEdited);
    on<HomeSessionDeleted>(_onSessionDeleted);
    on<HomeDrinkLogged>(_onDrinkLogged);
    on<HomeDrinkDeleted>((e, _) => _removeDrink(e.at));
    on<HomeUndoRequested>(_onUndoRequested);
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
    on<HomeLastDrinkChanged>(
      (e, emit) => emit(
        state.copyWith(
          lastDrinkAt: e.at,
          clearLastDrink: e.at == null,
        ),
      ),
    );
    on<HomeDrinksChanged>(
      (e, emit) => emit(state.copyWith(todaysDrinks: e.drinks)),
    );
  }

  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final HydrationRepository _hydration;
  final SwitchActivity _switchActivity;
  final GetTodaySessions _getTodaySessions;
  final UpdateSession _updateSession;
  final DeleteSession _deleteSession;
  final LogDrink _logDrink;
  final RemoveDrink _removeDrink;
  final UndoSwitchActivity _undoSwitchActivity;
  final IdGenerator _idGenerator;
  final Clock _clock;

  StreamSubscription<List<Session>>? _sessionsSub;
  StreamSubscription<WorkingWindow>? _windowSub;
  StreamSubscription<TimerConfig>? _waterSub;
  StreamSubscription<TimerConfig>? _walkingSub;
  StreamSubscription<DateTime?>? _lastDrinkSub;
  StreamSubscription<List<DateTime>>? _drinksSub;
  Timer? _ticker;

  /// Takes back the last action; paired with [HomeState.undo].
  Future<void> Function()? _pendingUndo;
  int _undoSerial = 0;

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

    await _lastDrinkSub?.cancel();
    _lastDrinkSub = _hydration
        .watchLastDrink()
        .listen((at) => add(HomeLastDrinkChanged(at)));

    await _drinksSub?.cancel();
    _drinksSub = _hydration
        .watchDrinks(from: _clock().atStartOfDay)
        .listen((drinks) => add(HomeDrinksChanged(drinks)));

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
    final previous = await _sessions.currentSession();
    final started = await _switchActivity(
      now: _clock(),
      idGenerator: _idGenerator(),
      to: e.to,
    );
    final current = await _sessions.currentSession();
    emit(
      state.copyWith(
        current: current,
        clearCurrent: current == null,
        undo: _offerUndo(
          started.kind == ActivityKind.walking
              ? 'Walk started'
              : 'Back to work',
          () => _undoSwitchActivity(started: started, previous: previous),
        ),
      ),
    );
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
  }

  Future<void> _onDrinkLogged(
    HomeDrinkLogged e,
    Emitter<HomeState> emit,
  ) async {
    final at = _clock();
    await _logDrink(now: at);
    emit(
      state.copyWith(
        undo: _offerUndo('Drink logged', () => _removeDrink(at)),
      ),
    );
  }

  Future<void> _onUndoRequested(
    HomeUndoRequested e,
    Emitter<HomeState> emit,
  ) async {
    final undo = _pendingUndo;
    if (undo == null) return;
    _pendingUndo = null;
    await undo();
    final current = await _sessions.currentSession();
    emit(
      state.copyWith(
        current: current,
        clearCurrent: current == null,
        clearUndo: true,
      ),
    );
  }

  /// Arms [undo] as the one action Undo takes back, replacing any earlier
  /// one, and returns the toast to show for it.
  HomeUndo _offerUndo(String message, Future<void> Function() undo) {
    _pendingUndo = undo;
    return HomeUndo(serial: ++_undoSerial, message: message);
  }

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await _sessionsSub?.cancel();
    await _windowSub?.cancel();
    await _waterSub?.cancel();
    await _walkingSub?.cancel();
    await _lastDrinkSub?.cancel();
    await _drinksSub?.cancel();
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

final class HomeLastDrinkChanged extends HomeEvent {
  const HomeLastDrinkChanged(this.at);
  final DateTime? at;

  @override
  List<Object?> get props => [at];
}

final class HomeDrinksChanged extends HomeEvent {
  const HomeDrinksChanged(this.drinks);
  final List<DateTime> drinks;

  @override
  List<Object?> get props => [drinks];
}
