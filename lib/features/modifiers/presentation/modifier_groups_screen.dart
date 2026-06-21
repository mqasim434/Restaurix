import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/item_modifier.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/modifier_selection_type.dart';
import '../providers/modifier_providers.dart';
import 'modifier_form_dialog.dart';
import 'modifier_group_form_dialog.dart';
import 'modifier_price_format.dart';

class ModifierGroupsScreen extends ConsumerStatefulWidget {
  const ModifierGroupsScreen({super.key});

  @override
  ConsumerState<ModifierGroupsScreen> createState() =>
      _ModifierGroupsScreenState();
}

class _ModifierGroupsScreenState extends ConsumerState<ModifierGroupsScreen> {
  String? _selectedGroupId;
  List<ItemModifier>? _localModifierOrder;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final groupsAsync = ref.watch(modifierGroupListProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppButton(
                label: 'Back to Products',
                variant: AppButtonVariant.ghost,
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/products'),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Text(
                  'Reusable modifier groups attach to one or many products',
                  style: typography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              AppButton(
                label: 'Add Group',
                icon: AppIcons.add,
                onPressed: () => _openGroupForm(context),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Expanded(
            child: groupsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading modifier groups...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load modifier groups',
                message: error.toString(),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return AppEmptyState(
                    title: 'No modifier groups yet',
                    message:
                        'Create groups like "Extras" or "Spice Level" and reuse them across products.',
                    actionLabel: 'Add Group',
                    onAction: () => _openGroupForm(context),
                  );
                }

                final selectedId = _selectedGroupId ?? groups.first.id;
                if (_selectedGroupId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedGroupId = groups.first.id);
                  });
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _GroupListPanel(
                        groups: groups,
                        selectedGroupId: selectedId,
                        onSelect: (id) => setState(() {
                          _selectedGroupId = id;
                          _localModifierOrder = null;
                        }),
                        onEdit: (group) => _openGroupForm(context, group: group),
                        onDelete: (group) => _confirmDeleteGroup(context, group),
                      ),
                    ),
                    SizedBox(width: spacing.lg),
                    Expanded(
                      flex: 3,
                      child: _ModifiersPanel(
                        groupId: selectedId,
                        groupName: groups
                            .firstWhere((g) => g.id == selectedId)
                            .name,
                        localOrder: _localModifierOrder,
                        onLocalOrderChanged: (order) =>
                            setState(() => _localModifierOrder = order),
                        onClearLocalOrder: () =>
                            setState(() => _localModifierOrder = null),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGroupForm(
    BuildContext context, {
    ModifierGroup? group,
  }) async {
    final result = await ModifierGroupFormDialog.show(
      context,
      group: group,
      title: group == null ? 'Add Modifier Group' : 'Edit Modifier Group',
    );
    if (result == null || !context.mounted) return;

    final actions = ref.read(modifierGroupActionsProvider);

    if (group == null) {
      final created = await actions.createGroup(
        name: result.name,
        selectionType: result.selectionType,
        isRequired: result.isRequired,
        minSelections: result.minSelections,
        maxSelections: result.maxSelections,
      );
      if (mounted) setState(() => _selectedGroupId = created.id);
    } else {
      await actions.updateGroup(
        group.copyWith(
          name: result.name,
          selectionType: result.selectionType,
          isRequired: result.isRequired,
          minSelections: result.minSelections,
          maxSelections: result.maxSelections,
          clearMaxSelections: result.clearMaxSelections,
        ),
      );
    }
  }

  Future<void> _confirmDeleteGroup(
    BuildContext context,
    ModifierGroup group,
  ) async {
    final actions = ref.read(modifierGroupActionsProvider);
    final products = await actions.findProductsUsingGroup(group.id);
    if (!context.mounted) return;

    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    final content = products.isEmpty
        ? Text(
            'Delete "${group.name}"? Modifiers in this group will also be removed.',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${group.name}" is attached to ${products.length} product(s):',
                style: typography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.sm),
              ...products.take(5).map(
                    (p) => Text(
                      '• ${p.name}',
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              if (products.length > 5)
                Text(
                  '…and ${products.length - 5} more',
                  style: typography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              SizedBox(height: spacing.sm),
              Text(
                'Deleting will detach this group from those products.',
                style: typography.bodySmall.copyWith(
                  color: colors.warning,
                ),
              ),
            ],
          );

    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete modifier group?',
      content: content,
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await actions.deleteGroup(group.id);
    if (!context.mounted) return;

    if (!deleted) {
      AppSnackbar.error(context, 'Could not delete modifier group');
      return;
    }

    if (_selectedGroupId == group.id) {
      setState(() => _selectedGroupId = null);
    }
  }
}

class _GroupListPanel extends StatelessWidget {
  const _GroupListPanel({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ModifierGroup> groups;
  final String selectedGroupId;
  final ValueChanged<String> onSelect;
  final void Function(ModifierGroup group) onEdit;
  final void Function(ModifierGroup group) onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Text(
              'Groups',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.divider),
              itemBuilder: (context, index) {
                final group = groups[index];
                final selected = group.id == selectedGroupId;

                return Material(
                  color: selected ? colors.primaryContainer : colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(group.id),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.md,
                        vertical: spacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: typography.bodyMedium.copyWith(
                                    color: selected
                                        ? colors.onPrimaryContainer
                                        : colors.onSurface,
                                  ),
                                ),
                                Text(
                                  _groupSubtitle(group),
                                  style: typography.bodySmall.copyWith(
                                    color: selected
                                        ? colors.onPrimaryContainer
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: Icon(
                              AppIcons.edit,
                              color: selected
                                  ? colors.onPrimaryContainer
                                  : colors.onSurfaceVariant,
                            ),
                            onPressed: () => onEdit(group),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(
                              AppIcons.delete,
                              color: colors.error,
                            ),
                            onPressed: () => onDelete(group),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _groupSubtitle(ModifierGroup group) {
    final parts = <String>[
      group.selectionType.label,
      if (group.isRequired) 'Required',
      if (group.minSelections > 0) 'Min ${group.minSelections}',
      if (group.maxSelections != null) 'Max ${group.maxSelections}',
    ];
    return parts.join(' · ');
  }
}

class _ModifiersPanel extends ConsumerWidget {
  const _ModifiersPanel({
    required this.groupId,
    required this.groupName,
    required this.localOrder,
    required this.onLocalOrderChanged,
    required this.onClearLocalOrder,
  });

  final String groupId;
  final String groupName;
  final List<ItemModifier>? localOrder;
  final ValueChanged<List<ItemModifier>> onLocalOrderChanged;
  final VoidCallback onClearLocalOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final modifiersAsync = ref.watch(groupModifiersProvider(groupId));
    final actions = ref.read(modifierGroupActionsProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Modifiers in "$groupName"',
                    style: typography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Add Modifier',
                  icon: AppIcons.add,
                  size: AppButtonSize.small,
                  onPressed: () => _addModifier(context, actions),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: modifiersAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading modifiers...',
              ),
              error: (error, _) => AppEmptyState(
                title: 'Failed to load modifiers',
                message: error.toString(),
              ),
              data: (modifiers) {
                final displayModifiers = localOrder ?? modifiers;

                if (displayModifiers.isEmpty) {
                  return AppEmptyState(
                    title: 'No modifiers in this group',
                    message: 'Add options like "Extra Cheese" or "No Onion".',
                    actionLabel: 'Add Modifier',
                    onAction: () => _addModifier(context, actions),
                  );
                }

                return ReorderableListView.builder(
                  padding: EdgeInsets.symmetric(vertical: spacing.sm),
                  buildDefaultDragHandles: false,
                  itemCount: displayModifiers.length,
                  onReorder: (oldIndex, newIndex) async {
                    final items = List<ItemModifier>.of(displayModifiers);
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    onLocalOrderChanged(items);
                    await actions.reorderModifiers(
                      groupId: groupId,
                      idsInOrder: items.map((m) => m.id).toList(),
                    );
                    onClearLocalOrder();
                  },
                  itemBuilder: (context, index) {
                    final modifier = displayModifiers[index];
                    return _ModifierRow(
                      key: ValueKey(modifier.id),
                      modifier: modifier,
                      index: index,
                      onEdit: () => _editModifier(context, actions, modifier),
                      onDelete: () =>
                          _deleteModifier(context, actions, modifier),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addModifier(
    BuildContext context,
    ModifierGroupActions actions,
  ) async {
    final result = await ModifierFormDialog.show(context);
    if (result == null || !context.mounted) return;

    await actions.createModifier(
      groupId: groupId,
      name: result.name,
      priceDelta: result.priceDelta,
    );
  }

  Future<void> _editModifier(
    BuildContext context,
    ModifierGroupActions actions,
    ItemModifier modifier,
  ) async {
    final result = await ModifierFormDialog.show(
      context,
      title: 'Edit Modifier',
      initialName: modifier.name,
      initialPriceDelta: modifier.priceDelta,
    );
    if (result == null || !context.mounted) return;

    await actions.updateModifier(
      modifier.copyWith(name: result.name, priceDelta: result.priceDelta),
    );
  }

  Future<void> _deleteModifier(
    BuildContext context,
    ModifierGroupActions actions,
    ItemModifier modifier,
  ) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Remove modifier?',
      content: Text(
        'Remove "${modifier.name}" from this group?',
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
      ),
      confirmLabel: 'Remove',
      isDanger: true,
    );

    if (confirmed != true || !context.mounted) return;

    final deleted = await actions.deleteModifier(modifier.id);
    if (!deleted && context.mounted) {
      AppSnackbar.error(context, 'Could not remove modifier');
    }
  }
}

class _ModifierRow extends StatelessWidget {
  const _ModifierRow({
    super.key,
    required this.modifier,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final ItemModifier modifier;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return Material(
      key: key,
      color: colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.xs,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded, color: colors.onSurfaceVariant),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                modifier.name,
                style: typography.bodyMedium.copyWith(color: colors.onSurface),
              ),
            ),
            Text(
              formatModifierPriceDelta(modifier.priceDelta),
              style: typography.bodyMedium.copyWith(
                color: modifier.priceDelta < 0
                    ? colors.error
                    : modifier.priceDelta > 0
                        ? colors.success
                        : colors.onSurfaceVariant,
              ),
            ),
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
      ),
    );
  }
}
