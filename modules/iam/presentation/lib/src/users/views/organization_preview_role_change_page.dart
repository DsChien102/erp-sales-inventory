import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/user_ui_model.dart';

class PermissionItem {
  final String title;
  final String description;

  const PermissionItem({
    required this.title,
    required this.description,
  });
}

/// Màn hình Xem trước thay đổi quyền (TA-D-04).
class OrganizationPreviewRoleChangePage extends StatelessWidget {
  final MemberUiModel member;
  final String newRole;

  const OrganizationPreviewRoleChangePage({
    super.key,
    required this.member,
    required this.newRole,
  });

  static const List<PermissionItem> _addedPermissions = [
    PermissionItem(
      title: 'Quản lý công nợ',
      description: 'Xem và cập nhật khoản phải thu',
    ),
    PermissionItem(
      title: 'Quản lý hóa đơn',
      description: 'Lập và theo dõi hóa đơn',
    ),
    PermissionItem(
      title: 'Xem báo cáo tài chính',
      description: 'Truy cập báo cáo được phân quyền',
    ),
  ];

  static const List<PermissionItem> _removedPermissions = [
    PermissionItem(
      title: 'Tạo đơn bán',
      description: 'Không còn tạo giao dịch bán hàng',
    ),
    PermissionItem(
      title: 'Thu tiền',
      description: 'Không còn thực hiện thu tiền bán hàng',
    ),
  ];

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
                variant: VButtonVariant.outline,
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
                      child: VText(
                        member.name,
                        variant: VTextVariant.headingH4,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    VBadge(
                      label: isActive ? 'Hoạt động' : 'Tạm ngừng',
                      status: isActive ? VBadgeStatus.success : VBadgeStatus.danger,
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
                  'Danh tính ${member.identityText}',
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
                VText(
                  'Thay đổi vai trò',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
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

          // Section 2: Quyền được thêm Card
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Quyền được thêm',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.md(),
                ..._addedPermissions.map((perm) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: VSpacing.space2),
                    padding: const EdgeInsets.all(VSpacing.space3),
                    decoration: BoxDecoration(
                      color: colors.successBg,
                      borderRadius: BorderRadius.circular(VRadius.r12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VIcon(
                          icon: VIcons.success,
                          size: 20,
                          color: colors.success,
                        ),
                        const VGap.horizontalSm(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VText(
                                perm.title,
                                variant: VTextVariant.bodyDefault,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.success,
                                ),
                              ),
                              const VGap.xs(),
                              VText(
                                perm.description,
                                variant: VTextVariant.bodySmall,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const VGap.md(),

          // Section 3: Quyền bị gỡ Card
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Quyền bị gỡ',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.md(),
                ..._removedPermissions.map((perm) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: VSpacing.space2),
                    padding: const EdgeInsets.all(VSpacing.space3),
                    decoration: BoxDecoration(
                      color: colors.dangerBg,
                      borderRadius: BorderRadius.circular(VRadius.r12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VIcon(
                          icon: VIcons.error,
                          size: 20,
                          color: colors.danger,
                        ),
                        const VGap.horizontalSm(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VText(
                                perm.title,
                                variant: VTextVariant.bodyDefault,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.danger,
                                ),
                              ),
                              const VGap.xs(),
                              VText(
                                perm.description,
                                variant: VTextVariant.bodySmall,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
