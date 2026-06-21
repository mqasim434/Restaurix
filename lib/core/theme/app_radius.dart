import 'package:flutter/material.dart';

/// Border radius scale.
abstract final class AppRadius {
  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double full = 999;
}

@immutable
class AppRadiusTheme extends ThemeExtension<AppRadiusTheme> {
  const AppRadiusTheme({
    required this.none,
    required this.sm,
    required this.md,
    required this.lg,
    required this.full,
  });

  final double none;
  final double sm;
  final double md;
  final double lg;
  final double full;

  BorderRadius get smBorder => BorderRadius.circular(sm);
  BorderRadius get mdBorder => BorderRadius.circular(md);
  BorderRadius get lgBorder => BorderRadius.circular(lg);
  BorderRadius get fullBorder => BorderRadius.circular(full);

  static const standard = AppRadiusTheme(
    none: AppRadius.none,
    sm: AppRadius.sm,
    md: AppRadius.md,
    lg: AppRadius.lg,
    full: AppRadius.full,
  );

  @override
  AppRadiusTheme copyWith({
    double? none,
    double? sm,
    double? md,
    double? lg,
    double? full,
  }) {
    return AppRadiusTheme(
      none: none ?? this.none,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      full: full ?? this.full,
    );
  }

  @override
  AppRadiusTheme lerp(covariant ThemeExtension<AppRadiusTheme>? other, double t) {
    if (other is! AppRadiusTheme) return this;
    return this;
  }
}
