import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:healthy_hour/src/domain/domain.dart';

/// App-wide "which mode am I in" — Working or Walking — for anything that
/// themes itself by it. Provided once above the router so every screen,
/// not just Home, can read it.
class ActivityCubit extends Cubit<ActivityKind> {
  ActivityCubit(SessionRepository sessions) : super(ActivityKind.working) {
    _sub = sessions
        .watchSessions()
        .map((all) => all.ongoing?.kind ?? ActivityKind.working)
        .listen(emit);
  }

  late final StreamSubscription<ActivityKind> _sub;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
