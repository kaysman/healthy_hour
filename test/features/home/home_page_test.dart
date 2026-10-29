import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/app.dart';
import 'package:healthy_hour/src/domain/domain.dart';

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

  // The Water card comes first in the row, Walking second.
  Future<void> tapAdd(WidgetTester tester, int index) async {
    final button = find.byIcon(Icons.add).at(index);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('the Water card + logs a drink', (tester) async {
    final hydration = FakeHydrationRepository();
    await pumpHome(
      tester,
      sessions: FakeSessionRepository(),
      hydration: hydration,
    );

    await tapAdd(tester, 0);

    expect(hydration.lastDrinkAt, isNotNull);
  });

  testWidgets('the Walking card + starts a walk', (tester) async {
    final sessions = FakeSessionRepository();
    await pumpHome(
      tester,
      sessions: sessions,
      hydration: FakeHydrationRepository(),
    );

    await tapAdd(tester, 1);

    expect(sessions.all.single.kind, ActivityKind.walking);
  });
}
