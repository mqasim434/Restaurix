import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/pickup_company_repository.dart';
import '../../../data/repositories/rider_repository.dart';
import '../../../domain/models/pickup_company.dart';
import '../../../domain/models/rider.dart';

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository(ref.watch(isarProvider));
});

final pickupCompanyRepositoryProvider = Provider<PickupCompanyRepository>((ref) {
  return PickupCompanyRepository(ref.watch(isarProvider));
});

final riderListProvider =
    AsyncNotifierProvider<RiderListNotifier, List<Rider>>(RiderListNotifier.new);

final pickupCompanyListProvider =
    AsyncNotifierProvider<PickupCompanyListNotifier, List<PickupCompany>>(
  PickupCompanyListNotifier.new,
);

final activeRidersProvider = StreamProvider<List<Rider>>((ref) {
  return ref.watch(riderRepositoryProvider).watchActive();
});

final activePickupCompaniesProvider = StreamProvider<List<PickupCompany>>((ref) {
  return ref.watch(pickupCompanyRepositoryProvider).watchActive();
});

class DeliveryMutationResult {
  const DeliveryMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

class RiderListNotifier extends AsyncNotifier<List<Rider>> {
  StreamSubscription<List<Rider>>? _subscription;

  RiderRepository get _repository => ref.read(riderRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<Rider>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (riders) => state = AsyncValue.data(riders),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<DeliveryMutationResult> create({
    required String name,
    String? phone,
    bool isActive = true,
  }) async {
    if (name.trim().isEmpty) {
      return const DeliveryMutationResult(
        success: false,
        errorMessage: 'Rider name is required',
      );
    }

    await _repository.create(
      name: name,
      deviceId: _deviceId,
      phone: phone,
      isActive: isActive,
    );
    return const DeliveryMutationResult(success: true);
  }

  Future<DeliveryMutationResult> updateRider(Rider rider) async {
    if (rider.name.trim().isEmpty) {
      return const DeliveryMutationResult(
        success: false,
        errorMessage: 'Rider name is required',
      );
    }

    await _repository.update(rider: rider, deviceId: _deviceId);
    return const DeliveryMutationResult(success: true);
  }

  Future<DeliveryMutationResult> toggleActive(Rider rider) async {
    await _repository.toggleActive(id: rider.id, deviceId: _deviceId);
    return const DeliveryMutationResult(success: true);
  }

  Future<DeliveryMutationResult> delete(String id) async {
    await _repository.softDelete(id: id, deviceId: _deviceId);
    return const DeliveryMutationResult(success: true);
  }
}

class PickupCompanyListNotifier extends AsyncNotifier<List<PickupCompany>> {
  StreamSubscription<List<PickupCompany>>? _subscription;

  PickupCompanyRepository get _repository =>
      ref.read(pickupCompanyRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<PickupCompany>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (companies) => state = AsyncValue.data(companies),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<DeliveryMutationResult> create({
    required String name,
    String? logoUrl,
    bool isActive = true,
  }) async {
    if (name.trim().isEmpty) {
      return const DeliveryMutationResult(
        success: false,
        errorMessage: 'Company name is required',
      );
    }

    await _repository.create(
      name: name,
      deviceId: _deviceId,
      logoUrl: logoUrl,
      isActive: isActive,
    );
    return const DeliveryMutationResult(success: true);
  }

  Future<DeliveryMutationResult> updateCompany(PickupCompany company) async {
    if (company.name.trim().isEmpty) {
      return const DeliveryMutationResult(
        success: false,
        errorMessage: 'Company name is required',
      );
    }

    await _repository.update(company: company, deviceId: _deviceId);
    return const DeliveryMutationResult(success: true);
  }

  Future<DeliveryMutationResult> toggleActive(PickupCompany company) async {
    await _repository.toggleActive(id: company.id, deviceId: _deviceId);
    return const DeliveryMutationResult(success: true);
  }

  Future<DeliveryMutationResult> delete(String id) async {
    await _repository.softDelete(id: id, deviceId: _deviceId);
    return const DeliveryMutationResult(success: true);
  }
}
