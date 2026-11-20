import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import '../models/sales_order/sales_order_detail_vm.dart';

class SalesOrderReturnListPage extends StatelessWidget {
  const SalesOrderReturnListPage({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.returns,
    required this.onOpenReturnDetail,
  });

  final String orderId;
  final String orderNumber;
  final String customerName;
  final List<SalesReturnExchangeSlipItemVm> returns;
  final ValueChanged<String> onOpenReturnDetail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      key: const Key('wgt_sg08_return_list_page'),
      title: 'Phiếu đổi/trả',
      subtitle: 'Đơn $orderNumber · $customerName',
      showBackButton: true,
      body: SingleChildScrollView(
        child: VPagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VGap.sm(),
              VText(
                'Các lần đổi/trả (${returns.length})',
                variant: VTextVariant.bodyDefault,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.sm(),
              VCard(
                backgroundColor: colors.surface,
                border: Border.all(color: colors.borderDefault),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < returns.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.borderDefault),
                      Builder(
                        builder: (context) {
                          final slip = returns[i];
                          final hasIdentity = slip.returnExchangeId.trim().isNotEmpty;
                          return InkWell(
                            onTap: hasIdentity
                                ? () => onOpenReturnDetail(slip.returnExchangeId)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(VSpacing.space3),
                              child: Row(
                                children: [
                                  VIcon(
                                    icon: VIcons.history,
                                    size: 20,
                                    color: colors.textPrimary,
                                  ),
                                  const VGap.horizontalSm(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        VText(
                                          '${slip.slipNumber} · ${slip.typeText}',
                                          variant: VTextVariant.bodyDefault,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const VGap.xs(),
                                        VText(
                                          '${slip.dateFormatted} · ${slip.statusText}',
                                          variant: VTextVariant.bodySmall,
                                          color: colors.textSecondary,
                                        ),
                                        const VGap.xs(),
                                        VText(
                                          slip.diffText,
                                          variant: VTextVariant.bodySmall,
                                          color: colors.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasIdentity) ...[
                                    const VGap.horizontalSm(),
                                    VIcon(
                                      icon: VIcons.chevronRight,
                                      size: 20,
                                      color: colors.textMuted,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const VGap.xl(),
            ],
          ),
        ),
      ),
    );
  }
}
