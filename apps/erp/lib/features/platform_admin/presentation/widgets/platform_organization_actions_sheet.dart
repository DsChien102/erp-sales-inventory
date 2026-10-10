import 'package:erp/core/session/models/tenant_context.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/platform_tenant_ui.dart';

/// C3 — sheet "Thao tác tổ chức". Chỉ hiện thao tác hợp lệ với [status] (BR-12, BR-13).
class PlatformOrganizationActionsSheet extends StatelessWidget {
  const PlatformOrganizationActionsSheet({
    super.key,
    required this.status,
    this.onSuspend,
    this.onRestore,
    this.onClose,
    this.onChangeOwner,
  });

  final TenantStatus status;
  final VoidCallback? onSuspend;
  final VoidCallback? onRestore;
  final VoidCallback? onClose;
  final VoidCallback? onChangeOwner;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    void choose(VoidCallback? action) {
      Navigator.of(context).pop();
      action?.call();
    }

    final actions = <Widget>[
      if (status.canSuspend)
        _ActionCard(
          key: const Key('platform_action_suspend'),
          title: 'Tạm ngừng tổ chức',
          subtitle: 'Chặn toàn bộ quyền vận hành',
          icon: VIcons.pause,
          isDanger: true,
          onTap: () => choose(onSuspend),
        ),
      if (status.canRestore)
        _ActionCard(
          key: const Key('platform_action_restore'),
          title: 'Khôi phục tổ chức',
          subtitle: 'Cho phép vận hành trở lại',
          icon: VIcons.restore,
          onTap: () => choose(onRestore),
        ),
      if (status.canClose)
        _ActionCard(
          key: const Key('platform_action_close'),
          title: 'Đóng tổ chức',
          subtitle: 'Ngừng hoạt động vĩnh viễn, không thể khôi phục',
          icon: VIcons.lock,
          isDanger: true,
          onTap: () => choose(onClose),
        ),
      if (status.canChangeOwner)
        _ActionCard(
          key: const Key('platform_action_change_owner'),
          title: 'Thay đổi chủ sở hữu',
          subtitle: 'Chọn Chủ sở hữu mới',
          icon: VIcons.person,
          onTap: () => choose(onChangeOwner),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.space4,
        right: VSpacing.space4,
        top: VSpacing.space2,
        bottom: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.space4),
            child: VText(
              'Thao tác tổ chức',
              variant: VTextVariant.headingH3,
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const VGap.md(),
            actions[i],
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  final String title;
  final String subtitle;
  final VIcons icon;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final borderColor = isDanger ? colors.danger.withValues(alpha: 0.4) : colors.borderDefault;
    final textColor = isDanger ? colors.danger : colors.textPrimary;
    final subtitleColor = isDanger ? colors.danger.withValues(alpha: 0.8) : colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r16),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.space4),
          decoration: BoxDecoration(
            color: isDanger ? colors.dangerBg : colors.surface,
            borderRadius: BorderRadius.circular(VRadius.r16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              VIcon(icon: icon, size: 24, color: textColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      title,
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    VText(subtitle, variant: VTextVariant.bodySmall, color: subtitleColor),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VIcon(
                icon: VIcons.chevronRight,
                size: 20,
                color: isDanger ? colors.danger : colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
