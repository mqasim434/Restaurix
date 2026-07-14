import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'esc_pos_print_config.dart';

/// Shared ESC/POS helpers for 80 mm thermal printers.
abstract final class EscPosCommands {
  static PosStyles _body({bool bold = false}) => PosStyles(
        fontType: EscPosPrintConfig.bodyFont,
        bold: bold,
      );

  static PosStyles _header({bool bold = true, bool large = false}) => PosStyles(
        fontType: EscPosPrintConfig.headerFont,
        bold: bold,
        height: large ? PosTextSize.size2 : PosTextSize.size1,
        width: PosTextSize.size1,
      );

  static List<int> init(Generator generator) {
    return [
      ...generator.reset(),
      ...generator.setGlobalFont(EscPosPrintConfig.bodyFont),
    ];
  }

  static List<int> useBodyFont(Generator generator) {
    return generator.setGlobalFont(EscPosPrintConfig.bodyFont);
  }

  static List<int> divider(Generator generator) {
    return [
      ...useBodyFont(generator),
      ...generator.hr(),
    ];
  }

  static List<int> centered(
    Generator generator,
    String text, {
    bool bold = false,
    bool large = false,
    bool header = false,
  }) {
    final bytes = generator.text(
      text,
      styles: PosStyles(
        fontType: header ? EscPosPrintConfig.headerFont : EscPosPrintConfig.bodyFont,
        align: PosAlign.center,
        bold: bold,
        height: large ? PosTextSize.size2 : PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
    return [...bytes, ...useBodyFont(generator)];
  }

  static List<int> leftLine(Generator generator, String text, {bool bold = false}) {
    return generator.text(text, styles: _body(bold: bold));
  }

  static List<int> fieldRow(
    Generator generator,
    String label,
    String value, {
    bool bold = false,
  }) {
    return generator.row([
      PosColumn(text: label, width: 5, styles: _body(bold: bold)),
      PosColumn(
        text: value,
        width: 7,
        styles: _body(bold: bold).copyWith(align: PosAlign.right),
      ),
    ]);
  }

  static List<int> priceRow(
    Generator generator,
    String description,
    String price, {
    bool bold = true,
  }) {
    return generator.row([
      PosColumn(text: description, width: 8, styles: _body(bold: bold)),
      PosColumn(
        text: price,
        width: 4,
        styles: _body(bold: bold).copyWith(align: PosAlign.right),
      ),
    ]);
  }

  static List<int> qtyItemRow(
    Generator generator,
    String qty,
    String name, {
    bool bold = true,
    bool largeQty = false,
  }) {
    final qtyStyle = largeQty
        ? _header(bold: bold, large: true)
        : _body(bold: bold);

    final bytes = generator.row([
      PosColumn(text: qty, width: 3, styles: qtyStyle),
      PosColumn(text: name, width: 9, styles: _body(bold: bold)),
    ]);
    return [...bytes, ...useBodyFont(generator)];
  }

  static List<int> detailLine(Generator generator, String text) {
    return leftLine(generator, text);
  }
}
