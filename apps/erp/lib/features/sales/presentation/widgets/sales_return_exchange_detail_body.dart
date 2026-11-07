import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import 'package:erp/features/sales/logic/sales_return_exchange_detail_state.dart';
import 'sales_return_exchange_detail_header_card.dart';
import 'sales_return_exchange_detail_lines_section.dart';
import 'sales_return_exchange_detail_summary_card.dart';
import 'sales_return_exchange_source_order_card.dart';

/// SG-13 detail body — lines/plan from authoritative detail VM only.
class SalesReturnExchangeDetailBody extends StatelessWidget {
  const SalesReturnExchangeDetailBody({
    super.key,
    required this.state,
    this.onRetry,
    this.onOpenActions,
    this.onOpenSourceOrder,
  });

  final SalesReturnExchangeDetailState state;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenActions;
  final VoidCallback? onOpenSourceOrder;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SalesReturnExchangeDetailStatus.initial:
      case SalesReturnExchangeDetailStatus.loading:
        return const Center(
          key: Key('wgt_sg13_detail_loading'),
          child: CircularProgressIndicator(),
        );
      case SalesReturnExchangeDetailStatus.notFound:
      case SalesReturnExchangeDetailStatus.failure:
      case SalesReturnExchangeDetailStatus.retryableFailure:
        return Padding(
          key: const Key('wgt_sg13_detail_error'),
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VText(
                state.screenError ?? 'Không tải được chi tiết phiếu.',
                variant: VTextVariant.bodyDefault,
              ),
              if (onRetry != null) ...[
                const VGap.md(),
                VButton(
                  key: const Key('btn_sg13_detail_retry'),
                  label: 'Thử lại',
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        );
      case SalesReturnExchangeDetailStatus.projectionPending:
      case SalesReturnExchangeDetailStatus.blocked:
      case SalesReturnExchangeDetailStatus.loaded:
        final detail = state.detail;
        if (detail == null) {
          return Padding(
            key: const Key('wgt_sg13_detail_error'),
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VText(
                  state.screenError ?? 'Không tải được chi tiết phiếu.',
                  variant: VTextVariant.bodyDefault,
                ),
                if (onRetry != null) ...[
                  const VGap.md(),
                  VButton(
                    key: const Key('btn_sg13_detail_retry'),
                    label: 'Thử lại',
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          );
        }
        final returnLines = detail.lines
            .where((l) => l.kind == ReturnExchangeLineKind.returnLine)
            .toList();
        final exchangeLines = detail.lines
            .where((l) => l.kind == ReturnExchangeLineKind.exchangeLine)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SalesReturnExchangeDetailHeaderCard(
                detail: detail,
                customerDisplayName: state.customerDisplayName,
                customerPhone: state.customerPhone,
              ),
              if (state.orderNumber.isNotEmpty) ...[
                const VGap.md(),
                SalesReturnExchangeSourceOrderCard(
                  orderNumber: state.orderNumber,
                  onTap: onOpenSourceOrder,
                ),
              ],
              const VGap.md(),
              SalesReturnExchangeDetailLinesSection(
                returnLines: returnLines,
                exchangeLines: exchangeLines,
              ),
              const VGap.md(),
              SalesReturnExchangeDetailSummaryCard(
                detail: detail,
              ),
              if (onOpenActions != null) ...[
                const VGap.lg(),
                VButton(
                  key: const Key('btn_return_detail_actions'),
                  label: 'Thao tác',
                  variant: VButtonVariant.primary,
                  tone: VComponentTone.success,
                  size: VButtonSize.large,
                  fullWidth: true,
                  trailingIcon: const VIcon(
                    icon: VIcons.expandLess,
                    iconColor: VIconColor.white,
                    iconSize: VIconSize.sm,
                  ),
                  onPressed: onOpenActions,
                ),
              ],
            ],
          ),
        );
    }
  }
}
