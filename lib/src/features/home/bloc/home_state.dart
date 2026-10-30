import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/domain.dart';

enum HomeStatus { initial, ready }

/// The habit Home is nudging you towards next.
enum Nudge { walk, water }

/// The last action that can still be taken back, shown as an Undo toast.
/// [serial] changes on every action, so logging two drinks in a row shows
/// the toast twice.
class HomeUndo extends Equatable {
  const HomeUndo({required this.serial, required this.message});

  final int serial;
  final String message;

  @override
  List<Object?> get props => [serial, message];
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.current,
    this.todaysSessions = const [],
    this.todaysDrinks = const [],
    this.workingWindow = WorkingWindow.defaultWindow,
    this.water = TimerConfig.water,
    this.walking = TimerConfig.walking,
    this.lastDrinkAt,
    this.undo,
    DateTime? now,
  }) : _now = now;

  final HomeStatus status;
  final Session? current;
  final List<Session> todaysSessions;

  /// Drinks logged since midnight, oldest first.
  final List<DateTime> todaysDrinks;
  final WorkingWindow workingWindow;
  final TimerConfig water;
  final TimerConfig walking;

  /// The last logged drink; `null` if none has been logged yet.
  final DateTime? lastDrinkAt;

  /// What the Undo toast would take back; `null` when there is nothing.
  final HomeUndo? undo;
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

  /// Whichever habit is due first; a walk wins a tie, since it also ends
  /// the sitting that caused it.
  Nudge get nextNudge =>
      walkingRemaining <= waterRemaining ? Nudge.walk : Nudge.water;

  /// Outside the working window nothing is due and no reminder fires, so
  /// Home stops counting down rather than nagging at 22:00.
  bool get isOffHours =>
      now.isBefore(workingWindow.startOn(now)) ||
      !now.isBefore(workingWindow.endOn(now));

  /// Today's working hours, each scored on walking and drinking.
  List<HealthyHour> get hours => healthyHours(
        now: now,
        window: workingWindow,
        sessions: todaysSessions,
        drinks: todaysDrinks,
      );

  HomeState copyWith({
    HomeStatus? status,
    Session? current,
    bool clearCurrent = false,
    List<Session>? todaysSessions,
    List<DateTime>? todaysDrinks,
    WorkingWindow? workingWindow,
    TimerConfig? water,
    TimerConfig? walking,
    DateTime? lastDrinkAt,
    bool clearLastDrink = false,
    HomeUndo? undo,
    bool clearUndo = false,
    DateTime? now,
  }) {
    return HomeState(
      status: status ?? this.status,
      current: clearCurrent ? null : (current ?? this.current),
      todaysSessions: todaysSessions ?? this.todaysSessions,
      todaysDrinks: todaysDrinks ?? this.todaysDrinks,
      workingWindow: workingWindow ?? this.workingWindow,
      water: water ?? this.water,
      walking: walking ?? this.walking,
      lastDrinkAt: clearLastDrink ? null : (lastDrinkAt ?? this.lastDrinkAt),
      undo: clearUndo ? null : (undo ?? this.undo),
      now: now ?? _now,
    );
  }

  @override
  List<Object?> get props => [
        status,
        current,
        todaysSessions,
        todaysDrinks,
        workingWindow,
        water,
        walking,
        lastDrinkAt,
        undo,
        _now,
      ];
}
