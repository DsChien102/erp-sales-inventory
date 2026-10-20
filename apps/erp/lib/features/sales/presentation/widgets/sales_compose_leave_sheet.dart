import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// O-02 — Thoát màn soạn đơn khi còn thay đổi chưa lưu.
enum SalesComposeLeaveAction {
  continueEditing,
  saveAndClose,
  discardAndClose,
}

Future<SalesComposeLeaveAction?> showSalesComposeLeaveSheet(
  BuildContext context,
) {
  return showVBottomSheet<SalesComposeLeaveAction>(
    context: context,
    semanticLabel: 'Đơn có thay đổi chưa lưu',
    child: const _SalesComposeLeaveSheetBody(),
  );
}

class _SalesComposeLeaveSheetBody extends StatelessWidget {
  const _SalesComposeLeaveSheetBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPagePadding(
      child: Column(
        key: const Key('wgt_sg02_leave_sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Đơn có thay đổi chưa lưu',
            variant: VTextVariant.headingH4,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.md(),
          _LeaveOptionCard(
            key: const Key('btn_compose_leave_continue'),
            icon: VIcons.pencil,
            title: 'Tiếp tục soạn đơn',
            subtitle: 'Giữ nguyên dữ liệu và quay lại đơn',
            onTap: () => Navigator.of(context).pop(
              SalesComposeLeaveAction.continueEditing,
            ),
          ),
          const VGap.sm(),
          _LeaveOptionCard(
            key: const Key('btn_compose_leave_save'),
            icon: VIcons.save,
            title: 'Lưu nháp và đóng',
            subtitle: 'Lưu thay đổi rồi thoát',
            onTap: () => Navigator.of(context).pop(
              SalesComposeLeaveAction.saveAndClose,
            ),
          ),
          const VGap.sm(),
          _LeaveOptionCard(
            key: const Key('btn_compose_leave_discard'),
            icon: VIcons.delete,
            title: 'Bỏ thay đổi và đóng',
            subtitle: 'Không lưu các thay đổi',
            destructive: true,
            onTap: () => Navigator.of(context).pop(
              SalesComposeLeaveAction.discardAndClose,
            ),
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}

class _LeaveOptionCard extends StatelessWidget {
  const _LeaveOptionCard({
    super.key,
    this.icon,
    this.iconData,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  }) : assert(icon != null || iconData != null);

  final VIcons? icon;
  final IconData? iconData;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final bgColor = destructive ? colors.dangerBg : colors.surface;
    final borderColor = destructive ? colors.danger.withValues(alpha: 0.3) : colors.borderDefault;
    final iconColor = destructive ? colors.danger : colors.textPrimary;
    final titleColor = destructive ? colors.danger : colors.textPrimary;
    final subtitleColor = destructive ? colors.danger.withValues(alpha: 0.7) : colors.textSecondary;
    final chevronColor = destructive ? colors.danger : colors.textMuted;

    return VCard(
      onTap: onTap,
      backgroundColor: bgColor,
      border: Border.all(color: borderColor),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          if (icon != null)
            VIcon(
              icon: icon!,
              size: 22,
              color: iconColor,
            )
          else if (iconData != null)
            Icon(
              iconData,
              size: 22,
              color: iconColor,
            ),
          const VGap.horizontalCozy(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  color: titleColor,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: VSpacing.space1),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VIcon(
            icon: VIcons.chevronRight,
            size: 20,
            color: chevronColor,
          ),
        ],
      ),
    );
  }
}
