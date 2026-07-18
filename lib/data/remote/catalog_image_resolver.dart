import 'imagekit_upload_service.dart';

/// Resolves a form image field into the URL that should be stored locally
/// and synced to Supabase (`image_url` / `logo_url`).
///
/// Local file paths are uploaded to ImageKit first; existing remote URLs
/// are kept as-is.
abstract final class CatalogImageResolver {
  static Future<String?> resolveForSave({
    required String? imageUrl,
    required bool clearImage,
    required String folder,
  }) async {
    if (clearImage) return null;
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;

    final value = imageUrl.trim();
    if (ImageKitUploadService.isRemoteUrl(value)) return value;

    if (!ImageKitUploadService.isLocalFilePath(value)) {
      throw ImageKitException(
        'Selected image is not available on this device.',
      );
    }

    return ImageKitUploadService.uploadLocalFile(
      localPath: value,
      folder: folder,
    );
  }
}
