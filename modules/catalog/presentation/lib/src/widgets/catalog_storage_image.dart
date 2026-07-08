import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/product_image_display_resolver.dart';

/// Displays a catalog product image from local preview, storage key, or URL ref.
class CatalogStorageImage extends StatefulWidget {
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
  State<CatalogStorageImage> createState() => _CatalogStorageImageState();
}

class _CatalogStorageImageState extends State<CatalogStorageImage> {
  Future<String?>? _resolveFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(CatalogStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.storageReference != oldWidget.storageReference) {
      _initFuture();
    }
  }

  void _initFuture() {
    final reference = widget.storageReference?.trim();
    if (reference != null && reference.isNotEmpty) {
      final imageResolver = widget.resolver ?? ProductImageDisplayResolver.instance;
      _resolveFuture = imageResolver.resolve(reference);
    } else {
      _resolveFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildContent();
    if (widget.borderRadius == null) {
      return child;
    }
    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: child,
    );
  }

  Widget _buildContent() {
    final local = widget.localPath?.trim();
    if (local != null && local.isNotEmpty) {
      return Image(
        image: kIsWeb ? NetworkImage(local) : FileImage(File(local)),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final reference = widget.storageReference?.trim();
    if (reference == null || reference.isEmpty || _resolveFuture == null) {
      return _placeholder();
    }

    return FutureBuilder<String?>(
      future: _resolveFuture,
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
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      },
    );
  }

  Widget _placeholder() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.placeholder ??
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
      width: widget.width,
      height: widget.height,
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
