import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

class ProductGuidedStepPriceBands extends StatefulWidget {
  const ProductGuidedStepPriceBands({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  State<ProductGuidedStepPriceBands> createState() => _ProductGuidedStepPriceBandsState();
}

class _ProductGuidedStepPriceBandsState extends State<ProductGuidedStepPriceBands> {
  late final TextEditingController _customMarkupController;
  late final TextEditingController _customFloorMarkupController;
  late final TextEditingController _manualListPriceController;
  late final TextEditingController _manualFloorPriceController;

  @override
  void initState() {
    super.initState();
    _customMarkupController = TextEditingController(text: widget.state.customAutoMarkup);
    _customFloorMarkupController = TextEditingController(text: widget.state.customAutoFloorMarkup);
    _manualListPriceController = TextEditingController(text: widget.state.manualListPrice);
    _manualFloorPriceController = TextEditingController(text: widget.state.manualFloorPrice);
  }

  @override
  void didUpdateWidget(covariant ProductGuidedStepPriceBands oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.customAutoMarkup != _customMarkupController.text &&
        widget.state.customAutoMarkup != oldWidget.state.customAutoMarkup) {
      _customMarkupController.text = widget.state.customAutoMarkup;
    }
    if (widget.state.customAutoFloorMarkup != _customFloorMarkupController.text &&
        widget.state.customAutoFloorMarkup != oldWidget.state.customAutoFloorMarkup) {
      _customFloorMarkupController.text = widget.state.customAutoFloorMarkup;
    }
    if (widget.state.manualListPrice != _manualListPriceController.text &&
        widget.state.manualListPrice != oldWidget.state.manualListPrice) {
      _manualListPriceController.text = widget.state.manualListPrice;
    }
    if (widget.state.manualFloorPrice != _manualFloorPriceController.text &&
        widget.state.manualFloorPrice != oldWidget.state.manualFloorPrice) {
      _manualFloorPriceController.text = widget.state.manualFloorPrice;
    }
  }

  @override
  void dispose() {
    _customMarkupController.dispose();
    _customFloorMarkupController.dispose();
    _manualListPriceController.dispose();
    _manualFloorPriceController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    final str = val.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '${str.replaceAllMapped(reg, (Match m) => '${m[1]}.')} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();
    final baseCost = double.tryParse(widget.state.baseCost) ?? 0.0;

    if (widget.state.baseUnit.trim().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(VSpacing.space3),
            decoration: BoxDecoration(
              color: dynamicColors.warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được khung giá bán.',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.warning,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.space4),
          ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thiết lập giá bán của sản phẩm. Bạn có thể chọn cách định giá tự động hoặc nhập thủ công.',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space3),

        // Selectors
        Row(
          children: [
            Expanded(
              child: _buildPricingMethodCard(
                context: context,
                label: 'Giá cửa hàng',
                isSelected: widget.state.pricingMethod == 'storeRule',
                onTap: () => cubit.updatePricingMethod('storeRule'),
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: _buildPricingMethodCard(
                context: context,
                label: 'Tự động riêng',
                isSelected: widget.state.pricingMethod == 'customAuto',
                onTap: () => cubit.updatePricingMethod('customAuto'),
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            Expanded(
              child: _buildPricingMethodCard(
                context: context,
                label: 'Thủ công',
                isSelected: widget.state.pricingMethod == 'manual',
                onTap: () => cubit.updatePricingMethod('manual'),
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space4),

        // Display Inputs and Previews depending on selected method
        if (widget.state.pricingMethod == 'storeRule') ...[
          _buildCalculatedPriceDisplay(
            context: context,
            baseCost: baseCost,
            markupPercent: 35,
            floorPercent: 15,
            labelSuffix: 'Cửa hàng',
          ),
        ] else if (widget.state.pricingMethod == 'customAuto') ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductGuidedFields.buildLabel(context, 'Lãi cơ sở (%)'),
                    TextField(
                      controller: _customMarkupController,
                      keyboardType: TextInputType.number,
                      decoration: ProductGuidedFields.buildInputDecoration(context, '35'),
                      style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                      onChanged: cubit.updateCustomAutoMarkup,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductGuidedFields.buildLabel(context, 'Giá sàn (%)'),
                    TextField(
                      controller: _customFloorMarkupController,
                      keyboardType: TextInputType.number,
                      decoration: ProductGuidedFields.buildInputDecoration(context, '15'),
                      style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                      onChanged: cubit.updateCustomAutoFloorMarkup,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space4),
          _buildCalculatedPriceDisplay(
            context: context,
            baseCost: baseCost,
            markupPercent: double.tryParse(widget.state.customAutoMarkup) ?? 35.0,
            floorPercent: double.tryParse(widget.state.customAutoFloorMarkup) ?? 15.0,
            labelSuffix: 'Cấu hình riêng',
          ),
        ] else if (widget.state.pricingMethod == 'manual') ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductGuidedFields.buildLabel(context, 'Giá niêm yết'),
                    TextField(
                      key: const Key('input_guided_manual_list_price'),
                      controller: _manualListPriceController,
                      keyboardType: TextInputType.number,
                      decoration: ProductGuidedFields.buildInputDecoration(context, '0').copyWith(
                        suffixText: '₫',
                      ),
                      style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                      onChanged: cubit.updateManualListPrice,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProductGuidedFields.buildLabel(context, 'Giá bán sàn'),
                    TextField(
                      key: const Key('input_guided_manual_floor_price'),
                      controller: _manualFloorPriceController,
                      keyboardType: TextInputType.number,
                      decoration: ProductGuidedFields.buildInputDecoration(context, '0').copyWith(
                        suffixText: '₫',
                        errorText: widget.state.manualPriceError,
                        errorMaxLines: 2,
                      ),
                      style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
                      onChanged: cubit.updateManualFloorPrice,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          Container(
            padding: const EdgeInsets.all(VSpacing.space2),
            decoration: BoxDecoration(
              color: dynamicColors.warningBg,
              borderRadius: BorderRadius.circular(VRadius.card),
              border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: dynamicColors.warning),
                const SizedBox(width: VSpacing.space2),
                Expanded(
                  child: Text(
                    'Giá nhập thủ công sẽ không tự động cập nhật khi giá vốn thay đổi.',
                    style: VTypography.bodySmall.copyWith(color: dynamicColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(
          context,
          showSkip: true,
          skipKey: const Key('btn_guided_price_band_skip'),
          nextKey: const Key('btn_guided_price_band_confirm'),
          onSkip: cubit.deferPriceBandStep,
          onNext: cubit.confirmPriceBandStep,
        ),
      ],
    );
  }

  Widget _buildPricingMethodCard({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final dynamicColors = context.vColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
        decoration: BoxDecoration(
          color: isSelected ? dynamicColors.primary.withValues(alpha: 0.08) : dynamicColors.surface,
          border: Border.all(
            color: isSelected ? dynamicColors.primary : dynamicColors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: VTypography.bodySmall.copyWith(
            color: isSelected ? dynamicColors.primary : dynamicColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatedPriceDisplay({
    required BuildContext context,
    required double baseCost,
    required double markupPercent,
    required double floorPercent,
    required String labelSuffix,
  }) {
    final listPrice = baseCost * (1 + markupPercent / 100);
    final floorPrice = baseCost * (1 + floorPercent / 100);

    return Column(
      children: [
        _buildPricePreviewRow(
          context: context,
          title: 'Giá niêm yết gợi ý (+$markupPercent%)',
          value: _formatCurrency(listPrice),
          subtitle: 'Giá bán chuẩn chưa chiết khấu',
        ),
        const SizedBox(height: VSpacing.space2),
        _buildPricePreviewRow(
          context: context,
          title: 'Giá bán sàn gợi ý (+$floorPercent%)',
          value: _formatCurrency(floorPrice),
          subtitle: 'Giá tối thiểu nhân viên được phép bán',
        ),
      ],
    );
  }

  Widget _buildPricePreviewRow({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final dynamicColors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        border: Border.all(color: dynamicColors.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VTypography.bodySmall.copyWith(
                    color: dynamicColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: VTypography.bodySmall.copyWith(color: dynamicColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: VTypography.headingH3.copyWith(
              color: dynamicColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
