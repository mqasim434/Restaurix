import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

/// Third-party pickup company — extended in Module 13.
class PickupCompany implements SyncableEntity {
  const PickupCompany({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.isActive,
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
  final String? logoUrl;
  final bool isActive;

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

  PickupCompany copyWith({
    String? name,
    String? logoUrl,
    bool clearLogoUrl = false,
    bool? isActive,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return PickupCompany(
      id: id,
      name: name ?? this.name,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      isActive: isActive ?? this.isActive,
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
