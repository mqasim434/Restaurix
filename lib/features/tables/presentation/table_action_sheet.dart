import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/models/table_status.dart';
import '../../../data/repositories/table_repository.dart';
import '../providers/table_providers.dart';
import 'transfer_table_dialog.dart';

Future<void> showTableActions({
  required BuildContext context,
  required WidgetRef ref,
  required RestaurantTable table,
  required List<RestaurantTable> hallTables,
}) async {
  final actions = ref.read(tableActionsProvider);
  Order? order;
  if (table.currentOrderId != null) {
    order = await actions.findOrder(table.currentOrderId!);
  }
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _TableActionSheet(
      table: table,
      order: order,
      hallTables: hallTables,
      actions: actions,
    ),
  );
}

class _TableActionSheet extends ConsumerWidget {
  const _TableActionSheet({
    required this.table,
    required this.order,
    required this.hallTables,
    required this.actions,
  });

  final RestaurantTable table;
  final Order? order;
  final List<RestaurantTable> hallTables;
  final TableActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            table.label,
            style: typography.titleLarge.copyWith(color: colors.onSurface),
          ),
          Text(
            '${table.status.label} · seats ${table.capacity}',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (order != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              'Order ${order!.orderNumber} · ${order!.paymentStatus.name}',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: spacing.lg),
          if (table.status == TableStatus.available) ...[
            AppButton(
              label: 'Start order',
              onPressed: () => _startOrder(context),
            ),
            SizedBox(height: spacing.sm),
            AppButton(
              label: 'Mark reserved',
              variant: AppButtonVariant.secondary,
              onPressed: () => _setStatus(context, TableStatus.reserved),
            ),
          ],
          if (table.status == TableStatus.reserved) ...[
            AppButton(
              label: 'Start order',
              onPressed: () => _startOrder(context),
            ),
            SizedBox(height: spacing.sm),
            AppButton(
              label: 'Mark available',
              variant: AppButtonVariant.secondary,
              onPressed: () => _setStatus(context, TableStatus.available),
            ),
          ],
          if (table.status == TableStatus.occupied) ...[
            AppButton(
              label: 'Open in POS',
              onPressed: () {
                Navigator.of(context).pop();
                AppSnackbar.info(
                  context,
                  'POS opens in Module 11 — order ${order?.orderNumber ?? ''} ready',
                );
                context.go('/sales');
              },
            ),
            SizedBox(height: spacing.sm),
            AppButton(
              label: 'Transfer table',
              variant: AppButtonVariant.secondary,
              onPressed: () => _transfer(context),
            ),
            SizedBox(height: spacing.sm),
            AppButton(
              label: 'Release table',
              variant: AppButtonVariant.ghost,
              onPressed: () => _releaseTable(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startOrder(BuildContext context) async {
    try {
      final order = await actions.startOrder(table.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.success(
        context,
        'Order ${order.orderNumber} started — full POS in Module 11',
      );
    } on TableTransferException catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, e.message);
    }
  }

  Future<void> _setStatus(BuildContext context, TableStatus status) async {
    try {
      await actions.setStatus(tableId: table.id, status: status);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on TableTransferException catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, e.message);
    }
  }

  Future<void> _transfer(BuildContext context) async {
    Navigator.of(context).pop();

    final destinationId = await TransferTableDialog.show(
      context,
      fromTable: table,
      candidateTables: hallTables,
    );
    if (destinationId == null || !context.mounted) return;

    try {
      await actions.transferOrder(
        fromTableId: table.id,
        toTableId: destinationId,
      );
      if (!context.mounted) return;
      AppSnackbar.success(context, 'Order transferred successfully');
    } on TableTransferException catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, e.message);
    }
  }

  Future<void> _releaseTable(BuildContext context) async {
    final orderActive = order?.isActiveOnTable ?? false;

    if (orderActive) {
      final confirmed = await AppDialog.show<bool>(
        context: context,
        title: 'Release occupied table?',
        content: Text(
          'Order ${order!.orderNumber} is still unpaid. Releasing may lose '
          'track of the active order unless you confirm.',
          style: context.appTypography.bodyMedium.copyWith(
            color: context.appColors.onSurfaceVariant,
          ),
        ),
        confirmLabel: 'Release anyway',
        isDanger: true,
      );
      if (confirmed != true || !context.mounted) return;

      try {
        await actions.setStatus(
          tableId: table.id,
          status: TableStatus.available,
          forceRelease: true,
        );
        if (!context.mounted) return;
        Navigator.of(context).pop();
      } on TableTransferException catch (e) {
        if (!context.mounted) return;
        AppSnackbar.error(context, e.message);
      }
      return;
    }

    try {
      await actions.setStatus(
        tableId: table.id,
        status: TableStatus.available,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on TableTransferException catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, e.message);
    }
  }
}
