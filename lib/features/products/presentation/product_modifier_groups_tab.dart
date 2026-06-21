import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/modifier_selection_type.dart';
import '../../modifiers/providers/modifier_providers.dart';

class ProductModifierGroupsTab extends ConsumerStatefulWidget {
  const ProductModifierGroupsTab({
    super.key,
    required this.productId,
    required this.assignedGroupIds,
  });

  final String productId;
  final List<String> assignedGroupIds;

  @override
  ConsumerState<ProductModifierGroupsTab> createState() =>
      _ProductModifierGroupsTabState();
}

class _ProductModifierGroupsTabState
    extends ConsumerState<ProductModifierGroupsTab> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.assignedGroupIds.toSet();
  }

  @override
  void didUpdateWidget(covariant ProductModifierGroupsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assignedGroupIds != widget.assignedGroupIds) {
      _selectedIds = widget.assignedGroupIds.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final groupsAsync = ref.watch(modifierGroupListProvider);

    return groupsAsync.when(
      loading: () =>
          const AppLoadingIndicator(message: 'Loading modifier groups...'),
      error: (error, _) => AppEmptyState(
        title: 'Failed to load modifier groups',
        message: error.toString(),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return AppEmptyState(
            title: 'No modifier groups yet',
            message:
                'Create reusable groups first, then attach them to this product.',
            actionLabel: 'Manage Modifier Groups',
            onAction: () => context.go('/modifier-groups'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select which modifier groups apply to this product. '
                    'Changes save immediately.',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Manage Groups',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  onPressed: () => context.go('/modifier-groups'),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            Expanded(
              child: ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: colors.divider),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final selected = _selectedIds.contains(group.id);

                  return CheckboxListTile(
                    value: selected,
                    onChanged: (value) => _toggleGroup(group.id, value ?? false),
                    title: Text(
                      group.name,
                      style: typography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _groupDescription(group),
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(horizontal: spacing.sm),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _groupDescription(ModifierGroup group) {
    final parts = <String>[
      group.selectionType.label,
      if (group.isRequired) 'Required at POS',
      if (group.minSelections > 0) 'Min ${group.minSelections}',
      if (group.maxSelections != null) 'Max ${group.maxSelections}',
    ];
    return parts.join(' · ');
  }

  Future<void> _toggleGroup(String groupId, bool selected) async {
    final previous = Set<String>.of(_selectedIds);
    setState(() {
      if (selected) {
        _selectedIds.add(groupId);
      } else {
        _selectedIds.remove(groupId);
      }
    });

    final assignment = ref.read(productModifierAssignmentProvider);
    final updated = await assignment.assignGroups(
      productId: widget.productId,
      groupIds: _selectedIds.toList(),
    );

    if (!mounted) return;
    if (updated == null) {
      setState(() => _selectedIds = previous);
      AppSnackbar.error(context, 'Could not update modifier groups');
    }
  }
}
