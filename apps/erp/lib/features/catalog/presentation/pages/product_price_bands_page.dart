import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import 'edit_product_unit_price_band_page.dart';

class ProductPriceBandsRouteArgs {
  final String productId;
  final String productName;

  ProductPriceBandsRouteArgs({
    required this.productId,
    this.productName = '',
  });
}

class ProductPriceBandsPage extends StatelessWidget {
  const ProductPriceBandsPage({
    super.key,
    required this.args,
  });

  final ProductPriceBandsRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductPriceBandsCubit(
        moduleMediator: GetIt.instance<ICatalogModule>(),
        executionContext: GetIt.instance<IExecutionContext>(),
        productId: args.productId,
      )..loadPriceBands(),
      child: BlocBuilder<ProductPriceBandsCubit, ProductPriceBandsState>(
        builder: (context, state) {
          final isLoading = state is ProductPriceBandsInitial || state is ProductPriceBandsLoading;

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
                : state is ProductPriceBandsFailure
                ? Center(child: Text(state.error))
                : state is ProductPriceBandsLoaded
                ? _buildContent(context, state.data)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductUnitPriceBandsDto data) {
    if (data.rows.isEmpty) {
      return const Center(child: Text('Chưa có đơn vị bán nào.'));
    }

    final dynamicColors = context.vColors;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: data.rows.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ĐƠN VỊ & KHUNG GIÁ BÁN',
              style: VTypography.caption.copyWith(
                color: dynamicColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        
        if (index == data.rows.length + 1) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Thay đổi có áp dụng cho cửa hàng và kênh phân phối.',
              style: VTypography.bodySmall.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
          );
        }

        final row = data.rows[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _buildUnitCard(context, row, data.productId),
        );
      },
    );
  }

  Widget _buildUnitCard(BuildContext context, ProductUnitPriceBandRowDto row, String productId) {
    final dynamicColors = context.vColors;

    if (!row.isActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dynamicColors.background,
          border: Border.all(color: dynamicColors.borderDefault),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.unitName,
                  style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Đơn vị ngừng hoạt động',
                  style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
                ),
              ],
            ),
            VBadge(label: 'Không hoạt động', status: VBadgeStatus.locked, isSmall: true),
          ],
        ),
      );
    }

    final hasPrice = !row.isMissing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        border: Border.all(color: dynamicColors.borderDefault),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.unitName,
                style: VTypography.bodyDefault.copyWith(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () async {
                  final didChange = await context.push<bool>(
                    '/products/items/pcc/price-bands/edit',
                    extra: EditProductUnitPriceBandRouteArgs(
                      row: row,
                      productId: productId,
                      productName: args.productName,
                    ),
                  );
                  if (didChange == true && context.mounted) {
                    context.read<ProductPriceBandsCubit>().loadPriceBands();
                  }
                },
                child: Text(
                  hasPrice ? 'Sửa' : 'Thiết lập',
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.success,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (row.isBaseUnit) ...[
            const SizedBox(height: 4),
            Text(
              'Đơn vị cơ sở',
              style: VTypography.bodySmall.copyWith(color: dynamicColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          _buildPriceRow(context, 'Giá cơ sở', null), // Assuming basePrice isn't in row DTO right now
          const SizedBox(height: 8),
          _buildPriceRow(context, 'Giá niêm yết', row.listPrice),
          const SizedBox(height: 8),
          _buildPriceRow(context, 'Giá sàn', row.floorPrice),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: VTypography.bodyDefault.copyWith(
            color: context.vColors.textSecondary,
          ),
        ),
        Text(
          price != null ? '${price.toStringAsFixed(0)} đ' : '—',
          style: VTypography.bodyDefault.copyWith(
            color: context.vColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
