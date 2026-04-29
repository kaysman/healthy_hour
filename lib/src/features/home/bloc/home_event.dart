import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/domain.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeTicked extends HomeEvent {
  const HomeTicked(this.now);
  final DateTime now;

  @override
  List<Object?> get props => [now];
}

final class HomeSwitchActivityRequested extends HomeEvent {
  const HomeSwitchActivityRequested();
}

/// User tapped a session bar on the embedded timeline. `null` to clear.
final class HomeSessionSelected extends HomeEvent {
  const HomeSessionSelected(this.id);
  final String? id;

  @override
  List<Object?> get props => [id];
}

/// User confirmed a new start time for a past session via the edit picker.
final class HomeSessionEdited extends HomeEvent {
  const HomeSessionEdited(this.session);
  final Session session;

  @override
  List<Object?> get props => [session];
}

/// User tapped the trash icon on a selected session.
final class HomeSessionDeleted extends HomeEvent {
  const HomeSessionDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
