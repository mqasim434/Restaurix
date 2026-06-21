import 'package:isar/isar.dart';

import '../../domain/models/pickup_company.dart';
import '../local/collections/pickup_company_isar.dart';
import '../local/mappers/delivery_mapper.dart';

class PickupCompanyRepository {
  PickupCompanyRepository(this._isar);

  final Isar _isar;

  Stream<List<PickupCompany>> watchActive() {
    return _isar.pickupCompanyIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(pickupCompanyFromIsar).toList());
  }

  Future<PickupCompany> create({
    required String name,
    required String deviceId,
    String? logoUrl,
  }) async {
    final record = PickupCompanyIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      logoUrl: logoUrl,
    );

    await _isar.writeTxn(() async {
      await _isar.pickupCompanyIsars.put(record);
    });

    return pickupCompanyFromIsar(record);
  }
}
