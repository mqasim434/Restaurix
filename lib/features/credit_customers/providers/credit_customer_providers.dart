import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/credit_customer_repository.dart';
import '../../../data/repositories/credit_transaction_repository.dart';
import '../../../domain/models/credit_customer.dart';
import '../../../domain/models/credit_transaction.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/services/credit_ledger_service.dart';
import '../../auth/providers/auth_providers.dart';

final creditCustomerRepositoryProvider = Provider<CreditCustomerRepository>((ref) {
  return CreditCustomerRepository(ref.watch(isarProvider));
});

final creditTransactionRepositoryProvider =
    Provider<CreditTransactionRepository>((ref) {
  return CreditTransactionRepository(ref.watch(isarProvider));
});

final creditLedgerServiceProvider = Provider<CreditLedgerService>((ref) {
  final isar = ref.watch(isarProvider);
  return CreditLedgerService(
    isar: isar,
    transactionRepository: ref.watch(creditTransactionRepositoryProvider),
  );
});

final creditCustomerByIdProvider =
    FutureProvider.family<CreditCustomer?, String>((ref, id) {
  return ref.watch(creditCustomerRepositoryProvider).findById(id);
});

final creditCustomerListProvider =
    AsyncNotifierProvider<CreditCustomerListNotifier, List<CreditCustomer>>(
  CreditCustomerListNotifier.new,
);

final activeCreditCustomersProvider = StreamProvider<List<CreditCustomer>>((ref) {
  return ref.watch(creditCustomerRepositoryProvider).watchActive();
});

final creditCustomerSearchQueryProvider = StateProvider<String>((ref) => '');

final creditCustomerActiveFilterProvider =
    StateProvider<CreditCustomerActiveFilter>(
  (ref) => CreditCustomerActiveFilter.all,
);

final filteredCreditCustomersProvider =
    Provider<AsyncValue<List<CreditCustomer>>>((ref) {
  final customersAsync = ref.watch(creditCustomerListProvider);
  final query = ref.watch(creditCustomerSearchQueryProvider);
  final activeFilter = ref.watch(creditCustomerActiveFilterProvider);

  return customersAsync.whenData(
    (customers) => filterCreditCustomers(
      customers: customers,
      searchQuery: query,
      activeFilter: activeFilter,
    ),
  );
});

final creditCustomerTransactionsProvider = StreamProvider.family<
    List<CreditTransaction>, String>((ref, customerId) {
  return ref
      .watch(creditTransactionRepositoryProvider)
      .watchByCustomerId(customerId);
});

enum CreditCustomerActiveFilter {
  all,
  active,
  inactive,
  withBalance,
}

extension CreditCustomerActiveFilterX on CreditCustomerActiveFilter {
  String get label => switch (this) {
        CreditCustomerActiveFilter.all => 'All',
        CreditCustomerActiveFilter.active => 'Active',
        CreditCustomerActiveFilter.inactive => 'Inactive',
        CreditCustomerActiveFilter.withBalance => 'Outstanding balance',
      };
}

List<CreditCustomer> filterCreditCustomers({
  required List<CreditCustomer> customers,
  required String searchQuery,
  required CreditCustomerActiveFilter activeFilter,
}) {
  final query = searchQuery.trim().toLowerCase();

  return customers.where((customer) {
    final matchesFilter = switch (activeFilter) {
      CreditCustomerActiveFilter.all => true,
      CreditCustomerActiveFilter.active => customer.isActive,
      CreditCustomerActiveFilter.inactive => !customer.isActive,
      CreditCustomerActiveFilter.withBalance => customer.hasOutstandingBalance,
    };
    if (!matchesFilter) return false;

    if (query.isEmpty) return true;

    final haystack = [
      customer.fullName,
      customer.phone,
      customer.addressLine1,
      customer.city,
      customer.notes,
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains(query);
  }).toList();
}

class CreditCustomerMutationResult {
  const CreditCustomerMutationResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

class CreditCustomerListNotifier extends AsyncNotifier<List<CreditCustomer>> {
  StreamSubscription<List<CreditCustomer>>? _subscription;

  CreditCustomerRepository get _repository =>
      ref.read(creditCustomerRepositoryProvider);
  String get _deviceId => ref.read(deviceIdProvider);

  @override
  Future<List<CreditCustomer>> build() async {
    _subscription?.cancel();
    _subscription = _repository.watchAll().listen(
      (customers) => state = AsyncValue.data(customers),
      onError: (error, stackTrace) =>
          state = AsyncValue.error(error, stackTrace),
    );
    ref.onDispose(() => _subscription?.cancel());

    return _repository.watchAll().first;
  }

  Future<CreditCustomerMutationResult> create({
    required String fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postcode,
    String? notes,
    double? creditLimit,
    bool isActive = true,
  }) async {
    if (fullName.trim().isEmpty) {
      return const CreditCustomerMutationResult(
        success: false,
        errorMessage: 'Name is required',
      );
    }

    await _repository.create(
      fullName: fullName,
      deviceId: _deviceId,
      phone: phone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      postcode: postcode,
      notes: notes,
      creditLimit: creditLimit,
      isActive: isActive,
    );

    return const CreditCustomerMutationResult(success: true);
  }

  Future<CreditCustomerMutationResult> updateCustomer(
    CreditCustomer customer,
  ) async {
    if (customer.fullName.trim().isEmpty) {
      return const CreditCustomerMutationResult(
        success: false,
        errorMessage: 'Name is required',
      );
    }

    final updated = await _repository.update(
      customer: customer,
      deviceId: _deviceId,
    );
    if (updated == null) {
      return const CreditCustomerMutationResult(
        success: false,
        errorMessage: 'Customer not found',
      );
    }

    return const CreditCustomerMutationResult(success: true);
  }

  Future<CreditCustomerMutationResult> setActive({
    required CreditCustomer customer,
    required bool isActive,
  }) async {
    final updated = await _repository.setActive(
      id: customer.id,
      isActive: isActive,
      deviceId: _deviceId,
    );
    if (updated == null) {
      return const CreditCustomerMutationResult(
        success: false,
        errorMessage: 'Customer not found',
      );
    }

    return const CreditCustomerMutationResult(success: true);
  }

  Future<CreditCustomerMutationResult> delete(String id) async {
    final deleted = await _repository.softDelete(id: id, deviceId: _deviceId);
    if (!deleted) {
      return const CreditCustomerMutationResult(
        success: false,
        errorMessage: 'Customer not found',
      );
    }

    return const CreditCustomerMutationResult(success: true);
  }
}

class CreditPaymentController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CreditCustomerMutationResult> recordPayment({
    required String creditCustomerId,
    required double amount,
    required PaymentType paymentType,
    String? notes,
  }) async {
    try {
      await ref.read(creditLedgerServiceProvider).recordPayment(
            creditCustomerId: creditCustomerId,
            amount: amount,
            paymentType: paymentType,
            createdByUserId: ref.read(currentUserProvider).id,
            deviceId: ref.read(deviceIdProvider),
            notes: notes,
          );
      return const CreditCustomerMutationResult(success: true);
    } on CreditLedgerException catch (error) {
      return CreditCustomerMutationResult(
        success: false,
        errorMessage: error.message,
      );
    }
  }
}

final creditPaymentControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreditPaymentController, void>(
  CreditPaymentController.new,
);
