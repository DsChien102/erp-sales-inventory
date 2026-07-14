import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dynamicColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                    child: Text(
                      'Cách tính',
                      style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildOption(
                    context,
                    title: 'Theo khung giá cửa hàng',
                    subtitle: 'Tự động áp dụng khung giá của hàng.',
                    value: PriceBandCalculationType.storeRule,
                    groupValue: state.selectedType,
                    onChanged: (val) => _changeType(context, val!),
                  ),
                  _buildOption(
                    context,
                    title: 'Tự động riêng theo cấu hình',
                    subtitle: 'Tự động tính giá theo cấu hình của sản phẩm.',
                    value: PriceBandCalculationType.customConfig,
                    groupValue: state.selectedType,
                    onChanged: (val) => _changeType(context, val!),
                  ),
                  _buildOption(
                    context,
                    title: 'Nhập thủ công',
                    subtitle: 'Tự nhập giá cho đơn vị này.',
                    value: PriceBandCalculationType.manual,
                    groupValue: state.selectedType,
                    onChanged: (val) => _changeType(context, val!),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: dynamicColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dynamicColors.borderDefault),
              ),
              padding: const EdgeInsets.all(16),
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

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required PriceBandCalculationType value,
    required PriceBandCalculationType groupValue,
    required ValueChanged<PriceBandCalculationType?> onChanged,
  }) {
    final dynamicColors = context.vColors;
    return Material(
      color: Colors.transparent,
      child: RadioListTile<PriceBandCalculationType>(
        title: Text(
          title,
          style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        activeColor: dynamicColors.success,
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context, EditProductUnitPriceBandLoaded state) {
    if (state.selectedType == PriceBandCalculationType.storeRule) {
      return _buildStoreRuleDetails(context, state);
    } else if (state.selectedType == PriceBandCalculationType.customConfig) {
      return _buildCustomConfigDetails(context, state);
    } else {
      return _buildManualDetails(context, state);
    }
  }

  Widget _buildStoreRuleDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khung của cửa hàng đang áp dụng',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context,
          'Giá niêm yết',
          margin: _calculateMargin(
            state.suggestion.basePrice,
            state.suggestion.suggestedListBeforeVat ?? 0,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          'Giá sàn',
          margin: _calculateMargin(
            state.suggestion.basePrice,
            state.suggestion.suggestedFloorBeforeVat ?? 0,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: dynamicColors.borderDefault),
        const SizedBox(height: 16),
        _buildFinalPriceRow(context, 'Giá niêm yết', state.suggestion.suggestedListBeforeVat),
        const SizedBox(height: 12),
        _buildFinalPriceRow(context, 'Giá sàn', state.suggestion.suggestedFloorBeforeVat),
      ],
    );
  }

  Widget _buildCustomConfigDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập cấu hình tính toán',
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildMarginInputRow(
          context,
          controller: _customBaseMarginController,
          label: 'Lãi cơ sở',
          value: state.customBaseMargin,
          calculatedPrice: state.calculatedListPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateCustomBaseMargin(val ?? 0),
        ),
        const SizedBox(height: 16),
        _buildMarginInputRow(
          context,
          controller: _customFloorMarginController,
          label: 'Giá sàn (% so với giá cơ sở)',
          value: state.customFloorMargin,
          calculatedPrice: state.calculatedFloorPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateCustomFloorMargin(val ?? 0),
        ),
        const SizedBox(height: 16),
        Divider(color: dynamicColors.borderDefault),
        const SizedBox(height: 16),
        _buildFinalPriceRow(context, 'Giá niêm yết (dự kiến)', state.calculatedListPrice),
        const SizedBox(height: 12),
        _buildFinalPriceRow(context, 'Giá sàn (dự kiến)', state.calculatedFloorPrice),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dynamicColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: dynamicColors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: dynamicColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Giá sẽ tự cập nhật khi Giá cơ sở thay đổi.',
                  style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
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
        Text(
          'Nhập giá thủ công',
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildManualInputRow(
          context,
          controller: _manualListPriceController,
          label: 'Giá niêm yết',
          value: state.manualListPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateManualListPrice(val ?? 0),
        ),
        const SizedBox(height: 16),
        _buildManualInputRow(
          context,
          controller: _manualFloorPriceController,
          label: 'Giá sàn',
          value: state.manualFloorPrice,
          onChanged: (val) =>
              context.read<EditProductUnitPriceBandCubit>().updateManualFloorPrice(val ?? 0),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dynamicColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: dynamicColors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: dynamicColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Giá sẽ không tự cập nhật khi Giá cơ sở thay đổi.',
                  style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
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
        Text(label, style: VTypography.bodySmall.copyWith(color: context.vColors.textSecondary)),
        const SizedBox(height: 8),
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
            const SizedBox(width: 12),
            Text(
              '= $priceStr',
              style: VTypography.bodyDefault.copyWith(color: context.vColors.textSecondary),
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
        Expanded(flex: 2, child: Text(label, style: VTypography.bodyDefault)),
        const SizedBox(width: 16),
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
        Text(label, style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary)),
        Text(margin, style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFinalPriceRow(BuildContext context, String label, int? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VTypography.bodyDefault),
        Text(
          price != null ? formatCatalogCurrency(price) : '—',
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
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
