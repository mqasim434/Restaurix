import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../providers/reports_providers.dart';

class DateRangeSelectorBar extends StatelessWidget {
  const DateRangeSelectorBar({
    super.key,
    required this.filter,
    required this.rangeLabel,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
  });

  final ReportsFilterState filter;
  final String rangeLabel;
  final ValueChanged<SalesDateRangePreset> onPresetSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RangeChip(
          label: 'Today',
          selected: filter.preset == SalesDateRangePreset.today,
          onTap: () => onPresetSelected(SalesDateRangePreset.today),
        ),
        _RangeChip(
          label: 'This week',
          selected: filter.preset == SalesDateRangePreset.thisWeek,
          onTap: () => onPresetSelected(SalesDateRangePreset.thisWeek),
        ),
        _RangeChip(
          label: 'This month',
          selected: filter.preset == SalesDateRangePreset.thisMonth,
          onTap: () => onPresetSelected(SalesDateRangePreset.thisMonth),
        ),
        _RangeChip(
          label: 'Custom',
          selected: filter.preset == SalesDateRangePreset.custom,
          onTap: () => _pickCustomRange(context),
        ),
        Text(
          rangeLabel,
          style: context.appTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = filter.customStart ?? now;
    final initialEnd = filter.customEnd ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (picked != null) {
      onCustomRangeSelected(picked.start, picked.end);
    }
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceVariant,
      borderRadius: radius.fullBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius.fullBorder,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSpacing.md,
            vertical: context.appSpacing.xs,
          ),
          child: Text(
            label,
            style: context.appTypography.labelLarge.copyWith(
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
