import 'package:isar/isar.dart';

import '../../core/utils/date_range_utils.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../local/collections/category_isar.dart';
import '../local/collections/order_isar.dart';
import '../local/collections/product_isar.dart';
import '../local/mappers/order_mapper.dart';

class OrderAnalyticsData {
  const OrderAnalyticsData({
    required this.orders,
    required this.items,
    required this.productCategoryByProductId,
    required this.categoryNameById,
    required this.kitchenCategoryByProductId,
  });

  final List<Order> orders;
  final List<OrderItem> items;
  final Map<String, String> productCategoryByProductId;
  final Map<String, String> categoryNameById;
  final Map<String, String> kitchenCategoryByProductId;
}

class OrderAnalyticsLoader {
  OrderAnalyticsLoader(this._isar);

  final Isar _isar;

  Future<OrderAnalyticsData> load(SalesDateRange range) async {
    final orders = await _loadOrdersInRange(range);
    final orderIds = orders.map((order) => order.id).toSet();
    final items = await _loadItemsForOrders(orderIds);
    final productRecords = await _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .findAll();
    final categoryRecords = await _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    return OrderAnalyticsData(
      orders: orders,
      items: items,
      productCategoryByProductId: {
        for (final record in productRecords) record.uuid: record.categoryId,
      },
      categoryNameById: {
        for (final record in categoryRecords) record.uuid: record.name,
      },
      kitchenCategoryByProductId: {
        for (final record in productRecords)
          record.uuid: record.kitchenCategory,
      },
    );
  }

  Future<List<Order>> _loadOrdersInRange(SalesDateRange range) async {
    final records = await _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .createdAtGreaterThan(range.startInclusive, include: true)
        .createdAtLessThan(range.endExclusive, include: false)
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
}
