import 'package:isar/isar.dart';

import '../../../data/local/collections/product_isar.dart';
import '../../../data/local/collections/restaurant_table_isar.dart';
import '../../../data/repositories/app_setting_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/order_enums.dart';
import 'esc_pos_transport_router.dart';
import 'kitchen_ticket_data.dart';
import 'kitchen_ticket_grouper.dart';
import 'kitchen_ticket_template.dart';
import 'product_kitchen_meta.dart';

class KitchenTicketService {
  KitchenTicketService({
    required Isar isar,
    required OrderRepository orderRepository,
    required AppSettingRepository settingsRepository,
    EscPosTransportRouter? transport,
  })  : _isar = isar,
        _orders = orderRepository,
        _settings = settingsRepository,
        _transport = transport ?? EscPosTransportRouter();

  final Isar _isar;
  final OrderRepository _orders;
  final AppSettingRepository _settings;
  final EscPosTransportRouter _transport;

  Future<KitchenTicketPrintResult> printOrder({
    required String orderId,
    required bool isReprint,
  }) async {
    final order = await _orders.findById(orderId);
    if (order == null) {
      return const KitchenTicketPrintResult(
        warnings: ['Order not found — kitchen ticket not printed'],
      );
    }

    if (order.status == OrderStatus.cancelled) {
      return const KitchenTicketPrintResult(
        warnings: ['Cancelled orders are not sent to the kitchen'],
      );
    }

    final items = await _orders.findItemsByOrderId(orderId);
    final productMeta = await _loadProductMeta(items);
    final defaultPrinter = await _settings.getKitchenDefaultPrinterId();
    final tableLabels = await _loadTableLabels([order.tableId]);

    final warnings = KitchenTicketGrouper.collectMissingPrinterWarnings(
      items: items,
      productMetaById: productMeta,
      defaultPrinterId: defaultPrinter,
    );

    final jobs = KitchenTicketGrouper.buildPrintJobs(
      order: order,
      items: items,
      productMetaById: productMeta,
      defaultPrinterId: defaultPrinter,
      isReprint: isReprint,
      contextLabel: KitchenTicketGrouper.contextLabel(
        order: order,
        tableLabelsById: tableLabels,
      ),
    );

    if (jobs.isEmpty) {
      return KitchenTicketPrintResult(warnings: warnings);
    }

    var printed = 0;
    final printWarnings = [...warnings];

    for (final job in jobs) {
      try {
        final bytes = await KitchenTicketTemplate.buildBytes(job.ticket);
        await _transport.send(target: job.printerTarget, bytes: bytes);
        printed += 1;
      } catch (error) {
        printWarnings.add(
          'Failed to print to "${job.printerTarget}": $error',
        );
      }
    }

    return KitchenTicketPrintResult(
      ticketsPrinted: printed,
      warnings: printWarnings,
    );
  }

  Future<Map<String, ProductKitchenMeta>> _loadProductMeta(
    List<OrderItem> items,
  ) async {
    final productIds = items
        .map((item) => item.productId)
        .whereType<String>()
        .toSet();
    if (productIds.isEmpty) return const {};

    final records = await _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    final result = <String, ProductKitchenMeta>{};
    for (final record in records) {
      if (!productIds.contains(record.uuid)) continue;
      result[record.uuid] = ProductKitchenMeta(
        kitchenCategory: record.kitchenCategory,
        printerId: record.printerId,
      );
    }
    return result;
  }

  Future<Map<String, String>> _loadTableLabels(List<String?> tableIds) async {
    final ids = tableIds.whereType<String>().toSet();
    if (ids.isEmpty) return const {};

    final records = await _isar.restaurantTableIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    return {
      for (final record in records)
        if (ids.contains(record.uuid)) record.uuid: record.label,
    };
  }
}
