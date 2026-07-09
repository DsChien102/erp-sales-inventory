import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_design_system/design_system.dart';
import '../../presentation.dart';
import '../bloc/product_guided_create_cubit.dart';
import '../bloc/product_guided_create_state.dart';
import 'custom_fields/product_custom_field_input_widget.dart';

class ProductGuidedStepCustomFields extends StatelessWidget {
  const ProductGuidedStepCustomFields({
    super.key,
    required this.state,
    required this.group,
  });

  final ProductGuidedCreateState state;
  final CustomFieldGroupConfigDto group;

  @override
  Widget build(BuildContext context) {
    if (group.fields.isEmpty) {
      return const Center(
        child: Text('Không có trường thông tin nào được cấu hình.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...group.fields.map((field) {
          final input = state.customFieldValues[field.fieldId] ??
              ProductCustomFieldValueInput(fieldId: field.fieldId);
          final errorText = state.customFieldValidationErrors[field.fieldId];

          // Map from CustomFieldDefinitionDto to ProductCustomFieldValueFieldDto
          final fieldDto = ProductCustomFieldValueFieldDto(
            fieldId: field.fieldId,
            groupId: field.groupId,
            name: field.name,
            fieldType: field.fieldType.name,
            isRequired: field.isRequired,
            isActive: field.status == CustomFieldConfigStatus.active,
            options: field.options,
          );

          return ProductCustomFieldInputWidget(
            field: fieldDto,
            input: input,
            errorText: errorText,
            onChanged: (newInput) {
              context.read<ProductGuidedCreateCubit>().updateCustomFieldValue(newInput);
            },
          );
        }),
        const SizedBox(height: VSpacing.space4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              onPressed: () {
                context.read<ProductGuidedCreateCubit>().prevStep();
              },
            ),
            const SizedBox(width: VSpacing.space2),
            VButton(
              label: 'Tiếp tục',
              onPressed: () {
                context.read<ProductGuidedCreateCubit>().nextStep();
              },
            ),
          ],
        ),
      ],
    );
  }
}
