import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';
import '../../core/network/windows_tls.dart';

/// ImageKit Media Library folders used by catalog uploads.
abstract final class ImageKitFolders {
  static const products = '/restaurix/products';
  static const categories = '/restaurix/categories';
  static const deals = '/restaurix/deals';
  static const pickupCompanies = '/restaurix/pickup_companies';
}

class ImageKitException implements Exception {
  ImageKitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Uploads local image files to ImageKit and returns the CDN URL.
///
/// Uses server-side Basic auth with [EnvConfig.imageKitPrivateKey]
/// (appropriate for a controlled Windows desktop install).
abstract final class ImageKitUploadService {
  static const _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

  static bool isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  static bool isLocalFilePath(String? value) {
    if (value == null || value.isEmpty || isRemoteUrl(value)) return false;
    return File(value).existsSync();
  }

  /// Uploads [localPath] into [folder] and returns the public ImageKit URL.
  static Future<String> uploadLocalFile({
    required String localPath,
    required String folder,
  }) async {
    if (!EnvConfig.isImageKitConfigured) {
      throw ImageKitException(
        'ImageKit is not configured. Add IMAGEKIT_PRIVATE_KEY and '
        'IMAGEKIT_URL_ENDPOINT to your .env file.',
      );
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw ImageKitException('Selected image file was not found.');
    }

    final privateKey = EnvConfig.imageKitPrivateKey;
    final auth = base64Encode(utf8.encode('$privateKey:'));
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_fileName(localPath)}';

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..headers['Authorization'] = 'Basic $auth'
      ..fields['fileName'] = fileName
      ..fields['folder'] = folder
      ..fields['useUniqueFileName'] = 'true'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          localPath,
          filename: fileName,
        ),
      );

    final client = WindowsTls.supabaseHttpClient ?? http.Client();
    final ownsClient = WindowsTls.supabaseHttpClient == null;

    try {
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'ImageKit upload failed (${response.statusCode}): ${response.body}',
        );
        throw ImageKitException(
          'Image upload failed (${response.statusCode}). '
          'Check ImageKit credentials and try again.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw ImageKitException('Unexpected ImageKit response.');
      }

      final url = body['url'] as String?;
      if (url == null || url.isEmpty) {
        throw ImageKitException('ImageKit did not return an image URL.');
      }
      return url;
    } finally {
      if (ownsClient) client.close();
    }
  }

  static String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash >= 0 ? normalized.substring(slash + 1) : normalized;
  }
}
