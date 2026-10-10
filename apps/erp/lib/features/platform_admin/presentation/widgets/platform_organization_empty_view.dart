import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum PlatformOrganizationEmptyType { noOrganizations, noResults, loadError, unauthorized }

/// Trạng thái trống / lỗi của C1 và C5. Không có "Khởi tạo tổ chức" (BR-01).
class PlatformOrganizationEmptyView extends StatelessWidget {
  const PlatformOrganizationEmptyView({
    super.key,
    required this.type,
    this.onAction,
    this.title,
    this.description,
    this.actionLabel,
  });

  final PlatformOrganizationEmptyType type;
  final VoidCallback? onAction;

  /// Ghi đè câu mặc định theo [type] (vd C5: "Chưa có thành viên đang hoạt động").
  final String? title;
  final String? description;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final VIcons icon;
    final Color iconBg;
    final Color iconColor;
    final String defaultTitle;
    final String defaultDescription;
    final String? defaultAction;
    switch (type) {
      case PlatformOrganizationEmptyType.noOrganizations:
        icon = VIcons.info;
        iconBg = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        defaultTitle = 'Chưa có tổ chức';
        defaultDescription = 'Tổ chức xuất hiện ở đây khi cửa hàng đăng ký trên nền tảng.';
        defaultAction = null;
      case PlatformOrganizationEmptyType.noResults:
        icon = VIcons.search;
        iconBg = colors.surfaceAlt;
        iconColor = colors.textSecondary;
        defaultTitle = 'Không tìm thấy tổ chức';
        defaultDescription = 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.';
        defaultAction = 'Xóa bộ lọc';
      case PlatformOrganizationEmptyType.loadError:
        icon = VIcons.error;
        iconBg = colors.dangerBg;
        iconColor = colors.danger;
        defaultTitle = 'Không thể tải dữ liệu';
        defaultDescription = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
        defaultAction = 'Thử lại';
      case PlatformOrganizationEmptyType.unauthorized:
        icon = VIcons.shield;
        iconBg = colors.warningBg;
        iconColor = colors.warning;
        defaultTitle = 'Không có quyền xem tổ chức';
        defaultDescription = 'Tài khoản của bạn không có quyền quản trị nền tảng.';
        defaultAction = null;
    }
    final label = actionLabel ?? defaultAction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: VSpacing.space3),
          child: SizedBox(
            width: double.infinity,
            child: VCard(
              padding: const EdgeInsets.all(VSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Center(child: VIcon(icon: icon, color: iconColor, size: 28)),
                  ),
                  const VGap.md(),
                  VText(
                    title ?? defaultTitle,
                    variant: VTextVariant.headingH3,
                    color: colors.textPrimary,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const VGap.xs(),
                  VText(
                    description ?? defaultDescription,
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  if (label != null && onAction != null) ...[
                    const VGap.md(),
                    GestureDetector(
                      onTap: onAction,
                      child: VText(
                        label,
                        variant: VTextVariant.bodyDefault,
                        color: type == PlatformOrganizationEmptyType.loadError
                            ? colors.danger
                            : colors.primary,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
