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
  final DateTime? _now;

  DateTime get now => _now ?? DateTime.now();

  ActivityKind get displayKind => current?.kind ?? ActivityKind.working;

  Duration get currentDuration => current?.durationAt(now) ?? Duration.zero;

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
        _now,
      ];
}
