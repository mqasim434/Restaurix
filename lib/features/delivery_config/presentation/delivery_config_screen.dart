import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/pickup_company.dart';
import '../../../domain/models/rider.dart';
import '../providers/delivery_config_providers.dart';
import 'pickup_company_form_dialog.dart';
import 'rider_form_dialog.dart';

class DeliveryConfigScreen extends ConsumerWidget {
  const DeliveryConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configure delivery riders and third-party pickup companies for POS',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            const TabBar(
              tabs: [
                Tab(text: 'Riders'),
                Tab(text: 'Pickup Companies'),
              ],
            ),
            SizedBox(height: spacing.md),
            const Expanded(
              child: TabBarView(
                children: [
                  DeliveryRidersPanel(),
                  DeliveryPickupCompaniesPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryRidersPanel extends ConsumerWidget {
  const DeliveryRidersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridersAsync = ref.watch(riderListProvider);

    return ridersAsync.when(
      loading: () => const AppLoadingIndicator(message: 'Loading riders...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load riders',
        message: error.toString(),
      ),
      data: (riders) => _DeliveryListScaffold(
        emptyTitle: 'No riders yet',
        emptyMessage: 'Add your own delivery riders for POS orders.',
        emptyActionLabel: 'Add Rider',
        onAdd: () => _openRiderForm(context, ref),
        itemCount: riders.length,
        itemBuilder: (context, index) {
          final rider = riders[index];
          return _RiderRow(
            rider: rider,
            onEdit: () => _openRiderForm(context, ref, rider: rider),
            onDelete: () => _confirmDeleteRider(context, ref, rider),
            onToggleActive: () => _toggleRider(context, ref, rider),
          );
        },
      ),
    );
  }

  Future<void> _openRiderForm(
    BuildContext context,
    WidgetRef ref, {
    Rider? rider,
  }) async {
    final result = await RiderFormDialog.show(
      context,
      rider: rider,
      title: rider == null ? 'Add Rider' : 'Edit Rider',
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(riderListProvider.notifier);
    final mutation = rider == null
        ? await notifier.create(
            name: result.name,
            phone: result.phone,
            isActive: result.isActive,
          )
        : await notifier.updateRider(
            rider.copyWith(
              name: result.name,
              phone: result.phone,
              clearPhone: result.clearPhone,
              isActive: result.isActive,
            ),
          );

    if (!context.mounted) return;
    _showMutation(context, mutation);
  }

  Future<void> _toggleRider(
    BuildContext context,
    WidgetRef ref,
    Rider rider,
  ) async {
    final mutation =
        await ref.read(riderListProvider.notifier).toggleActive(rider);
    if (!context.mounted) return;
    _showMutation(context, mutation);
  }

  Future<void> _confirmDeleteRider(
    BuildContext context,
    WidgetRef ref,
    Rider rider,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete rider?',
      content: Text(
        'Delete "${rider.name}"? In-progress orders keep the rider name snapshot.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final mutation =
        await ref.read(riderListProvider.notifier).delete(rider.id);
    if (!context.mounted) return;
    _showMutation(context, mutation);
  }
}

class DeliveryPickupCompaniesPanel extends ConsumerWidget {
  const DeliveryPickupCompaniesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(pickupCompanyListProvider);

    return companiesAsync.when(
      loading: () =>
          const AppLoadingIndicator(message: 'Loading pickup companies...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load pickup companies',
        message: error.toString(),
      ),
      data: (companies) => _DeliveryListScaffold(
        emptyTitle: 'No pickup companies yet',
        emptyMessage: 'Add Foodpanda, Careem, Bykea, or any custom partner.',
        emptyActionLabel: 'Add Company',
        onAdd: () => _openCompanyForm(context, ref),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final company = companies[index];
          return _PickupCompanyRow(
            company: company,
            onEdit: () => _openCompanyForm(context, ref, company: company),
            onDelete: () => _confirmDeleteCompany(context, ref, company),
            onToggleActive: () => _toggleCompany(context, ref, company),
          );
        },
      ),
    );
  }

  Future<void> _openCompanyForm(
    BuildContext context,
    WidgetRef ref, {
    PickupCompany? company,
  }) async {
    final result = await PickupCompanyFormDialog.show(
      context,
      company: company,
      title: company == null ? 'Add Pickup Company' : 'Edit Pickup Company',
    );
    if (result == null || !context.mounted) return;

    final notifier = ref.read(pickupCompanyListProvider.notifier);
    final mutation = company == null
        ? await notifier.create(
            name: result.name,
            logoUrl: result.logoUrl,
            isActive: result.isActive,
          )
        : await notifier.updateCompany(
            company.copyWith(
              name: result.name,
              logoUrl: result.logoUrl,
              clearLogoUrl: result.clearLogo,
              isActive: result.isActive,
            ),
          );

    if (!context.mounted) return;
    _showMutation(context, mutation);
  }

  Future<void> _toggleCompany(
    BuildContext context,
    WidgetRef ref,
    PickupCompany company,
  ) async {
    final mutation = await ref
        .read(pickupCompanyListProvider.notifier)
        .toggleActive(company);
    if (!context.mounted) return;
    _showMutation(context, mutation);
  }

  Future<void> _confirmDeleteCompany(
    BuildContext context,
    WidgetRef ref,
    PickupCompany company,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete pickup company?',
      content: Text(
        'Delete "${company.name}"? In-progress orders keep the company name snapshot.',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final mutation =
        await ref.read(pickupCompanyListProvider.notifier).delete(company.id);
    if (!context.mounted) return;
    _showMutation(context, mutation);
  }
}

void _showMutation(BuildContext context, DeliveryMutationResult mutation) {
  if (!mutation.success && mutation.errorMessage != null) {
    AppSnackbar.error(context, mutation.errorMessage!);
  }
}

class _DeliveryListScaffold extends StatelessWidget {
  const _DeliveryListScaffold({
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyActionLabel,
    required this.onAdd,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String emptyTitle;
  final String emptyMessage;
  final String emptyActionLabel;
  final VoidCallback onAdd;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    if (itemCount == 0) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: onAdd,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: emptyActionLabel,
            icon: AppIcons.add,
            size: AppButtonSize.small,
            onPressed: onAdd,
          ),
        ),
        SizedBox(height: spacing.sm),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: context.appRadius.mdBorder,
              border: Border.all(color: colors.border),
            ),
            child: ListView.separated(
              padding: EdgeInsets.all(spacing.sm),
              itemCount: itemCount,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.divider),
              itemBuilder: itemBuilder,
            ),
          ),
        ),
      ],
    );
  }
}

