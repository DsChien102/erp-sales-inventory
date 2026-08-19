import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

class PlatformUserStatusAlert extends StatelessWidget {
  const PlatformUserStatusAlert({super.key, required this.status});

  final PlatformUserStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (status == PlatformUserStatus.pendingActivation) {
      return VCard(
        tone: VComponentTone.warning,
        backgroundColor: colors.warningBg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIcon(
              icon: VIcons.warning,
              color: colors.warning,
              size: 20,
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Chưa hoàn tất kích hoạt',
                    variant: VTextVariant.bodyDefault,
                    color: colors.warning,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const VGap.xs(),
                  VText(
                    'Người dùng chưa đăng nhập để xác minh email và thiết lập thông tin đăng nhập.',
                    variant: VTextVariant.bodySmall,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == PlatformUserStatus.suspended) {
      return VCard(
        tone: VComponentTone.danger,
        backgroundColor: colors.dangerBg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIcon(
              icon: VIcons.error,
              color: colors.danger,
              size: 20,
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    'Quyền truy cập đã bị tạm ngừng',
                    variant: VTextVariant.bodyDefault,
                    color: colors.danger,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const VGap.xs(),
                  VText(
                    'Người dùng không thể đăng nhập hoặc truy cập bất kỳ tổ chức nào. Dữ liệu và lịch sử vẫn được giữ lại.',
                    variant: VTextVariant.bodySmall,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
