import 'package:flutter/material.dart';

/// Inter, bundled rather than fetched. The whole point of this system is that
/// it works with the internet unplugged, so nothing may load at runtime.
abstract final class AppType {
  static const family = 'Inter';

  /// Tabular figures keep prices and totals aligned in a column. Without this,
  /// a bill's digits shift around as the numbers change.
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Slightly tightened tracking at display sizes, which Inter is designed for.
  static const display = TextStyle(
    fontFamily: family, fontSize: 44, height: 1.1,
    fontWeight: FontWeight.w700, letterSpacing: -1.0, fontFeatures: _tabular,
  );

  static const headline = TextStyle(
    fontFamily: family, fontSize: 30, height: 1.2,
    fontWeight: FontWeight.w600, letterSpacing: -0.6,
  );

  static const title = TextStyle(
    fontFamily: family, fontSize: 22, height: 1.27,
    fontWeight: FontWeight.w600, letterSpacing: -0.3,
  );

  static const subtitle = TextStyle(
    fontFamily: family, fontSize: 18, height: 1.33,
    fontWeight: FontWeight.w600, letterSpacing: -0.2,
  );

  static const body = TextStyle(
    fontFamily: family, fontSize: 15, height: 1.47, fontWeight: FontWeight.w400,
  );

  static const bodyStrong = TextStyle(
    fontFamily: family, fontSize: 15, height: 1.47, fontWeight: FontWeight.w600,
  );

  static const small = TextStyle(
    fontFamily: family, fontSize: 13, height: 1.38, fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontFamily: family, fontSize: 13, height: 1.23,
    fontWeight: FontWeight.w600, letterSpacing: 0.1,
  );

  static const caption = TextStyle(
    fontFamily: family, fontSize: 11.5, height: 1.3,
    fontWeight: FontWeight.w500, letterSpacing: 0.3,
  );

  /// All-caps section markers. Sparingly — they shout.
  static const overline = TextStyle(
    fontFamily: family, fontSize: 11, height: 1.2,
    fontWeight: FontWeight.w700, letterSpacing: 0.9,
  );

  /// Money. Always tabular, always at least semibold — a total is the single
  /// most-scanned number on any of these screens.
  static const money = TextStyle(
    fontFamily: family, fontSize: 16, height: 1.25,
    fontWeight: FontWeight.w600, letterSpacing: -0.2, fontFeatures: _tabular,
  );

  static const moneyLarge = TextStyle(
    fontFamily: family, fontSize: 28, height: 1.14,
    fontWeight: FontWeight.w700, letterSpacing: -0.7, fontFeatures: _tabular,
  );

  /// Kitchen display. Read from across a hot, bright kitchen, so it is sized
  /// for roughly two metres rather than arm's length.
  static const kdsTicket = TextStyle(
    fontFamily: family, fontSize: 26, height: 1.2,
    fontWeight: FontWeight.w700, letterSpacing: -0.4,
  );

  static const kdsItem = TextStyle(
    fontFamily: family, fontSize: 21, height: 1.3, fontWeight: FontWeight.w600,
  );

  static const kdsTimer = TextStyle(
    fontFamily: family, fontSize: 19, height: 1.2,
    fontWeight: FontWeight.w700, fontFeatures: _tabular,
  );

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: display.copyWith(color: primary),
        displayMedium: headline.copyWith(color: primary),
        headlineMedium: headline.copyWith(color: primary),
        titleLarge: title.copyWith(color: primary),
        titleMedium: subtitle.copyWith(color: primary),
        titleSmall: label.copyWith(color: primary),
        bodyLarge: body.copyWith(color: primary),
        bodyMedium: body.copyWith(color: primary),
        bodySmall: small.copyWith(color: secondary),
        labelLarge: label.copyWith(color: primary),
        labelMedium: caption.copyWith(color: secondary),
        labelSmall: overline.copyWith(color: secondary),
      );
}
