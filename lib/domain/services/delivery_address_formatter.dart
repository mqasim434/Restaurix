/// Parses map-picked delivery addresses: extract coordinates for distance,
/// and keep only rider-friendly textual lines (street / area / house).
abstract final class DeliveryAddressFormatter {
  static final _coordPair = RegExp(
    r'(-?\d{1,2}\.\d{3,})\s*[,;\s]\s*(-?\d{1,3}\.\d{3,})',
  );

  static final _latLabel = RegExp(
    r'(?:^|\b)(?:lat|latitude)\s*[:=]\s*(-?\d+\.?\d*)',
    caseSensitive: false,
  );
  static final _lngLabel = RegExp(
    r'(?:^|\b)(?:lng|lon|longitude)\s*[:=]\s*(-?\d+\.?\d*)',
    caseSensitive: false,
  );

  /// Pulls coordinates from any of the raw address parts / notes.
  static GeoPoint? extractCoordinates(Iterable<String?> parts) {
    double? lat;
    double? lng;

    for (final part in parts) {
      final raw = part?.trim();
      if (raw == null || raw.isEmpty) continue;

      final pair = _coordPair.firstMatch(raw);
      if (pair != null) {
        final a = double.tryParse(pair.group(1)!);
        final b = double.tryParse(pair.group(2)!);
        if (a != null && b != null && _looksLikeLatLng(a, b)) {
          return GeoPoint(latitude: a, longitude: b);
        }
      }

      final latMatch = _latLabel.firstMatch(raw);
      final lngMatch = _lngLabel.firstMatch(raw);
      if (latMatch != null) lat ??= double.tryParse(latMatch.group(1)!);
      if (lngMatch != null) lng ??= double.tryParse(lngMatch.group(1)!);
    }

    if (lat != null && lng != null && _looksLikeLatLng(lat, lng)) {
      return GeoPoint(latitude: lat, longitude: lng);
    }
    return null;
  }

  /// Address lines for UI / receipt — coordinates removed.
  static List<String> textualLines({
    String? line1,
    String? line2,
    String? city,
    String? postcode,
    String? deliveryNotes,
  }) {
    final lines = <String>[];

    void addClean(String? value) {
      final cleaned = _stripCoordinates(value);
      if (cleaned == null || cleaned.isEmpty) return;
      if (lines.any((line) => line.toLowerCase() == cleaned.toLowerCase())) {
        return;
      }
      lines.add(cleaned);
    }

    addClean(line1);
    addClean(line2);

    final cityBits = <String>[
      if (_stripCoordinates(city)?.isNotEmpty == true) _stripCoordinates(city)!,
      if (_stripCoordinates(postcode)?.isNotEmpty == true)
        _stripCoordinates(postcode)!,
    ];
    if (cityBits.isNotEmpty) {
      addClean(cityBits.join(', '));
    }

    // Delivery notes often hold "Ring bell" — keep if not coords-only.
    final notes = _stripCoordinates(deliveryNotes);
    if (notes != null &&
        notes.isNotEmpty &&
        !_coordPair.hasMatch(notes) &&
        notes.length > 2) {
      // Only append notes separately in UI when useful; callers decide.
    }

    return lines;
  }

  static String? _stripCoordinates(String? value) {
    if (value == null) return null;
    var text = value.trim();
    if (text.isEmpty) return null;

    text = text.replaceAll(_coordPair, ' ');
    text = text.replaceAll(_latLabel, ' ');
    text = text.replaceAll(_lngLabel, ' ');
    text = text.replaceAll(RegExp(r'\(\s*\)'), ' ');
    text = text.replaceAll(RegExp(r'[\s,;|/-]{2,}'), ' ');
    text = text.replaceAll(RegExp(r'^[\s,;|/-]+|[\s,;|/-]+$'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Drop leftover pure-number crumbs.
    if (RegExp(r'^[\d.\s,+-]+$').hasMatch(text)) return null;
    return text.isEmpty ? null : text;
  }

  static bool _looksLikeLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get asQuery => '$latitude,$longitude';
}
