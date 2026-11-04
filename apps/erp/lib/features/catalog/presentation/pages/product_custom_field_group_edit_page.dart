import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/custom_field_repository.dart';
import '../../data/models.dart';
import '../../logic/product_custom_field_group_edit_cubit.dart';
import '../../logic/product_custom_field_group_edit_state.dart';
import '../widgets/custom_fields/product_custom_field_input_widget.dart';
import '../widgets/product_form_bottom_bar.dart';

class ProductCustomFieldGroupEditRouteArgs {
  const ProductCustomFieldGroupEditRouteArgs({
    required this.productId,
    required this.productName,
    required this.groupId,
  });

  final String productId;
  final String productName;
  final String groupId;
}

class ProductCustomFieldGroupEditPage extends StatelessWidget {
  const ProductCustomFieldGroupEditPage({
    super.key,
    required this.args,
  });

  final ProductCustomFieldGroupEditRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductCustomFieldGroupEditCubit(
        customFieldRepository: GetIt.I<CustomFieldRepository>(),
      )..loadGroup(args.productId, args.groupId),
      child: BlocConsumer<ProductCustomFieldGroupEditCubit, ProductCustomFieldGroupEditState>(
        listener: (context, state) {
          if (state is ProductCustomFieldGroupEditSuccess) {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Lưu thông tin thành công',
              type: VToastType.success,
            );
            context.pop();
          } else if (state is ProductCustomFieldGroupEditLoaded && state.error != null) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.error!,
              type: VToastType.danger,
            );
          }
        },
        builder: (context, state) {
          if (state is ProductCustomFieldGroupEditInitial ||
              state is ProductCustomFieldGroupEditLoading) {
            return const VPageScaffold(
              title: 'Trường thông tin',
              showBackButton: true,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProductCustomFieldGroupEditLoaded) {
            return VPageScaffold(
              title: state.group.name,
              titleStyle: VTypography.headingH3.copyWith(fontWeight: FontWeight.bold),
              subtitle: args.productName,
              centerTitle: false,
              leading: IconButton(
                icon: const VIcon(icon: VIcons.arrowBack),
                onPressed: () => context.pop(),
              ),
              body: state.group.fields.isEmpty
                  ? const Center(child: VText('Không có trường thông tin nào được cấu hình.'))
                  : ListView(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                            top: VSpacing.space4,
                            left: VSpacing.space4,
                            right: VSpacing.space4,
                          ),
                          decoration: BoxDecoration(
                            color: context.vColors.surface,
                            borderRadius: BorderRadius.circular(VRadius.r12),
                            border: Border.all(color: context.vColors.borderDefault),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: state.group.fields.map((field) {
                              final input =
                                  state.inputs[field.fieldId] ??
                                  ProductCustomFieldValueInput(fieldId: field.fieldId);
                              final errorText = state.validationErrors[field.fieldId];

                              return ProductCustomFieldInputWidget(
                                field: field,
                                input: input,
                                errorText: errorText,
                                onChanged: (newInput) {
                                  context.read<ProductCustomFieldGroupEditCubit>().updateInput(
                                    newInput,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
              bottomBar: state.group.fields.every((field) => !field.isActive)
                  ? null
                  : ProductFormBottomBar(
                      onCancel: () => context.pop(),
                      isLoading: state.isSubmitting,
                      saveEnabled: state.hasChanges,
                      onSave: () => context.read<ProductCustomFieldGroupEditCubit>().submit(
                        args.productId,
                      ),
                    ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
