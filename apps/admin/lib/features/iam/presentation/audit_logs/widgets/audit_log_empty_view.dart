import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Các trạng thái rỗng / lỗi của giao diện Lịch sử quản trị.
enum AuditLogEmptyStateType {
  noAuditLogs, // Chưa có hoạt động quản trị
  noResults, // Không có hoạt động phù hợp (khi lọc/tìm kiếm)
  loadError, // Không thể tải lịch sử quản trị
  unauthorized, // Bạn không có quyền xem lịch sử quản trị
}

/// Component hiển thị trang rỗng / lỗi / phân quyền cho Lịch sử quản trị.
class AuditLogEmptyView extends StatelessWidget {
  final AuditLogEmptyStateType type;
  final VoidCallback onAction;

  const AuditLogEmptyView({
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
      case AuditLogEmptyStateType.noAuditLogs:
        icon = VIcons.info;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Chưa có hoạt động quản trị';
        titleColor = null;
        description =
            'Các thay đổi người dùng, vai trò và thiết lập sẽ được ghi lại tại đây.';
        actionLabel = 'Tải lại';
        actionTextColor = colors.success;
        break;

      case AuditLogEmptyStateType.noResults:
        icon = VIcons.search;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Không có hoạt động phù hợp';
        titleColor = null;
        description = 'Thử thay đổi từ khóa hoặc bộ lọc đang áp dụng.';
        actionLabel = 'Xóa bộ lọc';
        actionTextColor = colors.success;
        break;

      case AuditLogEmptyStateType.loadError:
        icon = VIcons.error;
        iconBgColor = colors.dangerBg;
        iconColor = colors.danger;
        title = 'Không thể tải lịch sử quản trị';
        titleColor = colors.danger;
        description = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
        actionLabel = 'Thử lại';
        actionTextColor = colors.danger;
        break;

      case AuditLogEmptyStateType.unauthorized:
        icon = VIcons.shield;
        iconBgColor = colors.warningBg;
        iconColor = colors.warning;
        title = 'Bạn không có quyền xem lịch sử quản trị';
        titleColor = null;
        description =
            'Liên hệ Chủ sở hữu hoặc người có quyền quản trị để được cấp quyền.';
        actionLabel = 'Quay lại';
        actionTextColor = colors.success;
        break;
    }

    return Align(
      alignment: const Alignment(0, -0.75),
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
