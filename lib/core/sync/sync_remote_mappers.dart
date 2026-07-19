import 'package:isar/isar.dart';

import '../../core/constants.dart';
import '../../data/local/collections/credit_customer_isar.dart';
import '../../data/local/collections/credit_transaction_isar.dart';
import '../../data/local/collections/attendance_record_isar.dart';
import '../../data/local/collections/category_isar.dart';
import '../../data/local/collections/deal_isar.dart';
import '../../data/local/collections/deal_item_isar.dart';
import '../../data/local/collections/employee_isar.dart';
import '../../data/local/collections/hall_isar.dart';
import '../../data/local/collections/order_isar.dart';
import '../../data/local/collections/pickup_company_isar.dart';
import '../../data/local/collections/product_isar.dart';
import '../../data/local/collections/product_variant_isar.dart';
import '../../data/local/collections/restaurant_table_isar.dart';
import '../../data/local/collections/rider_isar.dart';
import '../../data/local/collections/salary_slip_isar.dart';
import '../../domain/models/table_status.dart';
import 'sync_remote_codec.dart';

Map<String, dynamic> _standardFields(dynamic record) {
  return SyncRemoteCodec.standardFields(
    id: record.uuid as String,
    createdAt: record.createdAt as DateTime,
    updatedAt: record.updatedAt as DateTime,
    isSynced: true,
    deletedAt: record.deletedAt as DateTime?,
    syncAction: record.syncAction as String,
    deviceId: record.deviceId as String,
    version: record.version as int,
  );
}

void _applyStandardFields(dynamic record, Map<String, dynamic> remote) {
  record
    ..createdAt = SyncRemoteCodec.parseDateTime(remote['created_at'])
    ..updatedAt = SyncRemoteCodec.parseDateTime(remote['updated_at'])
    ..isSynced = true
    ..deletedAt = SyncRemoteCodec.parseNullableDateTime(remote['deleted_at'])
    ..syncAction = remote['sync_action'] as String
    ..deviceId = (remote['device_id'] as String?) ?? ''
    ..version = SyncRemoteCodec.parseInt(remote['version']);
}

abstract final class CategoryRemoteMapper {
  static Map<String, dynamic> toRemote(CategoryIsar record) {
    return {
      ..._standardFields(record),
      'name': record.name,
      'image_url': record.imageUrl,
      'sort_order': record.sortOrder,
      'is_active': record.isActive,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.categoryIsars.filter().uuidEqualTo(id).findFirst() ??
              (CategoryIsar()..uuid = id);
      record
        ..name = remote['name'] as String
        ..imageUrl = remote['image_url'] as String?
        ..sortOrder = SyncRemoteCodec.parseInt(remote['sort_order'])
        ..isActive = remote['is_active'] as bool? ?? true;
      _applyStandardFields(record, remote);
      await isar.categoryIsars.put(record);
    });
  }
}

abstract final class ProductRemoteMapper {
  static Map<String, dynamic> toRemote(ProductIsar record) {
    return {
      ..._standardFields(record),
      'name': record.name,
      'category_id': record.categoryId,
      'base_price': record.basePrice,
      'description': record.description,
      'image_url': record.imageUrl,
      'is_available': record.isAvailable,
      'kitchen_category': record.kitchenCategory,
      'printer_id': record.printerId,
      'estimated_prep_minutes': record.estimatedPrepMinutes,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.productIsars.filter().uuidEqualTo(id).findFirst() ??
              (ProductIsar()..uuid = id);
      record
        ..name = remote['name'] as String
        ..categoryId = remote['category_id'] as String
        ..basePrice = SyncRemoteCodec.parseDouble(remote['base_price'])
        ..description = remote['description'] as String?
        ..imageUrl = remote['image_url'] as String?
        ..isAvailable = remote['is_available'] as bool? ?? true
        ..kitchenCategory = remote['kitchen_category'] as String? ?? ''
        ..printerId = remote['printer_id'] as String?
        ..estimatedPrepMinutes = remote['estimated_prep_minutes'] == null
            ? AppConstants.defaultProductPrepMinutes
            : SyncRemoteCodec.parseInt(remote['estimated_prep_minutes']);
      _applyStandardFields(record, remote);
      await isar.productIsars.put(record);
    });
  }
}

