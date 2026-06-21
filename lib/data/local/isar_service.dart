import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Opens and holds the local Isar database instance.
class IsarService {
  IsarService(this._isar);

  final Isar _isar;

  Isar get instance => _isar;

  static Future<IsarService> open() async {
    final directory = await getApplicationSupportDirectory();
    final isar = await Isar.open(
      const [],
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
