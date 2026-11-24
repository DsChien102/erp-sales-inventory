// harness:allow-design-system-bypass — fullscreen dark gallery (không phải page shell VAppBar chuẩn)
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation.dart';

class GalleryImageItem {
  final String? localPath;
  final String? storageKey;

  const GalleryImageItem({this.localPath, this.storageKey});
}

class ProductImageGalleryViewer extends StatefulWidget {
  const ProductImageGalleryViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.primaryIndex,
  });

  final List<GalleryImageItem> images;
  final int initialIndex;
  final int primaryIndex;

  static void show(
    BuildContext context, {
    required List<GalleryImageItem> images,
    required int primaryIndex,
  }) {
    if (images.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductImageGalleryViewer(
          images: images,
          initialIndex: 0,
          primaryIndex: primaryIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<ProductImageGalleryViewer> createState() => _ProductImageGalleryViewerState();
}

class _ProductImageGalleryViewerState extends State<ProductImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isPrimary = _currentIndex == widget.primaryIndex;

    return Scaffold(
      backgroundColor: colors.textPrimary,
      appBar: AppBar(
        backgroundColor: colors.textPrimary,
        iconTheme: IconThemeData(color: colors.surface),
        title: VText(
          'Gallery ảnh',
          variant: VTextVariant.headingH4,
          color: colors.surface,
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: VSpacing.space4),
              child: VText(
                '${_currentIndex + 1}/${widget.images.length}',
                variant: VTextVariant.bodyDefault,
                color: colors.surface,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final image = widget.images[index];

                Widget imageChild;
                if (image.localPath != null && image.localPath!.startsWith('http')) {
                  imageChild = Image.network(image.localPath!, fit: BoxFit.contain);
                } else if (image.storageKey != null && image.storageKey!.isNotEmpty) {
                  imageChild = CatalogStorageImage(
                    storageReference: image.storageKey!,
                    localPath: image.localPath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: Center(
                      child: CircularProgressIndicator(color: colors.surface),
                    ),
                  );
                } else if (image.localPath != null &&
                    !kIsWeb &&
                    File(image.localPath!).existsSync()) {
                  imageChild = Image.file(File(image.localPath!), fit: BoxFit.contain);
                } else {
                  imageChild = Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colors.surfaceAlt,
                      size: 64,
                    ),
                  );
                }

                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: imageChild,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  colors.textPrimary.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPrimary)
                    Container(
                      margin: const EdgeInsets.only(bottom: VSpacing.space4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.space3,
                        vertical: VSpacing.space1 + 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.success,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: VText(
                        'Mặc định',
                        variant: VTextVariant.bodyDefault,
                        color: colors.surface,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  VText(
                    'Vuốt để xem ảnh khác',
                    variant: VTextVariant.bodySmall,
                    color: colors.surface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: VSpacing.space4),
                  VButton(
                    label: 'Đóng',
                    fullWidth: true,
                    variant: VButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
