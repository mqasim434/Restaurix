import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../domain/models/pickup_company.dart';
import '../../../domain/models/rider.dart';
import '../../delivery_config/providers/delivery_config_providers.dart';
import '../providers/checkout_providers.dart';

class PosRiderPickerSheet extends ConsumerWidget {
  const PosRiderPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PosRiderPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridersAsync = ref.watch(activeRidersProvider);

    return _PickerSheetScaffold(
      title: 'Select rider',
      subtitle: 'Own-rider delivery fulfillment',
      child: ridersAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading riders...'),
        error: (error, _) => AppEmptyState(
          title: 'Failed to load riders',
          message: error.toString(),
        ),
        data: (riders) => _RiderList(riders: riders),
      ),
    );
  }
}

class _RiderList extends ConsumerWidget {
  const _RiderList({required this.riders});

  final List<Rider> riders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (riders.isEmpty) {
      return AppEmptyState(
        title: 'No riders configured',
        message:
            'Add delivery riders in Delivery Config — they appear here when active.',
        actionLabel: 'Open Delivery Config',
        onAction: () {
          Navigator.of(context).pop();
          context.go('/delivery-config');
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: riders.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: context.appColors.divider),
      itemBuilder: (context, index) {
        final rider = riders[index];
        return ListTile(
          title: Text(rider.name),
          subtitle: rider.phone == null ? null : Text(rider.phone!),
          onTap: () {
            ref.read(checkoutProvider.notifier).selectRider(
                  id: rider.id,
                  name: rider.name,
                );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class PosPickupCompanyPickerSheet extends ConsumerWidget {
  const PosPickupCompanyPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PosPickupCompanyPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(activePickupCompaniesProvider);

    return _PickerSheetScaffold(
      title: 'Select pickup company',
      subtitle: 'Third-party delivery partner',
      child: companiesAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading pickup companies...'),
        error: (error, _) => AppEmptyState(
          title: 'Failed to load pickup companies',
          message: error.toString(),
        ),
        data: (companies) => _PickupCompanyList(companies: companies),
      ),
    );
  }
}

class _PickupCompanyList extends ConsumerWidget {
  const _PickupCompanyList({required this.companies});

  final List<PickupCompany> companies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (companies.isEmpty) {
      return AppEmptyState(
        title: 'No pickup companies configured',
        message:
            'Add pickup companies in Delivery Config — they appear here when active.',
        actionLabel: 'Open Delivery Config',
        onAction: () {
          Navigator.of(context).pop();
          context.go('/delivery-config');
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: companies.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: context.appColors.divider),
      itemBuilder: (context, index) {
        final company = companies[index];
        return ListTile(
          title: Text(company.name),
          onTap: () {
            ref.read(checkoutProvider.notifier).selectPickupCompany(
                  id: company.id,
                  name: company.name,
                );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _PickerSheetScaffold extends StatelessWidget {
  const _PickerSheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding:
              EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: typography.titleMedium.copyWith(color: colors.onSurface),
              ),
              Text(
                subtitle,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.md),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: child,
                ),
              ),
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
