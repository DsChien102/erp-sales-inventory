import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/price_band_calculation_type_selector.dart';

class EditProductUnitPriceBandRouteArgs {
  final ProductUnitPriceBandRowDto row;
  final String productId;
  final String productName;

  EditProductUnitPriceBandRouteArgs({
    required this.row,
    required this.productId,
    this.productName = '',
  });
}

class EditProductUnitPriceBandPage extends StatelessWidget {
  const EditProductUnitPriceBandPage({
    super.key,
    required this.args,
  });

  final EditProductUnitPriceBandRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProductUnitPriceBandCubit(
        moduleMediator: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
        productId: args.productId,
        productUnitId: args.row.productUnitId,
      )..loadInitialData(),
      child: BlocConsumer<EditProductUnitPriceBandCubit, EditProductUnitPriceBandState>(
        listener: (context, state) {
          if (state is EditProductUnitPriceBandSuccess) {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Đã cập nhật khung giá bán.',
              type: VToastType.success,
            );
            context.pop(true); // Return true to signal refresh
          } else if (state is EditProductUnitPriceBandLoaded && state.error != null) {
            if (state.error == 'WARNING_REQUIRE_ACK') {
              _showWarningAckDialog(context);
            } else {
              VToast.show(
                context,
                title: 'Lỗi',
                message: state.error!,
                type: VToastType.danger,
              );
            }
          }
        },
        builder: (context, state) {
          final isLoading =
              state is EditProductUnitPriceBandInitial || state is EditProductUnitPriceBandLoading;
          final isSubmitting = state is EditProductUnitPriceBandLoaded && state.isSubmitting;
          final canSubmit = state is EditProductUnitPriceBandLoaded && state.canSubmit;

          return Scaffold(
            appBar: VAppBar(
              title: 'Khung giá bán',
              titleStyle: VTypography.headingH3.copyWith(fontWeight: FontWeight.bold),
              subtitle: args.productName.isNotEmpty ? args.productName : null,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state is EditProductUnitPriceBandLoaded) ...[
                            _buildTopCard(context, state),
                            const SizedBox(height: 16),
                            const PriceBandCalculationTypeSelector(),
                          ],
                        ],
                      ),
                    ),
                  ),
            bottomNavigationBar: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.vColors.surface,
                  border: Border(
                    top: BorderSide(color: context.vColors.borderDefault),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Hủy',
                        variant: VButtonVariant.secondary,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: VButton(
                        label: 'Lưu thay đổi',
                        variant: VButtonVariant.primary,
                        onPressed: canSubmit
                            ? () => context.read<EditProductUnitPriceBandCubit>().save()
                            : null,
                        isLoading: isSubmitting,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giá vốn cơ sở',
                style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '1 ${args.row.unitName.toLowerCase()}',
                style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
              ),
            ],
          ),
          Text(
            state.suggestion.basePrice > 0
                ? '${state.suggestion.basePrice.toStringAsFixed(0)} đ'
                : '—',
            style: VTypography.headingH4.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showWarningAckDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cảnh báo'),
          content: const Text(
            'Khung giá bạn thiết lập có thể vi phạm biên lợi nhuận hoặc giá sàn thấp hơn giá vốn. Bạn có chắc chắn muốn lưu?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<EditProductUnitPriceBandCubit>().save(
                  confirmAcknowledgeWarnings: true,
                );
              },
              child: const Text('Tiếp tục lưu'),
            ),
          ],
        );
      },
    );
  }
}
