import 'package:flutter/material.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class PriceBandManualSection extends StatelessWidget {
  const PriceBandManualSection({
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
  final ValueChanged<int?> onListChanged;
  final ValueChanged<int?> onFloorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập giá thủ công',
          style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _priceInput(
          label: 'Giá niêm yết',
          controller: listController,
          onChanged: onListChanged,
        ),
        const SizedBox(height: 16),
        _priceInput(
          label: 'Giá sàn',
          controller: floorController,
          onChanged: onFloorChanged,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.vColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.vColors.borderDefault),
          ),
          child: Text(
            'Giá sẽ không tự cập nhật khi Giá cơ sở thay đổi.',
            style: VTypography.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _priceInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
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
}
