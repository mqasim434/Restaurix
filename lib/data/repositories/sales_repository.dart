import 'package:isar/isar.dart';

import '../../core/utils/date_range_utils.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/sales_analytics.dart';
import '../../domain/services/sales_analytics.dart';
import '../local/collections/category_isar.dart';
import '../local/collections/order_isar.dart';
import '../local/collections/product_isar.dart';
import '../local/mappers/order_mapper.dart';

class SalesRepository {
  SalesRepository(this._isar);

  final Isar _isar;
  final SalesAnalyticsEngine _engine = const SalesAnalyticsEngine();

  Future<SalesAnalyticsSnapshot> loadSnapshot(
    SalesDateRange range, {
    String Function(String userId)? employeeDisplayName,
  }) async {
    final orders = await _loadOrdersInRange(range);
    final orderIds = orders.map((order) => order.id).toSet();
    final items = await _loadItemsForOrders(orderIds);
    final productCategoryByProductId = await _loadProductCategoryMap();
    final categoryNameById = await _loadCategoryNameMap();

    return _engine.compute(
      orders: orders,
      items: items,
      productCategoryByProductId: productCategoryByProductId,
      categoryNameById: categoryNameById,
      employeeDisplayName: employeeDisplayName,
    );
  }

  Future<List<Order>> _loadOrdersInRange(SalesDateRange range) async {
    final records = await _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .createdAtGreaterThan(
          range.startInclusive,
          include: true,
        )
        .createdAtLessThan(
          range.endExclusive,
          include: false,
        )
        .findAll();

    return records.map(orderFromIsar).toList();
  }

  Future<List<OrderItem>> _loadItemsForOrders(Set<String> orderIds) async {
    if (orderIds.isEmpty) return const [];

    final records = await _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    return records
        .where((record) => orderIds.contains(record.orderId))
        .map(orderItemFromIsar)
        .toList();
  }

  Future<Map<String, String>> _loadProductCategoryMap() async {
    final records = await _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    return {
      for (final record in records) record.uuid: record.categoryId,
    };
  }

  Future<Map<String, String>> _loadCategoryNameMap() async {
    final records = await _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    return {
      for (final record in records) record.uuid: record.name,
    };
  }
}
