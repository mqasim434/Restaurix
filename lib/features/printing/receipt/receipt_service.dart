import 'package:isar/isar.dart';

import '../../../data/local/collections/restaurant_table_isar.dart';
import '../../../data/repositories/app_setting_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order_enums.dart';
import '../kitchen_ticket/esc_pos_transport_router.dart';
import 'receipt_builder.dart';
import 'receipt_data.dart';
import 'receipt_template.dart';

class ReceiptService {
  ReceiptService({
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

  Future<ReceiptPrintResult> printOrder({
    required String orderId,
    required bool isReprint,
  }) async {
    final order = await _orders.findById(orderId);
    if (order == null) {
      return const ReceiptPrintResult(
        warnings: ['Order not found — receipt not printed'],
      );
    }

    if (order.status == OrderStatus.cancelled) {
      return const ReceiptPrintResult(
        warnings: ['Cancelled orders do not receive customer receipts'],
      );
    }

    if (!isReprint && !ReceiptPrintPolicy.shouldAutoPrint(order)) {
      return const ReceiptPrintResult(
        warnings: ['Receipt prints when the order is marked paid'],
      );
    }

    final appSettings = await _settings.loadSettings();
    final printerTarget = appSettings.resolvedReceiptPrinterTarget();
    if (printerTarget == null || printerTarget.trim().isEmpty) {
      return const ReceiptPrintResult(
        warnings: [
          'No receipt printer configured. Set one in Settings → Printers.',
        ],
      );
    }

    final items = await _orders.findItemsByOrderId(orderId);
    final tableLabels = await _loadTableLabels([order.tableId]);

    final receipt = ReceiptBuilder.fromPersisted(
      order: order,
      items: items,
      businessName: appSettings.businessName,
      businessAddress: appSettings.businessAddress,
      receiptHeaderText: appSettings.receiptHeaderText,
      receiptFooterText: appSettings.receiptFooterText,
      tableLabelsById: tableLabels,
      isReprint: isReprint,
    );

    try {
      final bytes = await ReceiptTemplate.buildBytes(receipt);
      await _transport.send(target: printerTarget.trim(), bytes: bytes);
      return const ReceiptPrintResult(printed: true);
    } catch (error) {
      return ReceiptPrintResult(
        warnings: ['Failed to print receipt: $error'],
      );
    }
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
