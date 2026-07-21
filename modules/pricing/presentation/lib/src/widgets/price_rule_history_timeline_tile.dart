import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_pricing_application/application.dart';

import 'price_rule_activity_detail_sheet.dart';
import 'price_rule_history_shared.dart';

/// Timeline row trong [PriceRuleHistoryView] (SG-06 D-02).
class PriceRuleHistoryTimelineTile extends StatelessWidget {
  const PriceRuleHistoryTimelineTile({
    super.key,
    required this.activity,
    required this.isLast,
    required this.hasSensitivePermission,
    this.onViewRuleDetail,
  });

  final CustomerPriceRuleActivityDto activity;
  final bool isLast;
  final bool hasSensitivePermission;
  final VoidCallback? onViewRuleDetail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final oldValue = activity.oldValue;
    final newValue = activity.newValue;

    final oldPrice = (oldValue?['rule_price_minor'] as num?)?.toInt();
    final newPrice = (newValue['rule_price_minor'] as num?)?.toInt();

    final orderId = activity.sourceTrace.orderId;
    final summary = PriceRuleHistoryShared.activitySummary(activity);

    return InkWell(
      onTap: () {
        PriceRuleActivityDetailSheet.show(
          context: context,
          activity: activity,
          hasSensitivePermission: hasSensitivePermission,
          onViewRuleDetail: onViewRuleDetail,
        );
      },
      borderRadius: BorderRadius.circular(VRadius.r8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                VIconBox(
                  icon: PriceRuleHistoryShared.activityIcon(activity.activityType),
                  size: 36,
                  iconSize: 18,
                  tone: PriceRuleHistoryShared.activityTone(activity.activityType),
                  isCircular: true,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.borderDefault,
                    ),
                  ),
              ],
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.space3),
                child: VCard(
                  padding: const EdgeInsets.all(VSpacing.space3),
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
                                  PriceRuleHistoryShared.activityLabel(
                                    activity.activityType,
                                  ),
                                  variant: VTextVariant.bodyDefault,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const VGap.xs(),
                                VText(
                                  '${activity.actor.displayName} · ${PriceRuleHistoryShared.sourceLabel(activity.sourceType)}',
                                  variant: VTextVariant.caption,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              VBadge(
                                label: PriceRuleHistoryShared.sourceLabel(
                                  activity.sourceType,
                                ),
                                status: PriceRuleHistoryShared.sourceBadgeStatus(
                                  activity.sourceType,
                                ),
                                isSmall: true,
                              ),
                              const VGap.xs(),
                              VText(
                                PriceRuleHistoryShared.formatDateTime(
                                  activity.createdAt,
                                ),
                                variant: VTextVariant.caption,
                                color: colors.textMuted,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          const VGap.horizontalXs(),
                          VIcon(
                            icon: VIcons.chevronRight,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                      if (summary != null) ...[
                        const VGap.xs(),
                        if (activity.activityType ==
                                CustomerPriceRuleActivityType.updated &&
                            oldPrice != null &&
                            newPrice != null)
                          Row(
                            children: [
                              VText(
                                'Giá đổi từ ',
                                variant: VTextVariant.bodySmall,
                                color: colors.textSecondary,
                              ),
                              VText(
                                PriceRuleHistoryShared.formatMoney(oldPrice),
                                variant: VTextVariant.bodySmallMono,
                                color: colors.textPrimary,
                              ),
                              VText(
                                ' → ',
                                variant: VTextVariant.bodySmall,
                                color: colors.success,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Flexible(
                                child: VText(
                                  PriceRuleHistoryShared.formatMoney(newPrice),
                                  variant: VTextVariant.bodySmallMono,
                                  color: colors.success,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        else if (orderId != null)
                          VText(
                            'Đơn #$orderId',
                            variant: VTextVariant.bodySmallMono,
                            color: colors.primary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )
                        else
                          VText(
                            summary,
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
