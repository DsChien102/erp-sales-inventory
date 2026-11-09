import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../data/models/catalog_enums.dart';
import '../../logic/product_guided_create_cubit.dart';
import '../../logic/product_guided_create_state.dart';
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
        VTextField(
          key: const Key('input_guided_name'),
          controller: TextEditingController(text: state.name)
            ..selection = TextSelection.fromPosition(TextPosition(offset: state.name.length)),
          label: 'Tên nội bộ',
          hintText: 'Ví dụ: Amoxicillin 500mg',
          isRequired: true,
          errorText: (state.showValidationErrors && !state.isStep1Valid)
              ? 'Tên nội bộ không được bỏ trống'
              : null,
          textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateName,
        ),
        const SizedBox(height: VSpacing.space3),
        VTextField(
          controller: TextEditingController(text: state.tradeName)
            ..selection = TextSelection.fromPosition(TextPosition(offset: state.tradeName.length)),
          label: 'Tên thương mại',
          hintText: 'Tên hiển thị cho khách',
          textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateTradeName,
        ),
        const SizedBox(height: VSpacing.space3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: VTextField(
                key: const Key('input_guided_sku'),
                controller: TextEditingController(text: state.sku)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: state.sku.length),
                  ),
                label: 'SKU',
                hintText: 'Nhập mã SKU',
                errorText: state.skuError,
                textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                onChanged: cubit.updateSku,
                onSubmitted: (_) => cubit.checkDuplicateCodes(),
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: VTextField(
                key: const Key('input_guided_barcode'),
                controller: TextEditingController(text: state.barcode)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: state.barcode.length),
                  ),
                label: 'Barcode',
                hintText: 'Quét hoặc nhập',
                errorText: state.barcodeError,
                suffixIcon: IconButton(
                  icon: Icon(Icons.qr_code_scanner, color: dynamicColors.primary),
                  onPressed: () {},
                ),
                textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                onChanged: cubit.updateBarcode,
                onSubmitted: (_) => cubit.checkDuplicateCodes(),
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
              label: VText(
                'Mở sản phẩm "${state.duplicateProductName}"',
                variant: VTextVariant.bodySmall,
                color: dynamicColors.primary,
              ),
            ),
          ),
        ],
        const SizedBox(height: VSpacing.space3),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: VText(
                      'Quản lý theo lô',
                      variant: VTextVariant.bodyDefault,
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                  VSwitch(
                    key: const Key('switch_guided_tracking_mode'),
                    value: state.trackingMode == ProductTrackingMode.lot,
                    enabled: true,
                    onChanged: (val) => cubit.setTrackingMode(
                      val ? ProductTrackingMode.lot : ProductTrackingMode.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space4),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: VText(
                      'Bắt buộc hạn dùng',
                      variant: VTextVariant.bodyDefault,
                      color: state.trackingMode == ProductTrackingMode.lot
                          ? dynamicColors.textPrimary
                          : dynamicColors.textSecondary,
                    ),
                  ),
                  VSwitch(
                    key: const Key('switch_guided_expiry_required'),
                    value: state.expiryRequired,
                    enabled: state.trackingMode == ProductTrackingMode.lot,
                    onChanged: state.trackingMode == ProductTrackingMode.lot
                        ? (val) => cubit.setExpiryRequired(val)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
