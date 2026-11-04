import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models.dart';
import '../../data/product_price_repository.dart';
import '../widgets/price_band_calculation_type_selector.dart';
import '../widgets/product_form_bottom_bar.dart';
import '../widgets/price_band_overwrite_dialog.dart';

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
      create: (context) =>
          EditProductUnitPriceBandCubit(
            productPriceRepository: GetIt.instance<ProductPriceRepository>(),
            productId: args.productId,
            productUnitId: args.row.productUnitId,
          )..loadInitialData(
            isNewPriceBand: args.row.isMissing,
            currentSourceType: args.row.sourceType,
            currentListAfterVat: args.row.listAfterVat,
            currentFloorAfterVat: args.row.floorAfterVat,
            currentListMarkupRatio: args.row.listMarkupRatio,
            currentFloorMarkupRatio: args.row.floorMarkupRatio,
          ),
      child: BlocConsumer<EditProductUnitPriceBandCubit, EditProductUnitPriceBandState>(
        listener: (context, state) async {
          if (state is EditProductUnitPriceBandSuccess) {
            VToast.show(
              context,
              title: 'Thành công',
              message: 'Đã cập nhật khung giá bán.',
              type: VToastType.success,
            );
            context.pop(true); // Return true to signal refresh
          } else if (state is EditProductUnitPriceBandNeedsOverwriteConfirm) {
            final confirmed = await showPriceBandOverwriteDialog(
              context,
              existingListAfterVat: state.existingListAfterVat,
              existingFloorAfterVat: state.existingFloorAfterVat,
            );
            if (confirmed == true && context.mounted) {
              context.read<EditProductUnitPriceBandCubit>().confirmOverwrite();
            } else if (context.mounted) {
              context.read<EditProductUnitPriceBandCubit>().cancelOverwrite();
            }
          } else if (state is EditProductUnitPriceBandLoaded && state.error != null) {
            VToast.show(
              context,
              title: 'Lỗi',
              message: state.error!,
              type: VToastType.danger,
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state is EditProductUnitPriceBandInitial || state is EditProductUnitPriceBandLoading;
          final isSubmitting = state is EditProductUnitPriceBandLoaded && state.isSubmitting;
          final canSubmit = state is EditProductUnitPriceBandLoaded && state.canSubmit;

          return VPageScaffold(
            title: 'Khung giá bán',
            titleStyle: VTypography.headingH3.copyWith(fontWeight: FontWeight.bold),
            subtitle: args.productName.isNotEmpty ? args.productName : null,
            centerTitle: false,
            leading: IconButton(
              icon: const VIcon(icon: VIcons.arrowBack),
              onPressed: () => context.pop(),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state is EditProductUnitPriceBandLoaded) ...[
                            _buildTopCard(context, state),
                            const SizedBox(height: VSpacing.space4),
                            PriceBandCalculationTypeSelector(row: args.row),
                          ],
                        ],
                      ),
                    ),
                  ),
            bottomBar: ProductFormBottomBar(
              saveKey: const Key('btn_price_band_save'),
              onCancel: () => context.pop(),
              isLoading: isSubmitting,
              saveEnabled: canSubmit,
              onSave: () => context.read<EditProductUnitPriceBandCubit>().save(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(VRadius.r8),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Giá cơ sở',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: VSpacing.space1),
              VText(
                '1 ${args.row.unitName.toLowerCase()}',
                variant: VTextVariant.bodySmall,
                color: dynamicColors.textSecondary,
              ),
            ],
          ),
          VText(
            state.suggestion.basePrice > 0
                ? formatCatalogCurrency(state.suggestion.basePrice)
                : '—',
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
