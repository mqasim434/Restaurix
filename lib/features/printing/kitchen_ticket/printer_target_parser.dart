/// Parses printer target strings configured on products or in settings.
abstract final class PrinterTargetParser {
  static final _networkPattern = RegExp(
    r'^(?:\d{1,3}\.){3}\d{1,3}(?::\d{1,5})?$',
  );

  static bool isNetworkTarget(String target) {
    return _networkPattern.hasMatch(target.trim());
  }

  static ({String host, int port}) parseNetwork(String target) {
    final trimmed = target.trim();
    final colonIndex = trimmed.lastIndexOf(':');
    if (colonIndex > 0 && colonIndex < trimmed.length - 1) {
      final host = trimmed.substring(0, colonIndex);
      final port = int.parse(trimmed.substring(colonIndex + 1));
      return (host: host, port: port);
    }
    return (host: trimmed, port: 9100);
  }
}
