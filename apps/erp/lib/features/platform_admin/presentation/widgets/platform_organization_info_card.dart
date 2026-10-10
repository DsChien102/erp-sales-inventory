import 'package:erp/core/session/models/tenant_context.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/platform_tenant.dart';

/// Thẻ "Thông tin nền tảng" ở C2 (TH-01 US-09.2 FR-02).
class PlatformOrganizationInfoCard extends StatelessWidget {
  const PlatformOrganizationInfoCard({super.key, required this.detail});

  final PlatformTenantDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final items = _items();

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Thông tin nền tảng',
            style: VTypography.bodyDefault.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.md(),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const VGap.md(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: VText(
                    items[i].label,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ),
                const VGap.horizontalSm(),
                Flexible(
                  child: VText(
                    items[i].value,
                    style: VTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<({String label, String value})> _items() {
    return [
      (label: 'Ngày đăng ký', value: _dateTime(detail.createdAt)),
      (label: 'Hoạt động gần nhất', value: _dateTime(detail.lastActivityAt)),
      if (detail.status == TenantStatus.suspended) ...[
        (label: 'Tạm ngừng lúc', value: _dateTime(detail.suspendedAt)),
        (label: 'Người thực hiện', value: _orDash(detail.suspendedBy)),
        (label: 'Lý do', value: _orDash(detail.suspendReason)),
      ],
      if (detail.status == TenantStatus.closed) ...[
        (label: 'Đóng lúc', value: _dateTime(detail.closedAt)),
        (label: 'Người thực hiện', value: _orDash(detail.closedBy)),
        (label: 'Lý do', value: _orDash(detail.closeReason)),
      ],
    ];
  }

  static String _dateTime(DateTime? value) =>
      value == null ? '--' : VDateTime.dateTime(value.toLocal());

  static String _orDash(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? '--' : trimmed;
  }
}
