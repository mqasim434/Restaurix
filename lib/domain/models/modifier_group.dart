import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';
import 'modifier_selection_type.dart';

class ModifierGroup implements SyncableEntity {
  const ModifierGroup({
    required this.id,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minSelections,
    this.maxSelections,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.deletedAt,
    required this.syncAction,
    required this.deviceId,
    required this.version,
  });

  @override
  final String id;
  final String name;
  final ModifierSelectionType selectionType;
  final bool isRequired;
  final int minSelections;
  final int? maxSelections;

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final bool isSynced;
  @override
  final DateTime? deletedAt;
  @override
  final SyncAction syncAction;
  @override
  final String deviceId;
  @override
  final int version;

  ModifierGroup copyWith({
    String? name,
    ModifierSelectionType? selectionType,
    bool? isRequired,
    int? minSelections,
    int? maxSelections,
    bool clearMaxSelections = false,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return ModifierGroup(
      id: id,
      name: name ?? this.name,
      selectionType: selectionType ?? this.selectionType,
      isRequired: isRequired ?? this.isRequired,
      minSelections: minSelections ?? this.minSelections,
      maxSelections:
          clearMaxSelections ? null : (maxSelections ?? this.maxSelections),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
      syncAction: syncAction ?? this.syncAction,
      deviceId: deviceId ?? this.deviceId,
      version: version ?? this.version,
    );
  }
}
