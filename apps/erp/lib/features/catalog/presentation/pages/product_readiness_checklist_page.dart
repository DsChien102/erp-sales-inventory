import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_domain/domain.dart';
import '../utils/resolve_priority_custom_field_group.dart';
import 'product_measurement_units_page.dart';
import 'product_stock_adjustment_page.dart';
import 'product_manual_base_price_page.dart';
import 'product_price_bands_page.dart';
import 'product_custom_field_group_edit_page.dart';

class ProductReadinessChecklistRouteArgs {
  final ProductReadinessViewDto readinessView;
  final ProductListItemModel product;
  final List<CustomFieldGroupCardDto> customFieldGroupCards;

  const ProductReadinessChecklistRouteArgs({
    required this.readinessView,
    required this.product,
    this.customFieldGroupCards = const [],
  });
}

class ProductReadinessChecklistPage extends StatelessWidget {
  const ProductReadinessChecklistPage({
    super.key,
    required this.readinessView,
    required this.product,
    this.customFieldGroupCards = const [],
  });

  final ProductReadinessViewDto readinessView;
  final ProductListItemModel product;
  final List<CustomFieldGroupCardDto> customFieldGroupCards;

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      key: const Key('wgt_e02_u03_checklist'),

      title: 'Sẵn sàng vận hành',
      body: ProductReadinessChecklistBody(
        readinessView: readinessView,
        onActionTap: (actionId) {
          // Chỉ chặn các mục phụ thuộc UOM. Custom field / ảnh độc lập đơn vị cơ sở.
          const actionsRequiringBaseUnit = {
            'missing_stock',
            'missing_price',
            'missing_price_band',
          };
          final hasMissingBaseUnit = readinessView.readinessSummary.blockers.any(
            (b) => b.code == 'missing_base_unit',
          );

          if (hasMissingBaseUnit && actionsRequiringBaseUnit.contains(actionId)) {
            VToast.show(
              context,
              title: 'Yêu cầu',
              message: 'Vui lòng thiết lập đơn vị cơ sở trước.',
              type: VToastType.warning,
            );
            return;
          }

          void popOnReturn(dynamic _) {
            if (context.mounted) {
              context.pop();
            }
          }

          if (actionId == 'missing_base_unit') {
            context
                .push(
                  '/products/items/pcc/measurement-units',
                  extra: ProductMeasurementUnitsRouteArgs(product: product),
                )
                .then(popOnReturn);
            return;
          }

          if (actionId == 'missing_image') {
            context
                .push(
                  '/products/items/pcc/images-maintenance',
                  extra: product,
                )
                .then(popOnReturn);
            return;
          }

          if (actionId == 'missing_stock') {
            context
                .push(
                  '/products/items/pcc/stock',
                  extra: ProductStockAdjustmentRouteArgs(product: product),
                )
                .then(popOnReturn);
            return;
          }

          if (actionId == 'missing_price') {
            context
                .push(
                  '/products/items/pcc/manual-base-price',
                  extra: ProductManualBasePriceRouteArgs(
                    product: product,
                    basePriceCard: ProductBasePriceCardDto(
                      mode: BasePriceMode.manual,
                      sourceLabel: 'Nhập thủ công',
                      baseUnitName: product.baseUnit,
                    ),
                  ),
                )
                .then(popOnReturn);
            return;
          }

          if (actionId == 'missing_price_band') {
            context
                .push(
                  '/products/items/pcc/price-bands',
                  extra: ProductPriceBandsRouteArgs(
                    productId: product.id,
                    productName: product.name,
                  ),
                )
                .then(popOnReturn);
            return;
          }

          if (actionId == 'missing_required_custom_fields') {
            final groupId = resolvePriorityCustomFieldGroupId(customFieldGroupCards);
            if (groupId == null) {
              VToast.show(
                context,
                title: 'Thông báo',
                message: 'Không tìm thấy nhóm trường tùy chỉnh cần bổ sung.',
                type: VToastType.warning,
              );
              return;
            }
            context
                .push(
                  '/products/items/pcc/custom-fields/edit',
                  extra: ProductCustomFieldGroupEditRouteArgs(
                    productId: product.id,
                    productName: product.name,
                    groupId: groupId,
                  ),
                )
                .then(popOnReturn);
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
