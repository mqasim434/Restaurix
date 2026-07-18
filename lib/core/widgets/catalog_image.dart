import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../data/remote/imagekit_upload_service.dart';

/// Renders a catalog image from an ImageKit/HTTPS URL or a local file path.
class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? context.appRadius.mdBorder;
    final child = _buildImage(context);
    final box = width.isFinite && height.isFinite
        ? SizedBox(width: width, height: height, child: child)
        : SizedBox.expand(child: child);

    return ClipRRect(borderRadius: radius, child: box);
  }

  double? get _finiteWidth => width.isFinite ? width : null;
  double? get _finiteHeight => height.isFinite ? height : null;

  Widget _buildImage(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return _placeholder(context);
    }

    if (ImageKitUploadService.isRemoteUrl(value)) {
      return Image.network(
        value,
        width: _finiteWidth,
        height: _finiteHeight,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(context, showSpinner: true);
        },
      );
    }

    final file = File(value);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: _finiteWidth,
        height: _finiteHeight,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context, {bool showSpinner = false}) {
    final colors = context.appColors;

    return Container(
      width: _finiteWidth,
      height: _finiteHeight,
      color: colors.surfaceVariant,
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onSurfaceVariant,
              ),
            )
          : Icon(placeholderIcon, color: colors.onSurfaceVariant),
    );
  }
}
