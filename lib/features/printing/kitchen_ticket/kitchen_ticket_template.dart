import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'kitchen_ticket_data.dart';

/// Builds ESC/POS byte payloads for kitchen tickets.
///
/// Uses [esc_pos_utils_plus] (maintained fork of esc_pos_utils) for command
/// generation. Transport is handled separately — see [EscPosTransportRouter].
abstract final class KitchenTicketTemplate {
  static Future<Uint8List> buildBytes(KitchenTicketData ticket) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var bytes = <int>[];

    if (ticket.isReprint) {
      bytes += generator.text(
        '*** REPRINT ***',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1,
      );
    }

    bytes += generator.text(
      'KITCHEN TICKET',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      ticket.orderNumber,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      linesAfter: 1,
    );
    bytes += generator.text(
      ticket.contextLabel,
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      _timestamp(ticket.placedAt),
      linesAfter: 1,
    );

    if (ticket.notes != null) {
      bytes += generator.text('Notes: ${ticket.notes}');
      bytes += generator.feed(1);
    }

    for (final group in ticket.categoryGroups) {
      bytes += generator.hr();
      bytes += generator.text(
        group.categoryLabel.toUpperCase(),
        styles: const PosStyles(bold: true, underline: true),
        linesAfter: 1,
      );

      for (final line in group.lines) {
        final label = line.variantName == null || line.variantName!.isEmpty
            ? line.name
            : '${line.name} (${line.variantName})';

        bytes += generator.row([
          PosColumn(
            text: '${line.quantity}x',
            width: 2,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(text: label, width: 10),
        ]);

        if (line.modifierNames.isNotEmpty) {
          bytes += generator.text(
            '  + ${line.modifierNames.join(', ')}',
          );
        }
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return Uint8List.fromList(bytes);
  }

  static String _timestamp(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
