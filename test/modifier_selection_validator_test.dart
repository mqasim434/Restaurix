import 'package:flutter_test/flutter_test.dart';

import 'package:restaurix/domain/models/item_modifier.dart';
import 'package:restaurix/domain/models/modifier_group.dart';
import 'package:restaurix/domain/models/modifier_selection_type.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/features/pos/services/modifier_selection_validator.dart';

ModifierGroup _group({
  required String id,
  required String name,
  bool isRequired = false,
  int minSelections = 0,
  int? maxSelections,
  ModifierSelectionType selectionType = ModifierSelectionType.multiple,
}) {
  final now = DateTime(2024, 1, 1);
  return ModifierGroup(
    id: id,
    name: name,
    selectionType: selectionType,
    isRequired: isRequired,
    minSelections: minSelections,
    maxSelections: maxSelections,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'test',
    version: 1,
  );
}

ItemModifier _modifier({
  required String id,
  required String groupId,
  required String name,
}) {
  final now = DateTime(2024, 1, 1);
  return ItemModifier(
    id: id,
    groupId: groupId,
    name: name,
    priceDelta: 0,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'test',
    version: 1,
  );
}

void main() {
  group('ModifierSelectionValidator', () {
    test('blocks required group with no selection', () {
      final group = _group(id: 'g1', name: 'Spice Level', isRequired: true);
      final modifiers = {
        'g1': [
          _modifier(id: 'm1', groupId: 'g1', name: 'Mild'),
        ],
      };

      final error = ModifierSelectionValidator.validate(
        groups: [group],
        modifiersByGroupId: modifiers,
        selectedModifierIdsByGroupId: const {},
      );

      expect(error, contains('Spice Level'));
    });

    test('passes when required group has a selection', () {
      final group = _group(id: 'g1', name: 'Spice Level', isRequired: true);
      final modifiers = {
        'g1': [
          _modifier(id: 'm1', groupId: 'g1', name: 'Mild'),
        ],
      };

      final error = ModifierSelectionValidator.validate(
        groups: [group],
        modifiersByGroupId: modifiers,
        selectedModifierIdsByGroupId: const {
          'g1': {'m1'},
        },
      );

      expect(error, isNull);
    });

    test('blocks exceeding max selections', () {
      final group = _group(
        id: 'g1',
        name: 'Extras',
        maxSelections: 1,
      );
      final modifiers = {
        'g1': [
          _modifier(id: 'm1', groupId: 'g1', name: 'Cheese'),
          _modifier(id: 'm2', groupId: 'g1', name: 'Bacon'),
        ],
      };

      final error = ModifierSelectionValidator.validate(
        groups: [group],
        modifiersByGroupId: modifiers,
        selectedModifierIdsByGroupId: const {
          'g1': {'m1', 'm2'},
        },
      );

      expect(error, contains('at most 1'));
    });
  });
}
