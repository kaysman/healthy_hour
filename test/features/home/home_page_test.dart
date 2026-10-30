import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/app.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/activity/activity.dart';
import 'package:healthy_hour/src/features/home/home.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

import '../../helpers/fakes.dart';

void main() {
  // Fakes are built inside each test body, not in setUp: `testWidgets` runs
  // on a fake clock, and streams created outside its zone never deliver.
  Future<void> pumpHome(
    WidgetTester tester, {
    required FakeSessionRepository sessions,
    required FakeHydrationRepository hydration,
  }) async {
    await tester.pumpWidget(
      HealthyHourApp(
        sessions: sessions,
        settings: FakeSettingsRepository(),
        hydration: hydration,
      ),
    );
    await tester.pump();
  }

  /// Home alone, on a clock frozen at [now], so the hero and the hour grid
  /// don't depend on when the suite runs.
  Future<void> pumpHomeAt(
    WidgetTester tester,
    DateTime now, {
    required FakeSessionRepository sessions,
    FakeHydrationRepository? hydration,
  }) async {
    final drinks = hydration ?? FakeHydrationRepository();
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ActivityCubit(sessions),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider(
            create: (_) => HomeBloc(
              sessions: sessions,
              settings: FakeSettingsRepository(),
              hydration: drinks,
              switchActivity: SwitchActivity(sessions),
              getTodaySessions: GetTodaySessions(sessions),
              updateSession: UpdateSession(sessions),
              deleteSession: DeleteSession(sessions),
              logDrink: LogDrink(drinks),
              removeDrink: RemoveDrink(drinks),
              undoSwitchActivity: UndoSwitchActivity(sessions),
              idGenerator: SequentialIds().call,
              clock: () => now,
            )..add(const HomeStarted()),
            child: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
  }

  // 10:00 on a weekday, inside the default 09:00–18:00 window.
  final tenAm = DateTime(2026, 10, 29, 10);

  testWidgets('Drank water logs a drink, and Undo takes it back',
      (tester) async {
    final hydration = FakeHydrationRepository();
    await pumpHomeAt(
      tester,
      tenAm,
      sessions: FakeSessionRepository(),
      hydration: hydration,
    );

    await tapKey(tester, 'water-action');
    expect(hydration.drinks, [tenAm]);

    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Drink logged'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(hydration.drinks, isEmpty);
  });

  testWidgets('Start walk starts a walk, then offers Back to work',
      (tester) async {
    final sessions = FakeSessionRepository();
    await pumpHomeAt(tester, tenAm, sessions: sessions);

    await tapKey(tester, 'walk-action');
    await tester.pump();

    expect(sessions.all.single.kind, ActivityKind.walking);
    expect(find.text('Back to work'), findsOneWidget);
  });

  testWidgets('counts down to whichever habit is due first', (tester) async {
    await pumpHomeAt(
      tester,
      tenAm,
      sessions: FakeSessionRepository([
        Session(
          id: 'w',
          kind: ActivityKind.working,
          startedAt: tenAm.subtract(const Duration(minutes: 5)),
        ),
      ]),
      hydration: FakeHydrationRepository([
        tenAm.subtract(const Duration(minutes: 20)),
      ]),
    );

    // Water (25:25 since a drink 20 min ago) beats the walk (5 min in).
    expect(find.text('05:25'), findsOneWidget);
    expect(find.text('until water'), findsOneWidget);
    expect(find.text('Walk in 20:25'), findsOneWidget);
  });

  testWidgets('a due walk takes over the hero', (tester) async {
    await pumpHomeAt(
      tester,
      tenAm,
      sessions: FakeSessionRepository([
        Session(
          id: 'w',
          kind: ActivityKind.working,
          startedAt: tenAm.subtract(const Duration(minutes: 47)),
        ),
      ]),
      hydration: FakeHydrationRepository([tenAm]),
    );

    expect(find.text('Time to walk'), findsOneWidget);
    expect(find.text('Sitting for 47 min'), findsOneWidget);
  });

  testWidgets('is off the clock outside the working window', (tester) async {
    await pumpHomeAt(
      tester,
      DateTime(2026, 10, 29, 7),
      sessions: FakeSessionRepository(),
    );

    expect(find.text('Off the clock'), findsOneWidget);
    expect(find.text('Reminders start at 09:00'), findsOneWidget);
  });

  testWidgets('the hour grid scores the day and opens an hour', (tester) async {
    final nine = DateTime(2026, 10, 29, 9);
    await pumpHomeAt(
      tester,
      DateTime(2026, 10, 29, 11, 30),
      sessions: FakeSessionRepository([
        Session(
          id: 'walk',
          kind: ActivityKind.walking,
          startedAt: nine.add(const Duration(minutes: 10)),
          endedAt: nine.add(const Duration(minutes: 20)),
        ),
      ]),
      hydration: FakeHydrationRepository([
        nine.add(const Duration(minutes: 30)),
      ]),
    );

    expect(
      find.text('1 / 9 healthy hours', findRichText: true),
      findsOneWidget,
    );

    await tapKey(tester, 'hour-9');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('09:00 – 10:00'), findsOneWidget);
    expect(find.text('09:10 – 09:20'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
  });

  testWidgets('every hour cell fills its share of the row', (tester) async {
    await pumpHomeAt(tester, tenAm, sessions: FakeSessionRepository());

    // 9 past, current and upcoming cells across an 800 px test screen.
    for (final h in [9, 10, 15]) {
      // The tile itself, not the slot around it — `Expanded` always
      // stretches the slot, whatever the tile inside does.
      final tile = find.descendant(
        of: find.byKey(ValueKey('hour-$h')),
        matching: find.byType(Material),
      );
      expect(tester.getSize(tile).width, greaterThan(40));
    }
  });

  testWidgets('upcoming hours cannot be opened', (tester) async {
    await pumpHomeAt(tester, tenAm, sessions: FakeSessionRepository());

    await tapKey(tester, 'hour-15');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('15:00 – 16:00'), findsNothing);
  });

  testWidgets('Settings opens on top of Home and back returns', (tester) async {
    await pumpHome(
      tester,
      sessions: FakeSessionRepository(),
      hydration: FakeHydrationRepository(),
    );

    await tester.tap(find.text('Working Time'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Adjust'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('healthy-hour-brand')), findsOneWidget);
  });

  testWidgets('Settings is tinted by the current activity', (tester) async {
    await pumpHome(
      tester,
      sessions: FakeSessionRepository([
        Session(
          id: 'k',
          kind: ActivityKind.walking,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ]),
      hydration: FakeHydrationRepository(),
    );

    await tester.tap(find.text('Working Time'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final backdrop = find.ancestor(
      of: find.text('Adjust'),
      matching: find.byType(ActivityBackdrop),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: backdrop, matching: find.byType(DecoratedBox)).first,
    );
    final gradient = (box.decoration as BoxDecoration).gradient!;
    final colors = tester.element(backdrop).colors;
    expect(gradient.colors.first, colors.walkingTint);
  });

  testWidgets('Home asks for dark status-bar icons in the light theme',
      (tester) async {
    await pumpHome(
      tester,
      sessions: FakeSessionRepository(),
      hydration: FakeHydrationRepository(),
    );

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('healthy-hour-brand')),
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
  });
}
