import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:get_it/get_it.dart';

import '../bloc/edit_product_unit_price_band_cubit.dart';
import '../bloc/edit_product_unit_price_band_state.dart';
import '../widgets/price_band_calculation_type_selector.dart';

String _formatCurrency(double? amount) {
  if (amount == null) return '—';
  final str = amount.toStringAsFixed(0);
  final formatted = str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '$formatted đ';
}

class EditProductUnitPriceBandPage extends StatelessWidget {
  const EditProductUnitPriceBandPage({
    super.key,
    required this.tenantId,
    required this.productId,
    this.productUnitId,
    this.unitName,
  });

  final String tenantId;
  final String productId;
  final String? productUnitId;
  final String? unitName;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider(
      create: (context) => EditProductUnitPriceBandCubit(
        tenantId: tenantId,
        productId: productId,
        productUnitId: productUnitId,
        moduleMediator: GetIt.instance<ICatalogModule>(),
      )..loadInitialData(),
      child: BlocListener<EditProductUnitPriceBandCubit, EditProductUnitPriceBandState>(
        listener: (context, state) {
          if (state is EditProductUnitPriceBandSuccess) {
            Navigator.of(context).pop(true);
          } else if (state is EditProductUnitPriceBandLoaded && state.error != null) {
            VToast.show(
              context, 
              title: 'Lỗi', 
              message: state.error!,
              type: VToastType.danger,
            );
          }
        },
        child: Scaffold(
          backgroundColor: dynamicColors.background,
          appBar: VAppBar(
            title: 'Khung giá bán',
            titleStyle: VTypography.headingH3.copyWith(fontWeight: FontWeight.bold),
            subtitle: unitName ?? 'Đơn vị cơ sở',
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: dynamicColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: BlocBuilder<EditProductUnitPriceBandCubit, EditProductUnitPriceBandState>(
            builder: (context, state) {
              if (state is EditProductUnitPriceBandLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is! EditProductUnitPriceBandLoaded) {
                return const Center(child: Text('Lỗi tải dữ liệu'));
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBasePriceCard(context, state),
                          const SizedBox(height: 16),
                          const PriceBandCalculationTypeSelector(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBasePriceCard(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(12),
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
                style: VTypography.bodyDefault.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '1 ${unitName ?? 'Đơn vị cơ sở'}',
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            _formatCurrency(state.suggestion.basePrice),
            style: VTypography.headingH4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, EditProductUnitPriceBandLoaded state) {
    final dynamicColors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        border: Border(
          top: BorderSide(color: dynamicColors.borderDefault),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: VButton(
                label: 'Lưu',
                variant: VButtonVariant.primary,
                isLoading: state.isSubmitting,
                onPressed: state.canSubmit ? () => context.read<EditProductUnitPriceBandCubit>().submit() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
