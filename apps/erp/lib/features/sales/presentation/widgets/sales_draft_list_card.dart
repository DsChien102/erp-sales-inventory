import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../models/sales_order_draft/sales_draft_list_item_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// Card đơn nháp — [VSwipeReveal] vuốt trái để xóa (SG-01).
class SalesDraftListCard extends StatelessWidget {
  const SalesDraftListCard({
    super.key,
    required this.item,
    required this.showCreatedBy,
    required this.onTap,
    required this.onDiscard,
  });

  final SalesDraftListItemVm item;
  final bool showCreatedBy;
  final VoidCallback onTap;
  final VoidCallback onDiscard;

  static const double _actionWidth = 100;

  String _timestampLabel(DateTime value) {
    final nowIct = VDateTime.toIct(DateTime.now());
    final valueIct = VDateTime.toIct(value);
    final today = DateTime.utc(nowIct.year, nowIct.month, nowIct.day);
    final day = DateTime.utc(valueIct.year, valueIct.month, valueIct.day);
    if (day == today) return VDateTime.time(value);
    if (day == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    final d = valueIct.day.toString().padLeft(2, '0');
    final m = valueIct.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final creator = item.creatorLabel;
    final phoneLine = showCreatedBy && creator != null && creator.isNotEmpty
        ? '${item.phoneLabel} · Tạo bởi: $creator'
        : item.phoneLabel;
    final note = item.note?.trim();
    final supportingText2 = (note == null || note.isEmpty) ? null : note;
    final summary = '${item.lineCount} mặt hàng · ${MoneyFormatter.format(amountMinor: item.total.amountMinor, currencyCode: item.total.currencyCode)}';
    final timestamp = _timestampLabel(item.updatedAt);
    final badgeLabel = item.needsCheck ? item.statusLabel : null;
    final hasBadge = badgeLabel != null && badgeLabel.trim().isNotEmpty;
    final cardRadius = BorderRadius.circular(VRadius.card);
    final borderWidth = VBorders.widthFor(VComponentEmphasis.medium);

    return Semantics(
      label: item.customerLabel,
      button: true,
      child: VSwipeReveal(
        actionExtent: _actionWidth,
        clipBorderRadius: cardRadius,
        semanticActions: [
          VSwipeSemanticAction(label: 'Xóa', onInvoke: onDiscard),
        ],
        actionsBuilder: (context, close) => SizedBox(
          height: double.infinity,
          width: _actionWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VGap.horizontalSm(),
              Expanded(
                child: VButton(
                  tone: VComponentTone.danger,
                  onPressed: () {
                    onDiscard();
                    close();
                  },
                  label: 'Xóa',
                ),
              ),
            ],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: VCard(
            onTap: onTap,
            padding: EdgeInsets.zero,
            border: VBorders.all(colors.borderDefault, width: borderWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VCardHeader(
                  title: VCardTitle(item.customerLabel, description: phoneLine),
                  action: hasBadge
                      ? VCardAction(
                          child: VBadge(
                            label: badgeLabel,
                            tone: VComponentTone.warning,
                            variant: VBadgeVariant.soft,
                            isSmall: true,
                          ),
                        )
                      : null,
                ),
                VCardContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supportingText2 != null) ...[
                        VText(
                          supportingText2,
                          variant: VTextVariant.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: colors.textPrimary,
                        ),
                        const VGap.sm(),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          VText(
                            summary,
                            variant: VTextVariant.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: colors.textSecondary,
                          ),
                          VText(
                            timestamp,
                            variant: VTextVariant.caption,
                            color: colors.textSecondary,
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
