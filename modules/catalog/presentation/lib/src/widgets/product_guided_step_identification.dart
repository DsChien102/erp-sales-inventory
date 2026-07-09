import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

class ProductGuidedStepIdentification extends StatelessWidget {
  const ProductGuidedStepIdentification({
    super.key,
    required this.state,
    this.onOpenDuplicateProduct,
  });

  final ProductGuidedCreateState state;
  final void Function(String productId, String productName)? onOpenDuplicateProduct;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductGuidedFields.buildLabel(context, 'Tên nội bộ *'),
        TextField(
          key: const Key('input_guided_name'),
          controller: TextEditingController(text: state.name)
            ..selection = TextSelection.fromPosition(TextPosition(offset: state.name.length)),
          decoration: ProductGuidedFields.buildInputDecoration(
            context,
            'Ví dụ: Amoxicillin 500mg',
            errorText: (state.showValidationErrors && !state.isStep1Valid)
                ? 'Tên nội bộ không được bỏ trống'
                : null,
          ),
          style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateName,
        ),
        const SizedBox(height: VSpacing.space3),
        ProductGuidedFields.buildLabel(context, 'Tên thương mại'),
        TextField(
          controller: TextEditingController(text: state.tradeName)
            ..selection = TextSelection.fromPosition(TextPosition(offset: state.tradeName.length)),
          decoration: ProductGuidedFields.buildInputDecoration(context, 'Tên hiển thị cho khách'),
          style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateTradeName,
        ),
        const SizedBox(height: VSpacing.space3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductGuidedFields.buildLabel(context, 'SKU'),
                  TextField(
                    key: const Key('input_guided_sku'),
                    controller: TextEditingController(text: state.sku)
                      ..selection = TextSelection.fromPosition(TextPosition(offset: state.sku.length)),
                    decoration: ProductGuidedFields.buildInputDecoration(
                      context,
                      'Nhập mã SKU',
                      errorText: state.skuError,
                    ),
                    style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                    onChanged: cubit.updateSku,
                    onEditingComplete: cubit.checkDuplicateCodes,
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductGuidedFields.buildLabel(context, 'Barcode'),
                  TextField(
                    key: const Key('input_guided_barcode'),
                    controller: TextEditingController(text: state.barcode)
                      ..selection = TextSelection.fromPosition(TextPosition(offset: state.barcode.length)),
                    decoration: ProductGuidedFields.buildInputDecoration(
                      context,
                      'Quét hoặc nhập',
                      errorText: state.barcodeError,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: dynamicColors.primary),
                        onPressed: () {},
                      ),
                    ),
                    style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                    onChanged: cubit.updateBarcode,
                    onEditingComplete: cubit.checkDuplicateCodes,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (state.duplicateProductId != null && state.duplicateProductName != null) ...[
          const SizedBox(height: VSpacing.space2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('btn_open_duplicate_product'),
              onPressed: onOpenDuplicateProduct == null
                  ? null
                  : () => onOpenDuplicateProduct!(
                        state.duplicateProductId!,
                        state.duplicateProductName!,
                      ),
              icon: Icon(Icons.open_in_new, size: 16, color: dynamicColors.primary),
              label: Text(
                'Mở sản phẩm "${state.duplicateProductName}"',
                style: VTypography.bodySmall.copyWith(color: dynamicColors.primary),
              ),
            ),
          ),
        ],
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
