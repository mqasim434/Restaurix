import '../models/attendance_record.dart';
import '../models/employee.dart';

enum AttendanceScanAction {
  checkIn,
  checkOut,
}

enum AttendanceFailureReason {
  unrecognized,
  inactiveEmployee,
}

class AttendanceSuccess {
  const AttendanceSuccess({
    required this.action,
    required this.employee,
    required this.record,
  });

  final AttendanceScanAction action;
  final Employee employee;
  final AttendanceRecord record;
}

class AttendanceFailure {
  const AttendanceFailure({
    required this.reason,
    required this.message,
  });

  final AttendanceFailureReason reason;
  final String message;
}

typedef AttendanceOperationResult = ({AttendanceSuccess? success, AttendanceFailure? failure});

/// Applies attendance business rules shared by biometric and manual flows.
///
/// Double-scan rule: when an employee already has an open shift, the next
/// successful fingerprint scan checks them out instead of creating a second
/// open record.
abstract final class AttendanceRules {
  static AttendanceScanAction resolveScanAction({required bool hasOpenShift}) {
    return hasOpenShift
        ? AttendanceScanAction.checkOut
        : AttendanceScanAction.checkIn;
  }
}
