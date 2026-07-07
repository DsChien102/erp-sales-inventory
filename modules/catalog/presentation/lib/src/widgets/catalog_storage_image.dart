import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/product_image_display_resolver.dart';

/// Displays a catalog product image from local preview, storage key, or URL ref.
class CatalogStorageImage extends StatelessWidget {
  const CatalogStorageImage({
    super.key,
    this.storageReference,
    this.localPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.resolver,
  });

  final String? storageReference;
  final String? localPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final ProductImageDisplayResolver? resolver;

  @override
  Widget build(BuildContext context) {
    final child = _buildContent();
    if (borderRadius == null) {
      return child;
    }
    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }

  Widget _buildContent() {
    final local = localPath?.trim();
    if (local != null && local.isNotEmpty) {
      return Image(
        image: kIsWeb ? NetworkImage(local) : FileImage(File(local)),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final reference = storageReference?.trim();
    if (reference == null || reference.isEmpty) {
      return _placeholder();
    }

    final imageResolver = resolver ?? ProductImageDisplayResolver.instance;
    return FutureBuilder<String?>(
      future: imageResolver.resolve(reference),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }

        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return _placeholder();
        }

        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      },
    );
  }

  Widget _placeholder() {
    return SizedBox(
      width: width,
      height: height,
      child: placeholder ??
          const ColoredBox(
            color: Color(0xFFECECEC),
            child: Center(
              child: Icon(Icons.image_outlined, color: Color(0xFF9E9E9E)),
            ),
          ),
    );
  }

  Widget _loading() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
