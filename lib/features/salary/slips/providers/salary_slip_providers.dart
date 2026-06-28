import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/navigation/navigation_provider.dart';
import '../../../../data/local/isar_service.dart';
import '../../../../data/local/device_id_service.dart';
import '../../../../data/repositories/salary_slip_coordinator.dart';
import '../../../../data/repositories/salary_slip_repository.dart';
import '../../../../domain/models/salary_calculation.dart';
import '../../../../domain/models/salary_slip.dart';
import '../../../attendance/providers/attendance_providers.dart';
import '../../../employees/providers/employee_providers.dart';
import '../../../printing/providers/kitchen_ticket_providers.dart';
import '../../calculation/providers/salary_calculation_providers.dart';

final salarySlipRepositoryProvider = Provider<SalarySlipRepository>((ref) {
  return SalarySlipRepository(ref.watch(isarProvider));
});

final salarySlipCoordinatorProvider = Provider<SalarySlipCoordinator>((ref) {
  return SalarySlipCoordinator(
    salarySlipRepository: ref.watch(salarySlipRepositoryProvider),
    employeeRepository: ref.watch(employeeRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    settingsRepository: ref.watch(appSettingRepositoryProvider),
  );
});

final salarySlipListProvider =
    StreamProvider.autoDispose<List<SalarySlip>>((ref) {
  return ref.watch(salarySlipRepositoryProvider).watchAll();
});

class SalaryAutoGenerationNotice {
  const SalaryAutoGenerationNotice({
    required this.createdCount,
    required this.period,
  });

  final int createdCount;
  final SalaryPeriod period;
}

final salaryAutoGenerationNoticeProvider =
    StateProvider<SalaryAutoGenerationNotice?>((ref) => null);

final salarySlipBootstrapProvider = FutureProvider<void>((ref) async {
  final coordinator = ref.read(salarySlipCoordinatorProvider);
  final deviceId = ref.read(deviceIdProvider);
  final userId = ref.read(currentUserProvider).id;

  final result = await coordinator.maybeAutoGenerate(
    generatedByUserId: userId,
    deviceId: deviceId,
  );

  if (result != null && result.didGenerate) {
    ref.read(salaryAutoGenerationNoticeProvider.notifier).state =
        SalaryAutoGenerationNotice(
      createdCount: result.createdCount,
      period: result.period,
    );
  }
});

final salaryGenerationDayProvider = FutureProvider<int>((ref) async {
  return ref.watch(salarySlipCoordinatorProvider).getGenerationDay();
});

class SalarySlipMutationResult {
  const SalarySlipMutationResult({
    required this.success,
    this.message,
    this.createdCount,
    this.skippedCount,
  });

  final bool success;
  final String? message;
  final int? createdCount;
  final int? skippedCount;
}

final salarySlipActionsProvider = Provider<SalarySlipActions>((ref) {
  return SalarySlipActions(ref);
});

class SalarySlipActions {
  SalarySlipActions(this._ref);

  final Ref _ref;

  Future<SalarySlipMutationResult> generateForCurrentFilter() async {
    final filter = _ref.read(salaryFilterProvider);
    final range = filter.resolve();
    final deviceId = _ref.read(deviceIdProvider);
    final userId = _ref.read(currentUserProvider).id;

    final result = await _ref
        .read(salarySlipCoordinatorProvider)
        .generateDraftSlipsForRange(
          range: range,
          generatedByUserId: userId,
          deviceId: deviceId,
        );

    _ref.invalidate(salarySlipListProvider);

    return SalarySlipMutationResult(
      success: true,
      createdCount: result.createdCount,
      skippedCount: result.skippedCount,
      message: result.createdCount == 0
          ? 'No new slips created — drafts already exist for this period.'
          : 'Created ${result.createdCount} draft slip(s).',
    );
  }

  Future<SalarySlipMutationResult> finalizeSlip(String slipId) async {
    final deviceId = _ref.read(deviceIdProvider);
    final updated = await _ref.read(salarySlipCoordinatorProvider).finalizeSlip(
          slipId: slipId,
          deviceId: deviceId,
        );

    if (updated == null) {
      return const SalarySlipMutationResult(
        success: false,
        message: 'Unable to finalize slip',
      );
    }

    return const SalarySlipMutationResult(
      success: true,
      message: 'Salary slip finalized',
    );
  }

  Future<SalarySlipMutationResult> updateDeductions({
    required String slipId,
    required double? deductions,
  }) async {
    final deviceId = _ref.read(deviceIdProvider);
    final updated =
        await _ref.read(salarySlipCoordinatorProvider).updateDraftDeductions(
              slipId: slipId,
              deductions: deductions,
              deviceId: deviceId,
            );

    if (updated == null) {
      return const SalarySlipMutationResult(
        success: false,
        message: 'Unable to update deductions on this slip',
      );
    }

    return const SalarySlipMutationResult(
      success: true,
      message: 'Deductions updated',
    );
  }
}
