import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/product_image_draft.dart';

/// Multi-image picker with upload status indicators.
class ProductImagePickerPanel extends StatelessWidget {
  const ProductImagePickerPanel({
    super.key,
    required this.drafts,
    required this.coverImageIndex,
    required this.onPickFromGallery,
    required this.onSetCover,
    required this.onRemoveAt,
    this.maxImages = 8,
  });

  final List<ProductImageDraft> drafts;
  final int coverImageIndex;
  final VoidCallback onPickFromGallery;
  final void Function(int index) onSetCover;
  final void Function(int index) onRemoveAt;
  final int maxImages;

  Widget _imageTile(ProductImageDraft draft, int index) {
    return Builder(
      builder: (context) {
        final dynamicColors = context.vColors;
        final isCover = coverImageIndex == index;
        final path = draft.localPath;

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
          height: 100,
          padding: EdgeInsets.all(isCover ? 0 : 1),
          decoration: BoxDecoration(
            border: Border.all(
              color: isCover ? VColors.success : dynamicColors.borderDefault,
              width: isCover ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(VRadius.card),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCover ? VRadius.card - 2 : VRadius.card - 1),
            child: GestureDetector(
              onTap: () => onSetCover(index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageChild,
                  if (draft.status == ProductImageUploadStatus.uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  if (draft.status == ProductImageUploadStatus.failed)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        draft.errorMessage ?? 'Lỗi',
                        textAlign: TextAlign.center,
                        style: VTypography.caption.copyWith(color: Colors.white, fontSize: 8),
                      ),
                    ),
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
                          'Mặc định',
                          style: VTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveAt(index),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (drafts.isEmpty)
          GestureDetector(
            onTap: onPickFromGallery,
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
          Wrap(
            spacing: VSpacing.space2,
            runSpacing: VSpacing.space2,
            children: [
              ...drafts.asMap().entries.map((e) => _imageTile(e.value, e.key)),
              if (drafts.length < maxImages)
                GestureDetector(
                  onTap: onPickFromGallery,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: dynamicColors.borderDefault),
                      borderRadius: BorderRadius.circular(VRadius.card),
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined, color: dynamicColors.textSecondary),
                  ),
                ),
            ],
          ),
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space3),
          Text(
            'Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa $maxImages ảnh.',
            style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
