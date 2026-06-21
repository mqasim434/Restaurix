import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/models/table_status.dart';

class TransferTableDialog extends ConsumerStatefulWidget {
  const TransferTableDialog({
    super.key,
    required this.fromTable,
    required this.candidateTables,
  });

  final RestaurantTable fromTable;
  final List<RestaurantTable> candidateTables;

  static Future<String?> show(
    BuildContext context, {
    required RestaurantTable fromTable,
    required List<RestaurantTable> candidateTables,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => TransferTableDialog(
        fromTable: fromTable,
        candidateTables: candidateTables,
      ),
    );
  }

  @override
  ConsumerState<TransferTableDialog> createState() =>
      _TransferTableDialogState();
}

class _TransferTableDialogState extends ConsumerState<TransferTableDialog> {
  String? _destinationId;

  @override
  void initState() {
    super.initState();
    final available = widget.candidateTables
        .where((t) => t.id != widget.fromTable.id && t.status != TableStatus.occupied)
        .toList();
    _destinationId = available.isNotEmpty ? available.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    final destinations = widget.candidateTables
        .where((t) => t.id != widget.fromTable.id && t.status != TableStatus.occupied)
        .toList();

    return AlertDialog(
      title: Text(
        'Transfer table',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 5,
        child: destinations.isEmpty
            ? Text(
                'No available destination tables in this hall.',
                style: typography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Move the active order from ${widget.fromTable.label} to:',
                    style: typography.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  AppDropdown<String>(
                    label: 'Destination table',
                    value: _destinationId,
                    items: destinations.map((t) => t.id).toList(),
                    itemLabel: (id) {
                      final table =
                          destinations.firstWhere((t) => t.id == id);
                      return '${table.label} (${table.status.label})';
                    },
                    onChanged: (value) => setState(() => _destinationId = value),
                  ),
                ],
              ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Transfer',
          onPressed: destinations.isEmpty || _destinationId == null
              ? null
              : () => Navigator.of(context).pop(_destinationId),
        ),
      ],
    );
  }
}
