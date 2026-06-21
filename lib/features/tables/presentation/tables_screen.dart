import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../domain/models/hall.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/models/table_status.dart';
import '../providers/table_providers.dart';
import 'hall_form_dialog.dart';
import 'table_action_sheet.dart';
import 'table_form_dialog.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  List<Hall>? _localHallOrder;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final hallsAsync = ref.watch(hallListProvider);
    final selectedHallId = ref.watch(selectedHallIdProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage halls and table layout — tap a table for actions',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              _StatusLegend(),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: hallsAsync.when(
              loading: () =>
                  const AppLoadingIndicator(message: 'Loading halls...'),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load halls',
                message: error.toString(),
              ),
              data: (halls) {
                if (halls.isEmpty) {
                  return AppEmptyState(
                    title: 'No halls yet',
                    message: 'Add a hall (e.g. Main Dining) then place tables.',
                    actionLabel: 'Add Hall',
                    onAction: () => _openHallForm(context),
                  );
                }

                final displayHalls = _localHallOrder ?? halls;
                final hallId = selectedHallId ?? displayHalls.first.id;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _HallPanel(
                        halls: displayHalls,
                        selectedHallId: hallId,
                        onSelect: (id) =>
                            ref.read(selectedHallIdProvider.notifier).state = id,
                        onAdd: () => _openHallForm(context),
                        onEdit: (hall) => _openHallForm(context, hall: hall),
                        onDelete: (hall) => _confirmDeleteHall(context, hall),
                        onReorder: (ids) async {
                          final source = ref.read(hallListProvider).valueOrNull ?? displayHalls;
                          setState(() {
                            _localHallOrder = [
                              for (final id in ids)
                                source.firstWhere((h) => h.id == id),
                            ];
                          });
                          await ref
                              .read(hallListProvider.notifier)
                              .reorder(ids);
                          if (mounted) setState(() => _localHallOrder = null);
                        },
                      ),
                    ),
                    SizedBox(width: spacing.lg),
                    Expanded(
                      flex: 5,
                      child: _HallLayoutPanel(hallId: hallId),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openHallForm(BuildContext context, {Hall? hall}) async {
    final result = await HallFormDialog.show(
      context,
      hall: hall,
      title: hall == null ? 'Add Hall' : 'Edit Hall',
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(hallListProvider.notifier);
    final mutation = hall == null
        ? await notifier.create(name: result.name)
        : await notifier.updateHall(hall.copyWith(name: result.name));

    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }

  Future<void> _confirmDeleteHall(BuildContext context, Hall hall) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete hall?',
      content: Text(
        'Delete "${hall.name}"? Halls with tables cannot be removed.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final mutation =
        await ref.read(hallListProvider.notifier).delete(hall.id);
    if (!context.mounted) return;
    if (!mutation.success && mutation.errorMessage != null) {
      AppSnackbar.error(context, mutation.errorMessage!);
    }
  }
}

class _StatusLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Wrap(
      spacing: spacing.md,
      children: [
        _LegendChip(status: TableStatus.available, label: 'Available'),
        _LegendChip(status: TableStatus.occupied, label: 'Occupied'),
        _LegendChip(status: TableStatus.reserved, label: 'Reserved'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.status, required this.label});

  final TableStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final color = tableStatusColor(context, status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: context.appSpacing.xs),
        Text(
          label,
          style: typography.labelSmall.copyWith(
            color: context.appColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HallPanel extends StatelessWidget {
  const _HallPanel({
    required this.halls,
    required this.selectedHallId,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  final List<Hall> halls;
  final String selectedHallId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final void Function(Hall hall) onEdit;
  final void Function(Hall hall) onDelete;
  final Future<void> Function(List<String> ids) onReorder;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Halls',
                    style: typography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Add',
                  icon: AppIcons.add,
                  size: AppButtonSize.small,
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: halls.length,
              onReorder: (oldIndex, newIndex) async {
                final items = List<Hall>.of(halls);
                if (newIndex > oldIndex) newIndex -= 1;
                final item = items.removeAt(oldIndex);
                items.insert(newIndex, item);
                await onReorder(items.map((h) => h.id).toList());
              },
              itemBuilder: (context, index) {
                final hall = halls[index];
                final selected = hall.id == selectedHallId;

                return Material(
                  key: ValueKey(hall.id),
                  color: selected ? colors.primaryContainer : colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(hall.id),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.md,
                        vertical: spacing.sm,
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Text(
                              hall.name,
                              style: typography.bodyMedium.copyWith(
                                color: selected
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: Icon(
                              AppIcons.edit,
                              color: selected
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                            onPressed: () => onEdit(hall),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(AppIcons.delete, color: colors.error),
                            onPressed: () => onDelete(hall),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HallLayoutPanel extends ConsumerWidget {
  const _HallLayoutPanel({required this.hallId});

  final String hallId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final tablesAsync = ref.watch(hallTablesProvider(hallId));
    final actions = ref.read(tableActionsProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Table layout',
                    style: typography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Add Table',
                  icon: AppIcons.add,
                  size: AppButtonSize.small,
                  onPressed: () => _openTableForm(context, ref, hallId),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: tablesAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading tables...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load tables',
                message: error.toString(),
              ),
              data: (tables) {
                if (tables.isEmpty) {
                  return AppEmptyState(
                    title: 'No tables in this hall',
                    message: 'Add tables to build your floor plan.',
                    actionLabel: 'Add Table',
                    onAction: () => _openTableForm(context, ref, hallId),
                  );
                }

                return Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: spacing.xxl * 3,
                      mainAxisSpacing: spacing.md,
                      crossAxisSpacing: spacing.md,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      return _TableTile(
                        table: table,
                        onTap: () => showTableActions(
                          context: context,
                          ref: ref,
                          table: table,
                          hallTables: tables,
                        ),
                        onEdit: () => _openTableForm(
                          context,
                          ref,
                          hallId,
                          table: table,
                        ),
                        onDelete: () => _confirmDeleteTable(
                          context,
                          ref,
                          actions,
                          table,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTableForm(
    BuildContext context,
    WidgetRef ref,
    String hallId, {
    RestaurantTable? table,
  }) async {
    final result = await TableFormDialog.show(
      context,
      table: table,
      title: table == null ? 'Add Table' : 'Edit Table',
    );
    if (result == null || !context.mounted) return;

    final actions = ref.read(tableActionsProvider);

    try {
      if (table == null) {
        await actions.createTable(
          hallId: hallId,
          label: result.label,
          capacity: result.capacity,
        );
      } else {
        await actions.updateTable(
          table.copyWith(label: result.label, capacity: result.capacity),
        );
      }
    } on TableTransferException catch (e) {
      if (context.mounted) AppSnackbar.error(context, e.message);
    }
  }

  Future<void> _confirmDeleteTable(
    BuildContext context,
    WidgetRef ref,
    TableActions actions,
    RestaurantTable table,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete table?',
      content: Text(
        'Delete "${table.label}"?',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final deleted = await actions.deleteTable(table.id);
      if (!deleted && context.mounted) {
        AppSnackbar.error(context, 'Could not delete table');
      }
    } on TableTransferException catch (e) {
      if (context.mounted) AppSnackbar.error(context, e.message);
    }
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.table,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final statusColor = tableStatusColor(context, table.status);

    return Material(
      color: statusColor.withValues(alpha: 0.15),
      borderRadius: context.appRadius.mdBorder,
      child: InkWell(
        borderRadius: context.appRadius.mdBorder,
        onTap: onTap,
        onLongPress: () => _showQuickMenu(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: context.appRadius.mdBorder,
            border: Border.all(color: statusColor, width: 2),
          ),
          padding: EdgeInsets.all(spacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      table.label,
                      style: typography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              Text(
                table.status.label,
                style: typography.labelMedium.copyWith(color: statusColor),
              ),
              const Spacer(),
              Text(
                '${table.capacity} seats',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (table.hasActiveOrder)
                Text(
                  'Order active',
                  style: typography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    onTap();
  }
}

Color tableStatusColor(BuildContext context, TableStatus status) {
  final colors = context.appColors;
  return switch (status) {
    TableStatus.available => colors.success,
    TableStatus.occupied => colors.error,
    TableStatus.reserved => colors.warning,
  };
}
