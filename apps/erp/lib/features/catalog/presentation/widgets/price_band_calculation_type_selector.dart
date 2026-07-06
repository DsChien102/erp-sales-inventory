import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/edit_product_unit_price_band_cubit.dart';
import '../bloc/edit_product_unit_price_band_state.dart';

String _formatCurrency(double? amount) {
  if (amount == null) return '—';
  final str = amount.toStringAsFixed(0);
  final formatted = str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$formatted đ';
}

String _formatMargin(double? price, double basePrice) {
  if (price == null || basePrice == 0) return '—';
  final margin = ((price - basePrice) / basePrice * 100).round();
  return '${margin >= 0 ? '+' : ''}$margin%';
}

class PriceBandCalculationTypeSelector extends StatefulWidget {
  const PriceBandCalculationTypeSelector({super.key});

  @override
  State<PriceBandCalculationTypeSelector> createState() => _PriceBandCalculationTypeSelectorState();
}

class _PriceBandCalculationTypeSelectorState extends State<PriceBandCalculationTypeSelector> {
  late TextEditingController _baseMarginCtrl;
  late TextEditingController _floorMarginCtrl;
  late TextEditingController _manualListPriceCtrl;
  late TextEditingController _manualFloorPriceCtrl;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<EditProductUnitPriceBandCubit>();
    final state = cubit.state;
    _baseMarginCtrl = TextEditingController();
    _floorMarginCtrl = TextEditingController();
    _manualListPriceCtrl = TextEditingController();
    _manualFloorPriceCtrl = TextEditingController();

