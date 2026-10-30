import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/core/core.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/home.dart';

import '../../helpers/fakes.dart';

void main() {
  final now = DateTime(2026, 10, 29, 10);

  late FakeSessionRepository sessions;
  late FakeSettingsRepository settings;
  late FakeHydrationRepository hydration;

  HomeBloc buildBloc({Clock? clock}) => HomeBloc(
        sessions: sessions,
        settings: settings,
        hydration: hydration,
        switchActivity: SwitchActivity(sessions),
        getTodaySessions: GetTodaySessions(sessions),
        updateSession: UpdateSession(sessions),
        deleteSession: DeleteSession(sessions),
        logDrink: LogDrink(hydration),
        removeDrink: RemoveDrink(hydration),
        undoSwitchActivity: UndoSwitchActivity(sessions),
        idGenerator: SequentialIds().call,
        clock: clock ?? () => now,
      );

  final pastWalk = Session(
    id: 'walk',
    kind: ActivityKind.walking,
    startedAt: now.subtract(const Duration(hours: 2)),
    endedAt: now.subtract(const Duration(hours: 1, minutes: 40)),
  );
  final ongoingWork = Session(
    id: 'work',
    kind: ActivityKind.working,
    startedAt: now.subtract(const Duration(hours: 1, minutes: 40)),
  );

  final freshWork = Session(
    id: 'fresh',
    kind: ActivityKind.working,
    startedAt: now.subtract(const Duration(seconds: 20)),
  );
  final pastDrink = now.subtract(const Duration(minutes: 40));

  setUp(() {
    sessions = FakeSessionRepository();
    settings = FakeSettingsRepository();
    hydration = FakeHydrationRepository();
  });

  group('HomeStarted', () {
    blocTest<HomeBloc, HomeState>(
      'becomes ready with now taken from the injected clock',
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [HomeState(status: HomeStatus.ready, now: now)],
    );

    blocTest<HomeBloc, HomeState>(
      "loads today's sessions and the ongoing one",
      setUp: () => sessions = FakeSessionRepository([pastWalk, ongoingWork]),
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [
        HomeState(status: HomeStatus.ready, now: now),
        HomeState(
          status: HomeStatus.ready,
          now: now,
          todaysSessions: [pastWalk, ongoingWork],
          current: ongoingWork,
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      "ignores sessions that didn't start today",
      setUp: () => sessions = FakeSessionRepository([
        Session(
          id: 'yesterday',
          kind: ActivityKind.working,
          startedAt: now.subtract(const Duration(days: 1)),
          endedAt: now.subtract(const Duration(hours: 20)),
        ),
      ]),
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [HomeState(status: HomeStatus.ready, now: now)],
    );

    blocTest<HomeBloc, HomeState>(
      'picks up settings changes as they happen',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        await settings.setWaterConfig(
          const TimerConfig(interval: Duration(minutes: 30)),
        );
        await settings.setWorkingWindow(
          const WorkingWindow(startMinutes: 8 * 60, endMinutes: 16 * 60),
        );
      },
      skip: 1,
      expect: () => [
        HomeState(
          status: HomeStatus.ready,
          now: now,
          water: const TimerConfig(interval: Duration(minutes: 30)),
        ),
        HomeState(
          status: HomeStatus.ready,
          now: now,
          water: const TimerConfig(interval: Duration(minutes: 30)),
          workingWindow:
              const WorkingWindow(startMinutes: 8 * 60, endMinutes: 16 * 60),
        ),
      ],
    );
  });

  group('HomeTicked', () {
    final later = now.add(const Duration(minutes: 20));

    blocTest<HomeBloc, HomeState>(
      'moves now forward and nothing else',
      build: buildBloc,
      seed: () => HomeState(status: HomeStatus.ready, now: now),
      act: (bloc) => bloc.add(HomeTicked(later)),
      expect: () => [HomeState(status: HomeStatus.ready, now: later)],
    );

    blocTest<HomeBloc, HomeState>(
      'currentDuration is derived from startedAt and the tick',
      build: buildBloc,
      seed: () => HomeState(current: ongoingWork, now: now),
      act: (bloc) => bloc.add(HomeTicked(later)),
      verify: (bloc) => expect(
        bloc.state.currentDuration,
        const Duration(hours: 2),
      ),
    );
  });

  group('ticker', () {
    test('ticks once a second from the clock and stops on close', () {
      fakeAsync((async) {
        final bloc = buildBloc(clock: () => now.add(async.elapsed))
          ..add(const HomeStarted());
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 3));
        expect(bloc.state.now, now.add(const Duration(seconds: 3)));

        bloc.close();
        async.elapse(const Duration(seconds: 5));
        expect(bloc.state.now, now.add(const Duration(seconds: 3)));
        expect(async.periodicTimerCount, 0);
      });
    });
  });

  group('HomeSwitchActivityRequested', () {
    blocTest<HomeBloc, HomeState>(
      'an explicit target starts a walk even with nothing running',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeSwitchActivityRequested(to: ActivityKind.walking));
      },
      verify: (bloc) => expect(bloc.state.current?.kind, ActivityKind.walking),
    );

    blocTest<HomeBloc, HomeState>(
      'starts working when nothing is running',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeSwitchActivityRequested());
      },
      verify: (bloc) {
        expect(bloc.state.current?.kind, ActivityKind.working);
        expect(bloc.state.current?.startedAt, now);
        expect(bloc.state.todaysSessions, [bloc.state.current]);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'ends the working session and starts a walk',
      setUp: () => sessions = FakeSessionRepository([ongoingWork]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeSwitchActivityRequested());
      },
      verify: (bloc) {
        expect(bloc.state.displayKind, ActivityKind.walking);
        expect(bloc.state.todaysSessions.first.endedAt, now);
        expect(bloc.state.todaysSessions, hasLength(2));
      },
    );
  });

  group('HomeDrinkLogged', () {
    blocTest<HomeBloc, HomeState>(
      'logs a drink at the clock time and resets the water countdown',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeDrinkLogged());
      },
      verify: (bloc) {
        expect(bloc.state.lastDrinkAt, now);
        expect(bloc.state.todaysDrinks, [now]);
        expect(bloc.state.waterRemaining, bloc.state.water.interval);
      },
    );

    blocTest<HomeBloc, HomeState>(
      "only loads today's drinks",
      setUp: () => hydration = FakeHydrationRepository([
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(minutes: 30)),
      ]),
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeStarted()),
      verify: (bloc) => expect(
        bloc.state.todaysDrinks,
        [now.subtract(const Duration(minutes: 30))],
      ),
    );

    blocTest<HomeBloc, HomeState>(
      'a deleted drink leaves the log',
      setUp: () => hydration = FakeHydrationRepository([pastDrink]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(HomeDrinkDeleted(pastDrink));
      },
      verify: (bloc) {
        expect(hydration.drinks, isEmpty);
        expect(bloc.state.todaysDrinks, isEmpty);
      },
    );
  });

  group('undo', () {
    blocTest<HomeBloc, HomeState>(
      'every log offers a fresh undo',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeDrinkLogged());
        await pumpEventQueue();
        bloc.add(const HomeDrinkLogged());
      },
      verify: (bloc) => expect(
        bloc.state.undo,
        const HomeUndo(serial: 2, message: 'Drink logged'),
      ),
    );

    blocTest<HomeBloc, HomeState>(
      'takes back a drink and the countdown it reset',
      setUp: () => hydration = FakeHydrationRepository([pastDrink]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeDrinkLogged());
        await pumpEventQueue();
        bloc.add(const HomeUndoRequested());
      },
      verify: (bloc) {
        expect(hydration.drinks, [pastDrink]);
        expect(bloc.state.lastDrinkAt, pastDrink);
        expect(bloc.state.undo, isNull);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'takes back a walk and reopens the work session it ended',
      setUp: () => sessions = FakeSessionRepository([pastWalk, ongoingWork]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeSwitchActivityRequested(to: ActivityKind.walking));
        await pumpEventQueue();
        expect(bloc.state.undo?.message, 'Walk started');
        bloc.add(const HomeUndoRequested());
      },
      verify: (bloc) {
        expect(sessions.all, [pastWalk, ongoingWork]);
        expect(bloc.state.current, ongoingWork);
        expect(bloc.state.undo, isNull);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'restores a session the switch discarded for being under a minute',
      setUp: () => sessions = FakeSessionRepository([freshWork]),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeSwitchActivityRequested(to: ActivityKind.walking));
        await pumpEventQueue();
        bloc.add(const HomeUndoRequested());
      },
      verify: (bloc) => expect(sessions.all, [freshWork]),
    );

    blocTest<HomeBloc, HomeState>(
      'only takes back the latest action, once',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeDrinkLogged());
        await pumpEventQueue();
        bloc.add(const HomeSwitchActivityRequested(to: ActivityKind.walking));
        await pumpEventQueue();
        bloc
          ..add(const HomeUndoRequested())
          ..add(const HomeUndoRequested());
      },
      verify: (bloc) {
        expect(sessions.all, isEmpty);
        expect(hydration.drinks, [now]);
      },
    );
  });

  group('edit and delete', () {
    setUp(() => sessions = FakeSessionRepository([pastWalk, ongoingWork]));

    blocTest<HomeBloc, HomeState>(
      'editing a session flows back through the repository stream',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(
          HomeSessionEdited(
            pastWalk.copyWith(
              startedAt: pastWalk.startedAt.subtract(
                const Duration(minutes: 10),
              ),
            ),
          ),
        );
      },
      verify: (bloc) => expect(
        bloc.state.todaysSessions.first.durationAt(now),
        const Duration(minutes: 30),
      ),
    );

    blocTest<HomeBloc, HomeState>(
      'deleting a session flows back through the repository stream',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const HomeStarted());
        await pumpEventQueue();
        bloc.add(const HomeSessionDeleted('walk'));
      },
      verify: (bloc) => expect(bloc.state.todaysSessions, [ongoingWork]),
    );
  });
}
