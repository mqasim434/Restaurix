import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/discount.dart';
import '../providers/cart_providers.dart';
import '../providers/checkout_providers.dart';
import '../providers/discount_providers.dart';
import '../services/discount_calculator.dart';
import 'discount_actions.dart';
import 'pos_order_type_section.dart';

class PosCartPanel extends ConsumerWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final items = ref.watch(cartProvider);
    final pricing = ref.watch(cartPricingProvider);
    final discounts = ref.watch(cartDiscountsProvider);

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
                if (items.isNotEmpty) ...[
                  AppButton(
                    label: 'Category discount',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => showCategoryDiscountPicker(context, ref),
                  ),
                  AppButton(
                    label: 'Clear',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => _confirmClear(context, ref),
                  ),
                ],
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
                      final item = items[index];
                      final linePricing = pricing.linePricing[item.lineId];
                      return _CartLineRow(
                        item: item,
                        linePricing: linePricing,
                        itemDiscount: _itemDiscountForLine(discounts, item.lineId),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: colors.divider),
          if (items.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(spacing.md),
              child: const PosOrderTypeSection(),
            ),
            Divider(height: 1, color: colors.divider),
          ],
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.isNotEmpty && pricing.hasDiscounts) ...[
                  _PricingRow(
                    label: 'Subtotal',
                    amount: pricing.subtotal,
                    style: typography.bodyMedium,
                  ),
                  if (pricing.lineDiscountTotal > 0) ...[
                    SizedBox(height: spacing.xs),
                    _PricingRow(
                      label: 'After item & category discounts',
                      amount: pricing.subtotalAfterLineDiscounts,
                      style: typography.bodySmall,
                      muted: true,
                    ),
                  ],
                  if (pricing.orderDiscountTotal > 0) ...[
                    SizedBox(height: spacing.xs),
                    _PricingRow(
                      label: 'Order discount',
                      amount: -pricing.orderDiscountTotal,
                      style: typography.bodySmall,
                      muted: true,
                      showSign: true,
                    ),
                  ],
                  SizedBox(height: spacing.sm),
                ],
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
                    if (items.isNotEmpty)
                      IconButton(
                        tooltip: 'Whole-order discount',
                        icon: Icon(
                          Icons.discount_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                        onPressed: () =>
                            showWholeOrderDiscountDialog(context, ref),
                      ),
                    Text(
                      formatPosPrice(
                        items.isEmpty ? 0 : pricing.total,
                      ),
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
                      : () => _onCheckout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppliedDiscount? _itemDiscountForLine(
    List<AppliedDiscount> discounts,
    String lineId,
  ) {
    for (final discount in discounts) {
      if (discount.scope == DiscountScope.item && discount.lineId == lineId) {
        return discount;
      }
    }
    return null;
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
      ref.read(cartDiscountsProvider.notifier).clear();
      ref.read(checkoutProvider.notifier).clear();
    }
  }

  void _onCheckout(BuildContext context, WidgetRef ref) {
    final error = ref.read(checkoutValidationErrorProvider);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    final pricing = ref.read(cartPricingProvider);
    for (final warning in pricing.warnings) {
      AppSnackbar.info(context, warning);
    }

    AppSnackbar.info(
      context,
      'Checkout validation passed — order placement in Module 15',
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.label,
    required this.amount,
    required this.style,
    this.muted = false,
    this.showSign = false,
  });

  final String label;
  final double amount;
  final TextStyle style;
  final bool muted;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style.copyWith(
              color: muted ? colors.onSurfaceVariant : colors.onSurface,
            ),
          ),
        ),
        Text(
          showSign && amount != 0
              ? '${amount < 0 ? '-' : ''}${formatPosPrice(amount.abs())}'
              : formatPosPrice(amount),
          style: style.copyWith(
            color: muted ? colors.onSurfaceVariant : colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CartLineRow extends ConsumerWidget {
  const _CartLineRow({
    required this.item,
    required this.linePricing,
    required this.itemDiscount,
  });

  final CartItem item;
  final LinePricing? linePricing;
  final AppliedDiscount? itemDiscount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final notifier = ref.read(cartProvider.notifier);
    final discountNotifier = ref.read(cartDiscountsProvider.notifier);

    final displayTotal = linePricing?.netTotal ?? item.lineTotal;
    final hasLineDiscount =
        linePricing != null && linePricing!.lineDiscountAmount > 0;

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
                  tooltip: itemDiscount == null
                      ? 'Apply item discount'
                      : 'Edit item discount',
                  icon: Icon(
                    Icons.discount_outlined,
                    color: itemDiscount == null
                        ? colors.onSurfaceVariant
                        : colors.primary,
                    size: 20,
                  ),
                  onPressed: () => showItemDiscountDialog(
                    context,
                    ref,
                    lineId: item.lineId,
                    name: item.name,
                    targetId: item.productId ?? item.dealId,
                  ),
                ),
                if (itemDiscount != null)
                  IconButton(
                    tooltip: 'Remove item discount',
                    icon: Icon(AppIcons.close, color: colors.error, size: 18),
                    onPressed: () => discountNotifier.remove(itemDiscount!.id),
                  ),
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(AppIcons.delete, color: colors.error, size: 20),
                  onPressed: () {
                    if (itemDiscount != null) {
                      discountNotifier.remove(itemDiscount!.id);
                    }
                    notifier.remove(item.lineId);
                  },
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
            if (itemDiscount?.reason != null)
              Text(
                'Reason: ${itemDiscount!.reason}',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
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
                      : () {
                          if (itemDiscount != null) {
                            discountNotifier.remove(itemDiscount!.id);
                          }
                          notifier.remove(item.lineId);
                        },
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
                if (hasLineDiscount)
                  Padding(
                    padding: EdgeInsets.only(right: spacing.sm),
                    child: Text(
                      formatPosPrice(item.lineTotal),
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                Text(
                  formatPosPrice(displayTotal),
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
