import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcons {
  const AppIcons._();

  static const _pkg = 'healthy_hour_ui_kit';

  static Widget edit({double size = 24, Color? color}) =>
      _svg('assets/icons/edit.svg', size, color);

  static Widget settings({double size = 24, Color? color}) =>
      _svg('assets/icons/settings.svg', size, color);

  static Widget trash({double size = 24, Color? color}) =>
      _svg('assets/icons/trash.svg', size, color);

  static Widget _svg(String path, double size, Color? color) {
    return SvgPicture.asset(
      path,
      package: _pkg,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
