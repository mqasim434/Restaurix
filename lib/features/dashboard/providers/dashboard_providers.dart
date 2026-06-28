import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/isar_service.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../domain/models/dashboard.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(isarProvider));
});

final dashboardSnapshotProvider = StreamProvider<DashboardSnapshot>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchSnapshot();
});
