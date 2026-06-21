import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../domain/models/cart_item.dart';
import '../providers/cart_providers.dart';

class PosCartPanel extends ConsumerWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

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
                    'Cart',
                    style: typography.titleMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  AppButton(
                    label: 'Clear',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => _confirmClear(context, ref),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Tap products or deals to add items',
                      style: typography.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(spacing.md),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      return _CartLineRow(item: items[index]);
                    },
                  ),
          ),
          Divider(height: 1, color: colors.divider),
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total',
                        style: typography.titleMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      formatPosPrice(total),
                      style: typography.titleLarge.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.sm),
                AppButton(
                  label: 'Checkout',
                  expand: true,
                  onPressed: items.isEmpty
                      ? null
                      : () {
                          // Module 12/15 — order type and placement
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Clear cart?',
      content: Text(
        'Remove all items from the current cart?',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Clear',
      isDanger: true,
    );

    if (confirmed == true) {
      ref.read(cartProvider.notifier).clear();
    }
  }
}

class _CartLineRow extends ConsumerWidget {
  const _CartLineRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final notifier = ref.read(cartProvider.notifier);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: typography.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(AppIcons.delete, color: colors.error, size: 20),
                  onPressed: () => notifier.remove(item.lineId),
                ),
              ],
            ),
            if (item.variantName != null)
              Text(
                item.variantName!,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            if (item.modifiers.isNotEmpty)
              Text(
                item.modifiers.map((m) => m.name).join(', '),
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove_rounded,
                  onPressed: item.quantity > 1
                      ? () => notifier.updateQuantity(
                            item.lineId,
                            item.quantity - 1,
                          )
                      : () => notifier.remove(item.lineId),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                  child: Text(
                    '${item.quantity}',
                    style: typography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add_rounded,
                  onPressed: () => notifier.updateQuantity(
                    item.lineId,
                    item.quantity + 1,
                  ),
                ),
                const Spacer(),
                Text(
                  formatPosPrice(item.lineTotal),
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: context.appRadius.smBorder,
      child: InkWell(
        borderRadius: context.appRadius.smBorder,
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: colors.onSurface),
        ),
      ),
    );
  }
}

String formatPosPrice(double price) {
  return NumberFormat.simpleCurrency().format(price);
}
