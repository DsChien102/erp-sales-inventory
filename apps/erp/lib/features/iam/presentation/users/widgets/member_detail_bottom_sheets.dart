import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

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
          Semantics(
            header: true,
            child: VText(
              'Đổi vai trò của ${member.name}?',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
            variant: VButtonVariant.secondary,
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
          Semantics(
            header: true,
            child: VText(
              'Tạm ngừng thành viên?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
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
            variant: VButtonVariant.secondary,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Tạm ngừng',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
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
                suspendedAt: member.suspendedAt ?? '—',
                suspendedBy: member.suspendedBy,
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
          Semantics(
            header: true,
            child: VText(
              'Kích hoạt lại thành viên?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
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
            variant: VButtonVariant.secondary,
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
          Semantics(
            header: true,
            child: VText(
              'Loại thành viên khỏi tổ chức?',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
            ),
          ),
          const VGap.xs(),
          VText(
            'Thành viên sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Loại thành viên',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
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
                removedAt: member.removedAt ?? '—',
                removedBy: member.removedBy,
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
