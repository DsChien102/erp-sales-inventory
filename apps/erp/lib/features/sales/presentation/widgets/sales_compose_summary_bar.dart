import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import '../bloc/sales_order_draft/sales_compose_state.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// Sticky footer commerce SG-02: Khách phải trả + Lưu nháp / Thanh toán.
///
/// [VPageScaffold.bottomBar] đã bọc Material + SafeArea — widget này chỉ nội dung.
class SalesComposeSummaryBar extends StatelessWidget {
  const SalesComposeSummaryBar({
    super.key,
    required this.subtotalMinor,
    required this.canCheckout,
    required this.canSaveDraft,
    required this.onCheckout,
    required this.onSaveDraft,
    this.disabledReason,
    this.pricingStatus = SalesComposePricingStatus.ready,
    this.isSavingDraft = false,
    this.isCheckingOut = false,
  });

  final int subtotalMinor;
  final bool canCheckout;
  final bool canSaveDraft;
  final VoidCallback onCheckout;
  final VoidCallback onSaveDraft;
  final String? disabledReason;
  final SalesComposePricingStatus pricingStatus;
  final bool isSavingDraft;
  final bool isCheckingOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final total = MoneyDto(amountMinor: subtotalMinor, currencyCode: 'VND');
    final totalLabel = MoneyFormatter.format(amountMinor: total.amountMinor, currencyCode: total.currencyCode);
    final busy =
        pricingStatus == SalesComposePricingStatus.refreshing || isSavingDraft || isCheckingOut;
    final refreshing = pricingStatus == SalesComposePricingStatus.refreshing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            VText(
              'Khách phải trả',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const Spacer(),
            if (refreshing)
              const VSkeleton(
                key: Key('skeleton_compose_summary_total'),
                width: 96,
                height: 18,
                semanticLabel: 'Đang làm mới giá',
              )
            else
              VText(
                totalLabel,
                variant: VTextVariant.bodyDefaultMono,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
          ],
        ),
        const VGap.sm(),
        Row(
          children: [
            Expanded(
              child: VButton(
                key: const Key('btn_compose_save_draft'),
                label: 'Lưu nháp',
                variant: VButtonVariant.secondary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: canSaveDraft && !busy ? onSaveDraft : null,
              ),
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: VButton(
                key: const Key('btn_compose_checkout'),
                label: 'Thanh toán',
                tone: VComponentTone.success,
                fullWidth: true,
                isLoading:
                    isCheckingOut ||
                    (pricingStatus == SalesComposePricingStatus.refreshing && !isSavingDraft),
                onPressed: canCheckout && !busy ? onCheckout : null,
              ),
            ),
          ],
        ),
        if (!canCheckout && disabledReason != null) ...[
          const VGap.xs(),
          VText(
            disabledReason!,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
        ],
      ],
    );
  }
}
