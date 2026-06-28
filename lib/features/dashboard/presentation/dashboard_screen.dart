import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../app/navigation/navigation_provider.dart';
import '../../../domain/models/user_role.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/dashboard_charts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    final role = ref.watch(currentUserProvider).role;
    final isSalesman = role == UserRole.salesman;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: snapshotAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading dashboard...'),
        error: (error, _) => AppEmptyState(
          title: 'Failed to load dashboard',
          message: error.toString(),
        ),
        data: (snapshot) {
          final cards = snapshot.cards;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isSalesman
                      ? 'Operational overview for today\'s service'
                      : 'Live overview of sales, kitchen flow, and staff presence',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: spacing.lg),
                Wrap(
                  spacing: spacing.md,
                  runSpacing: spacing.md,
                  children: [
                    if (!isSalesman)
                      _StatCard(
                        label: "Today's sales",
                        value: currency.format(cards.todaySales),
                        icon: Icons.payments_outlined,
                      ),
                    _StatCard(
                      label: 'Orders today',
                      value: '${cards.ordersToday}',
                      icon: Icons.receipt_long_outlined,
                    ),
                    _StatCard(
                      label: 'Preparing',
                      value: '${cards.preparingCount}',
                      icon: Icons.restaurant_outlined,
                    ),
                    _StatCard(
                      label: 'Ready',
                      value: '${cards.readyCount}',
                      icon: Icons.check_circle_outline,
                    ),
                    _StatCard(
                      label: 'Served',
                      value: '${cards.servedCount}',
                      icon: Icons.room_service_outlined,
                    ),
                    _StatCard(
                      label: 'Cancelled today',
                      value: '${cards.cancelledToday}',
                      icon: Icons.cancel_outlined,
                    ),
                    if (!isSalesman) ...[
                      _StatCard(
                        label: 'Employees present',
                        value: '${cards.employeesPresent}',
                        icon: Icons.groups_outlined,
                      ),
                      _StatCard(
                        label: 'Monthly revenue',
                        value: currency.format(cards.monthlyRevenue),
                        icon: Icons.calendar_month_outlined,
                      ),
                      _StatCard(
                        label: 'Average ticket',
                        value: currency.format(cards.averageTicketToday),
                        icon: Icons.local_offer_outlined,
                      ),
                    ],
                  ],
                ),
                if (!isSalesman) ...[
                  SizedBox(height: spacing.xl),
                  DashboardChartsSection(charts: snapshot.charts),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return SizedBox(
      width: 200,
      child: AppCard(
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary, size: spacing.lg),
              SizedBox(height: spacing.sm),
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                value,
                style: typography.titleLarge.copyWith(color: colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
