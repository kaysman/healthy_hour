import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/app.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('App boots and shows the Home brand', (tester) async {
    await tester.pumpWidget(
      HealthyHourApp(
        sessions: FakeSessionRepository(),
        settings: FakeSettingsRepository(),
        hydration: FakeHydrationRepository(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('healthy-hour-brand')), findsOneWidget);
    expect(find.text('Healthy Hour'), findsNothing);
  });
}
