import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import 'price_rule_status_badge.dart';

/// Card danh sách giá riêng — dùng [VCard] + [VBadge] theo design system.
///
/// Layout — badge cạnh khối tên/SP (không chung chiều cao với cả card),
/// nên 2 badge không đẩy giá / hiệu lực xuống:
/// ```
/// [Avatar]  Tên KH                    [Đã tắt]
///           Tên sản phẩm              [Dưới giá sàn]
///           Đơn vị: …
///           Giá riêng          Giá niêm yết
///           Hiệu lực: …                   >
/// ```
class PriceRuleCard extends StatelessWidget {
  const PriceRuleCard({super.key, required this.rule, this.onTap});

  final CustomerPriceRuleListItemDto rule;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isBelowFloor = rule.validationOutcome.warningCodes.contains(
      'below_floor_price',
    );
    final listPrice = rule.validationOutcome.listPrice;
    final specialColor = isBelowFloor ? colors.danger : colors.textPrimary;

    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VAvatar(name: rule.customer.displayName, textSize: 14),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VText(
                            rule.customer.displayName,
                            variant: VTextVariant.bodyDefault,
                            color: colors.textPrimary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const VGap.xs(),
                          VText(
                            rule.productUnit.productName,
                            variant: VTextVariant.bodyDefault,
                            color: colors.textPrimary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const VGap.xs(),
                          VText(
                            'Đơn vị: ${rule.productUnit.unitName}',
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const VGap.horizontalSm(),
                    _StatusBadges(
                      status: rule.derivedStatus,
                      isBelowFloor: isBelowFloor,
                    ),
                  ],
                ),
                const VGap.sm(),
                Row(
                  children: [
                    Expanded(
                      child: _PriceColumn(
                        label: 'Giá riêng',
                        value: _formatMoney(rule.price),
                        valueColor: specialColor,
                      ),
                    ),
                    Expanded(
                      child: _PriceColumn(
                        label: 'Giá niêm yết',
                        value: listPrice != null
                            ? _formatMoney(listPrice)
                            : '—',
                        valueColor: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const VGap.sm(),
                Row(
                  children: [
                    Expanded(
                      child: VText(
                        'Hiệu lực: ${_formatEffective(rule.effectivePeriod)}',
                        variant: VTextVariant.bodySmall,
                        color: colors.textMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    VIcon(
                      icon: VIcons.chevronRight,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(MoneyDto money) {
    return '${money.amountMinor.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatEffective(EffectivePeriodDto period) {
    final from = _formatDate(period.effectiveFrom);
    final to = period.effectiveTo == null
        ? 'Không giới hạn'
        : _formatDate(period.effectiveTo!);
    return '$from – $to';
  }
}

/// Cột badge status — cùng chiều rộng khi có 2 badge (theo badge dài hơn).
class _StatusBadges extends StatelessWidget {
  const _StatusBadges({required this.status, required this.isBelowFloor});

  final CustomerPriceRuleDerivedStatus status;
  final bool isBelowFloor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PriceRuleStatusBadge(status: status),
          if (isBelowFloor) ...[
            const VGap.xs(),
            const VBadge(
              label: 'Dưới giá sàn',
              status: VBadgeStatus.danger,
              isSmall: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(label, variant: VTextVariant.caption, color: colors.textMuted),
        const VGap.xs(),
        VText(
          value,
          variant: VTextVariant.monoNumeric,
          color: valueColor,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
