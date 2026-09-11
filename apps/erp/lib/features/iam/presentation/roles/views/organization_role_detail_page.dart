import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/role_ui_model.dart';

/// Trang Chi tiết vai trò hệ thống (TA-D-02).
class OrganizationRoleDetailPage extends StatelessWidget {
  final RoleUiModel role;

  const OrganizationRoleDetailPage({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      title: 'Chi tiết vai trò',
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          // Thẻ Tóm tắt vai trò
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: VIcon(
                          icon: VIcons.shield,
                          size: 20,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const VGap.horizontalSm(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: VText(
                                  role.title,
                                  variant: VTextVariant.headingH4,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              VBadge(
                                label: '${role.permissionCount} quyền',
                                status: VBadgeStatus.info,
                                isSmall: true,
                              ),
                            ],
                          ),
                          const VGap.xs(),
                          VText(
                            role.description,
                            variant: VTextVariant.bodySmall,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const VGap.md(),
                VText(
                  'Vai trò hệ thống · Chỉ đọc',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.md(),

          // Các nhóm quyền
          ...role.groups.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.space4),
                child: VCard(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        group.title,
                        variant: VTextVariant.headingH4,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.md(),
                      ...group.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: VSpacing.space2),
                          child: Container(
                            padding: const EdgeInsets.all(VSpacing.space3),
                            decoration: BoxDecoration(
                              color: colors.successBg,
                              borderRadius: BorderRadius.circular(VRadius.card),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VIcon(
                                  icon: VIcons.success,
                                  size: 22,
                                  color: colors.success,
                                ),
                                const VGap.horizontalSm(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        item.title,
                                        variant: VTextVariant.bodyDefault,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: colors.success,
                                        ),
                                      ),
                                      const VGap.xs(),
                                      VText(
                                        item.description,
                                        variant: VTextVariant.bodySmall,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
