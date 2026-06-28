import 'dart:convert';

import 'sync_queue_models.dart';

/// POS policy: an explicit local delete wins over a concurrent remote edit.
enum ConflictWinner { local, remote }

/// Record of a resolved sync conflict — losing payload kept for admin review.
class SyncConflictLogEntry {
  const SyncConflictLogEntry({
    required this.entityType,
    required this.recordId,
    required this.winner,
    required this.localVersion,
    required this.remoteVersion,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
    required this.losingPayloadJson,
    required this.resolvedAt,
    this.reason,
  });

  final SyncEntityType entityType;
  final String recordId;
  final ConflictWinner winner;
  final int localVersion;
  final int remoteVersion;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;
  final String losingPayloadJson;
  final DateTime resolvedAt;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'entityType': entityType.name,
        'recordId': recordId,
        'winner': winner.name,
        'localVersion': localVersion,
        'remoteVersion': remoteVersion,
        'localUpdatedAt': localUpdatedAt.toUtc().toIso8601String(),
        'remoteUpdatedAt': remoteUpdatedAt.toUtc().toIso8601String(),
        'losingPayloadJson': losingPayloadJson,
        'resolvedAt': resolvedAt.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      };

  factory SyncConflictLogEntry.fromJson(Map<String, dynamic> json) {
    return SyncConflictLogEntry(
      entityType: SyncEntityType.values.byName(json['entityType'] as String),
      recordId: json['recordId'] as String,
      winner: ConflictWinner.values.byName(json['winner'] as String),
      localVersion: json['localVersion'] as int,
      remoteVersion: json['remoteVersion'] as int,
      localUpdatedAt: DateTime.parse(json['localUpdatedAt'] as String).toLocal(),
      remoteUpdatedAt:
          DateTime.parse(json['remoteUpdatedAt'] as String).toLocal(),
      losingPayloadJson: json['losingPayloadJson'] as String,
      resolvedAt: DateTime.parse(json['resolvedAt'] as String).toLocal(),
      reason: json['reason'] as String?,
    );
  }
}

abstract final class SyncConflictResolver {
  /// Documented POS rule: local soft-delete beats remote edits.
  static ConflictWinner resolve({
    required bool localIsDelete,
    required int localVersion,
    required DateTime localUpdatedAt,
    required int remoteVersion,
    required DateTime remoteUpdatedAt,
  }) {
    if (localIsDelete) return ConflictWinner.local;

    if (localVersion != remoteVersion) {
      return localVersion > remoteVersion
          ? ConflictWinner.local
          : ConflictWinner.remote;
    }

    return localUpdatedAt.isAfter(remoteUpdatedAt)
        ? ConflictWinner.local
        : ConflictWinner.remote;
  }
}

class SyncConflictLogger {
  SyncConflictLogger(this._entries, {this.maxEntries = 100});

  final List<SyncConflictLogEntry> _entries;
  final int maxEntries;

  List<SyncConflictLogEntry> get entries => List.unmodifiable(_entries);

  void log(SyncConflictLogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }

  static List<SyncConflictLogEntry> decodeStored(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>)
          SyncConflictLogEntry.fromJson(entry),
    ];
  }

  static String encodeStored(List<SyncConflictLogEntry> entries) {
    return jsonEncode(entries.map((entry) => entry.toJson()).toList());
  }
}
