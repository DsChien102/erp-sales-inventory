import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/pricing/data/models.dart';

/// Bottom sheet Thao tác từ màn chi tiết (D-08 — SG-02).
///
/// Chỉ liệt kê action theo [CustomerPriceRuleDetailDto.availableActions]
/// (không header tóm tắt KH/SP — thông tin đó đã có trên màn chi tiết).
/// Action rows dùng [Material]+[InkWell] (không [ListTile]) để tránh
/// exception "ListTile background color or ink splashes may be invisible"
/// khi sheet không có Material ancestor rõ ràng.
class PriceRuleActionSheet extends StatelessWidget {
  const PriceRuleActionSheet({
    super.key,
    required this.rule,
    this.onEdit,
    this.onDisable,
    this.onReenable,
    this.onHistory,
  });

  final CustomerPriceRuleDetailDto rule;
  final VoidCallback? onEdit;
  final VoidCallback? onDisable;
  final VoidCallback? onReenable;
  final VoidCallback? onHistory;

  static Future<void> show({
    required BuildContext context,
    required CustomerPriceRuleDetailDto rule,
    VoidCallback? onEdit,
    VoidCallback? onDisable,
    VoidCallback? onReenable,
    VoidCallback? onHistory,
  }) {
    return showVBottomSheet(
      context: context,
      title: 'Thao tác',
      child: PriceRuleActionSheet(
        rule: rule,
        onEdit: onEdit,
        onDisable: onDisable,
        onReenable: onReenable,
        onHistory: onHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = rule.availableActions;
    final colors = context.vColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (actions.contains(CustomerPriceRuleAvailableActions.edit))
                _ActionTile(
                  icon: VIcons.edit,
                  label: 'Sửa giá riêng',
                  onTap: () {
                    Navigator.of(context).pop();
                    onEdit?.call();
                  },
                ),
              if (actions.contains(CustomerPriceRuleAvailableActions.disable))
                _ActionTile(
                  icon: VIcons.powerOff,
                  label: 'Tắt giá riêng',
                  color: colors.danger,
                  onTap: () {
                    Navigator.of(context).pop();
                    onDisable?.call();
                  },
                ),
              if (actions.contains(CustomerPriceRuleAvailableActions.reenable))
                _ActionTile(
                  icon: VIcons.power,
                  label: 'Bật lại giá riêng',
                  color: colors.success,
                  onTap: () {
                    Navigator.of(context).pop();
                    onReenable?.call();
                  },
                ),
              if (actions.contains(CustomerPriceRuleAvailableActions.history))
                _ActionTile(
                  icon: VIcons.history,
                  label: 'Lịch sử áp dụng & thay đổi',
                  onTap: () {
                    Navigator.of(context).pop();
                    onHistory?.call();
                  },
                ),
              if (actions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(VSpacing.space4),
                  child: VEmptyState(
                    icon: VIcons.shield,
                    title: 'Không có thao tác khả dụng',
                    description:
                        'Bạn không có quyền thực hiện thao tác trên giá riêng này.',
                  ),
                ),
              const VGap.md(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final VIcons icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final effectiveColor = color ?? colors.primary;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space3,
          ),
          child: Row(
            children: [
              VIconBox(
                icon: icon,
                size: 40,
                iconSize: 18,
                iconColor: effectiveColor,
                backgroundColor: effectiveColor.withValues(alpha: 0.1),
                borderRadius: VRadius.r12,
              ),
              const VGap.horizontalMd(),
              Expanded(
                child: VText(
                  label,
                  variant: VTextVariant.bodyDefault,
                  color: color ?? colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              VIcon(
                icon: VIcons.chevronRight,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
