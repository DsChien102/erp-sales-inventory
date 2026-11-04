import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../logic/product_images_maintenance_cubit.dart';
import '../models/product_image_draft.dart';
import 'image_picker/product_image_grid_item.dart';
import 'image_picker/product_image_add_sheet.dart';
import 'image_picker/product_image_gallery_viewer.dart';
import 'image_picker/product_image_delete_dialog.dart';

/// Multi-image picker with upload status indicators.
class ProductImagePickerPanel extends StatelessWidget {
  const ProductImagePickerPanel({
    super.key,
    required this.drafts,
    required this.coverImageIndex,
    required this.onPickImage,
    required this.onSetCover,
    required this.onRemoveAt,
    this.maxImages = 8,
  });

  final List<ProductImageDraft> drafts;
  final int coverImageIndex;
  final void Function(ProductImageSource) onPickImage;
  final void Function(int index) onSetCover;
  final void Function(int index) onRemoveAt;
  final int maxImages;

  Future<void> _showAddImageOptions(BuildContext context) async {
    final source = await ProductImageAddSheet.show(context);
    if (!context.mounted) return;
    if (source != null) {
      onPickImage(source);
    }
  }

  Future<void> _handleRemove(BuildContext context, int index) async {
    final confirm = await ProductImageDeleteDialog.show(context);
    if (confirm) {
      onRemoveAt(index);
    }
  }

  void _openGallery(BuildContext context) {
    if (drafts.isEmpty) return;

    final images = drafts
        .map(
          (draft) => GalleryImageItem(
            localPath: draft.localPath,
            storageKey: draft.storageKey,
          ),
        )
        .toList();

    ProductImageGalleryViewer.show(
      context,
      images: images,
      primaryIndex: coverImageIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final canAddMore = drafts.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: drafts.length + (canAddMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < drafts.length) {
              final draft = drafts[index];
              return ProductImageGridItem(
                localPath: draft.localPath,
                storageKey: draft.storageKey,
                isPrimary: coverImageIndex == index,
                isUploading: draft.status == ProductImageUploadStatus.uploading,
                isFailed: draft.status == ProductImageUploadStatus.failed,
                errorMessage: draft.errorMessage,
                onSetPrimary: () => onSetCover(index),
                onRemove: () => _handleRemove(context, index),
              );
            } else {
              return GestureDetector(
                onTap: () => _showAddImageOptions(context),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: dynamicColors.borderDefault,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(VRadius.card),
                    color: dynamicColors.surface,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 24, color: dynamicColors.textSecondary),
                      const SizedBox(height: VSpacing.space1),
                      VText(
                        'Thêm',
                        variant: VTextVariant.bodySmall,
                        color: dynamicColors.textSecondary,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: VSpacing.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _openGallery(context),
              child: VText(
                'Xem gallery',
                variant: VTextVariant.bodyDefault,
                color: dynamicColors.primary,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: VSpacing.space4),
        if (!canAddMore)
          RichText(
            text: TextSpan(
              style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
              children: [
                TextSpan(
                  text: 'Đã đạt tối đa $maxImages ảnh. ',
                  style: VTypography.bodySmall.copyWith(
                    color: dynamicColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: 'Xóa bớt ảnh nếu muốn thêm ảnh mới.'),
              ],
            ),
          )
        else
          VText(
            'Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa $maxImages ảnh.',
            variant: VTextVariant.bodySmall,
            color: dynamicColors.textSecondary,
          ),
      ],
    );
  }
}
