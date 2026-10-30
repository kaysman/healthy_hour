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

/// User picked a new start time for a walk in the hour sheet.
final class HomeSessionEdited extends HomeEvent {
  const HomeSessionEdited(this.session);
  final Session session;

  @override
  List<Object?> get props => [session];
}

/// User deleted a walk in the hour sheet.
final class HomeSessionDeleted extends HomeEvent {
  const HomeSessionDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// User tapped "Drank water": log a drink now.
final class HomeDrinkLogged extends HomeEvent {
  const HomeDrinkLogged();
}

/// User deleted a drink in the hour sheet.
final class HomeDrinkDeleted extends HomeEvent {
  const HomeDrinkDeleted(this.at);
  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// User tapped Undo on the toast: take back the last walk/work switch or
/// drink.
final class HomeUndoRequested extends HomeEvent {
  const HomeUndoRequested();
}
