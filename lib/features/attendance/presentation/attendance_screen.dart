import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/attendance_record.dart';
import '../../../domain/models/employee.dart';
import '../../../domain/services/attendance_service.dart';
import '../../../domain/services/biometric_service.dart';
import '../../employees/providers/employee_providers.dart';
import '../providers/attendance_providers.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fingerprint check-in/out with manual fallback when the reader is unavailable',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            const TabBar(
              tabs: [
                Tab(text: 'Scan'),
                Tab(text: 'Enroll'),
                Tab(text: 'Manual'),
              ],
            ),
            SizedBox(height: spacing.md),
            const Expanded(
              child: TabBarView(
                children: [
                  _ScanPanel(),
                  _EnrollmentPanel(),
                  _ManualPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPanel extends ConsumerWidget {
  const _ScanPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final statusAsync = ref.watch(biometricStatusProvider);
    final scanState = ref.watch(attendanceScanStateProvider);
    final enrolledAsync = ref.watch(enrolledEmployeesProvider);

    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reader status', style: typography.titleMedium),
              SizedBox(height: spacing.sm),
              statusAsync.when(
                loading: () => const Text('Connecting to reader...'),
                error: (error, _) => Text(
                  'Reader unavailable: $error',
                  style: typography.bodyMedium.copyWith(color: colors.error),
                ),
                data: (status) => Text(
                  status.message ??
                      switch (status.state) {
                        BiometricDeviceState.ready => 'Ready for scans',
                        BiometricDeviceState.disconnected =>
                          'Fingerprint device not detected',
                        BiometricDeviceState.enrolling => 'Enrollment in progress',
                      },
                  style: typography.bodyMedium,
                ),
              ),
              SizedBox(height: spacing.md),
              Text(
                'Scan rule: an open shift is checked out on the next scan; '
                'otherwise the employee is checked in.',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.md),
        if (scanState.isProcessing)
          const AppLoadingIndicator(message: 'Processing scan...')
        else if (scanState.lastSuccess case final success?)
          AppCard(
            child: Text(
              '${success.employee.fullName} '
              '${success.action == AttendanceScanAction.checkIn ? 'checked in' : 'checked out'} '
              'at ${DateFormat.jm().format(DateTime.now())}',
              style: typography.bodyLarge.copyWith(color: colors.success),
            ),
          )
        else if (scanState.lastFailure case final failure?)
          AppCard(
            child: Text(
              failure.message,
              style: typography.bodyLarge.copyWith(color: colors.error),
            ),
          ),
        SizedBox(height: spacing.md),
        enrolledAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (employees) {
            if (employees.isEmpty) {
              return const AppEmptyState(
                title: 'No enrolled employees',
                message: 'Enroll fingerprints before using the scan panel.',
              );
            }

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Simulate scan (dev)', style: typography.titleMedium),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Use this when no USB reader is connected.',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.sm,
                    children: [
                      for (final employee in employees)
                        AppButton(
                          label: employee.fullName,
                          variant: AppButtonVariant.secondary,
                          onPressed: employee.fingerprintEnrollmentId == null
                              ? null
                              : () => ref
                                  .read(attendanceScanStateProvider.notifier)
                                  .simulateScan(
                                    employee.fingerprintEnrollmentId!,
                                  ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EnrollmentPanel extends ConsumerWidget {
  const _EnrollmentPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(employeesPendingEnrollmentProvider);

    return pendingAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading employees...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load employees',
        message: error.toString(),
      ),
      data: (employees) {
        if (employees.isEmpty) {
          return const AppEmptyState(
            title: 'All active employees are enrolled',
            message: 'Add employees or reactivate staff to enroll more fingerprints.',
          );
        }

        return ListView.separated(
          itemCount: employees.length,
          separatorBuilder: (_, __) => SizedBox(height: context.appSpacing.sm),
          itemBuilder: (context, index) {
            final employee = employees[index];
            return AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employee.fullName, style: context.appTypography.titleMedium),
                        Text(
                          employee.role,
                          style: context.appTypography.bodySmall.copyWith(
                            color: context.appColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Enroll fingerprint',
                    onPressed: () => _enroll(context, ref, employee),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _enroll(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    final result =
        await ref.read(attendanceActionsProvider).enrollEmployee(employee);
    if (!context.mounted) return;

    if (result.success) {
      AppSnackbar.success(context, '${employee.fullName} enrolled');
    } else {
      AppSnackbar.error(
        context,
        result.errorMessage ?? 'Enrollment failed',
      );
    }
  }
}

class _ManualPanel extends ConsumerStatefulWidget {
  const _ManualPanel();

  @override
  ConsumerState<_ManualPanel> createState() => _ManualPanelState();
}

class _ManualPanelState extends ConsumerState<_ManualPanel> {
  String? _selectedEmployeeId;
  final _notesController = TextEditingController();
  final _checkInTime = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final employeesAsync = ref.watch(employeeListProvider);
    final openShiftsAsync = ref.watch(openAttendanceByEmployeeProvider);
    final recordsAsync = ref.watch(attendanceListProvider);
    final names = ref.watch(employeeNameLookupProvider);

    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manual check-in', style: context.appTypography.titleMedium),
              SizedBox(height: spacing.md),
              employeesAsync.when(
                loading: () => const AppLoadingIndicator(),
                error: (error, _) => Text(error.toString()),
                data: (employees) {
                  final active =
                      employees.where((employee) => employee.isActive).toList();
                  return AppDropdown<String>(
                    label: 'Employee',
                    value: _selectedEmployeeId,
                    hint: 'Select employee',
                    items: active.map((employee) => employee.id).toList(),
                    itemLabel: (id) =>
                        active.firstWhere((employee) => employee.id == id).fullName,
                    onChanged: (value) => setState(() => _selectedEmployeeId = value),
                  );
                },
              ),
              SizedBox(height: spacing.md),
              AppTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Optional reason for manual entry',
              ),
              SizedBox(height: spacing.md),
              AppButton(
                label: 'Record manual check-in',
                onPressed: _selectedEmployeeId == null ? null : _manualCheckIn,
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        Text('Open shifts', style: context.appTypography.titleMedium),
        SizedBox(height: spacing.sm),
        openShiftsAsync.when(
          loading: () => const AppLoadingIndicator(message: 'Loading open shifts...'),
          error: (error, _) => Text(error.toString()),
          data: (openByEmployee) {
            if (openByEmployee.isEmpty) {
              return Text(
                'No open shifts.',
                style: context.appTypography.bodyMedium.copyWith(
                  color: context.appColors.onSurfaceVariant,
                ),
              );
            }

            return Column(
              children: [
                for (final entry in openByEmployee.entries)
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                names[entry.key] ?? entry.key,
                                style: context.appTypography.titleMedium,
                              ),
                              Text(
                                'Since ${DateFormat.jm().format(entry.value.checkInTime)}',
                                style: context.appTypography.bodySmall.copyWith(
                                  color: context.appColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          label: 'Check out',
                          onPressed: () => _manualCheckOut(entry.value.id),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: spacing.lg),
        Text('Recent records', style: context.appTypography.titleMedium),
        SizedBox(height: spacing.sm),
        recordsAsync.when(
          loading: () => const AppLoadingIndicator(message: 'Loading records...'),
          error: (error, _) => Text(error.toString()),
          data: (records) {
            if (records.isEmpty) {
              return const AppEmptyState(
                title: 'No attendance yet',
                message: 'Scan or add a manual entry to begin.',
              );
            }

            return Column(
              children: [
                for (final record in records.take(20))
                  AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(names[record.employeeId] ?? record.employeeId),
                      subtitle: Text(
                        '${DateFormat.yMMMd().add_jm().format(record.checkInTime)}'
                        '${record.checkOutTime == null ? ' · Open' : ' – ${DateFormat.jm().format(record.checkOutTime!)}'}'
                        ' · ${record.source.label}',
                      ),
                      trailing: record.checkOutTime == null
                          ? null
                          : Text(
                              formatAttendanceDuration(
                                record.workedDuration()!,
                              ),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _manualCheckIn() async {
    final result = await ref.read(attendanceActionsProvider).manualCheckIn(
          employeeId: _selectedEmployeeId!,
          checkInTime: _checkInTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
    if (!mounted) return;
    if (result.success) {
      AppSnackbar.success(context, 'Manual check-in recorded');
      _notesController.clear();
    } else {
      AppSnackbar.error(context, result.errorMessage ?? 'Check-in failed');
    }
  }

  Future<void> _manualCheckOut(String recordId) async {
    final result = await ref.read(attendanceActionsProvider).manualCheckOut(
          recordId: recordId,
          checkOutTime: DateTime.now(),
        );
    if (!mounted) return;
    if (result.success) {
      AppSnackbar.success(context, 'Manual check-out recorded');
    } else {
      AppSnackbar.error(context, result.errorMessage ?? 'Check-out failed');
    }
  }
}
