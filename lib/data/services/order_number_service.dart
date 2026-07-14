import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../local/collections/order_isar.dart';

/// Prefix for **desktop / terminal** POS orders: `ORD-YYYYMMDD-###`.
const orderNumberPrefix = 'ORD';

/// Prefix for **waiter tablet** orders: `ODR-0001` (resets daily).
const tabletOrderNumberPrefix = 'ODR';

/// Prefix for **customer mobile app** orders: `ODRM-0001` (resets daily).
const customerOrderNumberPrefix = 'ODRM';

/// Legacy waiter prefix (`ORDM-YYYYMMDD-###`) — still recognized for old rows.
const legacyTabletOrderNumberPrefix = 'ORDM';

/// Legacy customer prefix (`ORDC-YYYYMMDD-###`) — still recognized for old rows.
const legacyCustomerOrderNumberPrefix = 'ORDC';

/// Whether [orderNumber] is a waiter tablet order (`ODR-*`, not `ODRM-*`).
bool isMobileOrderNumber(String orderNumber) =>
    isTabletOrderNumber(orderNumber);

/// Waiter / in-house tablet order numbers (`ODR-0001` or legacy `ORDM-*`).
bool isTabletOrderNumber(String orderNumber) {
  if (isCustomerAppOrderNumber(orderNumber)) return false;
  return orderNumber.startsWith('$tabletOrderNumberPrefix-') ||
      orderNumber.startsWith('$legacyTabletOrderNumberPrefix-');
}

/// Customer app order numbers (`ODRM-0001` or legacy `ORDC-*`).
bool isCustomerAppOrderNumber(String orderNumber) =>
    orderNumber.startsWith('$customerOrderNumberPrefix-') ||
    orderNumber.startsWith('$legacyCustomerOrderNumberPrefix-');

/// Formats a desktop daily order number, e.g. `ORD-20260630-002`.
String formatDailyOrderNumber(DateTime date, int dailySequence) {
  final datePart = DateFormat('yyyyMMdd').format(date);
  return '$orderNumberPrefix-$datePart-${dailySequence.toString().padLeft(3, '0')}';
}

/// Formats a tablet daily order number, e.g. `ODR-0001`.
String formatTabletDailyOrderNumber(int dailySequence) =>
    '$tabletOrderNumberPrefix-${dailySequence.toString().padLeft(4, '0')}';

/// Formats a customer-app daily order number, e.g. `ODRM-0001`.
String formatCustomerDailyOrderNumber(int dailySequence) =>
    '$customerOrderNumberPrefix-${dailySequence.toString().padLeft(4, '0')}';

/// Prefix for all desktop order numbers on a given local calendar day.
String dailyOrderNumberPrefix(DateTime date) =>
    '$orderNumberPrefix-${DateFormat('yyyyMMdd').format(date)}-';

/// Parses the daily sequence from a desktop order number, or null if format differs.
int? parseDailyOrderSequence(String orderNumber) {
  final parts = orderNumber.split('-');
  if (parts.length != 3 || parts[0] != orderNumberPrefix) return null;
  return int.tryParse(parts[2]);
}

/// Parses `ODR-0001` / `ODRM-0001` style sequences.
int? parseSimplePrefixedSequence(String orderNumber, String prefix) {
  final parts = orderNumber.split('-');
  if (parts.length != 2 || parts[0] != prefix) return null;
  return int.tryParse(parts[1]);
}

DateTime _startOfLocalDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Allocates the next desktop daily order number inside an existing Isar write txn.
Future<String> allocateNextOrderNumberInTxn(
  Isar isar, {
  DateTime? now,
}) async {
  final timestamp = now ?? DateTime.now();
  final prefix = dailyOrderNumberPrefix(timestamp);

  final existing = await isar.orderIsars
      .filter()
      .deletedAtIsNull()
      .orderNumberStartsWith(prefix)
      .findAll();

  var maxSeq = 0;
  for (final record in existing) {
    final seq = parseDailyOrderSequence(record.orderNumber);
    if (seq != null && seq > maxSeq) maxSeq = seq;
  }

  return formatDailyOrderNumber(timestamp, maxSeq + 1);
}

/// Allocates the next desktop daily order number in its own write transaction.
Future<String> allocateNextOrderNumber(
  Isar isar, {
  DateTime? now,
}) {
  return isar.writeTxn(
    () => allocateNextOrderNumberInTxn(isar, now: now),
  );
}

/// Next waiter-tablet number for today: `ODR-0001`, `ODR-0002`, …
Future<String> allocateNextTabletOrderNumberInTxn(
  Isar isar, {
  DateTime? now,
}) async {
  final timestamp = now ?? DateTime.now();
  final dayStart = _startOfLocalDay(timestamp);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final existing = await isar.orderIsars
      .filter()
      .deletedAtIsNull()
      .createdAtGreaterThan(dayStart, include: true)
      .createdAtLessThan(dayEnd)
      .findAll();

  var maxSeq = 0;
  for (final record in existing) {
    final seq = parseSimplePrefixedSequence(
      record.orderNumber,
      tabletOrderNumberPrefix,
    );
    if (seq != null && seq > maxSeq) maxSeq = seq;
  }

  return formatTabletDailyOrderNumber(maxSeq + 1);
}

/// Next customer-app number for today: `ODRM-0001`, `ODRM-0002`, …
Future<String> allocateNextCustomerOrderNumberInTxn(
  Isar isar, {
  DateTime? now,
}) async {
  final timestamp = now ?? DateTime.now();
  final dayStart = _startOfLocalDay(timestamp);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final existing = await isar.orderIsars
      .filter()
      .deletedAtIsNull()
      .createdAtGreaterThan(dayStart, include: true)
      .createdAtLessThan(dayEnd)
      .findAll();

  var maxSeq = 0;
  for (final record in existing) {
    final seq = parseSimplePrefixedSequence(
      record.orderNumber,
      customerOrderNumberPrefix,
    );
    if (seq != null && seq > maxSeq) maxSeq = seq;
  }

  return formatCustomerDailyOrderNumber(maxSeq + 1);
}
