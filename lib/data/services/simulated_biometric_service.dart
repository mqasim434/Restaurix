import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/services/biometric_service.dart';

/// Development implementation that simulates a USB fingerprint reader.
///
/// Replace with a Windows platform-channel adapter when hardware is available.
/// The adapter should map vendor scan events to [fingerprintEnrollmentId] strings
/// stored on [Employee.fingerprintEnrollmentId].
class SimulatedBiometricService implements BiometricService {
  SimulatedBiometricService();

  final _statusController = StreamController<BiometricDeviceStatus>.broadcast();
  final _scanController = StreamController<String>.broadcast();
  var _initialized = false;
  var _enrollingEmployeeId = '';

  @override
  Stream<BiometricDeviceStatus> watchStatus() => _statusController.stream;

  @override
  Stream<String> watchScans() => _scanController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _emitStatus(
      const BiometricDeviceStatus(
        state: BiometricDeviceState.ready,
        message: 'Simulated reader ready (dev mode)',
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _scanController.close();
  }

  @override
  Future<String> enroll({
    required String employeeId,
    required String employeeName,
  }) async {
    _enrollingEmployeeId = employeeId;
    _emitStatus(
      BiometricDeviceStatus(
        state: BiometricDeviceState.enrolling,
        message: 'Enrolling $employeeName...',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final enrollmentId = 'fp-${employeeId.substring(0, 8)}-${const Uuid().v4().substring(0, 8)}';
    _enrollingEmployeeId = '';
    _emitStatus(
      const BiometricDeviceStatus(
        state: BiometricDeviceState.ready,
        message: 'Enrollment captured',
      ),
    );
    return enrollmentId;
  }

  @override
  Future<void> simulateScan(String fingerprintEnrollmentId) async {
    if (!_initialized) {
      throw StateError('Biometric service is not initialized');
    }
    if (_enrollingEmployeeId.isNotEmpty) return;
    _scanController.add(fingerprintEnrollmentId);
  }

  void _emitStatus(BiometricDeviceStatus status) {
    if (_statusController.isClosed) return;
    _statusController.add(status);
  }
}
