import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

void main() {
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
