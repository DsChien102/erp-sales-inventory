import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';
import '../bloc/product_images_maintenance_cubit.dart';
import '../widgets/product_form_bottom_bar.dart';

class ProductImagesMaintenancePage extends StatelessWidget {
  const ProductImagesMaintenancePage({
    super.key,
    required this.product,
  });

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductImagesMaintenanceCubit(
        catalogModule: getIt<ICatalogModule>(),
        executionContext: getIt<IExecutionContext>(),
        productId: product.id,
        initialImages: product.images ?? [],
      ),
      child: const _ProductImagesMaintenanceView(),
    );
  }
}

class _ProductImagesMaintenanceView extends StatelessWidget {
  const _ProductImagesMaintenanceView();

  Future<void> _showAddImageOptions(BuildContext context) async {
    final source = await ProductImageAddSheet.show(context);
    if (!context.mounted) return;
    if (source != null) {
      context.read<ProductImagesMaintenanceCubit>().pickImages(source);
    }
  }

  Future<void> _handleRemove(BuildContext context, int index) async {
    final confirm = await ProductImageDeleteDialog.show(context);
    if (!context.mounted) return;
    if (confirm) {
      context.read<ProductImagesMaintenanceCubit>().removeImage(index);
    }
  }

  void _openGallery(BuildContext context, List<ProductImageStateItem> images) {
    if (images.isEmpty) return;

    final galleryImages = images
        .map(
          (image) => GalleryImageItem(
            localPath: image.localPath,
            storageKey: image.storageKey,
          ),
        )
        .toList();

    int primaryIndex = images.indexWhere((img) => img.isPrimary);
    if (primaryIndex == -1) primaryIndex = 0;

    ProductImageGalleryViewer.show(
      context,
      images: galleryImages,
      primaryIndex: primaryIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocListener<ProductImagesMaintenanceCubit, ProductImagesMaintenanceState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ProductImagesMaintenanceStatus.success) {
          VToast.show(
            context,
            title: 'Thành công',
            message: 'Đã cập nhật ảnh sản phẩm',
            type: VToastType.success,
          );
          context.pop();
        } else if (state.status == ProductImagesMaintenanceStatus.failure &&
            state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        }
      },
      child: VPageScaffold(
        key: const Key('wgt_e07_u01_fr02_01'),
        title: 'Ảnh sản phẩm',
        leading: IconButton(
          icon: VIcon(icon: VIcons.arrowBack, color: dynamicColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: BlocBuilder<ProductImagesMaintenanceCubit, ProductImagesMaintenanceState>(
            builder: (context, state) {
              final canAddMore = state.images.length < 8;

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
                    itemCount: state.images.length + (canAddMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < state.images.length) {
                        final image = state.images[index];
                        return ProductImageGridItem(
                          localPath: image.localPath,
                          storageKey: image.storageKey,
                          isPrimary: image.isPrimary,
                          isUploading: false,
                          onSetPrimary: () =>
                              context.read<ProductImagesMaintenanceCubit>().setPrimaryImage(index),
                          onRemove: () => _handleRemove(context, index),
                        );
                      } else {
                        return GestureDetector(
                          onTap: state.status == ProductImagesMaintenanceStatus.uploading
                              ? null
                              : () => _showAddImageOptions(context),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: dynamicColors.borderDefault,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(VRadius.card),
                              color: dynamicColors.surface,
                            ),
                            child: state.status == ProductImagesMaintenanceStatus.uploading
                                ? const Center(child: CircularProgressIndicator())
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      VIcon(
                                        icon: VIcons.add,
                                        size: 24,
                                        color: dynamicColors.textSecondary,
                                      ),
                                      const VGap.xs(),
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
                  if (state.images.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.space4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => _openGallery(context, state.images),
                        child: VText(
                          'Xem trước ảnh',
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
                            text: 'Đã đạt tối đa 8 ảnh. ',
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
                      'Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa 8 ảnh.',
                      variant: VTextVariant.bodySmall,
                      color: dynamicColors.textSecondary,
                    ),
                ],
              );
            },
          ),
        ),
        bottomBar: BlocBuilder<ProductImagesMaintenanceCubit, ProductImagesMaintenanceState>(
          builder: (context, state) {
            return ProductFormBottomBar(
              onCancel: () => context.pop(),
              saveKey: const Key('btn_images_maintenance_save'),
              isLoading: state.status == ProductImagesMaintenanceStatus.submitting,
              saveEnabled: context.read<ProductImagesMaintenanceCubit>().hasChanges,
              onSave: () => context.read<ProductImagesMaintenanceCubit>().submit(),
            );
          },
        ),
      ),
    );
  }
}
