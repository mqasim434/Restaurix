import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';
import '../../core/constants.dart';
import '../../domain/services/delivery_address_formatter.dart';
import 'windows_device_location.dart';

/// Google Geocoding + Distance Matrix helpers for Live Orders / receipts.
class GoogleMapsService {
  GoogleMapsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  GeoPoint? _restaurantCache;
  DateTime? _restaurantCacheAt;

  static const _restaurantCacheTtl = Duration(minutes: 15);

  bool get isConfigured => EnvConfig.isGoogleMapsConfigured;

  /// Restaurant origin for distance:
  /// 1) this PC's current GPS location (preferred)
  /// 2) optional RESTAURANT_LAT/LNG in .env
  /// 3) geocode business address (last resort; needs API key)
  Future<GeoPoint?> restaurantOrigin({String? businessAddress}) async {
    final now = DateTime.now();
    if (_restaurantCache != null &&
        _restaurantCacheAt != null &&
        now.difference(_restaurantCacheAt!) < _restaurantCacheTtl) {
      return _restaurantCache;
    }

    final device = await _currentDeviceLocation();
    if (device != null) {
      _restaurantCache = device;
      _restaurantCacheAt = now;
      debugPrint(
        'Restaurant origin: device GPS '
        '(${device.latitude}, ${device.longitude})',
      );
      return device;
    }

    final envLat = EnvConfig.restaurantLatitude;
    final envLng = EnvConfig.restaurantLongitude;
    if (envLat != null && envLng != null) {
      final point = GeoPoint(latitude: envLat, longitude: envLng);
      _restaurantCache = point;
      _restaurantCacheAt = now;
      debugPrint('Restaurant origin: .env RESTAURANT_LAT/LNG');
      return point;
    }

    if (!isConfigured) return null;

    final address = (businessAddress?.trim().isNotEmpty == true)
        ? businessAddress!.trim()
        : AppConstants.defaultBusinessAddress;
    final geocoded = await geocodeAddress(address);
    if (geocoded != null) {
      _restaurantCache = geocoded;
      _restaurantCacheAt = now;
      debugPrint('Restaurant origin: geocoded business address');
    }
    return geocoded;
  }

  /// Reads this PC's location (geolocator plugin, then Windows native fallback).
  Future<GeoPoint?> _currentDeviceLocation() async {
    final fromPlugin = await _locationViaGeolocator();
    if (fromPlugin != null) return fromPlugin;

    if (Platform.isWindows) {
      final fromWindows = await WindowsDeviceLocation.current();
      if (fromWindows != null) {
        debugPrint('Restaurant origin: Windows Location API fallback');
        return fromWindows;
      }
    }
    return null;
  }

  Future<GeoPoint?> _locationViaGeolocator() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled on this PC');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied for Restaurix');
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return null;
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on MissingPluginException {
      // Old Windows exe built before geolocator was added — use native fallback.
      debugPrint(
        'geolocator plugin missing — rebuild the Windows app, '
        'or using Windows Location fallback',
      );
      return null;
    } catch (error) {
      debugPrint('geolocator failed: $error');
      return null;
    }
  }

  Future<GeoPoint?> geocodeAddress(String address) async {
    if (!isConfigured || address.trim().isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': address.trim(),
        'key': EnvConfig.googleMapsApiKey,
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        debugPrint('Geocode HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') {
        debugPrint('Geocode status ${json['status']}: ${json['error_message']}');
        return null;
      }
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final location =
          (results.first as Map<String, dynamic>)['geometry']?['location']
              as Map<String, dynamic>?;
      if (location == null) return null;
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return GeoPoint(latitude: lat, longitude: lng);
    } catch (error, stack) {
      debugPrint('Geocode failed: $error\n$stack');
      return null;
    }
  }

  /// Turns coordinates into street / area style lines for riders.
  Future<List<String>> reverseGeocodeLines(GeoPoint point) async {
    if (!isConfigured) return const [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': point.asQuery,
        'key': EnvConfig.googleMapsApiKey,
        'result_type': 'street_address|route|neighborhood|sublocality|premise',
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return const [];
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return const [];

      final first = results.first as Map<String, dynamic>;
      final formatted = (first['formatted_address'] as String?)?.trim();
      final components = first['address_components'] as List<dynamic>? ?? [];

      final streetNumber = _component(components, 'street_number');
      final route = _component(components, 'route');
      final neighborhood = _component(components, 'neighborhood') ??
          _component(components, 'sublocality') ??
          _component(components, 'sublocality_level_1');
      final premise = _component(components, 'premise');

      final lines = <String>[];
      final street = [
        if (premise != null) premise,
        if (streetNumber != null) streetNumber,
        if (route != null) route,
      ].join(' ').trim();
      if (street.isNotEmpty) lines.add(street);
      if (neighborhood != null && neighborhood.isNotEmpty) {
        lines.add(neighborhood);
      }
      if (lines.isEmpty && formatted != null && formatted.isNotEmpty) {
        lines.add(formatted);
      }
      return lines;
    } catch (error, stack) {
      debugPrint('Reverse geocode failed: $error\n$stack');
      return const [];
    }
  }

  /// Driving distance in kilometers (Distance Matrix, metric).
  Future<double?> drivingDistanceKm({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    if (!isConfigured) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/distancematrix/json',
      {
        'origins': origin.asQuery,
        'destinations': destination.asQuery,
        'units': 'metric',
        'mode': 'driving',
        'key': EnvConfig.googleMapsApiKey,
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        debugPrint('Distance Matrix HTTP ${response.statusCode}');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') {
        debugPrint(
          'Distance Matrix status ${json['status']}: ${json['error_message']}',
        );
        return null;
      }
      final rows = json['rows'] as List<dynamic>?;
      if (rows == null || rows.isEmpty) return null;
      final elements =
          (rows.first as Map<String, dynamic>)['elements'] as List<dynamic>?;
      if (elements == null || elements.isEmpty) return null;
      final element = elements.first as Map<String, dynamic>;
      if (element['status'] != 'OK') return null;
      final meters =
          (element['distance'] as Map<String, dynamic>?)?['value'] as num?;
      if (meters == null) return null;
      return meters.toDouble() / 1000.0;
    } catch (error, stack) {
      debugPrint('Distance Matrix failed: $error\n$stack');
      return null;
    }
  }

  static String? _component(List<dynamic> components, String type) {
    for (final raw in components) {
      if (raw is! Map<String, dynamic>) continue;
      final types = (raw['types'] as List<dynamic>?)?.cast<String>() ?? [];
      if (types.contains(type)) {
        return (raw['long_name'] as String?)?.trim();
      }
    }
    return null;
  }
}

