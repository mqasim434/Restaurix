import 'package:flutter/material.dart';

import '../branding/app_brand.dart';

/// Reusable restaurant logo for login, sidebar, and other branded surfaces.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 72,
    this.width,
    this.fit = BoxFit.contain,
  });

  final double height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppBrand.logoAsset,
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(
        Icons.restaurant_menu_rounded,
        size: height,
      ),
    );
  }
}
