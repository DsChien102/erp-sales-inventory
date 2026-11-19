import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import '../models/sales_order/sales_order_history_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
class SalesOrderHistoryPage extends StatelessWidget {
  const SalesOrderHistoryPage({
    super.key,
    required this.orderNumber,
    required this.customerName,
    required this.history,
    this.fallbackActorName,
  });

  final String orderNumber;
  final String customerName;
  final SalesOrderHistoryVm history;
  final String? fallbackActorName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      key: const Key('wgt_sg08_history_page'),
      title: 'Lịch sử',
      leading: IconButton(
        key: const Key('btn_sg08_history_back'),
        icon: VIcon(
          icon: VIcons.chevronLeft,
          color: colors.textPrimary,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      showBackButton: true,
      body: SingleChildScrollView(
        child: VPagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VGap.md(),
              VText(
                '$orderNumber · $customerName',
                key: const Key('wgt_sg08_history_context'),
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.lg(),
              const VText(
                'Lịch sử',
                variant: VTextVariant.bodyDefault,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.sm(),
              VCard(
                key: const Key('wgt_sg08_history_timeline'),
                backgroundColor: colors.surface,
                border: Border.all(color: colors.borderDefault),
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  children: [
                    for (var i = 0; i < history.timeline.length; i++)
                      _TimelineItemRow(
                        item: history.timeline[i],
                        isLast: i == history.timeline.length - 1,
                        fallbackActorName: fallbackActorName,
                      ),
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

class _TimelineItemRow extends StatelessWidget {
  const _TimelineItemRow({
    required this.item,
    required this.isLast,
    this.fallbackActorName,
  });

  final SalesOrderDetailTimelineVm item;
  final bool isLast;
  final String? fallbackActorName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final localizedTitle = _SalesTimelineText.localizeTitle(item);
    final displayTitle = item.amountMinor != null
        ? '$localizedTitle ${MoneyFormatter.formatMinor(item.amountMinor!)}'
        : localizedTitle;
    final displayDescription = _SalesTimelineText.localizeDescription(
      item,
      localizedTitle: localizedTitle,
    );
    final displayActorName = _SalesTimelineText.displayActorName(
      item.actorName,
      fallbackActorName: fallbackActorName,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                VIconBox(
                  icon: VIcons.history,
                  isCircular: true,
                  size: 36,
                  iconSize: 18,
                  backgroundColor: colors.successBg,
                  iconColor: colors.success,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: VSpacing.space1),
                      color: colors.borderDefault,
                    ),
                  ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : VSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    displayTitle,
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const VGap.xs(),
                  VText(
                    '$displayActorName · ${item.timestamp}',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  if (displayDescription != null) ...[
                    const VGap.xs(),
                    VText(
                      displayDescription,
                      variant: VTextVariant.bodySmall,
                      color: colors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SalesTimelineText {
  const _SalesTimelineText._();

  static const Map<String, String> _titles = {
    'ORDER_COMPLETED': 'Hoàn tất đơn hàng',
    'SALES_ORDER_COMPLETED': 'Hoàn tất đơn hàng',
    'SALES_ORDER_FINALIZED': 'Hoàn tất đơn hàng',
    'ORDER_CREATED': 'Tạo đơn hàng',
    'SALES_ORDER_CREATED': 'Tạo đơn hàng',
    'ORDER_CONFIRMED': 'Xác nhận đơn hàng',
    'SALES_ORDER_CONFIRMED': 'Xác nhận đơn hàng',
    'PAYMENT_CASH_RECORDED': 'Ghi nhận thanh toán tiền mặt',
    'CASH_PAYMENT_RECORDED': 'Ghi nhận thanh toán tiền mặt',
    'SALES_PAYMENT_CASH_RECORDED': 'Ghi nhận thanh toán tiền mặt',
    'PAYMENT_BANK_RECORDED': 'Ghi nhận thanh toán chuyển khoản',
    'BANK_PAYMENT_RECORDED': 'Ghi nhận thanh toán chuyển khoản',
    'SALES_PAYMENT_BANK_RECORDED': 'Ghi nhận thanh toán chuyển khoản',
    'PAYMENT_RECORDED': 'Ghi nhận thanh toán',
    'SALES_PAYMENT_RECORDED': 'Ghi nhận thanh toán',
    'REFUND_RECORDED': 'Ghi nhận hoàn tiền',
    'SALES_REFUND_RECORDED': 'Ghi nhận hoàn tiền',
    'PAYMENT_VOIDED': 'Hủy thanh toán',
    'SALES_PAYMENT_VOIDED': 'Hủy thanh toán',
    'SETTLEMENT_CHANGED': 'Cập nhật quyết toán',
    'SALES_SETTLEMENT_CHANGED': 'Cập nhật quyết toán',
    'SETTLEMENT_RECOMPUTED': 'Tính lại quyết toán',
    'SALES_SETTLEMENT_RECOMPUTED': 'Tính lại quyết toán',
    'RECEIPT_PRINTED': 'In phiếu bán hàng',
    'SALES_RECEIPT_PRINTED': 'In phiếu bán hàng',
    'RECEIPT_SHARED': 'Chia sẻ phiếu bán hàng',
    'SALES_RECEIPT_SHARED': 'Chia sẻ phiếu bán hàng',
    'RECEIPT_ARCHIVED': 'Lưu trữ phiếu bán hàng',
    'SALES_RECEIPT_ARCHIVED': 'Lưu trữ phiếu bán hàng',
    'RECEIPT_GENERATED': 'Tạo phiếu bán hàng',
    'SALES_RECEIPT_GENERATED': 'Tạo phiếu bán hàng',
    'RETURN_EXCHANGE_COMPLETED': 'Hoàn tất đổi/trả',
    'RETURN_EXCHANGE_CONFIRMED': 'Xác nhận đổi/trả',
    'RETURN_COMPLETED': 'Hoàn tất đổi/trả',
    'RETURN_CONFIRMED': 'Xác nhận đổi/trả',
    'ORDER_NOTE_UPDATED': 'Cập nhật ghi chú đơn hàng',
    'SALES_ORDER_NOTE_UPDATED': 'Cập nhật ghi chú đơn hàng',
    'ORDER_ADJUSTED': 'Điều chỉnh đơn hàng',
    'SALES_ORDER_ADJUSTED': 'Điều chỉnh đơn hàng',
    'ORDER_CANCELLED': 'Hủy đơn hàng',
    'SALES_ORDER_CANCELLATION_CONFIRMED': 'Xác nhận hủy đơn hàng',
    'SALES_ORDER_PRICING_REVERSAL_REQUESTED': 'Yêu cầu hoàn tác giá bán',
    'SALES_ORDER_REPORTING_CANCELLATION_RECORDED': 'Ghi nhận báo cáo hủy đơn',
    'SALES_ORDER_CANCELLED': 'Hủy đơn hàng',
  };

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String displayActorName(String actorName, {String? fallbackActorName}) {
    final trimmed = actorName.trim();
    final fallback = fallbackActorName?.trim();
    final isUnknown = trimmed.isEmpty ||
        _uuidPattern.hasMatch(trimmed) ||
        trimmed == 'Không rõ' ||
        trimmed.toLowerCase() == 'unknown';
    if (isUnknown) {
      return fallback != null && fallback.isNotEmpty ? fallback : 'Nhân viên';
    }
    return trimmed;
  }

  static String localizeTitle(SalesOrderDetailTimelineVm item) {
    final title = _localizedCode(item.title);
    final description = item.description?.trim();
    if (_isReturnExchangeCompletion(item.title) &&
        description != null &&
        description.startsWith('#')) {
      return '$title $description';
    }
    return title;
  }

  static String? localizeDescription(
    SalesOrderDetailTimelineVm item, {
    required String localizedTitle,
  }) {
    final description = item.description?.trim();
    if (description == null || description.isEmpty) {
      return null;
    }
    if (description == item.title || description == localizedTitle) {
      return null;
    }
    final localizedDescription = _localizedCode(description);
    if (localizedDescription == localizedTitle) {
      return null;
    }
    if (_isReturnExchangeCompletion(item.title) && description.startsWith('#')) {
      return null;
    }
    return localizedDescription;
  }

  static String _localizedCode(String value) {
    final normalized = _normalizeCode(value);
    return _titles[normalized] ?? value;
  }

  static bool _isReturnExchangeCompletion(String value) {
    final normalized = _normalizeCode(value);
    return normalized == 'RETURN_EXCHANGE_COMPLETED' || normalized == 'RETURN_COMPLETED';
  }

  static String _normalizeCode(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceFirst(RegExp(r'_V[0-9]+$'), '')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