/// Resolved map address for Live Orders / receipt display.
class DeliveryLocationInfo {
  const DeliveryLocationInfo({
    required this.lines,
    this.distanceKm,
    this.deliveryNotes,
    this.mapsNavigationUrl,
  });

  const DeliveryLocationInfo.empty()
      : lines = const [],
        distanceKm = null,
        deliveryNotes = null,
        mapsNavigationUrl = null;

  final List<String> lines;
  final double? distanceKm;
  final String? deliveryNotes;
  /// Short QR payload (lat,lng or Maps query) for the receipt scanner.
  final String? mapsNavigationUrl;

  bool get hasLocation => lines.isNotEmpty;

  String? get distanceLabel {
    if (distanceKm == null) return null;
    final km = distanceKm!;
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.toStringAsFixed(0)} km';
  }

  /// Short payload for thermal QR (fewer modules = larger dots).
  /// Phones open lat,lng in Maps; keep digits tight for scan reliability.
  static String mapsUrlForPoint(GeoPoint point) {
    final lat = point.latitude.toStringAsFixed(6);
    final lng = point.longitude.toStringAsFixed(6);
    return '$lat,$lng';
  }

  /// Fallback when only a text address exists (still keep the query short).
  static String mapsUrlForQuery(String query) =>
      'https://maps.google.com/?q=${Uri.encodeComponent(query)}';
}

/// Builds rider-friendly address lines + distance from restaurant.
class DeliveryLocationResolver {
  DeliveryLocationResolver(this._maps);

  final GoogleMapsService _maps;

  Future<DeliveryLocationInfo> resolve({
    required String? line1,
    required String? line2,
    required String? city,
    required String? postcode,
    required String? deliveryNotes,
    String? businessAddress,
  }) async {
    final rawParts = [line1, line2, city, postcode, deliveryNotes];
    final coords = DeliveryAddressFormatter.extractCoordinates(rawParts);

    var lines = DeliveryAddressFormatter.textualLines(
      line1: line1,
      line2: line2,
      city: city,
      postcode: postcode,
    );

    // Map-only picks often store just lat/lng — reverse geocode for street/area.
    if (lines.isEmpty && coords != null && _maps.isConfigured) {
      lines = await _maps.reverseGeocodeLines(coords);
    }

    String? noteOut;
    final notes = deliveryNotes?.trim();
    if (notes != null && notes.isNotEmpty) {
      final stripped = DeliveryAddressFormatter.textualLines(line1: notes);
      if (stripped.isNotEmpty) {
        noteOut = stripped.join(', ');
      } else if (DeliveryAddressFormatter.extractCoordinates([notes]) == null) {
        noteOut = notes;
      }
    }

    GeoPoint? destination = coords;
    if (destination == null && lines.isNotEmpty && _maps.isConfigured) {
      destination = await _maps.geocodeAddress(lines.join(', '));
    }

    double? distanceKm;
    if (_maps.isConfigured && destination != null) {
      final origin =
          await _maps.restaurantOrigin(businessAddress: businessAddress);
      if (origin != null) {
        distanceKm = await _maps.drivingDistanceKm(
          origin: origin,
          destination: destination,
        );
      }
    }

    final mapsUrl = destination != null
        ? DeliveryLocationInfo.mapsUrlForPoint(destination)
        : (lines.isNotEmpty
            ? DeliveryLocationInfo.mapsUrlForQuery(lines.join(', '))
            : null);

    return DeliveryLocationInfo(
      lines: lines,
      distanceKm: distanceKm,
      deliveryNotes: noteOut,
      mapsNavigationUrl: mapsUrl,
    );
  }
}
