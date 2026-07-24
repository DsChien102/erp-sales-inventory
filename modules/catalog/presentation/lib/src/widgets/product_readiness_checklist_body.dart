import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductReadinessChecklistBody extends StatelessWidget {
  const ProductReadinessChecklistBody({
    super.key,
    required this.readinessView,
    this.onActionTap,
  });

  final ProductReadinessViewDto readinessView;
  final void Function(String actionId)? onActionTap;

  String? _getCallToAction(String code) {
    switch (code) {
      case 'missing_base_unit':
        return 'Thiết lập đơn vị';
      case 'missing_image':
        return 'Quản lý ảnh';
      case 'missing_stock':
        return 'Nhập tồn kho';
      case 'missing_price':
        return 'Thiết lập giá vốn';
      case 'missing_price_band':
        return 'Thiết lập giá';
      case 'missing_required_custom_fields':
        return 'Cập nhật trường';
      case 'pending_stock_from_inventory':
        return 'Xem Kho';
      case 'pending_base_price_from_costing':
        return 'Xem Giá vốn';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final blockers = readinessView.readinessSummary.blockers;

    if (blockers.isEmpty) {
      return Center(
        child: VText(
          'Sản phẩm đã sẵn sàng vận hành.',
          variant: VTextVariant.bodyDefault,
          color: dynamicColors.textSecondary,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(VSpacing.space4),
      itemCount: blockers.length,
      separatorBuilder: (_, _) => const SizedBox(height: VSpacing.space2),
      itemBuilder: (context, index) {
        final blocker = blockers[index];
        final ctaLabel = _getCallToAction(blocker.code);

        return GestureDetector(
          onTap: () => onActionTap?.call(blocker.code),
          child: Container(
            padding: const EdgeInsets.all(VSpacing.space4),
            decoration: BoxDecoration(
              color: dynamicColors.surface,
              borderRadius: BorderRadius.circular(VRadius.r8),
              border: Border.all(color: dynamicColors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: dynamicColors.warning,
                  size: VSpacing.space5,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VText(
                    blocker.message,
                    variant: VTextVariant.bodyDefault,
                    color: dynamicColors.textPrimary,
                  ),
                ),
                if (ctaLabel != null)
                  TextButton(
                    onPressed: () {
                      if (onActionTap != null) {
                        onActionTap!(blocker.code);
                      } else {
                        VToast.show(
                          context,
                          title: 'Thông báo',
                          message: 'Chức năng sẽ được hoàn thiện ở màn sau.',
                          type: VToastType.info,
                        );
                      }
                    },
                    child: VText(
                      ctaLabel,
                      variant: VTextVariant.bodySmall,
                      color: dynamicColors.primary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
