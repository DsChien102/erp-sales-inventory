import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerContactsErrorBody extends StatelessWidget {
  const PartnerContactsErrorBody({
    super.key,
    required this.isNoPermission,
    required this.message,
  });

  final bool isNoPermission;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Center(
      child: VPagePadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.danger, size: 48),
            const SizedBox(height: VSpacing.space3),
            VText(
              isNoPermission
                  ? 'Không có quyền quản lý người liên hệ'
                  : 'Đã xảy ra lỗi',
              variant: VTextVariant.headingH3,
              color: colors.textPrimary,
            ),
            const VGap.sm(),
            VText(
              isNoPermission
                  ? 'Bạn không có quyền xem hoặc thay đổi người liên hệ của tổ chức này.'
                  : message,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const VGap.md(),
            VButton(
              label: 'Quay lại',
              variant: VButtonVariant.outline,
              foregroundColor: colors.success,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
