import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import '../bloc/return_exchange_order/sales_return_exchange_detail_state.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'sales_return_result_action_bar.dart';

/// SG-13 result body — authoritative detail only (no fabricated customer/lines).
class SalesReturnExchangeResultBody extends StatelessWidget {
  const SalesReturnExchangeResultBody({
    super.key,
    required this.state,
    required this.onGoHome,
    required this.onViewOrderDetail,
    this.onViewReturnSlipDetail,
    this.onRetry,
    this.onComplete,
  });

  final SalesReturnExchangeDetailState state;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrderDetail;
  final VoidCallback? onViewReturnSlipDetail;
  final VoidCallback? onRetry;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    switch (state.status) {
      case SalesReturnExchangeDetailStatus.initial:
      case SalesReturnExchangeDetailStatus.loading:
        return const Center(
          key: Key('wgt_sg13_loading'),
          child: CircularProgressIndicator(),
        );
      case SalesReturnExchangeDetailStatus.notFound:
        return _message(
          key: 'wgt_sg13_not_found',
          title: 'Không tìm thấy phiếu đổi/trả',
          message: state.screenError ?? 'Phiếu không tồn tại.',
          onRetry: onRetry,
        );
      case SalesReturnExchangeDetailStatus.projectionPending:
        return _message(
          key: 'wgt_sg13_projection_pending',
          title: 'Đang đồng bộ dữ liệu',
          message: state.screenError ?? 'Phiếu đang được cập nhật.',
          onRetry: onRetry,
        );
      case SalesReturnExchangeDetailStatus.failure:
      case SalesReturnExchangeDetailStatus.retryableFailure:
        return _message(
          key: 'wgt_sg13_failure',
          title: 'Không tải được kết quả đổi/trả',
          message: state.screenError ?? 'Lỗi không xác định.',
          onRetry: onRetry,
        );
      case SalesReturnExchangeDetailStatus.blocked:
      case SalesReturnExchangeDetailStatus.loaded:
      case SalesReturnExchangeDetailStatus.completing:
        final detail = state.detail;
        if (detail == null) {
          return _message(
            key: 'wgt_sg13_failure',
            title: 'Thiếu dữ liệu phiếu',
            message: 'Không có chi tiết đổi/trả.',
            onRetry: onRetry,
          );
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusCard(colors, detail),
                    if (state.customerDisplayName.isNotEmpty) ...[
                      const VGap.md(),
                      _customerCard(colors, state),
                    ],
                    const VGap.md(),
                    _summaryCard(colors, detail),
                    const VGap.md(),
                    _settlementCard(colors, detail.settlementPlan),
                    if (state.screenError != null) ...[
                      const VGap.md(),
                      VBanner(
                        key: const Key('wgt_sg13_screen_error'),
                        title: state.screenError!,
                        status: VBannerStatus.warning,
                      ),
                    ],
                    if (state.canComplete) ...[
                      const VGap.md(),
                      VButton(
                        key: const Key('btn_sg13_complete'),
                        label: state.status == SalesReturnExchangeDetailStatus.completing
                            ? 'Đang hoàn tất...'
                            : 'Hoàn tất phiếu',
                        variant: VButtonVariant.primary,
                        fullWidth: true,
                        onPressed: state.status == SalesReturnExchangeDetailStatus.completing
                            ? null
                            : onComplete,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SalesReturnResultActionBar(
              onGoHome: onGoHome,
              onViewOrderDetail: onViewOrderDetail,
              isErrorState: false,
            ),
          ],
        );
    }
  }

