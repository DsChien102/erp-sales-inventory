import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
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
}
