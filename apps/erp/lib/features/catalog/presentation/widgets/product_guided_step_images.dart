import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';
import 'product_image_picker_panel.dart';

class ProductGuidedStepImages extends StatelessWidget {
  const ProductGuidedStepImages({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductImagePickerPanel(
          drafts: state.imageDrafts,
          coverImageIndex: state.coverImageIndex,
          maxImages: ProductGuidedCreateState.maxImages,
          onPickImage: cubit.pickImages,
          onSetCover: cubit.setCoverImageIndex,
          onRemoveAt: cubit.removeImageAt,
        ),
        if (state.imageDrafts.isEmpty) ...[
          const SizedBox(height: VSpacing.space2),
          VText(
            'Chưa có ảnh',
            variant: VTextVariant.caption,
            color: dynamicColors.textSecondary,
          ),
        ],
        if (state.hasUploadFailures) ...[
          const SizedBox(height: VSpacing.space2),
          VText(
            'Một số ảnh tải lên thất bại — bạn vẫn có thể lưu sản phẩm với ảnh đã tải thành công.',
            variant: VTextVariant.caption,
            color: dynamicColors.textSecondary,
          ),
        ],
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
