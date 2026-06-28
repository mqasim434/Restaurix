import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/services/salary_slip_service.dart';
import '../calculation/presentation/salary_calculation_screen.dart';
import '../slips/presentation/salary_slips_panel.dart';
import '../slips/providers/salary_slip_providers.dart';

class SalaryHubScreen extends ConsumerWidget {
  const SalaryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(salarySlipBootstrapProvider);

    final spacing = context.appSpacing;
    final notice = ref.watch(salaryAutoGenerationNoticeProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null)
            _AutoGenerationBanner(
              notice: notice,
              onDismiss: () {
                ref.read(salaryAutoGenerationNoticeProvider.notifier).state =
                    null;
              },
              onReview: () {
                ref.read(salaryAutoGenerationNoticeProvider.notifier).state =
                    null;
                DefaultTabController.of(context).animateTo(1);
              },
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
            child: const TabBar(
              tabs: [
                Tab(text: 'Preview'),
                Tab(text: 'Slips'),
              ],
            ),
          ),
          SizedBox(height: spacing.md),
          const Expanded(
            child: TabBarView(
              children: [
                SalaryCalculationScreen(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SalarySlipsPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoGenerationBanner extends StatelessWidget {
  const _AutoGenerationBanner({
    required this.notice,
    required this.onDismiss,
    required this.onReview,
  });

  final SalaryAutoGenerationNotice notice;
  final VoidCallback onDismiss;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTypography;
    final periodEnd = SalarySlipService.inclusivePeriodEnd(notice.period);

    return Material(
      color: colors.primaryContainer,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.onPrimaryContainer),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                '${notice.createdCount} draft salary slip(s) were auto-generated '
                'for the period ending ${periodEnd.month}/${periodEnd.day}/${periodEnd.year}. '
                'Review and finalize them when ready.',
                style: typography.bodyMedium.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            TextButton(onPressed: onReview, child: const Text('Review slips')),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
