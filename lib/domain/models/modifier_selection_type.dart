enum ModifierSelectionType {
  single,
  multiple,
}

extension ModifierSelectionTypeX on ModifierSelectionType {
  String get label => switch (this) {
        ModifierSelectionType.single => 'Single choice',
        ModifierSelectionType.multiple => 'Multiple choice',
      };
}
