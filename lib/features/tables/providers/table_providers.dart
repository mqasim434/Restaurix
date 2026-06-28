import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/hall_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../domain/models/hall.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/restaurant_table.dart';
import '../../../domain/models/table_status.dart';

final hallRepositoryProvider = Provider<HallRepository>((ref) {
  return HallRepository(ref.watch(isarProvider));
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository(ref.watch(isarProvider));
});

final hallListProvider =
    AsyncNotifierProvider<HallListNotifier, List<Hall>>(HallListNotifier.new);

final selectedHallIdProvider = StateProvider<String?>((ref) => null);

final hallTablesProvider =
    StreamProvider.autoDispose.family<List<RestaurantTable>, String>(
  (ref, hallId) {
    return ref.watch(tableRepositoryProvider).watchByHall(hallId);
  },
);

final tableActionsProvider = Provider<TableActions>((ref) {
  return TableActions(
    hallRepository: ref.watch(hallRepositoryProvider),
    tableRepository: ref.watch(tableRepositoryProvider),
    deviceId: ref.watch(deviceIdProvider),
    userId: ref.watch(currentUserProvider).id,
  );
});

class TableMutationResult {
  const TableMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

class HallListNotifier extends AsyncNotifier<List<Hall>> {
  StreamSubscription<List<Hall>>? _subscription;

  HallRepository get _repository => ref.read(hallRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<Hall>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (halls) {
        state = AsyncValue.data(halls);
        final selected = ref.read(selectedHallIdProvider);
        if (halls.isNotEmpty &&
            (selected == null || !halls.any((h) => h.id == selected))) {
          ref.read(selectedHallIdProvider.notifier).state = halls.first.id;
        }
        if (halls.isEmpty) {
          ref.read(selectedHallIdProvider.notifier).state = null;
        }
      },
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<TableMutationResult> create({required String name}) async {
    if (name.trim().isEmpty) {
      return const TableMutationResult(
        success: false,
        errorMessage: 'Hall name is required',
      );
    }

    final hall = await _repository.create(name: name, deviceId: _deviceId);
    ref.read(selectedHallIdProvider.notifier).state = hall.id;
    return const TableMutationResult(success: true);
  }

  Future<TableMutationResult> updateHall(Hall hall) async {
    if (hall.name.trim().isEmpty) {
      return const TableMutationResult(
        success: false,
        errorMessage: 'Hall name is required',
      );
    }

    await _repository.update(hall: hall, deviceId: _deviceId);
    return const TableMutationResult(success: true);
  }

  Future<TableMutationResult> delete(String id) async {
    final tableCount = await _repository.countTablesInHall(id);
    if (tableCount > 0) {
      return TableMutationResult(
        success: false,
        errorMessage: HallInUseException(tableCount).toString(),
      );
    }

    await _repository.softDelete(id: id, deviceId: _deviceId);
    return const TableMutationResult(success: true);
  }

  Future<void> reorder(List<String> idsInOrder) async {
    await _repository.reorder(idsInOrder: idsInOrder, deviceId: _deviceId);
  }
}

class TableActions {
  TableActions({
    required this.hallRepository,
    required this.tableRepository,
    required this.deviceId,
    required this.userId,
  });

  final HallRepository hallRepository;
  final TableRepository tableRepository;
  final String deviceId;
  final String userId;

  Future<RestaurantTable> createTable({
    required String hallId,
    required String label,
    int capacity = 4,
  }) {
    return tableRepository.create(
      hallId: hallId,
      label: label,
      deviceId: deviceId,
      capacity: capacity,
    );
  }

  Future<RestaurantTable?> updateTable(RestaurantTable table) {
    return tableRepository.update(table: table, deviceId: deviceId);
  }

  Future<RestaurantTable?> setStatus({
    required String tableId,
    required TableStatus status,
    bool forceRelease = false,
  }) {
    return tableRepository.setStatus(
      tableId: tableId,
      status: status,
      deviceId: deviceId,
      forceRelease: forceRelease,
    );
  }

  Future<Order> startOrder(String tableId) {
    return tableRepository.startDineInOrder(
      tableId: tableId,
      createdByUserId: userId,
      deviceId: deviceId,
    );
  }

  Future<Order?> findOrder(String orderId) {
    return tableRepository.findOrderById(orderId);
  }

  Future<void> transferOrder({
    required String fromTableId,
    required String toTableId,
  }) {
    return tableRepository.transferOrder(
      fromTableId: fromTableId,
      toTableId: toTableId,
      deviceId: deviceId,
    );
  }

  Future<bool> deleteTable(String id) {
    return tableRepository.softDelete(id: id, deviceId: deviceId);
  }
}
