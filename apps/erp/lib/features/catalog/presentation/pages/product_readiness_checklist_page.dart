import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/catalog/presentation/pages/product_measurement_units_page.dart';

class ProductReadinessChecklistRouteArgs {
  final ProductReadinessViewDto readinessView;
  final ProductListItemModel product;
  const ProductReadinessChecklistRouteArgs({required this.readinessView, required this.product});
}

class ProductReadinessChecklistPage extends StatelessWidget {
  const ProductReadinessChecklistPage({
    super.key,
    required this.readinessView,
    required this.product,
  });

  final ProductReadinessViewDto readinessView;
  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Scaffold(
      key: const Key('wgt_e02_u03_checklist'),
      backgroundColor: dynamicColors.background,
      appBar: VAppBar(
        title: 'Sẵn sàng vận hành',
        titleStyle: VTypography.headingH3.copyWith(
          color: dynamicColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        subtitle: readinessView.productName,
      ),
      body: ProductReadinessChecklistBody(
        readinessView: readinessView,
        onActionTap: (actionId) {
          if (actionId == 'missing_base_unit') {
            context.push('/products/items/pcc/units', extra: ProductMeasurementUnitsRouteArgs(product: product)).then((_) {
              if (context.mounted) {
                context.pop();
              }
            });
            return;
          }

          VToast.show(
            context,
            title: 'Thao tác',
            message: 'Tính năng ($actionId) đang được xây dựng.',
            type: VToastType.info,
          );
        },
      ),
    );
  }
}
