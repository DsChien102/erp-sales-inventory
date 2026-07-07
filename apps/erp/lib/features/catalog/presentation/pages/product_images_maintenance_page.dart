import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';
import '../bloc/product_images_maintenance_cubit.dart';

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
        } else if (state.status == ProductImagesMaintenanceStatus.failure && state.errorMessage != null) {
          VToast.show(
            context,
            title: 'Lỗi',
            message: state.errorMessage!,
            type: VToastType.danger,
          );
        }
      },
      child: Scaffold(
        key: const Key('wgt_e07_u01_fr02_01'),
        backgroundColor: dynamicColors.background,
        appBar: VAppBar(
          title: 'Ảnh sản phẩm',
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<ProductImagesMaintenanceCubit, ProductImagesMaintenanceState>(
                builder: (context, state) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...state.images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return GestureDetector(
                          onTap: () => context.read<ProductImagesMaintenanceCubit>().setPrimaryImage(index),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: image.isPrimary
                                        ? dynamicColors.success
                                        : dynamicColors.borderDefault,
                                    width: image.isPrimary ? 2 : 1,
                                  ),
                                ),
                                child: CatalogStorageImage(
                                  storageReference: image.storageKey,
                                  localPath: image.localPath,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(8),
                                  placeholder: ColoredBox(
                                    color: dynamicColors.surfaceAlt,
                                    child: Icon(
                                      Icons.image,
                                      color: dynamicColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              if (image.isPrimary)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: dynamicColors.success,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Mặc định',
                                      style: VTypography.bodySmall.copyWith(
                                        color: dynamicColors.surface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => context.read<ProductImagesMaintenanceCubit>().removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (state.images.length < 8)
                        GestureDetector(
                          onTap: state.status == ProductImagesMaintenanceStatus.uploading
                              ? null
                              : () => context.read<ProductImagesMaintenanceCubit>().pickImagesFromGallery(),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: dynamicColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: dynamicColors.borderDefault,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: state.status == ProductImagesMaintenanceStatus.uploading
                                ? const Center(child: CircularProgressIndicator())
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: dynamicColors.textSecondary),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Thêm',
                                        style: VTypography.bodySmall.copyWith(
                                          color: dynamicColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Chạm vào ảnh để đặt làm ảnh mặc định. Tối đa 8 ảnh.',
                style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dynamicColors.surface,
            border: Border(
              top: BorderSide(color: dynamicColors.borderDefault),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Huỷ',
                      style: VTypography.bodyDefault.copyWith(
                        color: dynamicColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<ProductImagesMaintenanceCubit, ProductImagesMaintenanceState>(
                    builder: (context, state) {
                      return VButton(
                        key: const Key('btn_images_maintenance_save'),
                        onPressed: state.status == ProductImagesMaintenanceStatus.submitting
                            ? null
                            : () => context.read<ProductImagesMaintenanceCubit>().submit(),
                        label: 'Lưu thay đổi',
                        isLoading: state.status == ProductImagesMaintenanceStatus.submitting,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
