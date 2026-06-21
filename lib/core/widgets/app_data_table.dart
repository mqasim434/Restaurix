import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final int flex;
  final Alignment alignment;
}

class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No data available',
  });

  final List<AppDataColumn<T>> columns;
  final List<T> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final typography = context.appTypography;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius.md)),
            ),
            child: Row(
              children: [
                for (final column in columns) ...[
                  Expanded(
                    flex: column.flex,
                    child: Align(
                      alignment: column.alignment,
                      child: Text(
                        column.label,
                        style: typography.labelLarge.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.sm,
                  ),
                  child: Row(
                    children: [
                      for (final column in columns)
                        Expanded(
                          flex: column.flex,
                          child: Align(
                            alignment: column.alignment,
                            child: column.cellBuilder(context, row),
                          ),
                        ),
                    ],
                  ),
                ),
                if (index < rows.length - 1)
                  Divider(height: 1, color: colors.divider, indent: spacing.md),
              ],
            );
          }),
        ],
      ),
    );
  }
}
