import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local/device_id_service.dart';
import 'data/local/isar_service.dart';
import 'data/remote/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deviceIdService = await DeviceIdService.loadOrCreate();
  final isarService = await IsarService.open();
  await SupabaseService.initialize();

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