  Widget _statusCard(dynamic colors, dynamic detail) {
    final completedAt = detail.completedAt ?? detail.confirmedAt ?? detail.createdAt;
    return VCard(
      key: const Key('wgt_sg13_status_card'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VIcon(
            icon: _statusIcon(detail.status),
            color: _statusColor(colors, detail.status),
            size: 40,
          ),
          const VGap.sm(),
          VText(
            _statusTitle(detail.status),
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const VGap.xs(),
          VText(
            'Phiếu #${detail.referenceNumber}',
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (completedAt != null) ...[
            const VGap.xs(),
            VText(
              _formatDateTime(completedAt as DateTime),
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
          if (onViewReturnSlipDetail != null) ...[
            const VGap.sm(),
            VButton(
              key: const Key('btn_sg13_view_slip'),
              label: 'Xem phiếu đổi/trả',
              variant: VButtonVariant.link,
              onPressed: onViewReturnSlipDetail,
            ),
          ],
        ],
      ),
    );
  }

  Widget _customerCard(dynamic colors, SalesReturnExchangeDetailState state) {
    return VCard(
      key: const Key('wgt_sg13_customer_card'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            state.customerDisplayName,
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (state.customerPhone.isNotEmpty) ...[
            const VGap.xs(),
            VText(
              state.customerPhone,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(dynamic colors, dynamic detail) {
    final valuation = detail.valuation as ReturnExchangeValuationDto;
    final plan = detail.settlementPlan as ReturnExchangeSettlementPlanDto;
    return VCard(
      key: const Key('wgt_sg13_summary_card'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Tóm tắt đổi/trả',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.sm(),
          _row('Giá trị hàng trả', valuation.returnValue.amountMinor),
          const VGap.xs(),
          _row('Giá trị hàng đổi', valuation.exchangeValue.amountMinor),
          const VGap.sm(),
          Container(
            padding: const EdgeInsets.all(VSpacing.space3),
            decoration: BoxDecoration(
              color: colors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const VText(
                  'Chênh lệch',
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                VText(
                  MoneyFormatter.formatMinor(plan.netDifferenceMinor),
                  variant: VTextVariant.bodyDefault,
                  color: colors.success,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settlementCard(dynamic colors, ReturnExchangeSettlementPlanDto plan) {
    final paymentLine = plan.refundAmountMinor > 0
        ? 'Hoàn cho khách: ${MoneyFormatter.formatMinor(plan.refundAmountMinor)}'
        : plan.collectAmountMinor > 0
        ? 'Thu thêm từ khách: ${MoneyFormatter.formatMinor(plan.collectAmountMinor)}'
        : 'Không phát sinh thu hoặc hoàn tiền';
    final debtLine = plan.receivableCreateAmountMinor > 0
        ? 'Ghi nợ khách: ${MoneyFormatter.formatMinor(plan.receivableCreateAmountMinor)}'
        : plan.receivableReverseAmountMinor > 0
        ? 'Giảm nợ khách: ${MoneyFormatter.formatMinor(plan.receivableReverseAmountMinor)}'
        : 'Không phát sinh công nợ';
    return VCard(
      key: const Key('wgt_sg13_settlement_card'),
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Quyết toán phiếu',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.sm(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VIcon(
                icon: VIcons.accountBalanceWallet,
                color: colors.warning,
                size: 20,
              ),
              const VGap.sm(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      paymentLine,
                      variant: VTextVariant.bodyDefault,
                      color: colors.warning,
                    ),
                    const VGap.xs(),
                    VText(
                      debtLine,
                      variant: VTextVariant.bodyDefault,
                      color: colors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, int amountMinor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(label, variant: VTextVariant.bodySmall),
        VText(
          MoneyFormatter.formatMinor(amountMinor),
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  VIcons _statusIcon(ReturnExchangeStatus status) => switch (status) {
    ReturnExchangeStatus.completed ||
    ReturnExchangeStatus.confirmed => VIcons.success,
    ReturnExchangeStatus.processing => VIcons.history,
    ReturnExchangeStatus.blocked ||
    ReturnExchangeStatus.failed ||
    ReturnExchangeStatus.cancelled => VIcons.warning,
    ReturnExchangeStatus.draft => VIcons.info,
  };

  Color _statusColor(dynamic colors, ReturnExchangeStatus status) => switch (status) {
    ReturnExchangeStatus.completed ||
    ReturnExchangeStatus.confirmed => colors.success as Color,
    _ => colors.warning as Color,
  };

  String _formatDateTime(DateTime value) => VDateTime.dateTime(value);

  String _statusTitle(ReturnExchangeStatus status) => switch (status) {
    ReturnExchangeStatus.completed => 'Đã hoàn tất đổi/trả',
    ReturnExchangeStatus.processing => 'Đang xử lý đổi/trả',
    ReturnExchangeStatus.confirmed => 'Đã ghi nhận đổi/trả',
    ReturnExchangeStatus.draft => 'Phiếu nháp đổi/trả',
    ReturnExchangeStatus.cancelled => 'Phiếu đổi/trả đã hủy',
    ReturnExchangeStatus.blocked => 'Phiếu đổi/trả bị chặn',
    ReturnExchangeStatus.failed => 'Phiếu đổi/trả thất bại',
  };

  Widget _message({
    required String key,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.vColors;
        return Column(
          key: Key(key),
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VText(
                      title,
                      variant: VTextVariant.headingH4,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const VGap.sm(),
                    VText(
                      message,
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    if (onRetry != null) ...[
                      const VGap.md(),
                      VButton(
                        key: const Key('btn_sg13_retry'),
                        label: 'Thử lại',
                        variant: VButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: onRetry,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SalesReturnResultActionBar(
              onGoHome: onGoHome,
              onViewOrderDetail: onViewOrderDetail,
              isErrorState: true,
            ),
          ],
        );
      },
    );
  }
}
