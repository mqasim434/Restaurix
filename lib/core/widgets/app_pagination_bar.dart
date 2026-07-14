import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// Footer controls for client-side paginated lists and tables.
class AppPaginationBar extends StatelessWidget {
  const AppPaginationBar({
    super.key,
    required this.pageIndex,
    required this.pageCount,
    required this.totalItems,
    required this.pageSize,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageIndex;
  final int pageCount;
  final int totalItems;
  final int pageSize;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= pageSize) return const SizedBox.shrink();

    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final start = pageIndex * pageSize + 1;
    final end = (start + pageSize - 1).clamp(1, totalItems);

    return Padding(
      padding: EdgeInsets.only(top: spacing.sm),
      child: Wrap(
        spacing: spacing.sm,
        runSpacing: spacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Showing $start–$end of $totalItems',
            style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(
            'Page ${pageIndex + 1} of $pageCount',
            style: typography.labelLarge.copyWith(color: colors.onSurfaceVariant),
          ),
          AppButton(
            label: 'Previous',
            variant: AppButtonVariant.secondary,
            onPressed: onPrevious,
          ),
          AppButton(
            label: 'Next',
            variant: AppButtonVariant.secondary,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
