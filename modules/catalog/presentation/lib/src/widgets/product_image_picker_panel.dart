import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vet45_design_system/design_system.dart';

/// Multi-image picker from device gallery (1–n images per product).
class ProductImagePickerPanel extends StatefulWidget {
  const ProductImagePickerPanel({
    super.key,
    required this.images,
    required this.coverImageIndex,
    required this.onChanged,
    this.maxImages = 8,
  });

  final List<String> images;
  final int coverImageIndex;
  final void Function(List<String> images, int coverIndex) onChanged;
  final int maxImages;

  @override
  State<ProductImagePickerPanel> createState() => _ProductImagePickerPanelState();
}

class _ProductImagePickerPanelState extends State<ProductImagePickerPanel> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    if (widget.images.length >= widget.maxImages) {
      VToast.show(
        context,
        title: 'Giới hạn ảnh',
        message: 'Tối đa ${widget.maxImages} ảnh cho mỗi sản phẩm.',
        type: VToastType.warning,
      );
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;

      final remaining = widget.maxImages - widget.images.length;
      final toAdd = picked.take(remaining).map((x) => x.path).toList();
      final next = [...widget.images, ...toAdd];
      widget.onChanged(next, widget.coverImageIndex.clamp(0, next.length - 1));
    } catch (_) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Không mở được thư viện ảnh',
        message: 'Vui lòng cấp quyền truy cập ảnh hoặc thử lại.',
        type: VToastType.danger,
      );
    }
  }

  void _removeAt(int index) {
    final next = [...widget.images]..removeAt(index);
    var cover = widget.coverImageIndex;
    if (cover >= next.length) {
      cover = next.isEmpty ? 0 : next.length - 1;
    } else if (index < cover) {
      cover -= 1;
    } else if (index == cover && next.isNotEmpty) {
      cover = 0;
    }
    widget.onChanged(next, cover);
  }

  Widget _imageTile(String path, int index) {
    final dynamicColors = context.vColors;
    final isCover = widget.coverImageIndex == index;

    Widget imageChild;
    if (path.startsWith('http')) {
      imageChild = Image.network(path, fit: BoxFit.cover);
    } else if (!kIsWeb && File(path).existsSync()) {
      imageChild = Image.file(File(path), fit: BoxFit.cover);
    } else {
      imageChild = Center(
        child: Icon(Icons.broken_image_outlined, color: dynamicColors.textMuted),
      );
    }

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: VSpacing.space2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCover ? VColors.success : dynamicColors.borderDefault,
          width: isCover ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageChild,
            if (isCover)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ảnh bìa',
                    style: VTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => _removeAt(index),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => widget.onChanged(widget.images, index),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    'Đặt ảnh bìa',
                    textAlign: TextAlign.center,
                    style: VTypography.caption.copyWith(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ảnh sản phẩm',
          style: VTypography.bodyDefault.copyWith(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          'Chọn từ thư viện máy — tối đa ${widget.maxImages} ảnh.',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space3),
        if (widget.images.isEmpty)
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VRadius.card),
                border: Border.all(color: dynamicColors.borderDefault),
                color: dynamicColors.surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 36, color: dynamicColors.textSecondary),
                  const SizedBox(height: VSpacing.space1),
                  Text(
                    'Chọn ảnh từ thư viện',
                    style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...widget.images.asMap().entries.map((e) => _imageTile(e.value, e.key)),
                if (widget.images.length < widget.maxImages)
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: dynamicColors.borderDefault),
                        borderRadius: BorderRadius.circular(VRadius.card),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined, color: dynamicColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
