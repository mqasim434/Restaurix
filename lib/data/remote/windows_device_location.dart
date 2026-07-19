import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/services/delivery_address_formatter.dart';

/// Windows Location API via PowerShell (works even when the Flutter geolocator
/// plugin is missing from an older build).
abstract final class WindowsDeviceLocation {
  static Future<GeoPoint?> current() async {
    if (!Platform.isWindows) return null;

    const script = r'''
Add-Type -AssemblyName System.Device
$ErrorActionPreference = 'Stop'
$w = New-Object System.Device.Location.GeoCoordinateWatcher
$w.Start()
$deadline = [DateTime]::UtcNow.AddSeconds(12)
while ($w.Status -ne 'Ready' -and [DateTime]::UtcNow -lt $deadline) {
  Start-Sleep -Milliseconds 250
}
if ($w.Position.Location.IsUnknown) { exit 2 }
Write-Output ("{0}|{1}" -f $w.Position.Location.Latitude, $w.Position.Location.Longitude)
''';

    try {
      final result = await Process.run(
        'powershell',
        const ['-NoProfile', '-NonInteractive', '-Command', script],
        runInShell: false,
      );
      if (result.exitCode != 0) {
        debugPrint(
          'Windows location PowerShell exit ${result.exitCode}: '
          '${result.stderr}',
        );
        return null;
      }
      final line = result.stdout.toString().trim().split('\n').last.trim();
      final parts = line.split('|');
      if (parts.length != 2) return null;
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) return null;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
      return GeoPoint(latitude: lat, longitude: lng);
    } catch (error, stack) {
      debugPrint('Windows location PowerShell failed: $error\n$stack');
      return null;
    }
  }
}
