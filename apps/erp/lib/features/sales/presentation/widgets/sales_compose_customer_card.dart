import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import '../models/sales_order_draft/sales_compose_customer_vm.dart';

/// Context header KH theo Figma SG-02 (D-01): tên + phụ đề + Chọn/Đổi KH | Tạo KH.
class SalesComposeCustomerCard extends StatelessWidget {
  const SalesComposeCustomerCard({
    super.key,
    required this.customer,
    required this.onSelectCustomer,
    required this.onCreateCustomer,
  });

  final SalesComposeCustomerVm customer;
  final VoidCallback onSelectCustomer;
  final VoidCallback onCreateCustomer;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final subtitle = customer.isWalkIn
        ? 'Không bắt buộc thông tin'
        : (customer.phone?.trim().isNotEmpty == true
              ? customer.phone!.trim()
              : 'Chưa có số điện thoại');

    return SizedBox(
      key: const Key('card_compose_customer'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VText(
                  customer.displayName,
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          VButton(
            key: const Key('btn_compose_select_customer'),
            label: customer.isWalkIn ? 'Chọn KH' : 'Đổi KH',
            variant: VButtonVariant.tertiary,
            size: VButtonSize.small,
            onPressed: onSelectCustomer,
          ),
          const VGap(VSpacing.space1, axis: Axis.horizontal),
          const SizedBox(
            height: 20,
            child: VDivider(axis: Axis.vertical),
          ),
          const VGap(VSpacing.space1, axis: Axis.horizontal),
          VButton(
            key: const Key('btn_compose_create_customer'),
            label: 'Tạo KH',
            variant: VButtonVariant.tertiary,
            size: VButtonSize.small,
            onPressed: onCreateCustomer,
          ),
        ],
      ),
    );
  }
}
