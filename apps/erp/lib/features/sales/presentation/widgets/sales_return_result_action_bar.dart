import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Action Bar at the bottom of Return & Exchange Result Page (2 buttons).
class SalesReturnResultActionBar extends StatelessWidget {
  const SalesReturnResultActionBar({
    super.key,
    required this.onGoHome,
    required this.onViewOrderDetail,
    this.isErrorState = false,
    this.onRetryLoad,
    this.onViewCustomerReceivable,
  });

  final VoidCallback onGoHome;
  final VoidCallback onViewOrderDetail;
  final bool isErrorState;
  final VoidCallback? onRetryLoad;

  /// Có thì hiện nút phụ "Xem công nợ của khách" (SG-14, khi có cấn trừ).
  final VoidCallback? onViewCustomerReceivable;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onViewCustomerReceivable != null) ...[
                VButton(
                  key: const Key('btn_return_result_view_receivable'),
                  label: 'Xem công nợ của khách',
                  variant: VButtonVariant.secondary,
                  size: VButtonSize.large,
                  fullWidth: true,
                  onPressed: onViewCustomerReceivable,
                ),
                const VGap.sm(),
              ],
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      key: const Key('btn_return_result_go_home'),
                      label: 'Về trang chủ',
                      variant: VButtonVariant.secondary,
                      size: VButtonSize.large,
                      fullWidth: true,
                      onPressed: onGoHome,
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      key: const Key('btn_return_result_view_detail'),
                      label: 'Xem chi tiết đơn',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.success,
                      size: VButtonSize.large,
                      fullWidth: true,
                      onPressed: onViewOrderDetail,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
