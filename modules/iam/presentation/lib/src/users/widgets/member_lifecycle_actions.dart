import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../bloc/organization_member_detail_state.dart';

/// Action sheet for membership lifecycle (no role-change in phase 1).
Future<void> showMemberLifecycleActionsBottomSheet({
  required BuildContext context,
  required OrganizationMemberDetailState state,
  required VoidCallback onDeactivate,
  required VoidCallback onReactivate,
  required VoidCallback onRemove,
}) {
  return showVBottomSheet<void>(
    context: context,
    child: Padding(
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
          const VText(
            'Thao tác thành viên',
            variant: VTextVariant.headingH3,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.md(),
          if (state.canDeactivate)
            _LifecycleActionItem(
              icon: VIcons.pause,
              title: 'Tạm ngừng thành viên',
              subtitle: 'Dừng quyền truy cập tạm thời',
              onTap: () {
                Navigator.of(context).pop();
                onDeactivate();
              },
            ),
          if (state.canReactivate)
            _LifecycleActionItem(
              icon: VIcons.personCheck,
              title: 'Kích hoạt lại',
              subtitle: 'Khôi phục quyền truy cập',
              onTap: () {
                Navigator.of(context).pop();
                onReactivate();
              },
            ),
          if (state.canRemove) ...[
            if (state.canDeactivate || state.canReactivate) const VGap.sm(),
            _LifecycleActionItem(
              icon: VIcons.personRemove,
              title: 'Loại khỏi tổ chức',
              subtitle: 'Kết thúc tư cách thành viên',
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                onRemove();
              },
            ),
          ],
        ],
      ),
    ),
  );
}

class _LifecycleActionItem extends StatelessWidget {
  const _LifecycleActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.card),
      child: Container(
        padding: const EdgeInsets.all(VSpacing.space4),
        decoration: BoxDecoration(
          color: isDanger ? colors.dangerBg : colors.surface,
          border: Border.all(
            color: isDanger ? colors.danger : colors.borderDefault,
          ),
          borderRadius: BorderRadius.circular(VRadius.card),
        ),
        child: Row(
          children: [
            VIcon(
              icon: icon,
              size: 24,
              color: isDanger ? colors.danger : colors.textPrimary,
            ),
            const VGap.horizontalMd(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    title,
                    variant: VTextVariant.bodyDefault,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDanger ? colors.danger : colors.textPrimary,
                    ),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            VIcon(
              icon: VIcons.chevronRight,
              size: 20,
              color: isDanger ? colors.danger : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
