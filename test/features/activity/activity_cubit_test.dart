import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/activity/activity.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 30, 10);

  late FakeSessionRepository sessions;

  setUp(() => sessions = FakeSessionRepository());

  blocTest<ActivityCubit, ActivityKind>(
    'is Working with nothing running',
    build: () => ActivityCubit(sessions),
    // Bloc always emits the first state, even when it equals the initial one.
    expect: () => [ActivityKind.working],
  );

  blocTest<ActivityCubit, ActivityKind>(
    'follows the ongoing session as it switches',
    build: () => ActivityCubit(sessions),
    act: (_) async {
      final switchActivity = SwitchActivity(sessions);
      await switchActivity(now: now, idGenerator: 'w');
      await switchActivity(
        now: now.add(const Duration(minutes: 50)),
        idGenerator: 'k',
      );
      await switchActivity(
        now: now.add(const Duration(minutes: 70)),
        idGenerator: 'w2',
      );
    },
    expect: () => [
      ActivityKind.working,
      ActivityKind.walking,
      ActivityKind.working,
    ],
  );
}
