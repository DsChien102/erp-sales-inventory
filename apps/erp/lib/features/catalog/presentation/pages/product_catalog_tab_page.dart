import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// Slice #1 shell: tab Sản phẩm trước khi có danh sách (EPIC-01 / slice #4).
class ProductCatalogTabPage extends StatelessWidget {
  const ProductCatalogTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      key: const Key('wgt_e02_u01_products_tab'),
      backgroundColor: dynamicColors.background,
      appBar: VAppBar(
        title: 'Sản phẩm',
        titleStyle: VTypography.headingH4.copyWith(
          color: dynamicColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        showBackButton: false,
      ),
      body: Center(
        child: VEmptyState(
          iconData: Icons.inventory_2_outlined,
          title: 'Chưa có sản phẩm',
          description:
              'Danh sách sản phẩm sẽ có ở slice tiếp theo. Bạn có thể tạo sản phẩm mới ngay bây giờ.',
          actionLabel: 'Tạo sản phẩm',
          actionLeadingIcon: const Icon(Icons.add, size: 18),
          onActionPressed: () => context.push('/products/items/new'),
        ),
      ),
      floatingActionButton: VFloatingActionButton(
        key: const Key('btn_create_product'),
        iconData: Icons.add,
        onTap: () => context.push('/products/items/new'),
        backgroundColor: dynamicColors.success,
      ),
    );
  }
}
