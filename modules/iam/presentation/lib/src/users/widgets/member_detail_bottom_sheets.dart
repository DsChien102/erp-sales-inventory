import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

/// Helper Option Card dùng trong Bottom Sheet thao tác thành viên.
class MemberDetailOptionItem extends StatelessWidget {
  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const MemberDetailOptionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

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
            width: 1,
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

/// Helper hiển thị confirm bottom sheet đổi vai trò.
void showChangeRoleConfirmBottomSheet({
  required BuildContext context,
  required MemberUiModel member,
  required String newRole,
  required ValueChanged<MemberUiModel> onConfirmed,
}) {
  final colors = context.vColors;

  showVBottomSheet(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Đổi vai trò của ${member.name}?',
            variant: VTextVariant.headingH3,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.xs(),
          VText(
            'Vai trò ${member.role} → $newRole. Quyền mới có hiệu lực ở yêu cầu tiếp theo.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Xác nhận thay đổi',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              final updated = MemberUiModel(
                id: member.id,
                name: member.name,
                email: member.email,
                role: newRole,
                status: member.status,
                identityText: member.identityText,
                joinedDate: member.joinedDate,
                lastActiveDate: member.lastActiveDate,
                dataVersion: 'v9',
                suspendedAt: member.suspendedAt,
                suspendedBy: member.suspendedBy,
              );
              onConfirmed(updated);
              VToast.show(
                context,
                title: 'Đã thay đổi vai trò.',
                message: '',
                type: VToastType.success,
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Helper hiển thị confirm bottom sheet tạm ngừng thành viên.
void showSuspendConfirmBottomSheet({
  required BuildContext context,
  required MemberUiModel member,
  required ValueChanged<MemberUiModel> onConfirmed,
}) {
  final colors = context.vColors;

  showVBottomSheet(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Tạm ngừng thành viên?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.danger,
            ),
          ),
          const VGap.xs(),
          VText(
            'Thành viên mất quyền truy cập tới khi được kích hoạt lại.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Tạm ngừng',
            variant: VButtonVariant.dangerOutline,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              final updated = MemberUiModel(
                id: member.id,
                name: member.name,
                email: member.email,
                role: member.role,
                status: MemberStatus.suspended,
                identityText: member.identityText,
                joinedDate: member.joinedDate,
                lastActiveDate: member.lastActiveDate,
                dataVersion: member.dataVersion,
                suspendedAt: member.suspendedAt ?? '14/07/2026 · 09:30',
                suspendedBy: member.suspendedBy ?? 'Lê Thị Lan',
              );
              onConfirmed(updated);
              VToast.show(
                context,
                title: 'Đã tạm ngừng thành viên.',
                message: '',
                type: VToastType.success,
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Helper hiển thị confirm bottom sheet kích hoạt lại thành viên.
void showReactivateConfirmBottomSheet({
  required BuildContext context,
  required MemberUiModel member,
  required ValueChanged<MemberUiModel> onConfirmed,
}) {
  final colors = context.vColors;

  showVBottomSheet(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Kích hoạt lại thành viên?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.xs(),
          VText(
            'Quyền truy cập sẽ được khôi phục theo vai trò hiện hành.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Kích hoạt lại',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              final updated = MemberUiModel(
                id: member.id,
                name: member.name,
                email: member.email,
                role: member.role,
                status: MemberStatus.active,
                identityText: member.identityText,
                joinedDate: member.joinedDate,
                lastActiveDate: member.lastActiveDate,
                dataVersion: 'v10',
                suspendedAt: member.suspendedAt,
                suspendedBy: member.suspendedBy,
              );
              onConfirmed(updated);
              VToast.show(
                context,
                title: 'Đã kích hoạt lại thành viên.',
                message: '',
                type: VToastType.success,
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// Helper hiển thị confirm bottom sheet loại thành viên.
void showRemoveConfirmBottomSheet({
  required BuildContext context,
  required MemberUiModel member,
  required ValueChanged<MemberUiModel> onConfirmed,
}) {
  final colors = context.vColors;

  showVBottomSheet(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Loại thành viên khỏi tổ chức?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.danger,
            ),
          ),
          const VGap.xs(),
          VText(
            'Membership sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Loại thành viên',
            variant: VButtonVariant.dangerOutline,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              final updated = MemberUiModel(
                id: member.id,
                name: member.name,
                email: member.email,
                role: member.role,
                status: MemberStatus.removed,
                identityText: member.identityText,
                joinedDate: member.joinedDate,
                lastActiveDate: member.lastActiveDate,
                dataVersion: member.dataVersion,
                suspendedAt: member.suspendedAt,
                suspendedBy: member.suspendedBy,
                removedAt: member.removedAt ?? '14/07/2026 · 09:45',
                removedBy: member.removedBy ?? 'Lê Thị Lan',
                previousRole: member.previousRole ?? member.role,
              );
              onConfirmed(updated);
              VToast.show(
                context,
                title: 'Đã loại thành viên khỏi tổ chức.',
                message: '',
                type: VToastType.success,
              );
            },
          ),
        ],
      ),
    ),
  );
}
