import 'package:flutter/widgets.dart';

class AppRadii {
  const AppRadii._();

  static const Radius xs = Radius.circular(8);
  static const Radius sm = Radius.circular(12);
  static const Radius md = Radius.circular(16);
  static const Radius lg = Radius.circular(20);
  static const Radius xl = Radius.circular(28);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius cardRadius = BorderRadius.all(lg);
  static const BorderRadius pillRadius = BorderRadius.all(pill);
}
