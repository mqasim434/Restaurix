/// Kitchen-safe ticket line — no prices.
class KitchenTicketLine {
  const KitchenTicketLine({
    required this.name,
    this.variantName,
    required this.quantity,
    this.modifierNames = const [],
  });

  final String name;
  final String? variantName;
  final int quantity;
  final List<String> modifierNames;
}

/// Items grouped by kitchen category for one physical ticket.
class KitchenTicketCategoryGroup {
  const KitchenTicketCategoryGroup({
    required this.categoryLabel,
    required this.lines,
  });

  final String categoryLabel;
  final List<KitchenTicketLine> lines;
}

/// Payload for one ESC/POS kitchen ticket.
class KitchenTicketData {
  const KitchenTicketData({
    required this.orderNumber,
    required this.contextLabel,
    required this.placedAt,
    required this.categoryGroups,
    this.notes,
    this.isReprint = false,
  });

  final String orderNumber;
  final String contextLabel;
  final DateTime placedAt;
  final List<KitchenTicketCategoryGroup> categoryGroups;
  final String? notes;
  final bool isReprint;
}

/// One ticket destined for a specific printer target.
class KitchenTicketPrintJob {
  const KitchenTicketPrintJob({
    required this.printerTarget,
    required this.ticket,
  });

  final String printerTarget;
  final KitchenTicketData ticket;
}

/// Outcome of a kitchen print attempt — warnings are non-fatal.
class KitchenTicketPrintResult {
  const KitchenTicketPrintResult({
    this.ticketsPrinted = 0,
    this.warnings = const [],
  });

  final int ticketsPrinted;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get anyPrinted => ticketsPrinted > 0;
}
