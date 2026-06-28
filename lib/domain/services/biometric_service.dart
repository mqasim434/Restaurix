/// Hardware-agnostic fingerprint integration surface.
///
/// Production Windows builds can swap [SimulatedBiometricService] for a
/// platform-channel implementation backed by WinBio or a vendor USB SDK.
/// UI and attendance logic must depend only on this interface.
library;

enum BiometricDeviceState {
  disconnected,
  ready,
  enrolling,
}

class BiometricDeviceStatus {
  const BiometricDeviceStatus({
    required this.state,
    this.message,
  });

  final BiometricDeviceState state;
  final String? message;

  bool get isReady => state == BiometricDeviceState.ready;
}

abstract class BiometricService {
  Stream<BiometricDeviceStatus> watchStatus();

  /// Emits the matched [fingerprintEnrollmentId] after a successful scan.
  Stream<String> watchScans();

  Future<void> initialize();

  Future<void> dispose();

  /// Captures a template and returns a stable enrollment id for the employee.
  Future<String> enroll({
    required String employeeId,
    required String employeeName,
  });

  /// Debug/dev helper to emit a scan without physical hardware.
  Future<void> simulateScan(String fingerprintEnrollmentId);
}
