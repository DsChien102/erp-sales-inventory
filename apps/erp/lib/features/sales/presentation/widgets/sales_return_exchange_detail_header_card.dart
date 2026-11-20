import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import '../models/return_exchange_order/sales_return_exchange_detail_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import '../support/sales_order_detail_mapper.dart';

class SalesReturnExchangeDetailHeaderCard extends StatelessWidget {
  const SalesReturnExchangeDetailHeaderCard({
    super.key,
    required this.detail,
    required this.customerDisplayName,
    required this.customerPhone,
  });

  final SalesReturnExchangeDetailVm detail;
  final String customerDisplayName;
  final String customerPhone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final plan = detail.settlementPlan;

    final String bannerLabel;
    final int bannerAmountMinor;
    if (plan.collectAmountMinor > 0 || plan.netDifferenceMinor > 0) {
      bannerLabel = 'Khách trả thêm';
      bannerAmountMinor = plan.collectAmountMinor > 0
          ? plan.collectAmountMinor
          : plan.netDifferenceMinor;
    } else if (plan.refundAmountMinor > 0 || plan.netDifferenceMinor < 0) {
      bannerLabel = 'Hoàn trả khách';
      bannerAmountMinor = plan.refundAmountMinor > 0
          ? plan.refundAmountMinor
          : plan.netDifferenceMinor.abs();
    } else {
      bannerLabel = 'Không chênh lệch';
      bannerAmountMinor = 0;
    }

    final createdAt = detail.createdAt;
    final createdAtText = createdAt != null
        ? SalesOrderDetailMapper.formatCommittedAt(createdAt)
        : '';

    return VCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference number & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                detail.referenceNumber,
                key: const Key('wgt_sg13_detail_reference'),
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              VBadge(
                label: _statusLabel(detail.status),
                tone: _badgeTone(detail.status),
                variant: VBadgeVariant.soft,
                isSmall: false,
              ),
            ],
          ),
          if (createdAtText.isNotEmpty) ...[
            const VGap.xs(),
            VText(
              createdAtText,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ],
          if (customerDisplayName.isNotEmpty) ...[
            const VGap.sm(),
            VText(
              customerDisplayName,
              variant: VTextVariant.bodyDefault,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          if (customerPhone.isNotEmpty) ...[
            const VGap.xs(),
            VText(
              customerPhone,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ],
          const VGap.md(),
          // Highlight Box for settlement difference
          VCard(
            backgroundColor: colors.successBg,
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VText(
                  bannerLabel,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                VText(
                  MoneyFormatter.formatMinor(bannerAmountMinor),
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

  static String _statusLabel(ReturnExchangeStatus status) => switch (status) {
    ReturnExchangeStatus.completed => 'Hoàn tất',
    ReturnExchangeStatus.processing => 'Đang xử lý',
    ReturnExchangeStatus.confirmed => 'Đã xác nhận',
    ReturnExchangeStatus.draft => 'Nháp',
    ReturnExchangeStatus.cancelled => 'Đã hủy',
    ReturnExchangeStatus.blocked => 'Bị chặn',
    ReturnExchangeStatus.failed => 'Thất bại',
  };

  static VComponentTone _badgeTone(ReturnExchangeStatus status) => switch (status) {
    ReturnExchangeStatus.completed => VComponentTone.success,
    ReturnExchangeStatus.processing => VComponentTone.primary,
    ReturnExchangeStatus.confirmed => VComponentTone.info,
    ReturnExchangeStatus.draft => VComponentTone.neutral,
    ReturnExchangeStatus.cancelled => VComponentTone.neutral,
    ReturnExchangeStatus.blocked => VComponentTone.danger,
    ReturnExchangeStatus.failed => VComponentTone.danger,
  };
}