abstract final class ProductVariantRemoteMapper {
  static Map<String, dynamic> toRemote(ProductVariantIsar record) {
    return {
      ..._standardFields(record),
      'product_id': record.productId,
      'name': record.name,
      'price': record.price,
      'sort_order': record.sortOrder,
      'is_default': record.isDefault,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record = await isar.productVariantIsars
              .filter()
              .uuidEqualTo(id)
              .findFirst() ??
          (ProductVariantIsar()..uuid = id);
      record
        ..productId = remote['product_id'] as String
        ..name = remote['name'] as String
        ..price = SyncRemoteCodec.parseDouble(remote['price'])
        ..sortOrder = SyncRemoteCodec.parseInt(remote['sort_order'])
        ..isDefault = remote['is_default'] as bool? ?? false;
      _applyStandardFields(record, remote);
      await isar.productVariantIsars.put(record);
    });
  }
}

abstract final class DealRemoteMapper {
  static Map<String, dynamic> toRemote(DealIsar record) {
    return {
      ..._standardFields(record),
      'name': record.name,
      'description': record.description,
      'image_url': record.imageUrl,
      'category_id': record.categoryId,
      'price': record.price,
      'is_available': record.isAvailable,
      'availability_start': record.availabilityStart?.toUtc().toIso8601String(),
      'availability_end': record.availabilityEnd?.toUtc().toIso8601String(),
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.dealIsars.filter().uuidEqualTo(id).findFirst() ??
              (DealIsar()..uuid = id);
      record
        ..name = remote['name'] as String
        ..description = remote['description'] as String?
        ..imageUrl = remote['image_url'] as String?
        ..categoryId = remote['category_id'] as String?
        ..price = SyncRemoteCodec.parseDouble(remote['price'])
        ..isAvailable = remote['is_available'] as bool? ?? true
        ..availabilityStart =
            SyncRemoteCodec.parseNullableDateTime(remote['availability_start'])
        ..availabilityEnd =
            SyncRemoteCodec.parseNullableDateTime(remote['availability_end']);
      _applyStandardFields(record, remote);
      await isar.dealIsars.put(record);
    });
  }
}

abstract final class DealItemRemoteMapper {
  static Map<String, dynamic> toRemote(DealItemIsar record) {
    return {
      ..._standardFields(record),
      'deal_id': record.dealId,
      'product_id': record.productId,
      'variant_id': record.variantId,
      'quantity': record.quantity,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.dealItemIsars.filter().uuidEqualTo(id).findFirst() ??
              (DealItemIsar()..uuid = id);
      record
        ..dealId = remote['deal_id'] as String
        ..productId = remote['product_id'] as String
        ..variantId = remote['variant_id'] as String?
        ..quantity = SyncRemoteCodec.parseInt(remote['quantity']);
      _applyStandardFields(record, remote);
      await isar.dealItemIsars.put(record);
    });
  }
}

abstract final class HallRemoteMapper {
  static Map<String, dynamic> toRemote(HallIsar record) {
    return {
      ..._standardFields(record),
      'name': record.name,
      'sort_order': record.sortOrder,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.hallIsars.filter().uuidEqualTo(id).findFirst() ??
              (HallIsar()..uuid = id);
      record
        ..name = remote['name'] as String
        ..sortOrder = SyncRemoteCodec.parseInt(remote['sort_order']);
      _applyStandardFields(record, remote);
      await isar.hallIsars.put(record);
    });
  }
}

