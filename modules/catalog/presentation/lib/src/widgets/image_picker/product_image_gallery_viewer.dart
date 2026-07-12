import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

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
    final isPrimary = _currentIndex == widget.primaryIndex;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Gallery ảnh',
          style: VTypography.headingH4.copyWith(color: Colors.white),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: VTypography.bodyDefault.copyWith(color: Colors.white),
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
                    placeholder: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                } else if (image.localPath != null &&
                    !kIsWeb &&
                    File(image.localPath!).existsSync()) {
                  imageChild = Image.file(File(image.localPath!), fit: BoxFit.contain);
                } else {
                  imageChild = const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 64),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
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
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: VColors.success,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Mặc định',
                        style: VTypography.bodyDefault.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    'Vuốt để xem ảnh khác',
                    style: VTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VRadius.input),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Đóng',
                        style: VTypography.bodyDefault.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
