import 'dart:async';

import 'package:isar/isar.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/services/dashboard_analytics.dart';
import '../local/collections/attendance_record_isar.dart';
import '../local/collections/category_isar.dart';
import '../local/collections/order_isar.dart';
import '../local/collections/product_isar.dart';
import '../local/mappers/order_mapper.dart';

class DashboardRepository {
  DashboardRepository(this._isar);

  final Isar _isar;

  Stream<DashboardSnapshot> watchSnapshot() {
    late StreamSubscription<List<OrderIsar>> ordersSub;
    late StreamSubscription<List<AttendanceRecordIsar>> attendanceSub;
    final controller = StreamController<DashboardSnapshot>();

    Future<void> emit() async {
      if (controller.isClosed) return;
      controller.add(await _buildSnapshot());
    }

    ordersSub = _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .watch(fireImmediately: true)
        .listen((_) => emit());

    attendanceSub = _isar.attendanceRecordIsars
        .filter()
        .deletedAtIsNull()
        .watch(fireImmediately: true)
        .listen((_) => emit());

    controller.onCancel = () async {
      await ordersSub.cancel();
      await attendanceSub.cancel();
    };

    return controller.stream;
  }

  Future<DashboardSnapshot> _buildSnapshot() async {
    final orderRecords = await _isar.orderIsars
        .filter()
        .deletedAtIsNull()
        .findAll();
    final orders = orderRecords.map(orderFromIsar).toList();
    final orderIds = orders.map((order) => order.id).toSet();

    final itemRecords = await _isar.orderItemIsars
        .filter()
        .deletedAtIsNull()
        .findAll();
    final items = itemRecords
        .where((record) => orderIds.contains(record.orderId))
        .map(orderItemFromIsar)
        .toList();

    final productRecords = await _isar.productIsars
        .filter()
        .deletedAtIsNull()
        .findAll();
    final categoryRecords = await _isar.categoryIsars
        .filter()
        .deletedAtIsNull()
        .findAll();

    final attendanceRecords = await _isar.attendanceRecordIsars
        .filter()
        .deletedAtIsNull()
        .findAll();
    final employeesPresent = attendanceRecords
        .where((record) => record.isOpen)
        .map((record) => record.employeeId)
        .toSet()
        .length;

    return DashboardAnalyticsEngine.compute(
      DashboardAnalyticsInput(
        orders: orders,
        items: items,
        productCategoryByProductId: {
          for (final record in productRecords) record.uuid: record.categoryId,
        },
        categoryNameById: {
          for (final record in categoryRecords) record.uuid: record.name,
        },
        employeesPresent: employeesPresent,
      ),
    );
  }
}
