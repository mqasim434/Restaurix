/// Helpers for mapping Isar records to Supabase row JSON (snake_case keys).
abstract final class SyncRemoteCodec {
  static Map<String, dynamic> standardFields({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isSynced,
    required DateTime? deletedAt,
    required String syncAction,
    required String deviceId,
    required int version,
  }) {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_synced': isSynced,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_action': syncAction,
      'device_id': deviceId,
      'version': version,
    };
  }

  static DateTime parseDateTime(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.parse(value).toLocal();
    throw FormatException('Invalid date value: $value');
  }

  static DateTime? parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    return parseDateTime(value);
  }

  static DateTime parseDateOnly(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String) {
      final parsed = DateTime.parse(value);
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    throw FormatException('Invalid date value: $value');
  }

  static String formatDateOnly(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0;
  }

  static double? parseNullableDouble(dynamic value) {
    if (value == null) return null;
    return parseDouble(value);
  }

  static int parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  static List<Map<String, dynamic>> decodeJsonList(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is Map) Map<String, dynamic>.from(entry),
    ];
  }
}
