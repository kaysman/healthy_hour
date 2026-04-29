import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

void main() {
  group('DurationFormatter', () {
    test('hms pads hours, minutes and seconds', () {
      expect(
        DurationFormatter.hms(
          const Duration(hours: 6, minutes: 34, seconds: 12),
        ),
        '06:34:12',
      );
    });

    test('ms uses total minutes', () {
      expect(
        DurationFormatter.ms(const Duration(minutes: 25, seconds: 25)),
        '25:25',
      );
    });

    test('hhmm formats wall-clock time', () {
      expect(DurationFormatter.hhmm(DateTime(2026, 4, 25, 15, 46)), '15:46');
    });
  });
}
