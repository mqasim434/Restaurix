import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles design tokens into a Material 3 [ThemeData].
abstract final class AppTheme {
  static ThemeData get light {
    const colors = AppColorsTheme.light;
    const typography = AppTypographyTheme.standard;
    const spacing = AppSpacingTheme.standard;
    const radius = AppRadiusTheme.standard;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      shadow: colors.shadow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.divider,
      fontFamily: AppTypography.fontFamily,
      textTheme: typography.toTextTheme(
        onSurface: colors.onSurface,
        onSurfaceVariant: colors.onSurfaceVariant,
      ),
      extensions: const [colors, typography, spacing, radius],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm + spacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: radius.mdBorder,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius.mdBorder,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius.mdBorder,
          borderSide: BorderSide(color: colors.primary, width: spacing.xs / 4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius.mdBorder,
          borderSide: BorderSide(color: colors.error),
        ),
        labelStyle: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        hintStyle: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius.mdBorder,
          side: BorderSide(color: colors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: radius.lgBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius.mdBorder),
      ),
    );
  }
}

/// Convenient access to design tokens from [BuildContext].
extension AppThemeContext on BuildContext {
  AppColorsTheme get appColors =>
      Theme.of(this).extension<AppColorsTheme>() ?? AppColorsTheme.light;

  AppTypographyTheme get appTypography =>
      Theme.of(this).extension<AppTypographyTheme>() ?? AppTypographyTheme.standard;

  AppSpacingTheme get appSpacing =>
      Theme.of(this).extension<AppSpacingTheme>() ?? AppSpacingTheme.standard;

  AppRadiusTheme get appRadius =>
      Theme.of(this).extension<AppRadiusTheme>() ?? AppRadiusTheme.standard;
}
