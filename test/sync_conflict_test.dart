import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_conflict.dart';

void main() {
  group('SyncConflictResolver', () {
    test('local delete wins over remote edit', () {
      final winner = SyncConflictResolver.resolve(
        localIsDelete: true,
        localVersion: 1,
        localUpdatedAt: DateTime(2024, 1, 1),
        remoteVersion: 5,
        remoteUpdatedAt: DateTime(2024, 6, 1),
      );

      expect(winner, ConflictWinner.local);
    });

    test('higher version wins when both sides changed', () {
      final winner = SyncConflictResolver.resolve(
        localIsDelete: false,
        localVersion: 4,
        localUpdatedAt: DateTime(2024, 1, 1),
        remoteVersion: 3,
        remoteUpdatedAt: DateTime(2024, 6, 1),
      );

      expect(winner, ConflictWinner.local);
    });

    test('updatedAt breaks equal version ties', () {
      final winner = SyncConflictResolver.resolve(
        localIsDelete: false,
        localVersion: 2,
        localUpdatedAt: DateTime(2024, 6, 2),
        remoteVersion: 2,
        remoteUpdatedAt: DateTime(2024, 6, 1),
      );

      expect(winner, ConflictWinner.local);
    });
  });
}