abstract final class RestaurantTableRemoteMapper {
  static Map<String, dynamic> toRemote(RestaurantTableIsar record) {
    return {
      ..._standardFields(record),
      'hall_id': record.hallId,
      'label': record.label,
      'capacity': record.capacity,
      // Normalize legacy `reserved` before syncing up.
      'status': record.statusEnum.name,
      'current_order_id': record.currentOrderId,
      'sort_order': record.sortOrder,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record = await isar.restaurantTableIsars
              .filter()
              .uuidEqualTo(id)
              .findFirst() ??
          (RestaurantTableIsar()..uuid = id);
      final currentOrderId = remote['current_order_id'] as String?;
      record
        ..hallId = remote['hall_id'] as String
        ..label = remote['label'] as String
        ..capacity = SyncRemoteCodec.parseInt(remote['capacity'])
        ..status = TableStatusX.fromWire(
          remote['status'] as String?,
          currentOrderId: currentOrderId,
        ).name
        ..currentOrderId = currentOrderId
        ..sortOrder = SyncRemoteCodec.parseInt(remote['sort_order']);
      _applyStandardFields(record, remote);
      await isar.restaurantTableIsars.put(record);
    });
  }
}

abstract final class RiderRemoteMapper {
  static Map<String, dynamic> toRemote(RiderIsar record) {
    return {
      ..._standardFields(record),
      'name': record.name,
      'phone': record.phone,
      'is_active': record.isActive,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.riderIsars.filter().uuidEqualTo(id).findFirst() ??
              (RiderIsar()..uuid = id);
      record
        ..name = remote['name'] as String
        ..phone = remote['phone'] as String?
        ..isActive = remote['is_active'] as bool? ?? true;
      _applyStandardFields(record, remote);
      await isar.riderIsars.put(record);
    });
  }
}

abstract final class PickupCompanyRemoteMapper {
  static Map<String, dynamic> toRemote(PickupCompanyIsar record) {
    return {
      ..._standardFields(record),
      'name': record.name,
      'logo_url': record.logoUrl,
      'is_active': record.isActive,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record = await isar.pickupCompanyIsars
              .filter()
              .uuidEqualTo(id)
              .findFirst() ??
          (PickupCompanyIsar()..uuid = id);
      record
        ..name = remote['name'] as String
        ..logoUrl = remote['logo_url'] as String?
        ..isActive = remote['is_active'] as bool? ?? true;
      _applyStandardFields(record, remote);
      await isar.pickupCompanyIsars.put(record);
    });
  }
}

abstract final class EmployeeRemoteMapper {
  static Map<String, dynamic> toRemote(EmployeeIsar record) {
    return {
      ..._standardFields(record),
      'full_name': record.fullName,
      'role': record.role,
      'phone': record.phone,
      'hire_date': SyncRemoteCodec.formatDateOnly(record.hireDate),
      'pay_type': record.payType,
      'hourly_rate': record.hourlyRate,
      'monthly_salary_base': record.monthlySalaryBase,
      'fingerprint_enrollment_id': record.fingerprintEnrollmentId,
      'is_active': record.isActive,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.employeeIsars.filter().uuidEqualTo(id).findFirst() ??
              (EmployeeIsar()..uuid = id);
      record
        ..fullName = remote['full_name'] as String
        ..role = remote['role'] as String? ?? ''
        ..phone = remote['phone'] as String?
        ..hireDate = SyncRemoteCodec.parseDateOnly(remote['hire_date'])
        ..payType = remote['pay_type'] as String? ?? 'hourly'
        ..hourlyRate = SyncRemoteCodec.parseNullableDouble(remote['hourly_rate'])
        ..monthlySalaryBase =
            SyncRemoteCodec.parseNullableDouble(remote['monthly_salary_base'])
        ..fingerprintEnrollmentId =
            remote['fingerprint_enrollment_id'] as String?
        ..isActive = remote['is_active'] as bool? ?? true;
      _applyStandardFields(record, remote);
      await isar.employeeIsars.put(record);
    });
  }
}

