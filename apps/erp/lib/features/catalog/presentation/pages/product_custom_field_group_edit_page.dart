import 'package:erp/features/catalog/presentation/bloc/product_custom_field_group_edit_cubit.dart';
import 'package:erp/features/catalog/presentation/bloc/product_custom_field_group_edit_state.dart';
import 'package:erp/features/catalog/presentation/widgets/custom_fields/product_custom_field_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';

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
        context: GetIt.I<IExecutionContext>(),
        catalogModule: GetIt.I<ICatalogModule>(),
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProductCustomFieldGroupEditLoaded) {
            return Scaffold(
              appBar: VAppBar(
                title: state.group.name,
                titleStyle: VTypography.headingH3.copyWith(fontWeight: FontWeight.bold),
                subtitle: args.productName,
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              body: state.group.fields.isEmpty
                  ? const Center(child: Text('Không có trường thông tin nào được cấu hình.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.vColors.surface,
                            borderRadius: BorderRadius.circular(12),
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
              bottomNavigationBar: state.group.fields.every((field) => !field.isActive)
                  ? null
                  : Container(
                      decoration: BoxDecoration(
                        color: context.vColors.surface,
                        border: Border(
                          top: BorderSide(color: context.vColors.borderDefault),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: VButton(
                                  label: 'Huỷ',
                                  variant: VButtonVariant.secondary,
                                  foregroundColor: context.vColors.textPrimary,
                                  onPressed: () => context.pop(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: VButton(
                                  label: 'Lưu thay đổi',
                                  variant: VButtonVariant.primary,
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => context.read<ProductCustomFieldGroupEditCubit>().submit(
                                          args.productId,
                                        ),
                                  isLoading: state.isSubmitting,
                                ),
                              ),
                            ],
                          ),
                        ),
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
