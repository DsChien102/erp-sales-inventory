import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Bottom Sheet hiển thị danh sách thao tác đối với tổ chức.
/// - Đang hoạt động: Thay đổi chủ sở hữu, Tạm ngừng tổ chức (Tone đỏ).
/// - Đã tạm ngừng: Thay đổi chủ sở hữu, Khôi phục tổ chức.
class OrganizationActionsBottomSheet extends StatelessWidget {
  final OrganizationUiModel organization;
  final VoidCallback? onChangeOwnerTap;
  final VoidCallback? onSuspendTap;
  final VoidCallback? onRestoreTap;

  const OrganizationActionsBottomSheet({
    super.key,
    required this.organization,
    this.onChangeOwnerTap,
    this.onSuspendTap,
    this.onRestoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isSuspended = organization.status == OrganizationStatus.suspended;

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
          // Tiêu đề "Thao tác tổ chức"
          Padding(
            padding: const EdgeInsets.only(bottom: VSpacing.space4),
            child: VText(
              'Thao tác tổ chức',
              variant: VTextVariant.headingH3,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Action 1: Thay đổi chủ sở hữu
          _ActionButtonCard(
            title: 'Thay đổi chủ sở hữu',
            subtitle: 'Chọn Chủ sở hữu mới',
            icon: VIcons.person,
            isDanger: false,
            onTap: () {
              Navigator.of(context).pop();
              onChangeOwnerTap?.call();
            },
          ),
          const VGap.md(),

          // Action 2: Tạm ngừng (nếu Active) hoặc Khôi phục (nếu Suspended)
          if (isSuspended) ...[
            _ActionButtonCard(
              title: 'Khôi phục tổ chức',
              subtitle: 'Cho phép vận hành trở lại',
              icon: VIcons.restore,
              isDanger: false,
              onTap: () {
                Navigator.of(context).pop();
                onRestoreTap?.call();
              },
            ),
          ] else ...[
            _ActionButtonCard(
              title: 'Tạm ngừng tổ chức',
              subtitle: 'Chặn toàn bộ quyền vận hành',
              icon: VIcons.pause,
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                onSuspendTap?.call();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButtonCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VIcons icon;
  final bool isDanger;
  final VoidCallback onTap;

  const _ActionButtonCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDanger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final bgColor = isDanger ? colors.dangerBg : colors.surface;
    final borderColor = isDanger ? colors.danger.withValues(alpha: 0.4) : colors.borderDefault;
    final textColor = isDanger ? colors.danger : colors.textPrimary;
    final subtitleColor = isDanger ? colors.danger.withValues(alpha: 0.8) : colors.textSecondary;
    final iconColor = isDanger ? colors.danger : colors.textPrimary;
    final chevronColor = isDanger ? colors.danger : colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(VRadius.r16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              VIcon(
                icon: icon,
                size: 24,
                color: iconColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      title,
                      variant: VTextVariant.bodyDefault,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    VText(
                      subtitle,
                      variant: VTextVariant.bodySmall,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VIcon(
                icon: VIcons.chevronRight,
                size: 20,
                color: chevronColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