abstract final class OrderRemoteMapper {
  static Map<String, dynamic> toRemote(OrderIsar record) {
    return {
      ..._standardFields(record),
      'order_number': record.orderNumber,
      'order_type': record.orderType,
      'table_id': record.tableId,
      'delivery_mode': record.deliveryMode,
      'rider_id': record.riderId,
      'rider_name': record.riderName,
      'pickup_company_id': record.pickupCompanyId,
      'pickup_company_name': record.pickupCompanyName,
      'subtotal': record.subtotal,
      'item_discount_total': record.itemDiscountTotal,
      'order_discount_total': record.orderDiscountTotal,
      'service_charge': record.serviceCharge,
      'delivery_charge': record.deliveryCharge,
      'total': record.total,
      'payment_type': record.paymentType,
      'payment_status': record.paymentStatus,
      'status': record.status,
      'is_prepaid': record.isPrepaid,
      'is_held': record.isHeld,
      'created_by_user_id': record.createdByUserId,
      'notes': record.notes,
      'cancel_reason': record.cancelReason,
      'credit_customer_id': record.creditCustomerId,
      'customer_name': record.customerName,
      'customer_phone': record.customerPhone,
      'delivery_address_line1': record.deliveryAddressLine1,
      'delivery_address_line2': record.deliveryAddressLine2,
      'delivery_city': record.deliveryCity,
      'delivery_postcode': record.deliveryPostcode,
      'delivery_notes': record.deliveryNotes,
      'bill_confirmed_at': record.billConfirmedAt?.toUtc().toIso8601String(),
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.orderIsars.filter().uuidEqualTo(id).findFirst() ??
              (OrderIsar()..uuid = id);
      record
        ..orderNumber = remote['order_number'] as String
        ..orderType = remote['order_type'] as String
        ..tableId = remote['table_id'] as String?
        ..deliveryMode = remote['delivery_mode'] as String?
        ..riderId = remote['rider_id'] as String?
        ..riderName = remote['rider_name'] as String?
        ..pickupCompanyId = remote['pickup_company_id'] as String?
        ..pickupCompanyName = remote['pickup_company_name'] as String?
        ..subtotal = SyncRemoteCodec.parseDouble(remote['subtotal'])
        ..itemDiscountTotal =
            SyncRemoteCodec.parseDouble(remote['item_discount_total'])
        ..orderDiscountTotal =
            SyncRemoteCodec.parseDouble(remote['order_discount_total'])
        ..total = SyncRemoteCodec.parseDouble(remote['total'])
        ..paymentType = remote['payment_type'] as String?
        ..paymentStatus = remote['payment_status'] as String
        ..status = remote['status'] as String
        ..isPrepaid = remote['is_prepaid'] as bool? ?? false
        ..isHeld = remote['is_held'] as bool? ?? false
        ..createdByUserId = remote['created_by_user_id'] as String? ?? ''
        ..notes = remote['notes'] as String?
        ..cancelReason = remote['cancel_reason'] as String?
        ..creditCustomerId = remote['credit_customer_id'] as String?;

      if (remote.containsKey('customer_name')) {
        record.customerName = remote['customer_name'] as String?;
      }
      if (remote.containsKey('customer_phone')) {
        record.customerPhone = remote['customer_phone'] as String?;
      }
      if (remote.containsKey('delivery_address_line1')) {
        record.deliveryAddressLine1 =
            remote['delivery_address_line1'] as String?;
      }
      if (remote.containsKey('delivery_address_line2')) {
        record.deliveryAddressLine2 =
            remote['delivery_address_line2'] as String?;
      }
      if (remote.containsKey('delivery_city')) {
        record.deliveryCity = remote['delivery_city'] as String?;
      }
      if (remote.containsKey('delivery_postcode')) {
        record.deliveryPostcode = remote['delivery_postcode'] as String?;
      }
      if (remote.containsKey('delivery_notes')) {
        record.deliveryNotes = remote['delivery_notes'] as String?;
      }

      // Preserve local charges when remote payload lacks these columns
      // (e.g. migration not applied yet on Supabase).
      if (remote.containsKey('service_charge')) {
        record.serviceCharge =
            SyncRemoteCodec.parseDouble(remote['service_charge']);
      }
      if (remote.containsKey('delivery_charge')) {
        record.deliveryCharge =
            SyncRemoteCodec.parseDouble(remote['delivery_charge']);
      }
      if (remote.containsKey('bill_confirmed_at')) {
        record.billConfirmedAt = SyncRemoteCodec.parseNullableDateTime(
          remote['bill_confirmed_at'],
        );
      }

      _applyStandardFields(record, remote);
      await isar.orderIsars.put(record);
    });
  }
}

