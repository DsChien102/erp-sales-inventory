import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'product_guided_fields.dart';

class ProductGuidedStepBaseUnit extends StatelessWidget {
  const ProductGuidedStepBaseUnit({
    super.key,
    required this.state,
  });

  final ProductGuidedCreateState state;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Đơn vị gốc để tính tồn/giá. Có thể bổ sung sau.',
          style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
        ),
        const SizedBox(height: VSpacing.space3),
        ProductGuidedFields.buildLabel(context, 'Đơn vị cơ sở'),
        TextField(
          key: const Key('input_guided_base_unit'),
          controller: TextEditingController(text: state.baseUnit)
            ..selection = TextSelection.fromPosition(TextPosition(offset: state.baseUnit.length)),
          decoration: ProductGuidedFields.buildInputDecoration(
            context,
            'Ví dụ: Hộp, Chai, Bao...',
          ),
          style: VTypography.bodyDefault.copyWith(color: dynamicColors.textPrimary),
          onChanged: cubit.updateBaseUnit,
        ),
        const SizedBox(height: VSpacing.space2),
        const SizedBox(height: VSpacing.space4),
        ProductGuidedFields.buildNavigationButtons(
          context,
          showSkip: true,
          showNext: false,
        ),
      ],
    );
  }
}
