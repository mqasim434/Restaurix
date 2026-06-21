import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/order_enums.dart';
import '../providers/checkout_providers.dart';
import 'pos_delivery_picker_sheets.dart';
import 'pos_table_picker_sheet.dart';

class PosOrderTypeSection extends ConsumerWidget {
  const PosOrderTypeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final draft = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Order type',
          style: typography.labelLarge.copyWith(color: colors.onSurface),
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: OrderType.values.map((type) {
            final selected = draft.orderType == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (_) => _onOrderTypeSelected(
                context,
                ref,
                type,
                checkoutNotifier,
              ),
            );
          }).toList(),
        ),
        if (draft.orderType == OrderType.dineIn) ...[
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.tableLabel == null
                      ? 'No table selected'
                      : 'Table ${draft.tableLabel}',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: draft.tableLabel == null ? 'Pick table' : 'Change',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                onPressed: () => PosTablePickerSheet.show(context),
              ),
            ],
          ),
        ],
        if (draft.orderType == OrderType.delivery) ...[
          SizedBox(height: spacing.sm),
          Text(
            'Delivery fulfillment',
            style: typography.labelMedium.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: spacing.xs),
          Wrap(
            spacing: spacing.sm,
            children: DeliveryMode.values.map((mode) {
              final selected = draft.deliveryMode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: selected,
                onSelected: (_) {
                  checkoutNotifier.setDeliveryMode(mode);
                  if (mode == DeliveryMode.ownRider) {
                    PosRiderPickerSheet.show(context);
                  } else {
                    PosPickupCompanyPickerSheet.show(context);
                  }
                },
              );
            }).toList(),
          ),
          if (draft.deliveryMode == DeliveryMode.ownRider) ...[
            SizedBox(height: spacing.xs),
            _DeliverySelectionRow(
              label: draft.riderName ?? 'No rider selected',
              actionLabel: draft.riderName == null ? 'Pick rider' : 'Change',
              onAction: () => PosRiderPickerSheet.show(context),
            ),
          ],
          if (draft.deliveryMode == DeliveryMode.pickupCompany) ...[
            SizedBox(height: spacing.xs),
            _DeliverySelectionRow(
              label: draft.pickupCompanyName ?? 'No company selected',
              actionLabel:
                  draft.pickupCompanyName == null ? 'Pick company' : 'Change',
              onAction: () => PosPickupCompanyPickerSheet.show(context),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _onOrderTypeSelected(
    BuildContext context,
    WidgetRef ref,
    OrderType type,
    CheckoutNotifier checkoutNotifier,
  ) async {
    await checkoutNotifier.setOrderType(type);
    if (!context.mounted) return;

    if (type == OrderType.dineIn) {
      await PosTablePickerSheet.show(context);
    }
  }
}

class _DeliverySelectionRow extends StatelessWidget {
  const _DeliverySelectionRow({
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: typography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        AppButton(
          label: actionLabel,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: onAction,
        ),
        SizedBox(width: spacing.xs),
      ],
    );
  }
}