abstract final class OrderItemRemoteMapper {
  static Map<String, dynamic> toRemote(OrderItemIsar record) {
    return {
      ..._standardFields(record),
      'order_id': record.orderId,
      'product_id': record.productId,
      'deal_id': record.dealId,
      'name': record.name,
      'variant_name': record.variantName,
      'unit_price': record.unitPrice,
      'quantity': record.quantity,
      'line_total': record.lineTotal,
      'applied_discounts': [
        for (final discount in record.appliedDiscounts)
          {
            'scope': discount.scope,
            'type': discount.type,
            'value': discount.value,
            'amount_applied': discount.amountApplied,
            'target_id': discount.targetId,
            'reason': discount.reason,
          },
      ],
      'kitchen_status': record.kitchenStatus,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.orderItemIsars.filter().uuidEqualTo(id).findFirst() ??
              (OrderItemIsar()..uuid = id);
      record
        ..orderId = remote['order_id'] as String
        ..productId = remote['product_id'] as String?
        ..dealId = remote['deal_id'] as String?
        ..name = remote['name'] as String
        ..variantName = remote['variant_name'] as String?
        ..unitPrice = SyncRemoteCodec.parseDouble(remote['unit_price'])
        ..quantity = SyncRemoteCodec.parseInt(remote['quantity'])
        ..lineTotal = SyncRemoteCodec.parseDouble(remote['line_total'])
        ..kitchenStatus = remote['kitchen_status'] as String? ?? 'received'
        ..appliedDiscounts = [
          for (final entry
              in SyncRemoteCodec.decodeJsonList(remote['applied_discounts']))
            (OrderLineDiscountEmbedded()
              ..scope = entry['scope'] as String
              ..type = entry['type'] as String
              ..value = SyncRemoteCodec.parseDouble(entry['value'])
              ..amountApplied =
                  SyncRemoteCodec.parseDouble(entry['amount_applied'])
              ..targetId = entry['target_id'] as String?
              ..reason = entry['reason'] as String?),
        ];
      _applyStandardFields(record, remote);
      await isar.orderItemIsars.put(record);
    });
  }
}

abstract final class AttendanceRecordRemoteMapper {
  static Map<String, dynamic> toRemote(AttendanceRecordIsar record) {
    return {
      ..._standardFields(record),
      'employee_id': record.employeeId,
      'check_in_time': record.checkInTime.toUtc().toIso8601String(),
      'check_out_time': record.checkOutTime?.toUtc().toIso8601String(),
      'source': record.source,
      'created_by_user_id': record.createdByUserId ?? '',
      'notes': record.notes,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record = await isar.attendanceRecordIsars
              .filter()
              .uuidEqualTo(id)
              .findFirst() ??
          (AttendanceRecordIsar()..uuid = id);
      record
        ..employeeId = remote['employee_id'] as String
        ..checkInTime = SyncRemoteCodec.parseDateTime(remote['check_in_time'])
        ..checkOutTime =
            SyncRemoteCodec.parseNullableDateTime(remote['check_out_time'])
        ..source = remote['source'] as String
        ..createdByUserId = remote['created_by_user_id'] as String?
        ..notes = remote['notes'] as String?;
      _applyStandardFields(record, remote);
      await isar.attendanceRecordIsars.put(record);
    });
  }
}

