import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/local/collections/debug_ping_isar.dart';
import '../../../data/local/device_id_service.dart';
import '../providers/debug_ping_providers.dart';

/// Temporary Isar CRUD demo — removed in Module 5.
class DebugIsarScreen extends ConsumerStatefulWidget {
  const DebugIsarScreen({super.key});

  @override
  ConsumerState<DebugIsarScreen> createState() => _DebugIsarScreenState();
}

class _DebugIsarScreenState extends ConsumerState<DebugIsarScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final pingsAsync = ref.watch(debugPingListProvider);
    final deviceId = ref.watch(deviceIdProvider);

    ref.listen(debugPingNotifierProvider, (previous, next) {
      if (next.hasError) {
        AppSnackbar.error(context, next.error.toString());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Isar Debug (temporary)',
          style: typography.titleLarge.copyWith(color: colors.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              title: 'Device ID',
              subtitle: deviceId,
              child: Text(
                'Stable per install — used for sync metadata on every write.',
                style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            SizedBox(height: spacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _messageController,
                    label: 'New ping message',
                    hint: 'Hello Isar',
                    onSubmitted: (_) => _createPing(),
                  ),
                ),
                SizedBox(width: spacing.md),
                AppButton(
                  label: 'Add',
                  onPressed: _createPing,
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            Text(
              'Records (soft-deleted hidden)',
              style: typography.titleMedium.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.sm),
            Expanded(
              child: pingsAsync.when(
                loading: () => const AppLoadingIndicator(message: 'Loading records...'),
                error: (error, _) => AppEmptyState(
                  title: 'Failed to load',
                  message: error.toString(),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return const AppEmptyState(
                      title: 'No pings yet',
                      message: 'Add a record above to test Isar persistence.',
                    );
                  }
                  return ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) => _PingTile(record: records[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPing() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    await ref.read(debugPingNotifierProvider.notifier).create(message);
    _messageController.clear();
  }
}

class _PingTile extends ConsumerWidget {
  const _PingTile({required this.record});

  final DebugPingIsar record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AppCard(
      title: record.message,
      subtitle: 'v${record.version} · synced: ${record.isSynced} · ${record.syncActionEnum.name}',
      actions: [
        AppButton(
          label: 'Edit',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          onPressed: () => _edit(context, ref),
        ),
        AppButton(
          label: 'Delete',
          variant: AppButtonVariant.danger,
          size: AppButtonSize.small,
          onPressed: () => ref.read(debugPingNotifierProvider.notifier).softDelete(record.uuid),
        ),
      ],
      child: Text(
        record.uuid,
        style: typography.labelSmall.copyWith(color: colors.onSurfaceVariant),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: record.message);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit ping'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      await ref.read(debugPingNotifierProvider.notifier).updateMessage(record.uuid, result);
    }
  }
}
