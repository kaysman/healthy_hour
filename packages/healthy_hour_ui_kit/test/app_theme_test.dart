import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

void main() {
  group('snack bar', () {
    for (final (name, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
    ]) {
      test('$name theme gives the action the brand color on a dark toast', () {
        final snack = theme.snackBarTheme;
        final c = theme.extension<AppColors>()!;

        expect(snack.actionTextColor, c.brand);
        expect(
          ThemeData.estimateBrightnessForColor(snack.backgroundColor!),
          Brightness.dark,
        );
      });
    }
  });

  group('status bar', () {
    test('light theme gets dark icons over a transparent bar', () {
      final style = AppTheme.light().appBarTheme.systemOverlayStyle!;

      expect(style.statusBarColor, Colors.transparent);
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.statusBarBrightness, Brightness.light);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    });

    test('dark theme gets light icons', () {
      final style = AppTheme.dark().appBarTheme.systemOverlayStyle!;

      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarBrightness, Brightness.dark);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });
  });
}
