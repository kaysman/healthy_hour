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

/// End the current session and start the next. Toggles kind unless [to] is
/// given.
final class HomeSwitchActivityRequested extends HomeEvent {
  const HomeSwitchActivityRequested({this.to});
  final ActivityKind? to;

  @override
  List<Object?> get props => [to];
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

/// User tapped `+` on the Water card: log a drink now.
final class HomeDrinkLogged extends HomeEvent {
  const HomeDrinkLogged();
}
