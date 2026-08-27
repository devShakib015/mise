// The reference ramps below are kept complete even where a step is not yet
// referenced — a ramp with holes in it invites mismatched one-off colours.
// ignore_for_file: unused_field

import 'package:flutter/material.dart';

/// Raw colour ramps. Never referenced by UI code directly — everything goes
/// through the semantic tokens in [AppPalette] so themes stay swappable.
abstract final class _Ref {
  // Warm neutrals. Warmer than a true grey; on a screen that sits in a dining
  // room all evening, cool greys read clinical.
  static const stone950 = Color(0xFF0C0A09);
  static const stone900 = Color(0xFF1C1917);
  static const stone850 = Color(0xFF232020);
  static const stone800 = Color(0xFF292524);
  static const stone700 = Color(0xFF44403C);
  static const stone600 = Color(0xFF57534E);
  static const stone500 = Color(0xFF78716C);
  static const stone400 = Color(0xFFA8A29E);
  static const stone300 = Color(0xFFD6D3D1);
  static const stone200 = Color(0xFFE7E5E4);
  static const stone100 = Color(0xFFF5F5F4);
  static const stone50 = Color(0xFFFAFAF9);
  static const white = Color(0xFFFFFFFF);

  // Ember — the brand. Reserved for identity and primary actions.
  static const ember700 = Color(0xFF9A3412);
  static const ember600 = Color(0xFFC2410C);
  static const ember500 = Color(0xFFEA580C);
  static const ember400 = Color(0xFFF97316);
  static const ember300 = Color(0xFFFB923C);
  static const ember100 = Color(0xFFFFEDD5);
  static const ember950 = Color(0xFF2B1206);

  // Status ramps. Deliberately cool, so an order's state can never be mistaken
  // for a button: neutral -> blue -> green, with red reserved for trouble.
  static const blue600 = Color(0xFF2563EB);
  static const blue500 = Color(0xFF3B82F6);
  static const blue400 = Color(0xFF60A5FA);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue950 = Color(0xFF0B1A33);

  static const emerald600 = Color(0xFF059669);
  static const emerald500 = Color(0xFF10B981);
  static const emerald400 = Color(0xFF34D399);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald950 = Color(0xFF04231A);

  static const amber600 = Color(0xFFD97706);
  static const amber500 = Color(0xFFF59E0B);
  static const amber400 = Color(0xFFFBBF24);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber950 = Color(0xFF2B1B02);

  static const red600 = Color(0xFFDC2626);
  static const red500 = Color(0xFFEF4444);
  static const red400 = Color(0xFFF87171);
  static const red100 = Color(0xFFFEE2E2);
  static const red950 = Color(0xFF2B0B0B);
}

/// Semantic colour tokens, reached via `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceHover,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.brand,
    required this.brandHover,
    required this.brandSubtle,
    required this.onBrand,
    required this.success,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.info,
    required this.infoSubtle,
    required this.statusQueued,
    required this.statusPreparing,
    required this.statusReady,
    required this.statusLate,
    required this.shadow,
  });

  final Brightness brightness;

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceHover;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;

  final Color brand;
  final Color brandHover;
  final Color brandSubtle;
  final Color onBrand;

  final Color success;
  final Color successSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color danger;
  final Color dangerSubtle;
  final Color info;
  final Color infoSubtle;

  /// Order and ticket states, shared by the POS and the kitchen display.
  final Color statusQueued;
  final Color statusPreparing;
  final Color statusReady;
  final Color statusLate;

  final Color shadow;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    canvas: _Ref.stone100,
    surface: _Ref.white,
    surfaceRaised: _Ref.white,
    surfaceSunken: _Ref.stone50,
    surfaceHover: _Ref.stone100,
    border: _Ref.stone200,
    borderStrong: _Ref.stone300,
    textPrimary: _Ref.stone900,
    textSecondary: _Ref.stone600,
    textTertiary: _Ref.stone500,
    textInverse: _Ref.white,
    brand: _Ref.ember600,
    brandHover: _Ref.ember700,
    brandSubtle: _Ref.ember100,
    onBrand: _Ref.white,
    success: _Ref.emerald600,
    successSubtle: _Ref.emerald100,
    warning: _Ref.amber600,
    warningSubtle: _Ref.amber100,
    danger: _Ref.red600,
    dangerSubtle: _Ref.red100,
    info: _Ref.blue600,
    infoSubtle: _Ref.blue100,
    statusQueued: _Ref.stone500,
    statusPreparing: _Ref.blue600,
    statusReady: _Ref.emerald600,
    statusLate: _Ref.red600,
    shadow: Color(0x1A0C0A09),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    canvas: _Ref.stone950,
    surface: _Ref.stone900,
    surfaceRaised: _Ref.stone850,
    surfaceSunken: _Ref.stone950,
    surfaceHover: _Ref.stone800,
    border: _Ref.stone800,
    borderStrong: _Ref.stone700,
    textPrimary: _Ref.stone50,
    textSecondary: _Ref.stone400,
    textTertiary: _Ref.stone500,
    textInverse: _Ref.stone950,
    brand: _Ref.ember500,
    brandHover: _Ref.ember400,
    brandSubtle: _Ref.ember950,
    onBrand: _Ref.white,
    success: _Ref.emerald400,
    successSubtle: _Ref.emerald950,
    warning: _Ref.amber400,
    warningSubtle: _Ref.amber950,
    danger: _Ref.red400,
    dangerSubtle: _Ref.red950,
    info: _Ref.blue400,
    infoSubtle: _Ref.blue950,
    statusQueued: _Ref.stone400,
    statusPreparing: _Ref.blue400,
    statusReady: _Ref.emerald400,
    statusLate: _Ref.red400,
    shadow: Color(0x66000000),
  );

  /// How long a kitchen ticket has been waiting, expressed as colour.
  /// Runs on a different visual channel to [statusPreparing] and friends —
  /// this tints borders and timers, never status chips.
  Color ageing(Duration waiting, {Duration target = const Duration(minutes: 10)}) {
    final ratio = waiting.inSeconds / target.inSeconds;
    if (ratio >= 1.0) return statusLate;
    if (ratio >= 0.6) return warning;
    return border;
  }

  @override
  AppPalette copyWith({Brightness? brightness}) => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension PaletteAccess on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
