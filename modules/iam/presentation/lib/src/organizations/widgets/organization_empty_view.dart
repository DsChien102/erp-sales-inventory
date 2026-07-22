import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Các trạng thái rỗng / lỗi của giao diện Tổ chức.
enum OrganizationEmptyStateType {
  noOrganizations, // Chưa có tổ chức
  noResults, // Không tìm thấy tổ chức
  loadError, // Không thể tải danh sách
  unauthorized, // Không có quyền xem tổ chức
}

/// Component hiển thị trang rỗng / lỗi cho Tổ chức bám sát thiết kế.
class OrganizationEmptyView extends StatelessWidget {
  final OrganizationEmptyStateType type;
  final VoidCallback onAction;

  const OrganizationEmptyView({
    super.key,
    required this.type,
    required this.onAction,
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
    final String actionLabel;
    final Color actionTextColor;

    switch (type) {
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
        icon = VIcons.warning;
        iconBgColor = colors.warningBg;
        iconColor = colors.warning;
        title = 'Không có quyền xem tổ chức';
        titleColor = null;
        description = 'Liên hệ chủ cửa hàng để được cấp quyền quản lý tổ chức nền tảng.';
        actionLabel = 'Quay lại';
        actionTextColor = colors.primary;
        break;
    }

    return Align(
      alignment: const Alignment(0, -0.85),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
        child: VCard(
          padding: const EdgeInsets.all(VSpacing.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: VIcon(
                    icon: icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
              ),
              const VGap.md(),
              VText(
                title,
                variant: VTextVariant.headingH3,
                color: titleColor ?? colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const VGap.sm(),
              VText(
                description,
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const VGap.md(),
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
  }
}
