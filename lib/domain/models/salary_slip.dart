import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

enum SalarySlipStatus {
  draft,
  finalized,
}

extension SalarySlipStatusX on SalarySlipStatus {
  String get label => switch (this) {
        SalarySlipStatus.draft => 'Draft',
        SalarySlipStatus.finalized => 'Finalized',
      };
}

class SalarySlip implements SyncableEntity {
  const SalarySlip({
    required this.id,
    required this.employeeId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalHours,
    required this.basePay,
    this.deductions,
    required this.netPay,
    required this.generatedAt,
    required this.generatedByUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.deletedAt,
    required this.syncAction,
    required this.deviceId,
    required this.version,
  });

  @override
  final String id;
  final String employeeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalHours;
  final double basePay;
  final double? deductions;
  final double netPay;
  final DateTime generatedAt;
  final String generatedByUserId;
  final SalarySlipStatus status;

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isSynced;
  @override
  final DateTime? deletedAt;
  @override
  final SyncAction syncAction;
  @override
  final String deviceId;
  @override
  final int version;

  bool get isFinalized => status == SalarySlipStatus.finalized;

  SalarySlip copyWith({
    double? deductions,
    bool clearDeductions = false,
    double? netPay,
    SalarySlipStatus? status,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return SalarySlip(
      id: id,
      employeeId: employeeId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalHours: totalHours,
      basePay: basePay,
      deductions: clearDeductions ? null : (deductions ?? this.deductions),
      netPay: netPay ?? this.netPay,
      generatedAt: generatedAt,
      generatedByUserId: generatedByUserId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
      syncAction: syncAction ?? this.syncAction,
      deviceId: deviceId ?? this.deviceId,
      version: version ?? this.version,
    );
  }
}

double computeSalaryNetPay({
  required double basePay,
  double? deductions,
}) {
  final deductionAmount = deductions ?? 0;
  return basePay - deductionAmount;
}
