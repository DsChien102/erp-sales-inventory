import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../logic/product_guided_create_cubit.dart';
import '../../logic/product_guided_create_state.dart';
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
          GestureDetector(
            onTap: () => context.read<ProductGuidedCreateCubit>().setStep(2),
            child: Container(
              padding: const EdgeInsets.all(VSpacing.space3),
              decoration: BoxDecoration(
                color: dynamicColors.warningBg,
                borderRadius: BorderRadius.circular(VRadius.r8),
                border: Border.all(color: dynamicColors.warning.withValues(alpha: 0.3)),
              ),
              child: VText(
                'Cần thiết lập đơn vị cơ sở ở bước trước rồi mới nhập được giá cơ sở.',
                variant: VTextVariant.bodyDefault,
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
        VText(
          'Nhập giá cơ sở của sản phẩm. Giá này dùng để tính gợi ý giá bán.',
          variant: VTextVariant.bodySmall,
          color: dynamicColors.textSecondary,
        ),
        const SizedBox(height: VSpacing.space3),
        ProductGuidedFields.buildLabel(
          context,
          'Giá cơ sở ${widget.state.baseUnit.isNotEmpty ? "(${widget.state.baseUnit})" : ""}',
        ),
        VMoneyField(
          key: const Key('input_guided_base_cost'),
          controller: _controller,
          hintText: 'Nhập giá cơ sở',
          suffixText: 'đ',
          textStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          min: 0,
          errorText: widget.state.showValidationErrors ? widget.state.baseCostError : null,
          onChanged: (_) => cubit.updateBaseCost(_controller.text),
        ),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(context, showSkip: true),
      ],
    );
  }
}
