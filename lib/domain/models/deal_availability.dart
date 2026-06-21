import 'deal.dart';
import 'deal_item.dart';
import 'product.dart';

/// Availability rules for deals — time windows and constituent product checks.
abstract final class DealAvailability {
  static bool isWithinWindow({
    required DateTime? start,
    required DateTime? end,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();

    if (start == null && end == null) return true;
    if (start != null && end == null) return !now.isBefore(start);
    if (start == null && end != null) return !now.isAfter(end);

    assert(start != null && end != null);
    final windowStart = start!;
    final windowEnd = end!;

    if (!windowStart.isAfter(windowEnd)) {
      return !now.isBefore(windowStart) && !now.isAfter(windowEnd);
    }

    // Overnight window when end time is earlier on the clock than start
    // (e.g. 22:00–02:00 stored on the same calendar date).
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = windowStart.hour * 60 + windowStart.minute;
    final endMinutes = windowEnd.hour * 60 + windowEnd.minute;

    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }

    // Absolute datetime range where start > end (multi-day spanning window).
    return !now.isBefore(windowStart) || !now.isAfter(windowEnd);
  }

  static bool isEffectivelyAvailable({
    required Deal deal,
    required List<DealItem> items,
    required Map<String, Product> productsById,
    DateTime? at,
  }) {
    if (!deal.isAvailable) return false;
    if (!isWithinWindow(
      start: deal.availabilityStart,
      end: deal.availabilityEnd,
      at: at,
    )) {
      return false;
    }
    if (items.isEmpty) return false;

    for (final item in items) {
      final product = productsById[item.productId];
      if (product == null || !product.isAvailable) return false;
    }

    return true;
  }
}
