import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Các trạng thái rỗng / lỗi của giao diện Tổ chức.
enum OrganizationEmptyStateType {
  noOrganizations, // Chưa có tổ chức
  noAuthorizedOrganizations, // Chưa có tổ chức được cấp quyền (Card 2)
  inaccessible, // Tổ chức không thể truy cập (Card 1)
  noResults, // Không tìm thấy tổ chức
  loadError, // Không thể tải danh sách (Card 3)
  unauthorized, // Không có quyền xem tổ chức
}

/// Component hiển thị trang rỗng / lỗi cho Tổ chức bám sát thiết kế.
class OrganizationEmptyView extends StatelessWidget {
  final OrganizationEmptyStateType type;
  final VoidCallback onAction;
  final String? suspendedOrgName;
  final bool isCompact;

  const OrganizationEmptyView({
    super.key,
    required this.type,
    required this.onAction,
    this.suspendedOrgName,
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
    final String actionLabel;
    final Color actionTextColor;

    switch (type) {
      case OrganizationEmptyStateType.inaccessible:
        icon = VIcons.error;
        iconBgColor = colors.dangerBg;
        iconColor = colors.danger;
        title = 'Tổ chức không thể truy cập';
        titleColor = colors.danger;
        description =
            '${suspendedOrgName ?? "ASC Commerce"} đang tạm ngừng. Bạn không thể truy cập dữ liệu của tổ chức này.';
        actionLabel = 'Chọn tổ chức khác';
        actionTextColor = colors.danger;
        break;

      case OrganizationEmptyStateType.noAuthorizedOrganizations:
      case OrganizationEmptyStateType.noOrganizations:
        icon = VIcons.info;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Chưa có tổ chức được cấp quyền';
        titleColor = null;
        description =
            'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.';
        actionLabel = 'Kiểm tra lại';
        actionTextColor = colors.success;
        break;

      case OrganizationEmptyStateType.noResults:
        icon = VIcons.search;
        iconBgColor = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        title = 'Không tìm thấy tổ chức';
        titleColor = null;
        description = 'Thử từ khóa khác.';
        actionLabel = 'Xóa tìm kiếm';
        actionTextColor = colors.success;
        break;

      case OrganizationEmptyStateType.loadError:
        icon = VIcons.error;
        iconBgColor = colors.dangerBg;
        iconColor = colors.danger;
        title = 'Không thể tải danh sách tổ chức';
        titleColor = colors.danger;
        description =
            'Kiểm tra kết nối mạng và thử lại. Dữ liệu cũ không được hiển thị khi quyền truy cập có thể đã thay đổi.';
        actionLabel = 'Thử lại';
        actionTextColor = colors.danger;
        break;

      case OrganizationEmptyStateType.unauthorized:
        icon = VIcons.shield;
        iconBgColor = colors.warningBg;
        iconColor = colors.warning;
        title = 'Bạn không có quyền quản lý';
        titleColor = null;
        description = 'Liên hệ Chủ tổ chức hoặc Quản trị viên để được cấp quyền phù hợp.';
        actionLabel = 'Quay lại';
        actionTextColor = colors.success;
        break;
    }

    final cardContent = Padding(
      padding: isCompact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
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
    );

    if (isCompact) {
      return Center(
        child: cardContent,
      );
    }

    return Align(
      alignment: const Alignment(0, -0.85),
      child: cardContent,
    );
  }
}
