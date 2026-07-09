import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_step_base_unit.dart';
import 'product_guided_step_identification.dart';
import 'product_guided_step_images.dart';
import 'product_guided_step_inventory.dart';
import 'product_guided_step_base_cost.dart';
import 'product_guided_step_price_bands.dart';

/// Slice #2 (EPIC-02/US-02): 6 accordion steps — mirror Lovable `#/products/items/new`.
class ProductGuidedCreateBody extends StatelessWidget {
  const ProductGuidedCreateBody({
    super.key,
    required this.onCancel,
    this.onOpenDuplicateProduct,
  });

  final VoidCallback onCancel;
  final void Function(String productId, String productName)? onOpenDuplicateProduct;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductGuidedCreateCubit, ProductGuidedCreateState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  children: [
                    _buildStep(
                      context: context,
                      stepIndex: 0,
                      title: '1. Nhận diện',
                      subtitle: 'Tên nội bộ, tên thương mại, SKU, barcode',
                      isExpanded: state.activeStepIndex == 0,
                      child: ProductGuidedStepIdentification(
                        state: state,
                        onOpenDuplicateProduct: onOpenDuplicateProduct,
                      ),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    _buildStep(
                      context: context,
                      stepIndex: 1,
                      title: '2. Ảnh',
                      subtitle: 'Ảnh bìa và ảnh phụ',
                      isExpanded: state.activeStepIndex == 1,
                      child: ProductGuidedStepImages(state: state),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    _buildStep(
                      context: context,
                      stepIndex: 2,
                      title: '3. Đơn vị cơ sở',
                      subtitle: 'Chọn đơn vị gốc để tính tồn/giá',
                      isExpanded: state.activeStepIndex == 2,
                      child: ProductGuidedStepBaseUnit(state: state),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    _buildStep(
                      context: context,
                      stepIndex: 3,
                      title: '4. Tồn kho khởi tạo',
                      subtitle: 'Nhập số lượng tồn ban đầu',
                      isExpanded: state.activeStepIndex == 3,
                      child: ProductGuidedStepInventory(state: state),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    _buildStep(
                      context: context,
                      stepIndex: 4,
                      title: '5. Giá vốn cơ sở',
                      subtitle: 'Thiết lập giá vốn ban đầu',
                      isExpanded: state.activeStepIndex == 4,
                      child: ProductGuidedStepBaseCost(state: state),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    _buildStep(
                      context: context,
                      stepIndex: 5,
                      title: '6. Khung giá bán',
                      subtitle: 'Thiết lập cách tính giá bán',
                      isExpanded: state.activeStepIndex == 5,
                      child: ProductGuidedStepPriceBands(state: state),
                    ),
                  ],
                ),
              ),
            ),
            _buildStickyFooter(context, state),
          ],
        ),
      );
    });
  }

  Widget _buildStep({
    required BuildContext context,
    required int stepIndex,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required Widget child,
  }) {
    final dynamicColors = context.vColors;

    return VCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              title,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: dynamicColors.textSecondary,
            ),
            onTap: () {
              context.read<ProductGuidedCreateCubit>().setStep(stepIndex);
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(BuildContext context, ProductGuidedCreateState state) {
    final dynamicColors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        boxShadow: VShadows.e2,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.outline,
                onPressed: state.status == ProductGuidedCreateStatus.loading ? null : onCancel,
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: VButton(
                key: const Key('btn_guided_save'),
                label: 'Lưu sản phẩm',
                onPressed: (!state.hasAnyData || state.status == ProductGuidedCreateStatus.loading)
                    ? null
                    : () => context.read<ProductGuidedCreateCubit>().submit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
