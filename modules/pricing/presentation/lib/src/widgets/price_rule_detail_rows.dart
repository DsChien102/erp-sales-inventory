import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import 'price_rule_history_shared.dart';

/// Cột label cố định — khớp pattern PartnerDetailInfoRow (+ chỗ icon).
const double kPriceRuleDetailLabelWidth = 128;

/// Section card: title + divider trong [VCard], padding thoáng đẹp như design.
class PriceRuleDetailSectionCard extends StatelessWidget {
  const PriceRuleDetailSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            title,
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.md(),
          Divider(height: 1, thickness: 1, color: colors.borderDefault),
          const VGap.md(),
          ...children,
        ],
      ),
    );
  }
}

class PriceRuleIconDetailRow extends StatelessWidget {
  const PriceRuleIconDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
    this.numeric = false,
    this.isLast = false,
  });

  final VIcons icon;
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;
  final bool numeric;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: VIcon(icon: icon, size: 18, color: colors.primary),
          ),
          const VGap.horizontalSm(),
          SizedBox(
            width: kPriceRuleDetailLabelWidth,
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: VText(
              value,
              variant: numeric
                  ? VTextVariant.bodySmallMono
                  : VTextVariant.bodySmall,
              color: valueColor ?? colors.textPrimary,
              textAlign: TextAlign.end,
              style: valueWeight == null
                  ? null
                  : TextStyle(fontWeight: valueWeight),
            ),
          ),
        ],
      ),
    );
  }
}

class PriceRuleIconDetailRowWidget extends StatelessWidget {
  const PriceRuleIconDetailRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.isLast = false,
  });

  final VIcons icon;
  final String label;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            child: VIcon(icon: icon, size: 18, color: colors.primary),
          ),
          const VGap.horizontalSm(),
          SizedBox(
            width: kPriceRuleDetailLabelWidth,
            child: VText(
              label,
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}

class PriceRuleRecentHistoryItem extends StatelessWidget {
  const PriceRuleRecentHistoryItem({super.key, required this.activity});

  final CustomerPriceRuleActivityDto activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final oldValue = activity.oldValue;
    final newValue = activity.newValue;
    final oldPrice = (oldValue?['rule_price_minor'] as num?)?.toInt();
    final newPrice = (newValue['rule_price_minor'] as num?)?.toInt();

    final orderId = activity.sourceTrace.orderId;
    final summary = PriceRuleHistoryShared.activitySummary(activity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VIconBox(
          icon: PriceRuleHistoryShared.activityIcon(activity.activityType),
          size: 32,
          iconSize: 16,
          tone: PriceRuleHistoryShared.activityTone(activity.activityType),
          isCircular: true,
        ),
        const VGap.horizontalSm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: VText(
                      PriceRuleHistoryShared.activityLabelDetail(
                        activity.activityType,
                      ),
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  VText(
                    PriceRuleHistoryShared.formatDateTime(activity.createdAt),
                    variant: VTextVariant.bodySmall,
                    color: colors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              VText(
                '${activity.actor.displayName} · ${PriceRuleHistoryShared.sourceLabel(activity.sourceType)}',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 4),
              if (activity.activityType ==
                      CustomerPriceRuleActivityType.updated &&
                  oldPrice != null &&
                  newPrice != null)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VText(
                      'Giá đổi từ ',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    VText(
                      PriceRuleHistoryShared.formatMoney(oldPrice),
                      variant: VTextVariant.bodySmall,
                      color: colors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    VText(
                      ' → ',
                      variant: VTextVariant.bodySmall,
                      color: colors.success,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    VText(
                      PriceRuleHistoryShared.formatMoney(newPrice),
                      variant: VTextVariant.bodySmall,
                      color: colors.success,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else if (orderId != null)
                VText(
                  'Đơn #$orderId',
                  variant: VTextVariant.bodySmall,
                  color: colors.primary,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )
              else if (summary != null)
                VText(
                  summary,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                )
              else
                VText(
                  'Giá áp dụng: ${newPrice != null ? PriceRuleHistoryShared.formatMoney(newPrice) : '—'}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