abstract final class SalarySlipRemoteMapper {
  static Map<String, dynamic> toRemote(SalarySlipIsar record) {
    return {
      ..._standardFields(record),
      'employee_id': record.employeeId,
      'period_start': SyncRemoteCodec.formatDateOnly(record.periodStart),
      'period_end': SyncRemoteCodec.formatDateOnly(record.periodEnd),
      'total_hours': record.totalHours,
      'base_pay': record.basePay,
      'deductions': record.deductions,
      'net_pay': record.netPay,
      'generated_at': record.generatedAt.toUtc().toIso8601String(),
      'generated_by_user_id': record.generatedByUserId,
      'status': record.status,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.salarySlipIsars.filter().uuidEqualTo(id).findFirst() ??
              (SalarySlipIsar()..uuid = id);
      record
        ..employeeId = remote['employee_id'] as String
        ..periodStart = SyncRemoteCodec.parseDateOnly(remote['period_start'])
        ..periodEnd = SyncRemoteCodec.parseDateOnly(remote['period_end'])
        ..totalHours = SyncRemoteCodec.parseDouble(remote['total_hours'])
        ..basePay = SyncRemoteCodec.parseDouble(remote['base_pay'])
        ..deductions = SyncRemoteCodec.parseNullableDouble(remote['deductions'])
        ..netPay = SyncRemoteCodec.parseDouble(remote['net_pay'])
        ..generatedAt = SyncRemoteCodec.parseDateTime(remote['generated_at'])
        ..generatedByUserId = remote['generated_by_user_id'] as String? ?? ''
        ..status = remote['status'] as String;
      _applyStandardFields(record, remote);
      await isar.salarySlipIsars.put(record);
    });
  }
}

abstract final class CreditCustomerRemoteMapper {
  static Map<String, dynamic> toRemote(CreditCustomerIsar record) {
    return {
      ..._standardFields(record),
      'full_name': record.fullName,
      'phone': record.phone,
      'address_line1': record.addressLine1,
      'address_line2': record.addressLine2,
      'city': record.city,
      'postcode': record.postcode,
      'notes': record.notes,
      'balance': record.balance,
      'credit_limit': record.creditLimit,
      'is_active': record.isActive,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record =
          await isar.creditCustomerIsars.filter().uuidEqualTo(id).findFirst() ??
              (CreditCustomerIsar()..uuid = id);
      record
        ..fullName = remote['full_name'] as String
        ..phone = remote['phone'] as String?
        ..addressLine1 = remote['address_line1'] as String?
        ..addressLine2 = remote['address_line2'] as String?
        ..city = remote['city'] as String?
        ..postcode = remote['postcode'] as String?
        ..notes = remote['notes'] as String?
        ..balance = SyncRemoteCodec.parseDouble(remote['balance'])
        ..creditLimit =
            SyncRemoteCodec.parseNullableDouble(remote['credit_limit'])
        ..isActive = remote['is_active'] as bool? ?? true;
      _applyStandardFields(record, remote);
      await isar.creditCustomerIsars.put(record);
    });
  }
}

abstract final class CreditTransactionRemoteMapper {
  static Map<String, dynamic> toRemote(CreditTransactionIsar record) {
    return {
      ..._standardFields(record),
      'credit_customer_id': record.creditCustomerId,
      'order_id': record.orderId,
      'transaction_type': record.transactionType,
      'amount': record.amount,
      'balance_delta': record.balanceDelta,
      'balance_after': record.balanceAfter,
      'payment_type': record.paymentType,
      'notes': record.notes,
      'created_by_user_id': record.createdByUserId,
    };
  }

  static Future<void> applyRemote(
    Isar isar,
    Map<String, dynamic> remote,
  ) async {
    final id = remote['id'] as String;
    await isar.writeTxn(() async {
      final record = await isar.creditTransactionIsars
              .filter()
              .uuidEqualTo(id)
              .findFirst() ??
          (CreditTransactionIsar()..uuid = id);
      record
        ..creditCustomerId = remote['credit_customer_id'] as String
        ..orderId = remote['order_id'] as String?
        ..transactionType = remote['transaction_type'] as String
        ..amount = SyncRemoteCodec.parseDouble(remote['amount'])
        ..balanceDelta = SyncRemoteCodec.parseDouble(remote['balance_delta'])
        ..balanceAfter = SyncRemoteCodec.parseDouble(remote['balance_after'])
        ..paymentType = remote['payment_type'] as String?
        ..notes = remote['notes'] as String?
        ..createdByUserId = remote['created_by_user_id'] as String? ?? '';
      _applyStandardFields(record, remote);
      await isar.creditTransactionIsars.put(record);
    });
  }
}
