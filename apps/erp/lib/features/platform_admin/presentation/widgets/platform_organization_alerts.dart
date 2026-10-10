import 'package:erp/core/session/models/tenant_context.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Cảnh báo theo trạng thái ở C2. Không còn cảnh báo email / hồ sơ (KI-05).
class PlatformOrganizationAlerts extends StatelessWidget {
  const PlatformOrganizationAlerts({super.key, required this.status});

  final TenantStatus status;

  @override
  Widget build(BuildContext context) {
    final (title, description) = switch (status) {
      TenantStatus.suspended => (
        'Quyền vận hành đã bị chặn',
        'Thành viên không thể thực hiện nghiệp vụ cho đến khi tổ chức được khôi phục.',
      ),
      TenantStatus.closed => (
        'Tổ chức đã đóng vĩnh viễn',
        'Dữ liệu và lịch sử vẫn được giữ lại.',
      ),
      _ => (null, null),
    };
    if (title == null || description == null) return const SizedBox.shrink();

    final colors = context.vColors;
    return VCard(
      backgroundColor: colors.dangerBg,
      border: Border.all(color: colors.danger.withValues(alpha: 0.5)),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(icon: VIcons.error, size: 20, color: colors.danger),
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
                    color: colors.danger,
                  ),
                ),
                const VGap.xs(),
                VText(
                  description,
                  style: VTypography.bodySmall.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
