import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

enum SalesOrderSheetAction { returnExchange, cancel }

Future<SalesOrderSheetAction?> showSalesOrderActionsSheet(
  BuildContext context, {
  required bool canReturnExchange,
  required bool canCancel,
  String? cancelDisabledReason,
}) {
  return showVBottomSheet<SalesOrderSheetAction>(
    context: context,
    title: 'Thao tác',
    semanticLabel: 'Thao tác',
    child: _SalesOrderActionsSheetBody(
      canReturnExchange: canReturnExchange,
      canCancel: canCancel,
      cancelDisabledReason: cancelDisabledReason,
    ),
  );
}

class _SalesOrderActionsSheetBody extends StatelessWidget {
  const _SalesOrderActionsSheetBody({
    required this.canReturnExchange,
    required this.canCancel,
    this.cancelDisabledReason,
  });

  final bool canReturnExchange;
  final bool canCancel;
  final String? cancelDisabledReason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionOptionTile(
            key: const Key('btn_order_action_return'),
            icon: VIcons.history,
            title: 'Đổi/trả hàng',
            subtitle: 'Chọn hàng khách trả hoặc đổi',
            enabled: canReturnExchange,
            onTap: () => Navigator.of(context).pop(SalesOrderSheetAction.returnExchange),
          ),
          const VGap.sm(),
          _ActionOptionTile(
            key: const Key('btn_order_action_cancel'),
            icon: VIcons.fileXCorner,
            title: 'Hủy đơn',
            subtitle: !canCancel && cancelDisabledReason != null
                ? cancelDisabledReason!
                : 'Kiểm tra điều kiện và tác động trước khi hủy',
            isDestructive: true,
            enabled: canCancel,
            onTap: () => Navigator.of(context).pop(SalesOrderSheetAction.cancel),
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}

class _ActionOptionTile extends StatelessWidget {
  const _ActionOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.enabled = true,
    this.onTap,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final titleColor = enabled
        ? (isDestructive ? colors.danger : colors.textPrimary)
        : colors.textMuted;
    final subtitleColor = colors.textSecondary;
    final iconColor = enabled
        ? (isDestructive ? colors.danger : colors.textPrimary)
        : colors.textMuted;
    final chevronColor = enabled
        ? (isDestructive ? colors.danger : colors.textMuted)
        : colors.borderDefault;

    return VCard(
      onTap: enabled ? onTap : null,
      backgroundColor: enabled
          ? (isDestructive ? colors.dangerBg : colors.surface)
          : colors.surfaceAlt,
      border: Border.all(
        color: enabled
            ? (isDestructive ? colors.danger.withValues(alpha: 0.3) : colors.borderDefault)
            : colors.borderDefault,
      ),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          VIcon(
            icon: icon,
            size: 22,
            color: iconColor,
          ),
          const VGap.horizontalSm(),
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
                const VGap.xs(),
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
