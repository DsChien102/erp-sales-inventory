import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

class ProductGuidedStepBaseCost extends StatefulWidget {
  const ProductGuidedStepBaseCost({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  State<ProductGuidedStepBaseCost> createState() => _ProductGuidedStepBaseCostState();
}

class _ProductGuidedStepBaseCostState extends State<ProductGuidedStepBaseCost> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.baseCost);
  }

  @override
  void didUpdateWidget(covariant ProductGuidedStepBaseCost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.baseCost != _controller.text &&
        widget.state.baseCost != oldWidget.state.baseCost) {
      _controller.text = widget.state.baseCost;
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
              'Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được giá vốn cơ sở.',
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
          'Nhập giá vốn cơ sở của sản phẩm. Giá vốn này dùng làm cơ sở để tính toán biên lợi nhuận và gợi ý giá bán.',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space3),
        ProductGuidedFields.buildLabel(
          context,
          'Giá vốn cơ sở ${widget.state.baseUnit.isNotEmpty ? "(${widget.state.baseUnit})" : ""}',
        ),
        TextField(
          key: const Key('input_guided_base_cost'),
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: ProductGuidedFields.buildInputDecoration(
            context,
            'Nhập giá vốn cơ sở',
          ).copyWith(
            suffixText: '₫',
          ),
          style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateBaseCost,
        ),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
