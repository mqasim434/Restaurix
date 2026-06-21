import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'collections/category_isar.dart';
import 'collections/deal_isar.dart';
import 'collections/deal_item_isar.dart';
import 'collections/hall_isar.dart';
import 'collections/item_modifier_isar.dart';
import 'collections/modifier_group_isar.dart';
import 'collections/order_isar.dart';
import 'collections/product_isar.dart';
import 'collections/product_variant_isar.dart';
import 'collections/pickup_company_isar.dart';
import 'collections/restaurant_table_isar.dart';
import 'collections/rider_isar.dart';

/// Opens and holds the local Isar database instance.
class IsarService {
  IsarService(this._isar);

  final Isar _isar;

  Isar get instance => _isar;

  static Future<IsarService> open() async {
    final directory = await getApplicationSupportDirectory();
    final isar = await Isar.open(
      [
        CategoryIsarSchema,
        ProductIsarSchema,
        ProductVariantIsarSchema,
        ModifierGroupIsarSchema,
        ItemModifierIsarSchema,
        DealIsarSchema,
        DealItemIsarSchema,
        HallIsarSchema,
        RestaurantTableIsarSchema,
        OrderIsarSchema,
        RiderIsarSchema,
        PickupCompanyIsarSchema,
      ],
      directory: directory.path,
      name: 'restaurix',
    );
    return IsarService(isar);
  }

  Future<void> close() => _isar.close();
}

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('IsarService must be overridden at app startup.');
});

final isarProvider = Provider<Isar>((ref) {
  return ref.watch(isarServiceProvider).instance;
});
