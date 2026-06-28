import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../data/local/device_id_service.dart';
import '../../../data/local/isar_service.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/services/simulated_biometric_service.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/employee.dart';
import '../../../domain/services/attendance_service.dart';
import '../../../domain/services/biometric_service.dart';
import '../../employees/providers/employee_providers.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  final service = SimulatedBiometricService();
  ref.onDispose(service.dispose);
  return service;
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(isarProvider));
});

final attendanceCoordinatorProvider = Provider<AttendanceCoordinator>((ref) {
  return AttendanceCoordinator(
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    employeeRepository: ref.watch(employeeRepositoryProvider),
  );
});

final attendanceListProvider =
    StreamProvider.autoDispose<List<AttendanceRecord>>((ref) {
  return ref.watch(attendanceRepositoryProvider).watchAll();
});

class AttendanceScanState {
  const AttendanceScanState({
    this.lastSuccess,
    this.lastFailure,
    this.isProcessing = false,
  });

  final AttendanceSuccess? lastSuccess;
  final AttendanceFailure? lastFailure;
  final bool isProcessing;

  AttendanceScanState copyWith({
    AttendanceSuccess? lastSuccess,
    AttendanceFailure? lastFailure,
    bool clearSuccess = false,
    bool clearFailure = false,
    bool? isProcessing,
  }) {
    return AttendanceScanState(
      lastSuccess: clearSuccess ? null : (lastSuccess ?? this.lastSuccess),
      lastFailure: clearFailure ? null : (lastFailure ?? this.lastFailure),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

final attendanceScanStateProvider =
    NotifierProvider<AttendanceScanNotifier, AttendanceScanState>(
  AttendanceScanNotifier.new,
);

class AttendanceScanNotifier extends Notifier<AttendanceScanState> {
  StreamSubscription<String>? _scanSubscription;

  @override
  AttendanceScanState build() {
    final biometric = ref.read(biometricServiceProvider);
    _scanSubscription?.cancel();
    _scanSubscription = biometric.watchScans().listen(_handleScan);
    ref.onDispose(() => _scanSubscription?.cancel());
    return const AttendanceScanState();
  }

  Future<void> _handleScan(String enrollmentId) async {
    state = state.copyWith(isProcessing: true, clearSuccess: true, clearFailure: true);
    final result = await ref.read(attendanceCoordinatorProvider).handleFingerprintScan(
          fingerprintEnrollmentId: enrollmentId,
          deviceId: ref.read(deviceIdProvider),
        );
    state = AttendanceScanState(
      lastSuccess: result.success,
      lastFailure: result.failure,
      isProcessing: false,
    );
  }

  Future<void> simulateScan(String enrollmentId) {
    return ref.read(biometricServiceProvider).simulateScan(enrollmentId);
  }

  void clearMessages() {
    state = state.copyWith(clearSuccess: true, clearFailure: true);
  }
}

final biometricStatusProvider = StreamProvider<BiometricDeviceStatus>((ref) async* {
  final service = ref.watch(biometricServiceProvider);
  await service.initialize();
  yield* service.watchStatus();
});

final enrolledEmployeesProvider = Provider<AsyncValue<List<Employee>>>((ref) {
  final employeesAsync = ref.watch(employeeListProvider);
  return employeesAsync.whenData(
    (employees) => employees
        .where((employee) =>
            employee.isActive &&
            employee.fingerprintEnrollmentId != null &&
            employee.fingerprintEnrollmentId!.isNotEmpty)
        .toList(),
  );
});

final employeesPendingEnrollmentProvider =
    Provider<AsyncValue<List<Employee>>>((ref) {
  final employeesAsync = ref.watch(employeeListProvider);
  return employeesAsync.whenData(
    (employees) => employees
        .where(
          (employee) =>
              employee.isActive &&
              (employee.fingerprintEnrollmentId == null ||
                  employee.fingerprintEnrollmentId!.isEmpty),
        )
        .toList(),
  );
});

class AttendanceMutationResult {
  const AttendanceMutationResult({
    required this.success,
    this.errorMessage,
    this.scanSuccess,
  });

  final bool success;
  final String? errorMessage;
  final AttendanceSuccess? scanSuccess;
}

final attendanceActionsProvider = Provider<AttendanceActions>((ref) {
  return AttendanceActions(ref);
});

class AttendanceActions {
  AttendanceActions(this._ref);

  final Ref _ref;

  AttendanceCoordinator get _coordinator =>
      _ref.read(attendanceCoordinatorProvider);

  String get _deviceId => _ref.read(deviceIdProvider);

  String get _userId => _ref.read(currentUserProvider).id;

  Future<AttendanceMutationResult> enrollEmployee(Employee employee) async {
    try {
      final enrollmentId = await _ref.read(biometricServiceProvider).enroll(
            employeeId: employee.id,
            employeeName: employee.fullName,
          );
      final updated = await _coordinator.enrollFingerprint(
        employeeId: employee.id,
        fingerprintEnrollmentId: enrollmentId,
        deviceId: _deviceId,
      );
      if (updated == null) {
        return const AttendanceMutationResult(
          success: false,
          errorMessage: 'Could not save fingerprint enrollment',
        );
      }
      return const AttendanceMutationResult(success: true);
    } catch (error) {
      return AttendanceMutationResult(
        success: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<AttendanceMutationResult> manualCheckIn({
    required String employeeId,
    required DateTime checkInTime,
    String? notes,
  }) async {
    final result = await _coordinator.manualCheckIn(
      employeeId: employeeId,
      createdByUserId: _userId,
      deviceId: _deviceId,
      checkInTime: checkInTime,
      notes: notes,
    );
    if (result.failure != null) {
      return AttendanceMutationResult(
        success: false,
        errorMessage: result.failure!.message,
      );
    }
    return AttendanceMutationResult(
      success: true,
      scanSuccess: result.success,
    );
  }

  Future<AttendanceMutationResult> manualCheckOut({
    required String recordId,
    required DateTime checkOutTime,
    String? notes,
  }) async {
    final result = await _coordinator.manualCheckOut(
      recordId: recordId,
      createdByUserId: _userId,
      deviceId: _deviceId,
      checkOutTime: checkOutTime,
      notes: notes,
    );
    if (result.failure != null) {
      return AttendanceMutationResult(
        success: false,
        errorMessage: result.failure!.message,
      );
    }
    return AttendanceMutationResult(
      success: true,
      scanSuccess: result.success,
    );
  }
}

final employeeNameLookupProvider = Provider<Map<String, String>>((ref) {
  final employeesAsync = ref.watch(employeeListProvider);
  return employeesAsync.maybeWhen(
    data: (employees) => {
      for (final employee in employees) employee.id: employee.fullName,
    },
    orElse: () => const {},
  );
});

final openAttendanceByEmployeeProvider =
    FutureProvider<Map<String, AttendanceRecord>>((ref) async {
  final employeesAsync = ref.watch(employeeListProvider);
  final repo = ref.watch(attendanceRepositoryProvider);
  final employees = employeesAsync.valueOrNull ?? const <Employee>[];
  final result = <String, AttendanceRecord>{};
  for (final employee in employees) {
    final open = await repo.findOpenForEmployee(employee.id);
    if (open != null) {
      result[employee.id] = open;
    }
  }
  return result;
});
