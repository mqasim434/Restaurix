import '../../../domain/models/item_modifier.dart';
import '../../../domain/models/modifier_group.dart';
import '../../../domain/models/modifier_selection_type.dart';

/// Validates modifier selections against group rules for POS add-to-cart.
abstract final class ModifierSelectionValidator {
  static String? validate({
    required List<ModifierGroup> groups,
    required Map<String, List<ItemModifier>> modifiersByGroupId,
    required Map<String, Set<String>> selectedModifierIdsByGroupId,
  }) {
    for (final group in groups) {
      final selectedIds = selectedModifierIdsByGroupId[group.id] ?? {};
      final count = selectedIds.length;
      final minRequired = _effectiveMinSelections(group);

      if (count < minRequired) {
        return minRequired <= 1
            ? 'Select an option for "${group.name}"'
            : 'Select at least $minRequired options for "${group.name}"';
      }

      if (group.maxSelections != null && count > group.maxSelections!) {
        return 'Select at most ${group.maxSelections} options for "${group.name}"';
      }

      if (group.selectionType == ModifierSelectionType.single && count > 1) {
        return 'Choose only one option for "${group.name}"';
      }

      final validIds = (modifiersByGroupId[group.id] ?? [])
          .map((modifier) => modifier.id)
          .toSet();
      if (!selectedIds.every(validIds.contains)) {
        return 'Invalid selection for "${group.name}"';
      }
    }

    return null;
  }

  static int _effectiveMinSelections(ModifierGroup group) {
    if (group.isRequired) {
      return group.minSelections > 0 ? group.minSelections : 1;
    }
    return group.minSelections;
  }
}
