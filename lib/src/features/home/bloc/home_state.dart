import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/domain.dart';

enum HomeStatus { initial, ready }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.current,
    this.todaysSessions = const [],
    this.workingWindow = WorkingWindow.defaultWindow,
    this.water = TimerConfig.water,
    this.walking = TimerConfig.walking,
    this.selectedId,
    this.lastDrinkAt,
    DateTime? now,
  }) : _now = now;

  final HomeStatus status;
  final Session? current;
  final List<Session> todaysSessions;
  final WorkingWindow workingWindow;
  final TimerConfig water;
  final TimerConfig walking;

  /// Currently selected session on the embedded timeline. `null` means
  /// nothing is selected (the floating actions card is hidden).
  final String? selectedId;

  /// The last logged drink; `null` if none has been logged yet.
  final DateTime? lastDrinkAt;
  final DateTime? _now;

  DateTime get now => _now ?? DateTime.now();

  ActivityKind get displayKind => current?.kind ?? ActivityKind.working;

  Duration get currentDuration => current?.durationAt(now) ?? Duration.zero;

  /// Time left until the next drink. Derived, like [currentDuration], from a
  /// stored timestamp and [now] — never counted down.
  Duration get waterRemaining => remainingOf(
        water.interval,
        start: waterCountdownStart(
          now: now,
          window: workingWindow,
          lastDrinkAt: lastDrinkAt,
        ),
        now: now,
      );

  /// Time left in the current Working session before a walk is due. Holds at
  /// the full interval while walking or idle.
  Duration get walkingRemaining {
    final start = walkingCountdownStart(current);
    if (start == null) return walking.interval;
    return remainingOf(walking.interval, start: start, now: now);
  }

  /// The session currently selected on the timeline, if any. Computed by
  /// looking [selectedId] up against [todaysSessions].
  Session? get selected {
    if (selectedId == null) return null;
    for (final s in todaysSessions) {
      if (s.id == selectedId) return s;
    }
    return null;
  }

  HomeState copyWith({
    HomeStatus? status,
    Session? current,
    bool clearCurrent = false,
    List<Session>? todaysSessions,
    WorkingWindow? workingWindow,
    TimerConfig? water,
    TimerConfig? walking,
    String? selectedId,
    bool clearSelection = false,
    DateTime? lastDrinkAt,
    bool clearLastDrink = false,
    DateTime? now,
  }) {
    return HomeState(
      status: status ?? this.status,
      current: clearCurrent ? null : (current ?? this.current),
      todaysSessions: todaysSessions ?? this.todaysSessions,
      workingWindow: workingWindow ?? this.workingWindow,
      water: water ?? this.water,
      walking: walking ?? this.walking,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      lastDrinkAt: clearLastDrink ? null : (lastDrinkAt ?? this.lastDrinkAt),
      now: now ?? _now,
    );
  }

  @override
  List<Object?> get props => [
        status,
        current,
        todaysSessions,
        workingWindow,
        water,
        walking,
        selectedId,
        lastDrinkAt,
        _now,
      ];
}
