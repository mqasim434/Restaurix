import 'package:flutter/material.dart';

import '../widgets/app_snackbar.dart';
import '../../data/remote/catalog_image_resolver.dart';
import '../../data/remote/imagekit_upload_service.dart';

/// Uploads a newly picked local image to ImageKit (with UI feedback) and
/// returns the URL to store in Isar / sync to Supabase.
///
/// Returns `null` when the image was cleared or never set.
/// Throws [ImageKitException] after showing an error snackbar.
Future<String?> prepareCatalogImageUrl({
  required BuildContext context,
  required String? imageUrl,
  required bool clearImage,
  required String folder,
}) async {
  final needsUpload =
      !clearImage && ImageKitUploadService.isLocalFilePath(imageUrl);
  if (needsUpload && context.mounted) {
    AppSnackbar.info(context, 'Uploading image...');
  }

  try {
    return await CatalogImageResolver.resolveForSave(
      imageUrl: imageUrl,
      clearImage: clearImage,
      folder: folder,
    );
  } on ImageKitException catch (error) {
    if (context.mounted) {
      AppSnackbar.error(context, error.message);
    }
    rethrow;
  }
}
