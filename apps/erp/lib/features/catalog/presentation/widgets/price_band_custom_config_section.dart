import 'package:flutter/material.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class PriceBandCustomConfigSection extends StatelessWidget {
  const PriceBandCustomConfigSection({
    super.key,
    required this.state,
    required this.listController,
    required this.floorController,
    required this.onListChanged,
    required this.onFloorChanged,
  });

  final EditProductUnitPriceBandLoaded state;
  final TextEditingController listController;
  final TextEditingController floorController;
  final ValueChanged<double?> onListChanged;
  final ValueChanged<double?> onFloorChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập cấu hình tính toán',
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ratioInput(
          context,
          controller: listController,
          label: 'Tỷ lệ giá niêm yết',
          calculatedPrice: state.calculatedListPrice,
          onChanged: onListChanged,
        ),
        const SizedBox(height: 16),
        _ratioInput(
          context,
          controller: floorController,
          label: 'Tỷ lệ giá sàn',
          calculatedPrice: state.calculatedFloorPrice,
          onChanged: onFloorChanged,
        ),
        const SizedBox(height: 16),
        Divider(color: colors.borderDefault),
        const SizedBox(height: 16),
        _priceRow(context, 'Giá niêm yết (dự kiến)', state.calculatedListPrice),
        const SizedBox(height: 12),
        _priceRow(context, 'Giá sàn (dự kiến)', state.calculatedFloorPrice),
        const SizedBox(height: 16),
        _note(
          context,
          state.suggestion.basePrice > 0
              ? 'Giá sẽ tự cập nhật khi Giá cơ sở thay đổi.'
              : 'Cấu hình sẽ được lưu và tự tính giá khi có Giá cơ sở.',
        ),
      ],
    );
  }

  Widget _ratioInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required int? calculatedPrice,
    required ValueChanged<double?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VTypography.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: VTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                suffixText: '%',
                onChanged: (value) => onChanged(double.tryParse(value)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              calculatedPrice == null ? '= —' : '= ${formatCatalogCurrency(calculatedPrice)}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(BuildContext context, String label, int? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          price == null ? '—' : formatCatalogCurrency(price),
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _note(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.vColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.vColors.borderDefault),
      ),
      child: Text(message, style: VTypography.bodySmall),
    );
  }
}
