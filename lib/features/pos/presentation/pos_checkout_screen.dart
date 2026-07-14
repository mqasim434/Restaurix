import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/cart_providers.dart';
import '../providers/checkout_providers.dart';
import '../providers/discount_providers.dart';
import '../../orders/providers/order_management_providers.dart';
import '../providers/order_edit_provider.dart';
import '../../printing/providers/kitchen_ticket_providers.dart';
import '../../printing/providers/receipt_providers.dart';
import '../../printing/kitchen_ticket/kitchen_ticket_feedback.dart';
import '../../printing/receipt/receipt_feedback.dart';

class PosCheckoutScreen extends ConsumerStatefulWidget {
  const PosCheckoutScreen({super.key});

  @override
  ConsumerState<PosCheckoutScreen> createState() => _PosCheckoutScreenState();
}

class _PosCheckoutScreenState extends ConsumerState<PosCheckoutScreen> {
  final _notesController = TextEditingController();
  final _promisedPrepController = TextEditingController();
  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(checkoutProvider);
      _notesController.text = draft.notes ?? '';
      _promisedPrepController.text =
          draft.promisedPrepMinutes?.toString() ?? '';
      if (draft.paymentType == null) {
        ref.read(checkoutProvider.notifier).setPaymentType(PaymentType.cash);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _promisedPrepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final items = ref.watch(cartProvider);
    final draft = ref.watch(checkoutProvider);
    final pricing = ref.watch(cartPricingProvider);
    final formatMoney = ref.watch(formatMoneyProvider);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your cart is empty',
              style: typography.titleMedium.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            AppButton(
              label: 'Back to POS',
              onPressed: () => context.go('/sales'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Checkout',
                    style: typography.headlineSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  _SectionCard(
                    title: 'Order summary',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryRow(
                          label: 'Order type',
                          value: draft.orderType?.label ?? '—',
                        ),
                        if (draft.orderType == OrderType.dineIn)
                          _SummaryRow(
                            label: 'Table',
                            value: draft.tableLabel ?? '—',
                          ),
                        if (draft.orderType == OrderType.delivery) ...[
                          _SummaryRow(
                            label: 'Delivery',
                            value: draft.deliveryMode?.label ?? '—',
                          ),
                          if (draft.riderName != null)
                            _SummaryRow(
                              label: 'Rider',
                              value: draft.riderName!,
                            ),
                          if (draft.pickupCompanyName != null)
                            _SummaryRow(
                              label: 'Pickup company',
                              value: draft.pickupCompanyName!,
                            ),
                        ],
                        Divider(height: spacing.lg, color: colors.divider),
                        for (final item in items) ...[
                          _SummaryRow(
                            label:
                                '${item.quantity}x ${item.name}${item.variantName != null ? ' (${item.variantName})' : ''}',
                            value: formatMoney(
                              pricing.linePricing[item.lineId]?.netTotal ??
                                  item.lineTotal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  _SectionCard(
                    title: 'Payment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Payment type',
                          style: typography.labelLarge.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        Wrap(
                          spacing: spacing.sm,
                          runSpacing: spacing.sm,
                          children: PaymentType.values.map((type) {
                            return ChoiceChip(
                              label: Text(type.label),
                              selected: draft.paymentType == type,
                              onSelected: (_) => ref
                                  .read(checkoutProvider.notifier)
                                  .setPaymentType(type),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: spacing.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Prepaid order',
                            style: typography.bodyMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            draft.orderType?.defaultIsPrepaid == true
                                ? 'On by default for ${draft.orderType?.label ?? 'this order type'}'
                                : 'Off by default for dine-in — enable to mark paid on placement',
                            style: typography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          value: draft.isPrepaid,
                          onChanged: (value) => ref
                              .read(checkoutProvider.notifier)
                              .setIsPrepaid(value),
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: _promisedPrepController,
                          decoration: const InputDecoration(
                            labelText: 'Customer wait time (minutes)',
                            hintText: 'Optional — overrides product prep times',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final trimmed = value.trim();
                            if (trimmed.isEmpty) {
                              ref
                                  .read(checkoutProvider.notifier)
                                  .setPromisedPrepMinutes(null);
                              return;
                            }
                            final minutes = int.tryParse(trimmed);
                            if (minutes != null && minutes > 0) {
                              ref
                                  .read(checkoutProvider.notifier)
                                  .setPromisedPrepMinutes(minutes);
                            }
                          },
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Order notes (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          onChanged: (value) => ref
                              .read(checkoutProvider.notifier)
                              .setNotes(
                                value.trim().isEmpty ? null : value.trim(),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: spacing.lg),
          SizedBox(
            width: 320,
            child: _SectionCard(
              title: 'Totals',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryRow(
                    label: 'Subtotal',
                    value: formatMoney(pricing.subtotal),
                  ),
                  if (pricing.lineDiscountTotal > 0)
                    _SummaryRow(
                      label: 'Line discounts',
                      value: '-${formatMoney(pricing.lineDiscountTotal)}',
                    ),
                  if (pricing.orderDiscountTotal > 0)
                    _SummaryRow(
                      label: 'Order discount',
                      value: '-${formatMoney(pricing.orderDiscountTotal)}',
                    ),
                  Divider(height: spacing.lg, color: colors.divider),
                  _SummaryRow(
                    label: 'Total',
                    value: formatMoney(pricing.total),
                    emphasized: true,
                  ),
                  SizedBox(height: spacing.md),
                  AppButton(
                    label: _isPlacing
                        ? (ref.watch(editingOrderIdProvider) != null
                            ? 'Updating order…'
                            : 'Placing order…')
                        : (ref.watch(editingOrderIdProvider) != null
                            ? 'Update Order'
                            : 'Place Order'),
                    expand: true,
                    onPressed: _isPlacing ? null : () => _placeOrder(context),
                  ),
                  SizedBox(height: spacing.sm),
                  AppButton(
                    label: 'Back to cart',
                    variant: AppButtonVariant.ghost,
                    expand: true,
                    onPressed: _isPlacing ? null : () => context.go('/sales'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final validationError = ref.read(checkoutValidationErrorProvider);
    if (validationError != null) {
      AppSnackbar.error(context, validationError);
      return;
    }

    final draft = ref.read(checkoutProvider);
    if (draft.paymentType == null) {
      AppSnackbar.error(context, 'Select a payment type');
      return;
    }

    final editingOrderId = ref.read(editingOrderIdProvider);
    setState(() => _isPlacing = true);

    try {
      final controller = ref.read(placeOrderProvider);
      final Order order;

      if (editingOrderId != null) {
        order = await controller.update(
          UpdateOrderInput(
            orderId: editingOrderId,
            checkout: draft,
            cartItems: ref.read(cartProvider),
            discounts: ref.read(cartDiscountsProvider),
            pricing: ref.read(cartPricingProvider),
            paymentType: draft.paymentType!,
            isPrepaid: draft.isPrepaid,
            deviceId: controller.deviceId,
            notes: draft.notes,
          ),
        );
      } else {
        order = await controller.place(
          PlaceOrderInput(
            checkout: draft,
            cartItems: ref.read(cartProvider),
            discounts: ref.read(cartDiscountsProvider),
            pricing: ref.read(cartPricingProvider),
            paymentType: draft.paymentType!,
            isPrepaid: draft.isPrepaid,
            createdByUserId: controller.createdByUserId,
            deviceId: controller.deviceId,
            notes: draft.notes,
          ),
        );
      }

      ref.read(cartProvider.notifier).clear();
      ref.read(cartDiscountsProvider.notifier).clear();
      ref.read(orderEditLoaderProvider).clearEditMode();
      await ref.read(checkoutProvider.notifier).clear();

      if (editingOrderId == null) {
        final orderId = order.id;
        unawaited(_printOrderSlips(orderId));
      }

      if (!context.mounted) return;
      context.go('/sales/confirmation/${order.id}');
    } on OrderPlacementException catch (error) {
      if (context.mounted) {
        AppSnackbar.error(context, error.message);
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to place order: $error');
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  Future<void> _printOrderSlips(String orderId) async {
    await _printKitchenCopy(orderId);
    await _printCustomerReceipt(orderId);
  }

  Future<void> _printKitchenCopy(String orderId) async {
    try {
      final result = await ref
          .read(kitchenTicketPrintControllerProvider)
          .printOrder(orderId: orderId, isReprint: false);
      if (!mounted) return;
      showKitchenPrintFeedback(context, result);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.info(
        context,
        'Order placed, but kitchen printing failed: $error',
      );
    }
  }

  Future<void> _printCustomerReceipt(String orderId) async {
    try {
      final result = await ref
          .read(receiptPrintControllerProvider)
          .printOrder(orderId: orderId, isReprint: false, forPlacement: true);
      if (!mounted) return;
      showReceiptPrintFeedback(context, result);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.info(
        context,
        'Order placed, but receipt printing failed: $error',
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: typography.titleMedium.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final style = emphasized ? typography.titleMedium : typography.bodyMedium;

    return Padding(
      padding: EdgeInsets.only(bottom: context.appSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style.copyWith(color: colors.onSurface),
            ),
          ),
          Text(
            value,
            style: style.copyWith(
              color: emphasized ? colors.primary : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
