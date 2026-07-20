import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/dashed_border_container.dart';
import '../widgets/product_form_bottom_bar.dart';
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
                : state is ProductPriceBandsFailure
                ? Center(child: VText(state.error))
                : state is ProductPriceBandsMissingBaseUnit
                ? _buildMissingBaseUnit(context)
                : state is ProductPriceBandsLoaded
                ? _buildContent(context, state.data)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildMissingBaseUnit(BuildContext context) {
    final dynamicColors = context.vColors;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.space4),
              child: DashedBorderContainer(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: VTypography.bodyDefault.copyWith(
                          color: dynamicColors.textPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'Cần thiết lập '),
                          TextSpan(
                            text: 'đơn vị cơ sở',
                            style: VTypography.bodyDefault.copyWith(
                              color: dynamicColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' cho sản phẩm trước khi thiết lập khung giá bán.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VText(
                      'Khung giá bán được tính theo đơn vị cơ sở của sản phẩm.',
                      variant: VTextVariant.bodySmall,
                      color: dynamicColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ProductFormBottomBar(
          onCancel: () => context.pop(),
          saveEnabled: false,
          onSave: null,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ProductUnitPriceBandsDto data) {
    if (data.rows.isEmpty) {
      return const Center(child: VText('Chưa có đơn vị bán nào.'));
    }

    final dynamicColors = context.vColors;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: data.rows.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: VText(
              'ĐƠN VỊ & KHUNG GIÁ BÁN',
              variant: VTextVariant.caption,
              color: dynamicColors.textSecondary,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }

        if (index == data.rows.length + 1) {
          return Padding(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: VText(
              'Thay đổi có áp dụng cho cửa hàng và kênh phân phối.',
              variant: VTextVariant.bodySmall,
              color: dynamicColors.textSecondary,
            ),
          );
        }

        final row = data.rows[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _buildUnitCard(context, row, data),
        );
      },
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    ProductUnitPriceBandRowDto row,
    ProductUnitPriceBandsDto data,
  ) {
    final productId = data.productId;
    final dynamicColors = context.vColors;

    if (!row.isActive) {
      return Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: dynamicColors.background,
          border: Border.all(color: dynamicColors.borderDefault),
          borderRadius: BorderRadius.circular(VRadius.r8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  row.unitName,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                VText(
                  'Đơn vị ngừng hoạt động',
                  variant: VTextVariant.bodySmall,
                  color: dynamicColors.textSecondary,
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
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        border: Border.all(color: dynamicColors.borderDefault),
        borderRadius: BorderRadius.circular(VRadius.r8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                row.unitName,
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                child: VText(
                  hasPrice ? 'Sửa' : 'Thiết lập',
                  variant: VTextVariant.bodyDefault,
                  color: dynamicColors.success,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
          if (row.isBaseUnit) ...[
            const SizedBox(height: VSpacing.space1),
            VText(
              'Đơn vị cơ sở',
              variant: VTextVariant.bodySmall,
              color: dynamicColors.textSecondary,
            ),
          ],
          const SizedBox(height: VSpacing.space4),
          _buildPriceRow(context, 'Giá cơ sở', row.basePrice ?? data.basePrice),
          const SizedBox(height: VSpacing.space2),
          _buildPriceRow(context, 'Giá niêm yết', row.listBeforeVat),
          const SizedBox(height: VSpacing.space2),
          _buildPriceRow(context, 'Giá sàn', row.floorBeforeVat),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, num? price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: context.vColors.textSecondary,
        ),
        VText(
          price != null ? formatCatalogCurrency(price) : '—',
          variant: VTextVariant.bodyDefault,
          color: context.vColors.textPrimary,
        ),
      ],
    );
  }
}
