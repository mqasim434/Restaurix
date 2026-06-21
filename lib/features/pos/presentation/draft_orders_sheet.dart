import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/repositories/draft_order_repository.dart';
import '../../../domain/models/draft_order.dart';
import '../../../domain/models/order_enums.dart';
import '../../../data/local/mappers/draft_order_mapper.dart';
import '../providers/draft_providers.dart';

class DraftOrdersSheet extends ConsumerWidget {
  const DraftOrdersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const DraftOrdersSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final draftsAsync = ref.watch(draftOrderListProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Draft orders',
                    style: typography.titleLarge.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Drafts are removed when resumed. Discarding releases any held table.',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: draftsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: AppLoadingIndicator(message: 'Loading drafts...'),
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load drafts',
                message: error.toString(),
              ),
              data: (drafts) {
                if (drafts.isEmpty) {
                  return const AppEmptyState(
                    title: 'No drafts saved',
                    message: 'Use Save as Draft on an in-progress cart.',
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: drafts.length,
                  separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                  itemBuilder: (context, index) {
                    return _DraftTile(draft: drafts[index]);
                  },
                );
              },
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _DraftTile extends ConsumerWidget {
  const _DraftTile({required this.draft});

  final DraftOrder draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final controller = ref.read(draftOrderControllerProvider);

    final snapshot = snapshotFromDraft(draft);
    final itemCount =
        snapshot.cartItems.fold(0, (sum, item) => sum + item.quantity);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              draft.label ??
                  snapshot.checkout.tableLabel ??
                  'Draft ${draft.orderNumberFallback}',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.xs),
            Text(
              '$itemCount items · ${snapshot.checkout.orderType?.label ?? 'No type'} · ${DateFormat.yMMMd().add_jm().format(draft.updatedAt)}',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Resume',
                    expand: true,
                    onPressed: () async {
                      try {
                        await controller.resume(draft.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          AppSnackbar.success(context, 'Draft restored to POS');
                        }
                      } on DraftOrderException catch (error) {
                        if (context.mounted) {
                          AppSnackbar.error(context, error.message);
                        }
                      }
                    },
                  ),
                ),
                SizedBox(width: spacing.sm),
                AppButton(
                  label: 'Discard',
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    await controller.discard(draft.id);
                    if (context.mounted) {
                      AppSnackbar.info(context, 'Draft discarded');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on DraftOrder {
  String get orderNumberFallback => id.substring(0, 6).toUpperCase();
}
