import 'package:intl/intl.dart';

import '../../../../domain/models/employee.dart';
import '../../../../domain/models/salary_slip.dart';

class SalarySlipDocument {
  const SalarySlipDocument({
    required this.businessName,
    required this.employeeName,
    required this.employeeRole,
    required this.slip,
  });

  final String businessName;
  final String employeeName;
  final String employeeRole;
  final SalarySlip slip;
}

String formatSalaryMoney(double amount) {
  return NumberFormat.simpleCurrency().format(amount);
}

String formatSalaryPeriod(DateTime start, DateTime end) {
  final formatter = DateFormat.yMMMd();
  return '${formatter.format(start)} – ${formatter.format(end)}';
}

abstract final class SalarySlipPreview {
  static List<String> renderLines(SalarySlipDocument document) {
    final slip = document.slip;
    final lines = <String>[
      document.businessName,
      'SALARY SLIP',
      document.employeeName,
      document.employeeRole,
      'Period: ${formatSalaryPeriod(slip.periodStart, slip.periodEnd)}',
      'Status: ${slip.status.label}',
      'Generated: ${DateFormat.yMMMd().add_jm().format(slip.generatedAt)}',
      'Hours worked: ${slip.totalHours.toStringAsFixed(1)}',
      'Base pay: ${formatSalaryMoney(slip.basePay)}',
    ];

    if (slip.deductions != null && slip.deductions! > 0) {
      lines.add('Deductions: -${formatSalaryMoney(slip.deductions!)}');
    }

    lines.add('NET PAY: ${formatSalaryMoney(slip.netPay)}');

    if (slip.isFinalized) {
      lines.add('This slip is finalized and locked.');
    }

    return lines;
  }

  static String renderText(SalarySlipDocument document) {
    return renderLines(document).join('\n');
  }
}

SalarySlipDocument buildSalarySlipDocument({
  required String businessName,
  required Employee employee,
  required SalarySlip slip,
}) {
  return SalarySlipDocument(
    businessName: businessName,
    employeeName: employee.fullName,
    employeeRole: employee.role,
    slip: slip,
  );
}
