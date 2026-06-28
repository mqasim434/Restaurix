import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:restaurix/app/app.dart';
import 'package:restaurix/core/sync/sync_queue_models.dart';
import 'package:restaurix/data/local/device_id_service.dart';
import 'package:restaurix/data/local/isar_service.dart';
import 'package:restaurix/domain/models/dashboard.dart';
import 'package:restaurix/features/auth/providers/auth_providers.dart';
import 'package:restaurix/features/dashboard/providers/dashboard_providers.dart';
import 'package:restaurix/features/sync/providers/sync_queue_providers.dart';

void main() {
  late Directory tempDir;
  late IsarService isarService;
  late DeviceIdService deviceIdService;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('restaurix_widget_test');
    final isar = await Isar.open(
      IsarService.schemas,
      directory: tempDir.path,
      name: 'widget_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    isarService = IsarService(isar);
    deviceIdService = DeviceIdService('test-device-id');
  });

  tearDown(() async {
    await isarService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows app shell with dashboard placeholder', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarServiceProvider.overrideWithValue(isarService),
          deviceIdServiceProvider.overrideWithValue(deviceIdService),
          authControllerProvider.overrideWith(AuthController.forTesting),
          dashboardSnapshotProvider.overrideWith(
            (ref) => Stream.value(DashboardSnapshot.empty()),
          ),
          syncQueueSnapshotProvider.overrideWith(
            (ref) => Stream.value(SyncQueueSnapshot.empty),
          ),
        ],
        child: const RestaurixApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Admin'), findsOneWidget);
  });
}
