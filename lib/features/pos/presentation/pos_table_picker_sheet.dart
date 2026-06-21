import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../tables/providers/table_providers.dart';
import '../providers/checkout_providers.dart';

class PosTablePickerSheet extends ConsumerWidget {
  const PosTablePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PosTablePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final tablesAsync = ref.watch(posAvailableTablesProvider);
    final halls = ref.watch(hallListProvider).valueOrNull ?? [];
    final hallNames = {for (final hall in halls) hall.id: hall.name};

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select table',
                style: typography.titleMedium.copyWith(color: colors.onSurface),
              ),
              Text(
                'Only available tables are shown',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.md),
              Expanded(
                child: tablesAsync.when(
                  loading: () =>
                      const AppLoadingIndicator(message: 'Loading tables...'),
                  error: (error, _) => AppEmptyState(
                    title: 'Failed to load tables',
                    message: error.toString(),
                  ),
                  data: (tables) {
                    if (tables.isEmpty) {
                      return const AppEmptyState(
                        title: 'No available tables',
                        message: 'Free up a table or add tables in Tables management.',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: tables.length,
                      separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        return _TablePickTile(
                          table: table,
                          hallName: hallNames[table.hallId] ?? 'Hall',
                          onTap: () => _selectTable(context, ref, table),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectTable(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
  ) async {
    await ref.read(checkoutProvider.notifier).selectTable(
          tableId: table.id,
          tableLabel: table.label,
        );
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _TablePickTile extends StatelessWidget {
  const _TablePickTile({
    required this.table,
    required this.hallName,
    required this.onTap,
  });

  final RestaurantTable table;
  final String hallName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.surfaceVariant,
      borderRadius: context.appRadius.mdBorder,
      child: InkWell(
        borderRadius: context.appRadius.mdBorder,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(context.appSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.label,
                      style: typography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '$hallName · ${table.capacity} seats',
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
