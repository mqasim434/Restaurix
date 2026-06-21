import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/debug_ping_repository.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';

final debugPingRepositoryProvider = Provider<DebugPingRepository>((ref) {
  return DebugPingRepository(ref.watch(isarProvider));
});

final debugPingListProvider = StreamProvider((ref) {
  return ref.watch(debugPingRepositoryProvider).watchAll();
});

final debugPingNotifierProvider =
    NotifierProvider<DebugPingNotifier, AsyncValue<void>>(DebugPingNotifier.new);

class DebugPingNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  DebugPingRepository get _repository => ref.read(debugPingRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  Future<void> create(String message) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.create(message: message, deviceId: _deviceId);
    });
  }

  Future<void> updateMessage(String uuid, String message) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateMessage(
        uuid: uuid,
        message: message,
        deviceId: _deviceId,
      );
    });
  }

  Future<void> softDelete(String uuid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.softDelete(uuid: uuid, deviceId: _deviceId);
    });
  }
}
