import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/sync/sync_conflict.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_queue_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/sync_engine_providers.dart';
import '../providers/sync_queue_providers.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final syncState = ref.watch(syncUiStateProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final queueAsync = ref.watch(syncQueueSnapshotProvider);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bidirectional sync with Supabase. Local deletes win over remote '
            'edits; otherwise higher version, then latest timestamp.',
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.lg),
          _StatusCard(state: syncState, pendingCount: pendingCount),
          SizedBox(height: spacing.md),
          Row(
            children: [
              AppButton(
                label: syncState.runState == SyncRunState.syncing
                    ? 'Syncing...'
                    : 'Sync now',
                icon: Icons.sync_rounded,
                onPressed: syncState.runState == SyncRunState.syncing
                    ? null
                    : () => _syncNow(context, ref),
              ),
              SizedBox(width: spacing.md),
              AppButton(
                label: 'Refresh status',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  ref.read(syncUiStateProvider.notifier).refreshConnectivity();
                },
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Text('Recent conflicts', style: typography.titleSmall),
          SizedBox(height: spacing.sm),
          Expanded(
            child: syncState.conflictLog.isEmpty
                ? const AppEmptyState(
                    title: 'No conflicts logged',
                    message:
                        'When sync resolves competing offline edits, the losing copy is kept here for review.',
                  )
                : ListView.separated(
                    itemCount: syncState.conflictLog.length,
                    separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) {
                      return _ConflictCard(entry: syncState.conflictLog[index]);
                    },
                  ),
          ),
          SizedBox(height: spacing.md),
          Text('Pending by type', style: typography.titleSmall),
          SizedBox(height: spacing.sm),
          queueAsync.when(
            loading: () => const AppLoadingIndicator(message: 'Loading queue...'),
            error: (error, _) => Text(error.toString()),
            data: (snapshot) => Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final entry in snapshot.countsByType.entries)
                  Chip(
                    label: Text(
                      '${entry.key.label}: ${entry.value}',
                    ),
                  ),
                if (snapshot.countsByType.isEmpty)
                  Text(
                    'Nothing pending',
                    style: typography.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    await ref.read(syncUiStateProvider.notifier).syncNow();
    if (!context.mounted) return;

    final state = ref.read(syncUiStateProvider);
    AppSnackbar.show(
      context,
      message: state.runState == SyncRunState.error
          ? (state.lastError ?? 'Sync failed')
          : 'Sync complete — uploaded ${state.lastUploaded}, '
              'downloaded ${state.lastDownloaded}',
      type: state.runState == SyncRunState.error
          ? AppSnackbarType.error
          : AppSnackbarType.success,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.pendingCount,
  });

  final SyncUiState state;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final formatter = DateFormat.yMMMd().add_jm();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_labelForState(state.runState)}',
                style: typography.titleMedium),
            SizedBox(height: spacing.xs),
            Text(
              state.isOnline ? 'Network: online' : 'Network: offline',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              state.lastSuccessfulSyncAt == null
                  ? 'Last successful sync: never'
                  : 'Last successful sync: ${formatter.format(state.lastSuccessfulSyncAt!.toLocal())}',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Pending local changes: $pendingCount',
              style: typography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (state.lastError != null) ...[
              SizedBox(height: spacing.sm),
              Text(
                state.lastError!,
                style: typography.bodySmall.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _labelForState(SyncRunState runState) {
    return switch (runState) {
      SyncRunState.idle => 'Idle',
      SyncRunState.syncing => 'Syncing',
      SyncRunState.error => 'Error',
      SyncRunState.offline => 'Offline',
      SyncRunState.disabled => 'Disabled',
    };
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.entry});

  final SyncConflictLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final formatter = DateFormat.yMMMd().add_jm();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.entityType.label} • ${entry.recordId}',
              style: typography.labelLarge,
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Winner: ${entry.winner.name} • '
              'local v${entry.localVersion} vs remote v${entry.remoteVersion}',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (entry.reason != null) ...[
              SizedBox(height: spacing.xs),
              Text(
                entry.reason!,
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: spacing.xs),
            Text(
              formatter.format(entry.resolvedAt.toLocal()),
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
