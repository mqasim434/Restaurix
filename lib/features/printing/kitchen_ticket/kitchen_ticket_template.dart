import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../core/printing/esc_pos_commands.dart';
import '../../../core/printing/esc_pos_text_sanitizer.dart';
import 'kitchen_ticket_data.dart';

/// Builds ESC/POS byte payloads for kitchen tickets (80 mm).
abstract final class KitchenTicketTemplate {
  static String _t(String value) => EscPosTextSanitizer.sanitize(value);

  static Future<Uint8List> buildBytes(KitchenTicketData ticket) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var bytes = <int>[]
      ..addAll(EscPosCommands.init(generator));

    if (ticket.isReprint) {
      bytes += EscPosCommands.centered(
        generator,
        '*** REPRINT ***',
        bold: true,
      );
    }

    bytes += EscPosCommands.centered(
      generator,
      'KITCHEN',
      bold: true,
      large: true,
      header: true,
    );
    bytes += EscPosCommands.divider(generator);
    bytes += EscPosCommands.centered(
      generator,
      '${_t(ticket.orderTypeLabel).toUpperCase()}  '
          '${_t(ticket.contextLabel).toUpperCase()}',
      bold: true,
    );
    bytes += EscPosCommands.centered(
      generator,
      _t(ticket.orderNumber),
      bold: true,
      large: true,
      header: true,
    );
    bytes += EscPosCommands.centered(generator, _timestamp(ticket.placedAt));
    bytes += EscPosCommands.divider(generator);

    if (ticket.notes != null && ticket.notes!.trim().isNotEmpty) {
      bytes += EscPosCommands.leftLine(generator, 'NOTES:', bold: true);
      bytes += EscPosCommands.leftLine(generator, _t(ticket.notes!.trim()));
      bytes += EscPosCommands.divider(generator);
    }

    for (final group in ticket.categoryGroups) {
      for (final line in group.lines) {
        final label = line.variantName == null || line.variantName!.isEmpty
            ? _t(line.name)
            : '${_t(line.name)} (${_t(line.variantName!)})';

        bytes += EscPosCommands.qtyItemRow(
          generator,
          '${line.quantity}x',
          label,
          largeQty: true,
        );
      }
    }

    bytes += generator.cut();
    return Uint8List.fromList(bytes);
  }

  static String _timestamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year}  $hour:$minute';
  }
}