    if (state is EditProductUnitPriceBandLoaded) {
      if (state.customBaseMargin != null) _baseMarginCtrl.text = state.customBaseMargin.toString();
      if (state.customFloorMargin != null) _floorMarginCtrl.text = state.customFloorMargin.toString();
      if (state.manualListPrice != null) _manualListPriceCtrl.text = state.manualListPrice!.toStringAsFixed(0);
      if (state.manualFloorPrice != null) _manualFloorPriceCtrl.text = state.manualFloorPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _baseMarginCtrl.dispose();
    _floorMarginCtrl.dispose();
    _manualListPriceCtrl.dispose();
    _manualFloorPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditProductUnitPriceBandCubit, EditProductUnitPriceBandState>(
      builder: (context, state) {
        if (state is! EditProductUnitPriceBandLoaded) {
          return const SizedBox.shrink();
        }

        final dynamicColors = context.vColors;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: dynamicColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dynamicColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Cách tính',
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildRadioOption(
                    context,
                    title: 'Theo khung giá cửa hàng',
                    subtitle: 'Tự động áp dụng khung giá của cửa hàng.',
                    value: PriceBandCalculationType.storeRule,
                    groupValue: state.selectedType,
                    onChanged: (val) {
                      context.read<EditProductUnitPriceBandCubit>().changeCalculationType(val!);
                    },
                  ),
                  _buildRadioOption(
                    context,
                    title: 'Tự động riêng theo cấu hình',
                    subtitle: 'Tự động tính giá theo cấu hình của sản phẩm.',
                    value: PriceBandCalculationType.customConfig,
                    groupValue: state.selectedType,
                    onChanged: (val) {
                      context.read<EditProductUnitPriceBandCubit>().changeCalculationType(val!);
                    },
                  ),
                  _buildRadioOption(
                    context,
                    title: 'Nhập thủ công',
                    subtitle: 'Tự nhập giá cho đơn vị này.',
                    value: PriceBandCalculationType.manual,
                    groupValue: state.selectedType,
                    onChanged: (val) {
                      context.read<EditProductUnitPriceBandCubit>().changeCalculationType(val!);
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),
            if (state.selectedType == PriceBandCalculationType.storeRule) ...[
              const SizedBox(height: 16),
              _buildStoreRuleDetails(context, state),
            ],
            if (state.selectedType == PriceBandCalculationType.customConfig) ...[
              const SizedBox(height: 16),
              _buildCustomConfigDetails(context, state),
            ],
            if (state.selectedType == PriceBandCalculationType.manual) ...[
              const SizedBox(height: 16),
              _buildManualDetails(context, state),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRadioOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required PriceBandCalculationType value,
    required PriceBandCalculationType groupValue,
    required ValueChanged<PriceBandCalculationType?> onChanged,
    bool isLast = false,
  }) {
    final dynamicColors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<PriceBandCalculationType>(
                    value: value,
                    groupValue: groupValue,
                    onChanged: onChanged,
                    activeColor: dynamicColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: VTypography.bodySmall.copyWith(
                          color: dynamicColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 8),
        if (isLast) const SizedBox(height: 8), // Padding bottom for the last item
      ],
    );
  }

  Widget _buildStoreRuleDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khung của cửa hàng đang áp dụng',
            style: VTypography.bodyDefault.copyWith(
              color: dynamicColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Giá niêm yết',
            _formatMargin(state.suggestion.suggestedListPrice, state.suggestion.basePrice),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Giá sàn',
            _formatMargin(state.suggestion.suggestedFloorPrice, state.suggestion.basePrice),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            'Giá niêm yết',
            _formatCurrency(state.suggestion.suggestedListPrice),
            isBoldValue: false,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Giá sàn',
            _formatCurrency(state.suggestion.suggestedFloorPrice),
            isBoldValue: false,
          ),
          if (!state.suggestion.canSuggest) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: dynamicColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.suggestion.unavailableReason ?? 'Không thể gợi ý giá.',
                    style: VTypography.bodySmall.copyWith(color: dynamicColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomConfigDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhập cấu hình tính toán',
            style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Lãi cơ sở', style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: VTextField(
                  controller: _baseMarginCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffixText: '%',
                  onChanged: (val) {
                    final doubleVal = double.tryParse(val);
                    if (doubleVal != null) {
                      context.read<EditProductUnitPriceBandCubit>().updateCustomBaseMargin(doubleVal);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '= ${_formatCurrency(state.calculatedListPrice)}',
                  style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Giá sàn (% so với giá cơ sở)', style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 140,
                child: VTextField(
                  controller: _floorMarginCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffixText: '%',
                  onChanged: (val) {
                    final doubleVal = double.tryParse(val);
                    if (doubleVal != null) {
                      context.read<EditProductUnitPriceBandCubit>().updateCustomFloorMargin(doubleVal);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '= ${_formatCurrency(state.calculatedFloorPrice)}',
                  style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            'Giá niêm yết (dự kiến)',
            _formatCurrency(state.calculatedListPrice),
            isBoldValue: false,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Giá sàn (dự kiến)',
            _formatCurrency(state.calculatedFloorPrice),
            isBoldValue: false,
          ),
        ],
      ),
    );
  }

  Widget _buildManualDetails(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhập giá thủ công',
            style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2, 
                child: Text('Giá niêm yết', style: VTypography.bodyDefault),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: VTextField(
                  controller: _manualListPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffixText: 'đ',
                  onChanged: (val) {
                    final doubleVal = double.tryParse(val);
                    if (doubleVal != null) {
                      context.read<EditProductUnitPriceBandCubit>().updateManualListPrice(doubleVal);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2, 
                child: Text('Giá sàn', style: VTypography.bodyDefault),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: VTextField(
                  controller: _manualFloorPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffixText: 'đ',
                  onChanged: (val) {
                    final doubleVal = double.tryParse(val);
                    if (doubleVal != null) {
                      context.read<EditProductUnitPriceBandCubit>().updateManualFloorPrice(doubleVal);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: dynamicColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dynamicColors.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: dynamicColors.textSecondary),
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
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, {
    bool isBoldValue = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: context.vColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: VTypography.bodyDefault.copyWith(
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
