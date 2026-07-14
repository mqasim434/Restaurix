import 'package:flutter_test/flutter_test.dart';

import 'package:restaurix/domain/models/deal.dart';
import 'package:restaurix/domain/models/deal_availability.dart';
import 'package:restaurix/domain/models/deal_item.dart';
import 'package:restaurix/domain/models/product.dart';
import 'package:restaurix/core/sync/sync_action.dart';

Deal _deal({
  bool isAvailable = true,
  DateTime? availabilityStart,
  DateTime? availabilityEnd,
}) {
  final now = DateTime(2024, 6, 21, 12);
  return Deal(
    id: 'deal-1',
    name: 'Lunch Combo',
    price: 9.99,
    isAvailable: isAvailable,
    availabilityStart: availabilityStart,
    availabilityEnd: availabilityEnd,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'test',
    version: 1,
  );
}

Product _product({required String id, bool isAvailable = true}) {
  final now = DateTime(2024, 6, 21, 12);
  return Product(
    id: id,
    name: 'Product $id',
    categoryId: 'cat-1',
    basePrice: 5,
    isAvailable: isAvailable,
    kitchenCategory: '',
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'test',
    version: 1,
  );
}

DealItem _item(String productId) {
  final now = DateTime(2024, 6, 21, 12);
  return DealItem(
    id: 'item-$productId',
    dealId: 'deal-1',
    productId: productId,
    quantity: 1,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'test',
    version: 1,
  );
}

void main() {
  group('DealAvailability', () {
    test('future-only window is unavailable before start', () {
      final at = DateTime(2024, 6, 21, 10);
      final start = DateTime(2024, 6, 21, 11);
      final end = DateTime(2024, 6, 21, 14);

      expect(
        DealAvailability.isWithinWindow(start: start, end: end, at: at),
        isFalse,
      );
    });

    test('future-only window is available during window', () {
      final at = DateTime(2024, 6, 21, 12);
      final start = DateTime(2024, 6, 21, 11);
      final end = DateTime(2024, 6, 21, 14);

      expect(
        DealAvailability.isWithinWindow(start: start, end: end, at: at),
        isTrue,
      );
    });

    test('overnight window supports times crossing midnight', () {
      final at = DateTime(2024, 6, 21, 23, 30);
      final start = DateTime(2024, 6, 21, 22, 0);
      final end = DateTime(2024, 6, 21, 2, 0);

      expect(
        DealAvailability.isWithinWindow(start: start, end: end, at: at),
        isTrue,
      );
    });

    test('isEffectivelyAvailable is false when product unavailable', () {
      final deal = _deal();
      final items = [_item('p1')];
      final products = {'p1': _product(id: 'p1', isAvailable: false)};

      expect(
        deal.isEffectivelyAvailable(
          items: items,
          productsById: products,
          at: DateTime(2024, 6, 21, 12),
        ),
        isFalse,
      );
    });

    test('isEffectivelyAvailable is true when all checks pass', () {
      final deal = _deal(
        availabilityStart: DateTime(2024, 6, 21, 11),
        availabilityEnd: DateTime(2024, 6, 21, 14),
      );
      final items = [_item('p1'), _item('p2')];
      final products = {
        'p1': _product(id: 'p1'),
        'p2': _product(id: 'p2'),
      };

      expect(
        deal.isEffectivelyAvailable(
          items: items,
          productsById: products,
          at: DateTime(2024, 6, 21, 12),
        ),
        isTrue,
      );
    });
  });
}
