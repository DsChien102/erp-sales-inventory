import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

import 'price_rule_detail_rows.dart';
import 'price_rule_history_shared.dart';
import 'price_rule_status_badge.dart';
import 'price_rule_warning_banner.dart';

/// Nội dung chi tiết giá riêng (SG-02 D-05/D-06/D-07).
///
/// Padding card theo design: 1 lớp [VCard.padding] = [VSpacing.space3],
/// không bọc Padding lồng thêm.
class PriceRuleDetailContent extends StatelessWidget {
  const PriceRuleDetailContent({
    super.key,
    required this.rule,
    this.onViewHistory,
    this.recentActivities,
  });

  final CustomerPriceRuleDetailDto rule;
  final VoidCallback? onViewHistory;
  final List<CustomerPriceRuleActivityDto>? recentActivities;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final outcome = rule.validationOutcome;
    final listPrice = outcome.listPrice;
    final floorPrice = outcome.floorPrice;
    final isBelowFloor = outcome.warningCodes.contains('below_floor_price');
    final diff = listPrice == null
        ? null
        : rule.price.amountMinor - listPrice.amountMinor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rule.derivedStatus ==
                  CustomerPriceRuleDerivedStatus.needsReview ||
              isBelowFloor) ...[
            PriceRuleReviewBanner(
              issues: [
                if (isBelowFloor) 'Giá riêng đang thấp hơn giá sàn hiện tại',
                ...rule.referenceHealth.issueCodes,
              ],
            ),
            const VGap.sm(),
          ],
          if (rule.persistedStatus == CustomerPriceRuleStatus.disabled) ...[
            const PriceRuleBanner(
              tone: VComponentTone.info,
              title: 'Giá riêng đã tắt',
              message: 'Không áp dụng cho đơn hàng mới.',
            ),
            const VGap.sm(),
          ],

          // Header summary — không có title trong card
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              children: [
                PriceRuleIconDetailRow(
                  icon: VIcons.people,
                  label: 'Khách hàng',
                  value: rule.customer.displayName,
                ),
                PriceRuleIconDetailRow(
                  icon: VIcons.phone,
                  label: 'Số điện thoại',
                  value: rule.customer.phone ?? '—',
                  numeric: true,
                ),
                PriceRuleIconDetailRow(
                  icon: VIcons.inventory,
                  label: 'Sản phẩm',
                  value: rule.productUnit.productName,
                ),
                PriceRuleIconDetailRow(
                  icon: VIcons.store,
                  label: 'Đơn vị bán',
                  value: rule.productUnit.unitName,
                ),
                PriceRuleIconDetailRowWidget(
                  icon: VIcons.info,
                  label: 'Trạng thái',
                  child: PriceRuleStatusBadge(status: rule.derivedStatus),
                  isLast: true,
                ),
              ],
            ),
          ),
          const VGap.md(),
          PriceRuleDetailSectionCard(
            title: 'Thông tin giá',
            children: [
              PriceRuleIconDetailRow(
                icon: VIcons.tag,
                label: 'Giá riêng',
                value: _formatMoney(rule.price),
                valueColor: isBelowFloor ? colors.danger : colors.textPrimary,
                valueWeight: FontWeight.w700,
                numeric: true,
              ),
              PriceRuleIconDetailRow(
                icon: VIcons.receipt,
                label: 'Giá niêm yết',
                value: listPrice != null ? _formatMoney(listPrice) : '—',
                numeric: true,
              ),
              PriceRuleIconDetailRow(
                icon: VIcons.shield,
                label: 'Giá sàn',
                value: (!outcome.floorPriceHidden && floorPrice != null)
                    ? _formatMoney(floorPrice)
                    : 'Ẩn theo quyền',
                numeric: !outcome.floorPriceHidden && floorPrice != null,
              ),
              PriceRuleIconDetailRow(
                icon: VIcons.swapVert,
                label: 'Chênh lệch',
                value: diff == null
                    ? '—'
                    : _formatDiff(diff, listPriceMinor: listPrice?.amountMinor),
                valueColor: diff == null
                    ? null
                    : (diff < 0 ? colors.danger : colors.success),
                valueWeight: FontWeight.w600,
                numeric: diff != null,
                isLast: true,
              ),
            ],
          ),
          const VGap.md(),

          PriceRuleDetailSectionCard(
            title: 'Hiệu lực & nguồn',
            children: [
              PriceRuleIconDetailRow(
                icon: VIcons.calendar,
                label: 'Từ ngày',
                value: _formatDate(rule.effectivePeriod.effectiveFrom),
                numeric: true,
              ),
              PriceRuleIconDetailRow(
                icon: VIcons.calendar,
                label: 'Đến ngày',
                value: rule.effectivePeriod.effectiveTo != null
                    ? _formatDate(rule.effectivePeriod.effectiveTo!)
                    : 'Không giới hạn',
                numeric: rule.effectivePeriod.effectiveTo != null,
              ),
              PriceRuleIconDetailRow(
                icon: VIcons.download,
                label: 'Nguồn tạo',
                value: _formatSource(rule.sourceType),
                isLast: true,
              ),
            ],
          ),

          if (rule.persistedStatus == CustomerPriceRuleStatus.disabled) ...[
            const VGap.md(),
            PriceRuleDetailSectionCard(
              title: 'Thông tin tắt',
              children: [
                PriceRuleIconDetailRow(
                  icon: VIcons.person,
                  label: 'Người tắt',
                  value: rule.disabledBy ?? '—',
                ),
                PriceRuleIconDetailRow(
                  icon: VIcons.calendar,
                  label: 'Thời gian',
                  value: rule.disabledAt != null
                      ? _formatDateTime(rule.disabledAt!)
                      : '—',
                  numeric: rule.disabledAt != null,
                ),
                PriceRuleIconDetailRow(
                  icon: VIcons.edit,
                  label: 'Lý do',
                  value: rule.disabledReason?.isNotEmpty == true
                      ? rule.disabledReason!
                      : 'Không có',
                  isLast: true,
                ),
              ],
            ),
          ],
          if (onViewHistory != null ||
              (recentActivities != null && recentActivities!.isNotEmpty)) ...[
            const VGap.md(),
            PriceRuleDetailSectionCard(
              title: 'Lịch sử gần đây',
              children: [
                if (recentActivities != null &&
                    recentActivities!.isNotEmpty) ...[
                  for (var i = 0; i < recentActivities!.take(3).length; i++) ...[
                    PriceRuleRecentHistoryItem(
                      activity: recentActivities!.take(3).elementAt(i),
                    ),
                    if (i < recentActivities!.take(3).length - 1) ...[
                      const VGap.md(),
                      Divider(height: 1, color: colors.borderDefault),
                      const VGap.md(),
                    ] else ...[
                      const VGap.md(),
                    ],
                  ],
                  Divider(height: 1, color: colors.borderDefault),
                  const VGap.md(),
                ],
                if (onViewHistory != null)
                  InkWell(
                    onTap: onViewHistory,
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: VSpacing.space1,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          VText(
                            'Xem tất cả lịch sử',
                            variant: VTextVariant.bodyDefault,
                            color: colors.primary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const VGap.horizontalXs(),
                          VIcon(
                            icon: VIcons.chevronRight,
                            size: 18,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const VGap.xl(),
        ],
      ),
    );
  }

  String _formatMoney(MoneyDto money) {
    return '${money.amountMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';
  }

  String _formatDiff(int diffMinor, {int? listPriceMinor}) {
    final sign = diffMinor > 0 ? '+' : '';
    final amountLabel =
        '$sign${diffMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';
    if (listPriceMinor == null || listPriceMinor == 0) return amountLabel;
    final pct = (diffMinor / listPriceMinor) * 100;
    final pctLabel = pct.toStringAsFixed(1).replaceAll('.', ',');
    return '$amountLabel ($sign$pctLabel%)';
  }

  String _formatDate(DateTime d) => VDateTime.date(d);

  String _formatDateTime(DateTime d) =>
      PriceRuleHistoryShared.formatDateTime(d);

  String _formatSource(CustomerPriceRuleSourceType src) => switch (src) {
    CustomerPriceRuleSourceType.manual => 'Tạo thủ công',
    CustomerPriceRuleSourceType.excelImport => 'Nhập Excel',
    CustomerPriceRuleSourceType.salesOrder => 'Từ đơn hàng',
    CustomerPriceRuleSourceType.migration => 'Migration',
  };
}
