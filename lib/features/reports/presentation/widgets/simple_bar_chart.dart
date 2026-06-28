import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.valueLabelBuilder,
    this.maxHeight = 180,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double value)? valueLabelBuilder;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    if (maxValue <= 0) {
      return Center(
        child: Text(
          'No data for chart',
          style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: maxHeight + spacing.xl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (valueLabelBuilder != null)
                    Text(
                      valueLabelBuilder!(values[index]),
                      style: typography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: spacing.xs),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: values[index] / maxValue,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: context.appRadius.smBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    labels[index],
                    style: typography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (index != values.length - 1) SizedBox(width: spacing.xs),
          ],
        ],
      ),
    );
  }
}

class CompactBarChart extends StatelessWidget {
  const CompactBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.maxHeight = 220,
  });

  final List<num> values;
  final List<String> labels;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return SimpleBarChart(
      values: values.map((value) => value.toDouble()).toList(),
      labels: labels,
      maxHeight: maxHeight,
      valueLabelBuilder: (value) => value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1),
    );
  }
}
