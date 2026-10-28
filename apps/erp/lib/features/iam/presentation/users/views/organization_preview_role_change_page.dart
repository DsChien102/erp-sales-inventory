import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

/// Màn hình xem trước đổi vai trò (US-06.5).
class OrganizationPreviewRoleChangePage extends StatelessWidget {
  final MemberUiModel member;
  final String newRole;

  const OrganizationPreviewRoleChangePage({
    super.key,
    required this.member,
    required this.newRole,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isActive = member.status == MemberStatus.active;

    return VPageScaffold(
      title: 'Xem trước thay đổi',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Quay lại',
                variant: VButtonVariant.secondary,
                tone: VComponentTone.neutral,
                fullWidth: true,
                onPressed: () => context.pop(),
              ),
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: VButton(
                label: 'Tiếp tục',
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: () => context.pop(newRole),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          // Top Summary Card
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: VText(
                          member.name,
                          variant: VTextVariant.headingH4,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    VBadge(
                      label: isActive ? 'Hoạt động' : 'Tạm ngừng',
                      tone: isActive ? VComponentTone.success : VComponentTone.danger,
                      variant: VBadgeVariant.soft,
                      isSmall: true,
                    ),
                  ],
                ),
                const VGap.xs(),
                VText(
                  '${member.email} · ${member.role}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                VText(
                  member.isOwner
                      ? 'Quyền sở hữu: Chủ sở hữu'
                      : 'Danh tính: ${member.identityText}',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const VGap.md(),

          // Section 1: Thay đổi vai trò Card
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: VText(
                    'Thay đổi vai trò',
                    variant: VTextVariant.headingH4,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const VGap.md(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Vai trò hiện tại',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    VText(
                      member.role,
                      variant: VTextVariant.bodySmall,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const VGap.md(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Vai trò mới',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    VText(
                      newRole,
                      variant: VTextVariant.bodySmall,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const VGap.md(),
          VText(
            'Vai trò là nhãn công việc; quyền nghiệp vụ của thành viên không thay đổi.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}
