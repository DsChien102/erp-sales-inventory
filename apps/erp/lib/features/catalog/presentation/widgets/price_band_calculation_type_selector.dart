import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import 'price_band_custom_config_section.dart';
import 'price_band_manual_section.dart';
import 'price_band_store_rule_section.dart';

class PriceBandCalculationTypeSelector extends StatefulWidget {
  const PriceBandCalculationTypeSelector({
    super.key,
    required this.row,
  });

  final ProductUnitPriceBandRowDto row;

  @override
  State<PriceBandCalculationTypeSelector> createState() => _PriceBandCalculationTypeSelectorState();
}

class _PriceBandCalculationTypeSelectorState extends State<PriceBandCalculationTypeSelector> {
  final _customBaseMarginController = TextEditingController();
  final _customFloorMarginController = TextEditingController();
  final _manualListPriceController = TextEditingController();
  final _manualFloorPriceController = TextEditingController();

  @override
  void dispose() {
    _customBaseMarginController.dispose();
    _customFloorMarginController.dispose();
    _manualListPriceController.dispose();
    _manualFloorPriceController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, num? value) {
    final valueStr = value != null && value != 0 ? value.round().toString() : '';
    if (num.tryParse(controller.text.replaceAll(',', '')) != value) {
      controller.text = valueStr;
    }
  }

  void _syncMoneyController(TextEditingController controller, num? value) {
    final expected = value != null && value != 0 ? VMoneyValidator.format(value.round()) : '';
    final parsed = VMoneyValidator.parse(controller.text);
    final expectedInt = value != null && value != 0 ? value.round() : null;
    if (parsed != expectedInt) {
      controller.text = expected;
    }
  }

