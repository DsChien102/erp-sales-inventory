import 'package:erp/core/session/session_state.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

export 'package:erp/core/session/session_state.dart' show OrganizationEmptyStateType;

/// Component hiển thị trang rỗng / lỗi cho Tổ chức bám sát thiết kế.
class OrganizationEmptyView extends StatelessWidget {
  final OrganizationEmptyStateType type;
  final VoidCallback onAction;
  final String? customActionLabel;
  final bool isCompact;

  const OrganizationEmptyView({
    super.key,
    required this.type,
    required this.onAction,
    this.customActionLabel,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final VIcons icon;
    final Color iconBgColor;
    final Color iconColor;
    final String title;
    final Color? titleColor;
    final String description;
    String actionLabel;
    final Color actionTextColor;

    switch (type) {
      case OrganizationEmptyStateType.inaccessible:
      case OrganizationEmptyStateType.noAuthorizedOrganizations:
        icon = VIcons.info;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Chưa có tổ chức được cấp quyền';
        titleColor = null;
        description =
            'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.';
        actionLabel = 'Kiểm tra lại';
        actionTextColor = colors.primary;
        break;

      case OrganizationEmptyStateType.noOrganizations:
        icon = VIcons.info;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Chưa có tổ chức';
        titleColor = null;
        description = 'Khởi tạo tổ chức đầu tiên để bắt đầu quản lý tổ chức trên nền tảng.';
        actionLabel = 'Khởi tạo tổ chức';
        actionTextColor = colors.primary;
        break;

      case OrganizationEmptyStateType.noResults:
        icon = VIcons.search;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Không tìm thấy tổ chức';
        titleColor = null;
        description = 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.';
        actionLabel = 'Xóa bộ lọc';
        actionTextColor = colors.primary;
        break;

      case OrganizationEmptyStateType.loadError:
        icon = VIcons.error;
        iconBgColor = colors.dangerBg;
        iconColor = colors.danger;
        title = 'Không thể tải danh sách';
        titleColor = colors.danger;
        description = 'Đã xảy ra lỗi khi tải danh sách tổ chức. Vui lòng thử lại.';
        actionLabel = 'Thử lại';
        actionTextColor = colors.danger;
        break;

      case OrganizationEmptyStateType.unauthorized:
        icon = VIcons.shield;
        iconBgColor = colors.warningBg;
        iconColor = colors.warning;
        title = 'Không có quyền xem tổ chức';
        titleColor = null;
        description = 'Liên hệ chủ cửa hàng để được cấp quyền quản lý tổ chức nền tảng.';
        actionLabel = 'Quay lại';
        actionTextColor = colors.primary;
        break;
    }

    if (customActionLabel != null) {
      actionLabel = customActionLabel!;
    }

    final cardContent = Padding(
      padding: isCompact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
      child: SizedBox(
        width: double.infinity,
        child: VCard(
          padding: isCompact
              ? const EdgeInsets.symmetric(
                  horizontal: VSpacing.space4,
                  vertical: VSpacing.space5,
                )
              : const EdgeInsets.all(VSpacing.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCompact ? 56 : 64,
                height: isCompact ? 56 : 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: VIcon(
                    icon: icon,
                    color: iconColor,
                    size: isCompact ? 24 : 28,
                  ),
                ),
              ),
              isCompact ? const VGap.sm() : const VGap.md(),
              VText(
                title,
                variant: VTextVariant.headingH3,
                color: titleColor ?? colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const VGap.xs(),
              VText(
                description,
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              isCompact ? const VGap.sm() : const VGap.md(),
              GestureDetector(
                onTap: onAction,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: VText(
                    actionLabel,
                    variant: VTextVariant.bodyDefault,
                    color: actionTextColor,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isCompact) {
      return Center(
        child: cardContent,
      );
    }

    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: VSpacing.space3),
      child: cardContent,
    );
  }
}