class _RiderRow extends StatelessWidget {
  const _RiderRow({
    required this.rider,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Rider rider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.appSpacing.sm,
        vertical: context.appSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: typography.bodyMedium.copyWith(
                    color: rider.isActive
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (rider.phone != null)
                  Text(
                    rider.phone!,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: rider.isActive, onChanged: (_) => onToggleActive()),
          IconButton(
            tooltip: 'Edit',
            icon: Icon(AppIcons.edit, color: colors.onSurfaceVariant),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(AppIcons.delete, color: colors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PickupCompanyRow extends StatelessWidget {
  const _PickupCompanyRow({
    required this.company,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final PickupCompany company;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final size = spacing.xl;

    Widget leading;
    if (company.logoUrl != null && File(company.logoUrl!).existsSync()) {
      leading = ClipRRect(
        borderRadius: context.appRadius.smBorder,
        child: Image.file(
          File(company.logoUrl!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      leading = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: context.appRadius.smBorder,
        ),
        child: Icon(Icons.delivery_dining_outlined,
            color: colors.onSurfaceVariant),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      child: Row(
        children: [
          leading,
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              company.name,
              style: typography.bodyMedium.copyWith(
                color: company.isActive
                    ? colors.onSurface
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          Switch(value: company.isActive, onChanged: (_) => onToggleActive()),
          IconButton(
            tooltip: 'Edit',
            icon: Icon(AppIcons.edit, color: colors.onSurfaceVariant),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: Icon(AppIcons.delete, color: colors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
