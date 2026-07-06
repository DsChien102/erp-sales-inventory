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
    _controller = TextEditingController(text: widget.state.initialStock);
  }

  @override
  void didUpdateWidget(covariant ProductGuidedStepInventory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.initialStock != _controller.text &&
        widget.state.initialStock != oldWidget.state.initialStock) {
      _controller.text = widget.state.initialStock;
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
          Container(
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
        TextField(
          key: const Key('input_guided_initial_stock'),
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: ProductGuidedFields.buildInputDecoration(
            context,
            '0',
          ).copyWith(
            suffixText: widget.state.baseUnit.isNotEmpty ? widget.state.baseUnit : null,
          ),
          style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateInitialStock,
        ),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
