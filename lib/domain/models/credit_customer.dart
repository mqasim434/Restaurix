import '../../core/sync/sync_action.dart';
import '../../core/sync/syncable_entity.dart';

class CreditCustomer implements SyncableEntity {
  const CreditCustomer({
    required this.id,
    required this.fullName,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.postcode,
    this.notes,
    required this.balance,
    this.creditLimit,
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
  final String fullName;
  final String? phone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? postcode;
  final String? notes;
  final double balance;
  final double? creditLimit;
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

  String get displayAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      postcode,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  bool get hasOutstandingBalance => balance > 0;

  CreditCustomer copyWith({
    String? fullName,
    String? phone,
    bool clearPhone = false,
    String? addressLine1,
    bool clearAddressLine1 = false,
    String? addressLine2,
    bool clearAddressLine2 = false,
    String? city,
    bool clearCity = false,
    String? postcode,
    bool clearPostcode = false,
    String? notes,
    bool clearNotes = false,
    double? balance,
    double? creditLimit,
    bool clearCreditLimit = false,
    bool? isActive,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
    SyncAction? syncAction,
    String? deviceId,
    int? version,
  }) {
    return CreditCustomer(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: clearPhone ? null : (phone ?? this.phone),
      addressLine1:
          clearAddressLine1 ? null : (addressLine1 ?? this.addressLine1),
      addressLine2:
          clearAddressLine2 ? null : (addressLine2 ?? this.addressLine2),
      city: clearCity ? null : (city ?? this.city),
      postcode: clearPostcode ? null : (postcode ?? this.postcode),
      notes: clearNotes ? null : (notes ?? this.notes),
      balance: balance ?? this.balance,
      creditLimit: clearCreditLimit ? null : (creditLimit ?? this.creditLimit),
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
