import 'package:intl/intl.dart';

import 'kitchen_ticket_data.dart';

/// Plain-text preview of a kitchen ticket — used in tests and debugging.
abstract final class KitchenTicketPreview {
  static List<String> renderLines(KitchenTicketData ticket) {
    final lines = <String>[];

    if (ticket.isReprint) {
      lines.add('*** REPRINT ***');
    }

    lines.add('KITCHEN TICKET');
    lines.add(ticket.orderNumber);
    lines.add(ticket.orderTypeLabel);
    lines.add(ticket.contextLabel);
    lines.add(DateFormat.yMMMd().add_jm().format(ticket.placedAt));

    if (ticket.notes != null) {
      lines.add('Notes: ${ticket.notes}');
    }

    for (final group in ticket.categoryGroups) {
      for (final line in group.lines) {
        final label = line.variantName == null || line.variantName!.isEmpty
            ? line.name
            : '${line.name} (${line.variantName})';
        lines.add('${line.quantity}x $label');
      }
    }

    return lines;
  }
}
