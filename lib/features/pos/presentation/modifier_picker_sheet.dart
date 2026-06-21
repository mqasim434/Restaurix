import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/item_modifier.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/modifier_selection_type.dart';
import '../../modifiers/presentation/modifier_price_format.dart';
import '../services/modifier_selection_validator.dart';

class ModifierPickerSheet extends StatefulWidget {
  const ModifierPickerSheet({
    super.key,
    required this.productName,
    required this.groups,
    required this.modifiersByGroupId,
  });

  final String productName;
  final List<ModifierGroup> groups;
  final Map<String, List<ItemModifier>> modifiersByGroupId;

  static Future<List<CartModifier>?> show(
    BuildContext context, {
    required String productName,
    required List<ModifierGroup> groups,
    required Map<String, List<ItemModifier>> modifiersByGroupId,
  }) {
    return showModalBottomSheet<List<CartModifier>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ModifierPickerSheet(
        productName: productName,
        groups: groups,
        modifiersByGroupId: modifiersByGroupId,
      ),
    );
  }

  @override
  State<ModifierPickerSheet> createState() => _ModifierPickerSheetState();
}

class _ModifierPickerSheetState extends State<ModifierPickerSheet> {
  final Map<String, Set<String>> _selectedByGroupId = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Customize',
                style: typography.titleMedium.copyWith(color: colors.onSurface),
              ),
              Text(
                widget.productName,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.md),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final group in widget.groups)
                      _ModifierGroupSection(
                        group: group,
                        modifiers: widget.modifiersByGroupId[group.id] ?? const [],
                        selectedIds: _selectedByGroupId[group.id] ?? {},
                        onToggle: (modifierId, selected) {
                          setState(() {
                            final selectedIds =
                                _selectedByGroupId.putIfAbsent(group.id, () => {});
                            if (group.selectionType == ModifierSelectionType.single) {
                              selectedIds
                                ..clear()
                                ..add(modifierId);
                            } else if (selected) {
                              if (group.maxSelections != null &&
                                  selectedIds.length >= group.maxSelections!) {
                                return;
                              }
                              selectedIds.add(modifierId);
                            } else {
                              selectedIds.remove(modifierId);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              AppButton(
                label: 'Add to cart',
                expand: true,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    final error = ModifierSelectionValidator.validate(
      groups: widget.groups,
      modifiersByGroupId: widget.modifiersByGroupId,
      selectedModifierIdsByGroupId: _selectedByGroupId,
    );

    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    final cartModifiers = <CartModifier>[];
    for (final group in widget.groups) {
      final selectedIds = _selectedByGroupId[group.id] ?? {};
      final modifiers = widget.modifiersByGroupId[group.id] ?? const [];
      for (final modifier in modifiers) {
        if (selectedIds.contains(modifier.id)) {
          cartModifiers.add(
            CartModifier(
              id: modifier.id,
              groupId: group.id,
              name: modifier.name,
              priceDelta: modifier.priceDelta,
            ),
          );
        }
      }
    }

    Navigator.of(context).pop(cartModifiers);
  }
}

class _ModifierGroupSection extends StatelessWidget {
  const _ModifierGroupSection({
    required this.group,
    required this.modifiers,
    required this.selectedIds,
    required this.onToggle,
  });

  final ModifierGroup group;
  final List<ItemModifier> modifiers;
  final Set<String> selectedIds;
  final void Function(String modifierId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    final subtitle = [
      group.selectionType.label,
      if (group.isRequired) 'Required',
      if (group.minSelections > 0) 'Min ${group.minSelections}',
      if (group.maxSelections != null) 'Max ${group.maxSelections}',
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
          Text(
            subtitle,
            style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: spacing.sm),
          if (modifiers.isEmpty)
            Text(
              'No modifiers configured',
              style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
            )
          else if (group.selectionType == ModifierSelectionType.single)
            ...modifiers.map((modifier) {
              return RadioListTile<String>(
                value: modifier.id,
                groupValue: selectedIds.isEmpty ? null : selectedIds.first,
                onChanged: (_) => onToggle(modifier.id, true),
                title: Text(modifier.name),
                subtitle: Text(formatModifierPriceDelta(modifier.priceDelta)),
                contentPadding: EdgeInsets.zero,
              );
            })
          else
            ...modifiers.map((modifier) {
              return CheckboxListTile(
                value: selectedIds.contains(modifier.id),
                onChanged: (value) => onToggle(modifier.id, value ?? false),
                title: Text(modifier.name),
                subtitle: Text(formatModifierPriceDelta(modifier.priceDelta)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
        ],
      ),
    );
  }
}
