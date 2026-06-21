import 'package:isar/isar.dart';

import '../../domain/models/rider.dart';
import '../local/collections/rider_isar.dart';
import '../local/mappers/delivery_mapper.dart';

class RiderRepository {
  RiderRepository(this._isar);

  final Isar _isar;

  Stream<List<Rider>> watchActive() {
    return _isar.riderIsars
        .filter()
        .deletedAtIsNull()
        .isActiveEqualTo(true)
        .sortByName()
        .watch(fireImmediately: true)
        .map((records) => records.map(riderFromIsar).toList());
  }

  Future<Rider> create({
    required String name,
    required String deviceId,
    String? phone,
  }) async {
    final record = RiderIsar.create(
      name: name.trim(),
      deviceId: deviceId,
      phone: phone?.trim(),
    );

    await _isar.writeTxn(() async {
      await _isar.riderIsars.put(record);
    });

    return riderFromIsar(record);
  }
}
