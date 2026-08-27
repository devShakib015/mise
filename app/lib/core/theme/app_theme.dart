import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandSubtle,
      onPrimaryContainer: p.brand,
      secondary: p.info,
      onSecondary: p.textInverse,
      error: p.danger,
      onError: p.textInverse,
      errorContainer: p.dangerSubtle,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceRaised,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.borderStrong,
      shadow: p.shadow,
    );

    final text = AppType.textTheme(p.textPrimary, p.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      fontFamily: AppType.family,
      textTheme: text,
      extensions: [p],

      // Flat by default. Depth comes from borders and surface steps, which hold
      // up far better than shadows on a glare-covered terminal.
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.title.copyWith(color: p.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.large,
          side: BorderSide(color: p.border),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.surfaceHover,
          disabledForegroundColor: p.textTertiary,
          minimumSize: const Size(0, Hit.button),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          textStyle: AppType.bodyStrong,
          shape: const RoundedRectangleBorder(borderRadius: Radii.medium),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          disabledForegroundColor: p.textTertiary,
          minimumSize: const Size(0, Hit.button),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          textStyle: AppType.bodyStrong,
          side: BorderSide(color: p.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: Radii.medium),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand,
          minimumSize: const Size(0, Hit.control),
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          textStyle: AppType.bodyStrong,
          shape: const RoundedRectangleBorder(borderRadius: Radii.small),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.md,
        ),
        hintStyle: AppType.body.copyWith(color: p.textTertiary),
        labelStyle: AppType.body.copyWith(color: p.textSecondary),
        floatingLabelStyle: AppType.label.copyWith(color: p.brand),
        errorStyle: AppType.small.copyWith(color: p.danger),
        border: OutlineInputBorder(
          borderRadius: Radii.medium,
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.medium,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.medium,
          borderSide: BorderSide(color: p.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.medium,
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.medium,
          borderSide: BorderSide(color: p.danger, width: 2),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.extraLarge,
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: AppType.title.copyWith(color: p.textPrimary),
        contentTextStyle: AppType.body.copyWith(color: p.textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.surfaceRaised : p.textPrimary,
        contentTextStyle: AppType.body.copyWith(color: p.textInverse),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.medium),
        elevation: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceHover,
        circularTrackColor: p.surfaceHover,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.isDark ? p.surfaceRaised : p.textPrimary,
          borderRadius: Radii.small,
          border: p.isDark ? Border.all(color: p.border) : null,
        ),
        textStyle: AppType.small.copyWith(color: p.textInverse),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onBrand : p.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.brand : p.surfaceHover,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.brand : p.borderStrong,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.brand : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(p.onBrand),
        side: BorderSide(color: p.borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
    );
  }
}
