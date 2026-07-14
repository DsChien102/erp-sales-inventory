import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

class ProductGuidedStepInventory extends StatefulWidget {
  const ProductGuidedStepInventory({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  State<ProductGuidedStepInventory> createState() => _ProductGuidedStepInventoryState();
}

class _ProductGuidedStepInventoryState extends State<ProductGuidedStepInventory> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.basicStockQuantityBase);
  }

  @override
  void didUpdateWidget(covariant ProductGuidedStepInventory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.basicStockQuantityBase != _controller.text &&
        widget.state.basicStockQuantityBase != oldWidget.state.basicStockQuantityBase) {
      _controller.text = widget.state.basicStockQuantityBase;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    if (widget.state.baseUnit.trim().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => context.read<ProductGuidedCreateCubit>().setStep(2),
            child: Container(
              padding: const EdgeInsets.all(VSpacing.space3),
              decoration: BoxDecoration(
                color: dynamicColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được tồn kho khởi tạo.',
                style: VTypography.bodyDefault.copyWith(
                  color: dynamicColors.warning,
                ),
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
          'Nhập số lượng tồn kho ban đầu của sản phẩm. Tồn kho này sẽ được ghi nhận vào kho mặc định.',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space3),
        ProductGuidedFields.buildLabel(
          context,
          'Tồn khởi tạo ${widget.state.baseUnit.isNotEmpty ? "(${widget.state.baseUnit})" : ""}',
        ),
        VNumberField(
          key: const Key('input_guided_basic_stock_quantity_base'),
          controller: _controller,
          hintText: '0',
          suffixText: widget.state.baseUnit.isNotEmpty ? widget.state.baseUnit : null,
          textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          allowDecimal: false,
          allowNegative: true,
          min: 0,
          isRequired: false,
          errorText: widget.state.showValidationErrors
              ? widget.state.basicStockQuantityBaseError
              : null,
          onChanged: (_) => cubit.updateBasicStockQuantityBase(_controller.text),
        ),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
