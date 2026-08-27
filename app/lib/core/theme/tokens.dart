import 'package:flutter/widgets.dart';

/// Layout constants shared by every screen.
///
/// A point-of-sale terminal is touched thousands of times a shift, often with
/// wet or gloved hands, so the tap targets here are deliberately larger than
/// Material's 48px baseline.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 64;

  static const EdgeInsets screen = EdgeInsets.all(xl);
  static const EdgeInsets card = EdgeInsets.all(md);
}

abstract final class Radii {
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius xl = Radius.circular(20);

  static const BorderRadius small = BorderRadius.all(sm);
  static const BorderRadius medium = BorderRadius.all(md);
  static const BorderRadius large = BorderRadius.all(lg);
  static const BorderRadius extraLarge = BorderRadius.all(xl);
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Minimum interactive sizes. [tile] is what the POS menu grid uses — big
/// enough to hit reliably without looking.
abstract final class Hit {
  static const double control = 48;
  static const double field = 52;
  static const double button = 52;
  static const double tile = 96;
}

abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasis = Curves.easeOutBack;
}

/// Breakpoints. The same binary runs on a wall-mounted kitchen screen, a
/// handheld tablet and a back-office desktop.
abstract final class Breakpoints {
  static const double handset = 600;
  static const double tablet = 1000;
  static const double desktop = 1400;

  static bool isHandset(double w) => w < handset;
  static bool isTablet(double w) => w >= handset && w < tablet;
  static bool isDesktop(double w) => w >= tablet;
}
