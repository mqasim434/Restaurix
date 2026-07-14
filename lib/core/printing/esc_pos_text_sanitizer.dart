/// Normalizes text for thermal ESC/POS printers (ASCII-safe output).
abstract final class EscPosTextSanitizer {
  static String sanitize(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.runes) {
      final mapped = _map(codeUnit);
      if (mapped != null) {
        buffer.write(mapped);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _map(int codeUnit) {
    if (codeUnit >= 0x20 && codeUnit <= 0x7E) {
      return String.fromCharCode(codeUnit);
    }

    switch (codeUnit) {
      case 0x00A0: // no-break space
        return ' ';
      case 0x00B7: // middle dot
      case 0x2022: // bullet
        return '*';
      case 0x2013: // en dash
      case 0x2014: // em dash
      case 0x2212: // minus sign
        return '-';
      case 0x2018: // left single quote
      case 0x2019: // right single quote
      case 0x0060: // backtick
        return "'";
      case 0x201C: // left double quote
      case 0x201D: // right double quote
        return '"';
      case 0x20AC: // euro
        return 'EUR';
      case 0x00A3: // pound
        return 'GBP';
      case 0x20B9: // rupee
        return 'Rs.';
      default:
        return _latinExtendedToAscii(codeUnit);
    }
  }

  static String? _latinExtendedToAscii(int codeUnit) {
    const replacements = <int, String>{
      0x00C0: 'A',
      0x00C1: 'A',
      0x00C2: 'A',
      0x00C3: 'A',
      0x00C4: 'A',
      0x00C5: 'A',
      0x00C6: 'AE',
      0x00C7: 'C',
      0x00C8: 'E',
      0x00C9: 'E',
      0x00CA: 'E',
      0x00CB: 'E',
      0x00CC: 'I',
      0x00CD: 'I',
      0x00CE: 'I',
      0x00CF: 'I',
      0x00D0: 'D',
      0x00D1: 'N',
      0x00D2: 'O',
      0x00D3: 'O',
      0x00D4: 'O',
      0x00D5: 'O',
      0x00D6: 'O',
      0x00D8: 'O',
      0x00D9: 'U',
      0x00DA: 'U',
      0x00DB: 'U',
      0x00DC: 'U',
      0x00DD: 'Y',
      0x00DE: 'Th',
      0x00DF: 'ss',
      0x00E0: 'a',
      0x00E1: 'a',
      0x00E2: 'a',
      0x00E3: 'a',
      0x00E4: 'a',
      0x00E5: 'a',
      0x00E6: 'ae',
      0x00E7: 'c',
      0x00E8: 'e',
      0x00E9: 'e',
      0x00EA: 'e',
      0x00EB: 'e',
      0x00EC: 'i',
      0x00ED: 'i',
      0x00EE: 'i',
      0x00EF: 'i',
      0x00F0: 'd',
      0x00F1: 'n',
      0x00F2: 'o',
      0x00F3: 'o',
      0x00F4: 'o',
      0x00F5: 'o',
      0x00F6: 'o',
      0x00F8: 'o',
      0x00F9: 'u',
      0x00FA: 'u',
      0x00FB: 'u',
      0x00FC: 'u',
      0x00FD: 'y',
      0x00FE: 'th',
      0x00FF: 'y',
    };
    return replacements[codeUnit];
  }
}
