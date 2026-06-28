import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/order_held_badge.dart';
import '../../../domain/models/kitchen_board.dart';
import '../../../domain/models/order_enums.dart';
import '../../../domain/services/kitchen_prep_timer.dart';
import '../providers/kitchen_providers.dart';
import '../../printing/providers/kitchen_ticket_providers.dart';
import '../../printing/kitchen_ticket/kitchen_ticket_feedback.dart';

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() =>
      _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  late DateTime _now;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(kitchenAutoAdvanceProvider);
    final boardAsync = ref.watch(kitchenBoardProvider);
    final timeFormat = DateFormat.jm();

    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: VisualDensity.compact,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KitchenHeader(timeFormat: timeFormat, now: _now),
              Expanded(
                child: boardAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Unable to load kitchen board',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  data: (board) => Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _KitchenColumn(
                          title: 'Incoming',
                          accent: const Color(0xFF42A5F5),
                          cards: board.incoming,
                          now: _now,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xFF2A2A2A)),
                      Expanded(
                        child: _KitchenColumn(
                          title: 'Preparing',
                          accent: const Color(0xFFFFA726),
                          cards: board.preparing,
                          now: _now,
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Color(0xFF2A2A2A)),
                      Expanded(
                        child: _KitchenColumn(
                          title: 'Ready',
                          accent: const Color(0xFF66BB6A),
                          cards: board.ready,
                          now: _now,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenHeader extends StatelessWidget {
  const _KitchenHeader({required this.timeFormat, required this.now});

  final DateFormat timeFormat;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Kitchen Display',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Auto',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            timeFormat.format(now),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.title,
    required this.accent,
    required this.cards,
    required this.now,
  });

  final String title;
  final Color accent;
  final List<KitchenOrderCard> cards;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF161616),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.45)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _KitchenOrderCard(
                        card: cards[index],
                        now: now,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends ConsumerWidget {
  const _KitchenOrderCard({
    required this.card,
    required this.now,
  });

  final KitchenOrderCard card;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldBorder = card.isHeld ? const Color(0xFFFFB74D) : null;
    final timeLabel = DateFormat.Hm().format(card.createdAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.isHeld
            ? const Color(0xFF2A2418)
            : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: heldBorder ?? const Color(0xFF333333),
          width: card.isHeld ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.orderNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.contextLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reprint kitchen ticket',
                  onPressed: () => _reprint(context, ref),
                  icon: Icon(
                    Icons.print_outlined,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (card.isHeld) ...[
              const SizedBox(height: 10),
              const OrderHeldBadge(),
            ],
            if (card.notes != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.notes!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...card.items.map(
              (item) => _KitchenItemRow(item: item, now: now),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reprint(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(kitchenTicketPrintControllerProvider)
          .printOrder(orderId: card.orderId, isReprint: true);
      if (!context.mounted) return;
      showKitchenPrintFeedback(
        context,
        result,
        successMessage: 'Kitchen ticket reprinted',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kitchen reprint failed: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }
}

class _KitchenItemRow extends StatelessWidget {
  const _KitchenItemRow({
    required this.item,
    required this.now,
  });

  final KitchenDisplayItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final label = item.variantName == null || item.variantName!.isEmpty
        ? item.name
        : '${item.name} (${item.variantName})';

    final remaining = KitchenPrepTimer.remainingForDisplayItem(
      item: item,
      now: now,
    );
    final progress = KitchenPrepTimer.displayStageProgress(
      item: item,
      now: now,
    );
    final showTimer = item.kitchenStatus != KitchenStatus.ready;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.modifierNames.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.modifierNames.join(', '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (showTimer) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF333333),
                      color: const Color(0xFF66BB6A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    KitchenPrepTimer.formatRemaining(remaining),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
