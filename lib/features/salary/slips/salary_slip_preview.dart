import 'package:intl/intl.dart';

import '../../../../core/format/money_format.dart';
import '../../../../domain/models/app_currency.dart';
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

String formatSalaryMoney(
  double amount, [
  String currencyCode = AppCurrency.defaultCode,
]) {
  return MoneyFormat.format(amount, currencyCode);
}

String formatSalaryPeriod(DateTime start, DateTime end) {
  final formatter = DateFormat.yMMMd();
  return '${formatter.format(start)} – ${formatter.format(end)}';
}

abstract final class SalarySlipPreview {
  static List<String> renderLines(
    SalarySlipDocument document, {
    String currencyCode = AppCurrency.defaultCode,
  }) {
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
      'Base pay: ${formatSalaryMoney(slip.basePay, currencyCode)}',
    ];

    if (slip.deductions != null && slip.deductions! > 0) {
      lines.add(
        'Deductions: -${formatSalaryMoney(slip.deductions!, currencyCode)}',
      );
    }

    lines.add('NET PAY: ${formatSalaryMoney(slip.netPay, currencyCode)}');

    if (slip.isFinalized) {
      lines.add('This slip is finalized and locked.');
    }

    return lines;
  }

  static String renderText(
    SalarySlipDocument document, {
    String currencyCode = AppCurrency.defaultCode,
  }) {
    return renderLines(document, currencyCode: currencyCode).join('\n');
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
