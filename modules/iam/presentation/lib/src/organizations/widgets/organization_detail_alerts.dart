import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Widget hiển thị các hộp banner Cảnh báo / Khóa theo từng trạng thái tổ chức sử dụng VCard chuẩn DS.
class OrganizationDetailAlerts extends StatelessWidget {
  final OrganizationUiModel organization;

  const OrganizationDetailAlerts({
    super.key,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    switch (organization.status) {
      case OrganizationStatus.settingUp:
        return Column(
          children: [
            if (organization.unverifiedEmail) ...[
              _buildAlertBox(
                colors: colors,
                backgroundColor: colors.warningBg,
                border: null,
                icon: VIcons.warning,
                iconColor: colors.warning,
                titleColor: colors.warning,
                title: 'Email Chủ sở hữu chưa xác minh',
                description:
                    '${organization.ownerName ?? "Chủ sở hữu"} cần xác minh email trước khi kích hoạt tổ chức.',
              ),
              const VGap.md(),
            ],
            if (organization.incompleteProfile) ...[
              _buildAlertBox(
                colors: colors,
                backgroundColor: colors.warningBg,
                border: null,
                icon: VIcons.warning,
                iconColor: colors.warning,
                titleColor: colors.warning,
                title: 'Hồ sơ cơ bản chưa hoàn thiện',
                description: 'Còn thiếu tên liên hệ và địa chỉ liên hệ của tổ chức.',
              ),
              const VGap.md(),
            ],
          ],
        );

      case OrganizationStatus.suspended:
        return Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.space4),
          child: _buildAlertBox(
            colors: colors,
            backgroundColor: colors.dangerBg,
            border: Border.all(color: colors.danger.withValues(alpha: 0.5)),
            icon: VIcons.error,
            iconColor: colors.danger,
            titleColor: colors.danger,
            title: 'Quyền vận hành đã bị chặn',
            description:
                'Thành viên không thể thực hiện nghiệp vụ cho đến khi tổ chức được khôi phục.',
          ),
        );

      case OrganizationStatus.closed:
        return Padding(
          padding: const EdgeInsets.only(bottom: VSpacing.space4),
          child: _buildAlertBox(
            colors: colors,
            backgroundColor: colors.dangerBg,
            border: Border.all(color: colors.danger.withValues(alpha: 0.5)),
            icon: VIcons.error,
            iconColor: colors.danger,
            titleColor: colors.danger,
            title: 'Tổ chức đã đóng vĩnh viễn',
            description: 'Dữ liệu và lịch sử vẫn được giữ lại.',
          ),
        );

      case OrganizationStatus.active:
      case OrganizationStatus.all:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAlertBox({
    required VColorScheme colors,
    required Color backgroundColor,
    required Border? border,
    required VIcons icon,
    required Color iconColor,
    required Color titleColor,
    required String title,
    required String description,
  }) {
    return VCard(
      backgroundColor: backgroundColor,
      border: border ?? const Border.fromBorderSide(BorderSide.none),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(
            icon: icon,
            size: 20,
            color: iconColor,
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  title,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const VGap.xs(),
                VText(
                  description,
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