  void _syncControllers(EditProductUnitPriceBandLoaded state) {
    _syncController(_customBaseMarginController, state.customBaseMargin);
    _syncController(_customFloorMarginController, state.customFloorMargin);
    _syncMoneyController(_manualListPriceController, state.manualListPrice);
    _syncMoneyController(_manualFloorPriceController, state.manualFloorPrice);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocBuilder<EditProductUnitPriceBandCubit, EditProductUnitPriceBandState>(
      builder: (context, state) {
        if (state is! EditProductUnitPriceBandLoaded) return const SizedBox.shrink();

        _syncControllers(state);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: dynamicColors.surface,
                borderRadius: BorderRadius.circular(VRadius.r8),
                border: Border.all(color: dynamicColors.borderDefault),
              ),
              padding: const EdgeInsets.all(VSpacing.space4),
              child: VChoiceList<PriceBandCalculationType>(
                title: 'Cách tính',
                choices: const [
                  VChoiceOption(
                    value: PriceBandCalculationType.storeRule,
                    label: 'Theo khung giá cửa hàng',
                    helpText: 'Tự động áp dụng khung giá của hàng.',
                  ),
                  VChoiceOption(
                    value: PriceBandCalculationType.customConfig,
                    label: 'Tự động riêng theo cấu hình',
                    helpText: 'Tự động tính giá theo cấu hình của sản phẩm.',
                  ),
                  VChoiceOption(
                    value: PriceBandCalculationType.manual,
                    label: 'Nhập thủ công',
                    helpText: 'Tự nhập giá cho đơn vị này.',
                  ),
                ],
                selected: [state.selectedType],
                onChanged: (selected) {
                  if (selected.isEmpty) return;
                  _changeType(context, selected.first);
                },
              ),
            ),
            const SizedBox(height: VSpacing.space4),
            Container(
              decoration: BoxDecoration(
                color: dynamicColors.surface,
                borderRadius: BorderRadius.circular(VRadius.r8),
                border: Border.all(color: dynamicColors.borderDefault),
              ),
              padding: const EdgeInsets.all(VSpacing.space4),
              child: _buildDetailsContent(context, state),
            ),
          ],
        );
      },
    );
  }

  void _changeType(BuildContext context, PriceBandCalculationType type) {
    context.read<EditProductUnitPriceBandCubit>().changeCalculationType(type);
  }

  Widget _buildDetailsContent(BuildContext context, EditProductUnitPriceBandLoaded state) {
    if (state.selectedType == PriceBandCalculationType.storeRule) {
      return Column(
        children: [
          PriceBandStoreRuleSection(
            key: const Key('wgt_e06_u02_fr02_01'),
            state: state,
          ),
          const SizedBox(key: Key('wgt_e06_u02_fr03_01')),
        ],
      );
    } else if (state.selectedType == PriceBandCalculationType.customConfig) {
      return PriceBandCustomConfigSection(
        state: state,
        listController: _customBaseMarginController,
        floorController: _customFloorMarginController,
        onListChanged: context.read<EditProductUnitPriceBandCubit>().updateCustomBaseMargin,
        onFloorChanged: context.read<EditProductUnitPriceBandCubit>().updateCustomFloorMargin,
      );
    } else {
      return PriceBandManualSection(
        state: state,
        listController: _manualListPriceController,
        floorController: _manualFloorPriceController,
        onListChanged: context.read<EditProductUnitPriceBandCubit>().updateManualListPrice,
        onFloorChanged: context.read<EditProductUnitPriceBandCubit>().updateManualFloorPrice,
      );
    }
  }

  Widget _buildStoreRuleDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          'Khung của cửa hàng đang áp dụng',
          variant: VTextVariant.bodySmall,
          color: dynamicColors.textSecondary,
        ),
        const SizedBox(height: VSpacing.space4),
        _buildDetailRow(
          context,
          'Giá niêm yết',
          margin: _calculateMargin(
            state.suggestion.basePrice,
            state.suggestion.suggestedListBeforeVat ?? 0,
          ),
        ),
        const SizedBox(height: VSpacing.space3),
        _buildDetailRow(
          context,
          'Giá sàn',
          margin: _calculateMargin(
            state.suggestion.basePrice,
            state.suggestion.suggestedFloorBeforeVat ?? 0,
          ),
        ),
        const SizedBox(height: VSpacing.space4),
        Divider(color: dynamicColors.borderDefault),
        const SizedBox(height: VSpacing.space4),
        _buildFinalPriceRow(context, 'Giá niêm yết', state.suggestion.suggestedListBeforeVat),
        const SizedBox(height: VSpacing.space3),
        _buildFinalPriceRow(context, 'Giá sàn', state.suggestion.suggestedFloorBeforeVat),
      ],
    );
  }

  Widget _buildCustomConfigDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          'Nhập cấu hình tính toán',
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: VSpacing.space4),
        _buildMarginInputRow(
          context,
          controller: _customBaseMarginController,
          label: 'Lãi cơ sở',
          value: state.customBaseMargin,
          calculatedPrice: state.calculatedListPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateCustomBaseMargin(val ?? 0),
        ),
        const SizedBox(height: VSpacing.space4),
        _buildMarginInputRow(
          context,
          controller: _customFloorMarginController,
          label: 'Giá sàn (% so với giá cơ sở)',
          value: state.customFloorMargin,
          calculatedPrice: state.calculatedFloorPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateCustomFloorMargin(val ?? 0),
        ),
        const SizedBox(height: VSpacing.space4),
        Divider(color: dynamicColors.borderDefault),
        const SizedBox(height: VSpacing.space4),
        _buildFinalPriceRow(context, 'Giá niêm yết (dự kiến)', state.calculatedListPrice),
        const SizedBox(height: VSpacing.space3),
        _buildFinalPriceRow(context, 'Giá sàn (dự kiến)', state.calculatedFloorPrice),
        const SizedBox(height: VSpacing.space4),
        Container(
          padding: const EdgeInsets.all(VSpacing.space3),
          decoration: BoxDecoration(
            color: dynamicColors.background,
            borderRadius: BorderRadius.circular(VRadius.r4),
            border: Border.all(color: dynamicColors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VIcon(icon: VIcons.info, size: 16, color: dynamicColors.textSecondary),
              const VGap.horizontalSm(),
              Expanded(
                child: VText(
                  'Giá sẽ tự cập nhật khi Giá cơ sở thay đổi.',
                  variant: VTextVariant.bodySmall,
                  color: dynamicColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          'Nhập giá thủ công',
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: VSpacing.space4),
        _buildManualInputRow(
          context,
          controller: _manualListPriceController,
          label: 'Giá niêm yết',
          value: state.manualListPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateManualListPrice(val ?? 0),
        ),
        const SizedBox(height: VSpacing.space4),
        _buildManualInputRow(
          context,
          controller: _manualFloorPriceController,
          label: 'Giá sàn',
          value: state.manualFloorPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateManualFloorPrice(val ?? 0),
        ),
        const SizedBox(height: VSpacing.space4),
        Container(
          padding: const EdgeInsets.all(VSpacing.space3),
          decoration: BoxDecoration(
            color: dynamicColors.background,
            borderRadius: BorderRadius.circular(VRadius.r4),
            border: Border.all(color: dynamicColors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VIcon(icon: VIcons.info, size: 16, color: dynamicColors.textSecondary),
              const VGap.horizontalSm(),
              Expanded(
                child: VText(
                  'Giá sẽ không tự cập nhật khi Giá cơ sở thay đổi.',
                  variant: VTextVariant.bodySmall,
                  color: dynamicColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarginInputRow(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required double? value,
    required int? calculatedPrice,
    required ValueChanged<double?> onChanged,
  }) {
    final priceStr = calculatedPrice != null && calculatedPrice > 0
        ? formatCatalogCurrency(calculatedPrice)
        : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(label, variant: VTextVariant.bodySmall, color: context.vColors.textSecondary),
        const SizedBox(height: VSpacing.space2),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: VTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                suffixText: '%',
                onChanged: (val) => onChanged(double.tryParse(val)),
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            VText(
              '= $priceStr',
              variant: VTextVariant.bodyDefault,
              color: context.vColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualInputRow(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 2, child: VText(label, style: VTypography.bodyDefault)),
        const SizedBox(width: VSpacing.space4),
        Expanded(
          flex: 3,
          child: VMoneyField(
            controller: controller,
            suffixText: 'đ',
            textAlign: TextAlign.right,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, {required String margin}) {
    final dynamicColors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(label, variant: VTextVariant.bodyDefault, color: dynamicColors.textSecondary),
        VText(
          margin,
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFinalPriceRow(BuildContext context, String label, int? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(label, style: VTypography.bodyDefault),
        VText(
          price != null ? formatCatalogCurrency(price) : '—',
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _calculateMargin(num base, num price) {
    if (base == 0 || price == 0) return '—';
    final margin = ((price - base) / base * 100).toStringAsFixed(0);
    return margin.startsWith('-') ? '$margin%' : '+$margin%';
  }
}
