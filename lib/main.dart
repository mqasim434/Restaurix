import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/network/windows_tls.dart';
import 'data/local/device_id_service.dart';
import 'data/local/isar_service.dart';
import 'data/remote/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await WindowsTls.configure();
  await EnvConfig.load();

  final deviceIdService = await DeviceIdService.loadOrCreate();
  final isarService = await IsarService.open();
  await SupabaseService.initialize();
  SupabaseService.pingInBackground();

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
        deviceIdServiceProvider.overrideWithValue(deviceIdService),
      ],
      child: const RestaurixApp(),
    ),
  );
}
