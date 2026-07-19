import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/order_held_badge.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/remote/supabase_service.dart';
import '../../../data/services/order_number_service.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/services/order_lifecycle.dart';
import '../../../domain/services/tablet_order_detection.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../orders/presentation/mark_paid_dialog.dart';
import '../../orders/providers/order_management_providers.dart';
import '../../printing/providers/kitchen_ticket_providers.dart';
import '../../printing/providers/receipt_providers.dart';
import '../../settings/providers/currency_providers.dart';
import '../providers/delivery_location_providers.dart';
import '../providers/tablet_order_providers.dart';
import '../services/tablet_order_auto_print_service.dart';
import 'live_order_detail_dialog.dart';

/// Charge field shown before a live order receipt can print.
enum _LiveChargeKind { service, delivery }

_LiveChargeKind _chargeKindFor(Order order) {
  if (isCustomerAppOrder(order) && order.orderType == OrderType.delivery) {
    return _LiveChargeKind.delivery;
  }
  return _LiveChargeKind.service;
}

/// Live order board: waiter tablets | customer app | all with mark-paid.
class TabletOrdersScreen extends ConsumerWidget {
  const TabletOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final syncEnabled =
        EnvConfig.isSupabaseConfigured && SupabaseService.isInitialized;
    final allAsync = ref.watch(tabletOrderListProvider);
    final waiterAsync = ref.watch(waiterTabletOrderListProvider);
    final customerAsync = ref.watch(customerAppOrderListProvider);
    final arrivalState = ref.watch(tabletOrderArrivalControllerProvider);
    final localDeviceId = ref.watch(deviceIdProvider);

