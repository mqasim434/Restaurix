import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Generates and persists a stable device ID once per install.
class DeviceIdService {
  DeviceIdService(this._deviceId);

  final String _deviceId;

  String get id => _deviceId;

  static const _fileName = 'device_id.txt';

  static Future<DeviceIdService> loadOrCreate() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$_fileName');

    if (await file.exists()) {
      final stored = (await file.readAsString()).trim();
      if (stored.isNotEmpty) {
        return DeviceIdService(stored);
      }
    }

    final deviceId = const Uuid().v4();
    await file.writeAsString(deviceId);
    return DeviceIdService(deviceId);
  }
}

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  throw UnimplementedError('DeviceIdService must be overridden at app startup.');
});

final deviceIdProvider = Provider<String>((ref) {
  return ref.watch(deviceIdServiceProvider).id;
});