    ref.listen<AsyncValue<List<Order>>>(tabletOrderListProvider, (previous, next) {
      next.whenData((orders) {
        ref
            .read(tabletOrderArrivalControllerProvider.notifier)
            .reconcileSyncedOrders(orders);
      });
    });

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            syncEnabled
                ? 'Enter service or delivery charges, press Enter to print, then mark paid in All orders'
                : 'Configure Supabase to receive live orders from tablets and the customer app',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.md),
          Expanded(
            child: allAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading live orders...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load live orders',
                message: error.toString(),
              ),
              data: (allOrders) {
                bool isOpenLiveOrder(Order order) =>
                    !order.paymentStatus.isSettled &&
                    order.status != OrderStatus.cancelled &&
                    order.status != OrderStatus.completed;

                final unpaid = allOrders.where(isOpenLiveOrder).toList();
                final waiterOrders = (waiterAsync.valueOrNull
                            ?.where(isOpenLiveOrder)
                            .toList() ??
                        unpaid
                            .where(
                              (order) =>
                                  isWaiterTabletOrder(order, localDeviceId),
                            )
                            .toList())
                    .where((order) => order.needsBillConfirmation)
                    .toList();
                final customerOrders = (customerAsync.valueOrNull
                            ?.where(isOpenLiveOrder)
                            .toList() ??
                        unpaid.where(isCustomerAppOrder).toList())
                    .where((order) => order.needsBillConfirmation)
                    .toList();
                final confirmedOrders = unpaid
                    .where((order) => !order.needsBillConfirmation)
                    .toList();

                final syncedIds = allOrders.map((order) => order.id).toSet();
                final incoming = arrivalState.pending
                    .where((entry) => !syncedIds.contains(entry.orderId))
                    .toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _OrderColumn(
                        title: 'In-house',
                        subtitle: 'Enter Service Charges → print',
                        icon: Icons.tablet_android_outlined,
                        emptyMessage: 'No in-house orders awaiting charges',
                        orders: waiterOrders,
                        incoming: incoming
                            .where(
                              (entry) =>
                                  !isCustomerAppOrderNumber(entry.orderNumber),
                            )
                            .toList(),
                        arrivalState: arrivalState,
                        showMarkPaid: false,
                        showChargeInput: true,
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: _OrderColumn(
                        title: 'Customer app',
                        subtitle: 'Enter Delivery / Service Charges → print',
                        icon: Icons.smartphone_outlined,
                        emptyMessage: 'No customer orders awaiting charges',
                        orders: customerOrders,
                        incoming: incoming
                            .where(
                              (entry) =>
                                  isCustomerAppOrderNumber(entry.orderNumber),
                            )
                            .toList(),
                        arrivalState: arrivalState,
                        showMarkPaid: false,
                        showChargeInput: true,
                      ),
                    ),
                    SizedBox(width: spacing.md),
                    Expanded(
                      child: _OrderColumn(
                        title: 'All orders',
                        subtitle: 'Mark paid / complete credit',
                        icon: Icons.payments_outlined,
                        emptyMessage: 'No confirmed bills yet',
                        orders: confirmedOrders,
                        incoming: const [],
                        arrivalState: arrivalState,
                        showMarkPaid: true,
                        showChargeInput: false,
                      ),
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
}

class _OrderColumn extends ConsumerWidget {
  const _OrderColumn({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emptyMessage,
    required this.orders,
    required this.incoming,
    required this.arrivalState,
    required this.showMarkPaid,
    required this.showChargeInput,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String emptyMessage;
  final List<Order> orders;
  final List<PendingTabletOrder> incoming;
  final TabletOrderArrivalState arrivalState;
  final bool showMarkPaid;
  final bool showChargeInput;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final totalCount = incoming.length + orders.length;

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
                Icon(icon, color: colors.secondary, size: spacing.lg),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: typography.titleMedium),
                      Text(
                        subtitle,
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountBadge(count: totalCount),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: totalCount == 0
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: typography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(spacing.sm),
                    itemCount: totalCount,
                    separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      if (index < incoming.length) {
                        return _IncomingOrderCard(
                          pending: incoming[index],
                          isHighlighted: arrivalState.highlightedOrderIds
                              .contains(incoming[index].orderId),
                        );
                      }
                      final order = orders[index - incoming.length];
                      return _LiveOrderCard(
                        order: order,
                        isHighlighted: arrivalState.highlightedOrderIds
                            .contains(order.id),
                        showMarkPaid: showMarkPaid,
                        showChargeInput: showChargeInput,
                        onOpened: () => ref
                            .read(tabletOrderArrivalControllerProvider.notifier)
                            .acknowledgeHighlight(order.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Text(
          '$count',
          style: typography.labelMedium.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard({
    required this.pending,
    required this.isHighlighted,
  });

  final PendingTabletOrder pending;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(
          color: isHighlighted ? colors.secondary : colors.border,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      padding: EdgeInsets.all(spacing.md),
      child: Row(
        children: [
          SizedBox(
            width: spacing.lg,
            height: spacing.lg,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.secondary,
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pending.orderNumber, style: typography.titleSmall),
                Text(
                  'Incoming · syncing…',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveOrderCard extends ConsumerStatefulWidget {
  const _LiveOrderCard({
    required this.order,
    required this.isHighlighted,
    required this.showMarkPaid,
    required this.showChargeInput,
    required this.onOpened,
  });

  final Order order;
  final bool isHighlighted;
  final bool showMarkPaid;
  final bool showChargeInput;
  final VoidCallback onOpened;

  @override
  ConsumerState<_LiveOrderCard> createState() => _LiveOrderCardState();
}

class _LiveOrderCardState extends ConsumerState<_LiveOrderCard> {
  late final TextEditingController _chargeController;
  var _isConfirming = false;

  Order get order => widget.order;

  @override
  void initState() {
    super.initState();
    _chargeController = TextEditingController();
  }

  @override
  void dispose() {
    _chargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatMoney = ref.watch(formatMoneyProvider);
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final role = ref.watch(currentUserProvider).role;
    final itemsAsync = ref.watch(orderItemsProvider(order.id));
    final canPay = OrderLifecycle.canMarkPaid(order, role);
    final canCompleteCredit =
        OrderLifecycle.canCompleteCreditOrder(order, role);
    final isCancelled = order.status == OrderStatus.cancelled;
    final isHeld = order.isHeld;
    final sourceLabel = isCustomerAppOrder(order)
        ? 'Customer app'
        : 'In-house';
    final chargeKind = _chargeKindFor(order);
    final chargeLabel = chargeKind == _LiveChargeKind.delivery
        ? 'Delivery Charges'
        : 'Service Charges';

    return Material(
      color: isCancelled
          ? colors.errorContainer.withValues(alpha: 0.25)
          : isHeld
              ? colors.warning.withValues(alpha: 0.12)
              : widget.isHighlighted
                  ? colors.secondaryContainer.withValues(alpha: 0.25)
                  : colors.surfaceVariant.withValues(alpha: 0.35),
      borderRadius: context.appRadius.mdBorder,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: context.appRadius.mdBorder,
          border: Border.all(
            color: widget.isHighlighted
                ? colors.secondary
                : isCancelled
                    ? colors.error.withValues(alpha: 0.4)
                    : colors.border,
            width: widget.isHighlighted ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: context.appRadius.smBorder,
              onTap: () {
                widget.onOpened();
                LiveOrderDetailDialog.show(context, orderId: order.id);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNumber,
                          style: typography.titleSmall.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      if (widget.isHighlighted)
                        _Chip(
                          label: 'New',
                          emphasized: true,
                          accent: colors.secondary,
                          onAccent: colors.onSecondary,
                        ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '$sourceLabel · ${order.orderType.label}',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (order.customerName?.trim().isNotEmpty == true)
                    Text(
                      order.customerName!.trim(),
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  if (order.customerPhone?.trim().isNotEmpty == true)
                    Text(
                      order.customerPhone!.trim(),
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (order.orderType == OrderType.delivery)
                    _DeliveryLocationBlock(orderId: order.id),
                  Text(
                    DateFormat.MMMd().add_jm().format(order.createdAt),
                    style: typography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (isHeld) ...[
                    SizedBox(height: spacing.xs),
                    const OrderHeldBadge(compact: true),
                  ],
                  SizedBox(height: spacing.sm),
                  itemsAsync.when(
                    loading: () => Text(
                      'Loading items…',
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    error: (_, __) => Text(
                      'Items unavailable',
                      style: typography.bodySmall.copyWith(color: colors.error),
                    ),
                    data: (items) => _OrderItemsSummary(
                      items: items,
                      formatMoney: formatMoney,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Row(
                    children: [
                      _Chip(label: order.status.label, emphasized: true),
                      SizedBox(width: spacing.xs),
                      _Chip(label: order.paymentStatus.label),
                      const Spacer(),
                      Text(
                        formatMoney(order.total),
                        style: typography.titleSmall.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.showChargeInput) ...[
              SizedBox(height: spacing.sm),
              Text(
                chargeLabel,
                style: typography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.xs),
              TextField(
                controller: _chargeController,
                enabled: !_isConfirming,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '0',
                  suffixText: 'Enter ↵',
                  border: OutlineInputBorder(
                    borderRadius: context.appRadius.smBorder,
                  ),
                ),
                onSubmitted: (_) => _confirmCharges(context),
              ),
            ],
            if (widget.showMarkPaid) ...[
              SizedBox(height: spacing.sm),
              if (order.serviceCharge > 0 || order.deliveryCharge > 0)
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xs),
                  child: Text(
                    [
                      if (order.serviceCharge > 0)
                        'Service Charges ${formatMoney(order.serviceCharge)}',
                      if (order.deliveryCharge > 0)
                        'Delivery Charges ${formatMoney(order.deliveryCharge)}',
                    ].join(' · '),
                    style: typography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (canPay)
                AppButton(
                  label: 'Mark paid',
                  size: AppButtonSize.small,
                  expand: true,
                  onPressed: () => _markPaid(context),
                )
              else if (canCompleteCredit)
                AppButton(
                  label: 'Complete Order',
                  size: AppButtonSize.small,
                  expand: true,
                  onPressed: () => _completeCreditOrder(context),
                )
              else if (order.paymentType == PaymentType.credit)
                _Chip(label: 'On credit — admin can complete')
              else if (order.paymentStatus.isSettled)
                _Chip(
                  label: 'Paid',
                  emphasized: true,
                  accent: colors.secondary,
                  onAccent: colors.onSecondary,
                )
              else
                _Chip(label: 'Only admin can mark paid'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCharges(BuildContext context) async {
    if (_isConfirming) return;

    final raw = _chargeController.text.trim();
    final amount = raw.isEmpty ? 0.0 : double.tryParse(raw);
    if (amount == null) {
      AppSnackbar.error(context, 'Enter a valid amount');
      return;
    }
    if (amount < 0) {
      AppSnackbar.error(context, 'Charges cannot be negative');
      return;
    }

    final kind = _chargeKindFor(order);
    final serviceCharge = kind == _LiveChargeKind.service ? amount : 0.0;
    final deliveryCharge = kind == _LiveChargeKind.delivery ? amount : 0.0;

    // Capture controllers before awaits — confirming the bill removes this card
    // from the column and disposes this State; later ref.read() would fail and
    // skip the customer receipt after kitchen already printed.
    final placeOrder = ref.read(placeOrderProvider);
    final kitchenPrinter = ref.read(kitchenTicketPrintControllerProvider);
    final receiptPrinter = ref.read(receiptPrintControllerProvider);
    final autoPrint = ref.read(tabletOrderAutoPrintServiceProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);

    setState(() => _isConfirming = true);
    try {
      final confirmed = await placeOrder.confirmLiveOrderBill(
        orderId: order.id,
        serviceCharge: serviceCharge,
        deliveryCharge: deliveryCharge,
      );

      final kitchenResult = await kitchenPrinter.printOrder(
        orderId: order.id,
        isReprint: false,
      );

      // Give the Windows spooler a moment before the second raw job.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      var receiptResult = await receiptPrinter.printOrder(
        orderId: order.id,
        isReprint: false,
        forPlacement: true,
        orderSnapshot: confirmed,
      );
      if (!receiptResult.printed) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        receiptResult = await receiptPrinter.printOrder(
          orderId: order.id,
          isReprint: false,
          forPlacement: true,
          orderSnapshot: confirmed,
        );
      }

      await autoPrint.markSlipsPrinted(order.id);

      final warnings = <String>[
        ...kitchenResult.warnings,
        ...receiptResult.warnings,
      ];
      final message = !receiptResult.printed
          ? 'Kitchen printed, but receipt failed'
              '${warnings.isEmpty ? '' : ': ${warnings.join('; ')}'}'
          : warnings.isNotEmpty
              ? 'Printed with warnings: ${warnings.join('; ')}'
              : 'Kitchen + receipt printed — order moved to All orders';

      if (context.mounted) {
        if (!receiptResult.printed) {
          AppSnackbar.error(context, message);
        } else if (warnings.isNotEmpty) {
          AppSnackbar.info(context, message);
        } else {
          AppSnackbar.success(context, message);
        }
      } else if (messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      final message = error.toString();
      if (context.mounted) {
        AppSnackbar.error(context, message);
      } else if (messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<void> _markPaid(BuildContext context) async {
    final paymentType = await MarkPaidDialog.show(
      context,
      initialPaymentType: order.paymentType == PaymentType.credit
          ? PaymentType.cash
          : order.paymentType,
    );
    if (paymentType == null || !context.mounted) return;

    try {
      await ref.read(placeOrderProvider).markPaid(
            orderId: order.id,
            paymentType: paymentType,
          );
      if (!context.mounted) return;
      AppSnackbar.success(context, 'Order marked paid and completed');
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.toString());
    }
  }

  Future<void> _completeCreditOrder(BuildContext context) async {
    try {
      await ref.read(placeOrderProvider).completeCreditOrder(
            orderId: order.id,
          );
      if (!context.mounted) return;
      AppSnackbar.success(
        context,
        'Order completed — settle balance in Credit Customers',
      );
    } catch (error) {
      if (!context.mounted) return;
      AppSnackbar.error(context, error.toString());
    }
  }
}

class _OrderItemsSummary extends StatelessWidget {
  const _OrderItemsSummary({
    required this.items,
    required this.formatMoney,
  });

  final List<OrderItem> items;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    if (items.isEmpty) {
      return Text(
        'No items',
        style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}× ${item.name}'
                    '${item.variantName == null || item.variantName!.isEmpty ? '' : ' (${item.variantName})'}',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  formatMoney(item.lineTotal),
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DeliveryLocationBlock extends ConsumerWidget {
  const _DeliveryLocationBlock({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final locationAsync = ref.watch(deliveryLocationInfoProvider(orderId));

    return locationAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.only(top: spacing.xs),
        child: Text(
          'Resolving location…',
          style: typography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        if (!info.hasLocation &&
            info.distanceLabel == null &&
            (info.deliveryNotes == null || info.deliveryNotes!.isEmpty)) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(top: spacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info.hasLocation) ...[
                Text(
                  'Location',
                  style: typography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                for (final line in info.lines)
                  Text(
                    line,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
              ],
              if (info.distanceLabel != null)
                Text(
                  'Distance: ${info.distanceLabel}',
                  style: typography.bodySmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (info.deliveryNotes != null &&
                  info.deliveryNotes!.trim().isNotEmpty)
                Text(
                  'Note: ${info.deliveryNotes!.trim()}',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.emphasized = false,
    this.accent,
    this.onAccent,
  });

  final String label;
  final bool emphasized;
  final Color? accent;
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? (accent ?? colors.primaryContainer)
            : colors.surfaceVariant,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Text(
          label,
          style: typography.labelSmall.copyWith(
            color: emphasized
                ? (onAccent ?? colors.onPrimaryContainer)
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
