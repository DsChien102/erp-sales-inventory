import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/organization_ui_model.dart';

/// Card hiển thị "Thông tin nền tảng" dạng Key-Value chuẩn thiết kế.
class OrganizationDetailPlatformInfoCard extends StatelessWidget {
  final OrganizationUiModel organization;

  const OrganizationDetailPlatformInfoCard({
    super.key,
    required this.organization,
  });

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final items = _buildInfoItems();

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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const VGap.md(),
            itemBuilder: (context, index) {
              final item = items[index];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: VText(
                      item.label,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Flexible(
                    child: VText(
                      item.value,
                      style: VTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<({String label, String value})> _buildInfoItems() {
    switch (organization.status) {
      case OrganizationStatus.settingUp:
        return [
          (
            label: 'Ngày khởi tạo',
            value: _formatDateTime(organization.createdAt),
          ),
        ];

      case OrganizationStatus.active:
        return [
          (
            label: 'Kích hoạt lúc',
            value: _formatDateTime(organization.activatedAt),
          ),
          (
            label: 'Hoạt động gần nhất',
            value: _formatDateTime(organization.lastActiveAt),
          ),
          (
            label: 'Phiên bản dữ liệu',
            value: organization.dataVersion ?? '--',
          ),
        ];

      case OrganizationStatus.suspended:
        return [
          (
            label: 'Tạm ngừng lúc',
            value: _formatDateTime(organization.suspendedAt),
          ),
          (
            label: 'Người thực hiện',
            value: _displayOrDash(organization.suspendedBy),
          ),
          (
            label: 'Lý do',
            value: _displayOrDash(organization.suspendReason),
          ),
        ];

      case OrganizationStatus.closed:
        return [
          (
            label: 'Đóng lúc',
            value: _formatDateTime(organization.closedAt),
          ),
          (
            label: 'Người thực hiện',
            value: _displayOrDash(organization.closedBy),
          ),
          (
            label: 'Lý do',
            value: _displayOrDash(organization.closeReason),
          ),
        ];

      case OrganizationStatus.all:
        return [
          (
            label: 'Ngày tạo',
            value: _formatDateTime(organization.createdAt),
          ),
        ];
    }
  }

  static String _displayOrDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '--';
    return trimmed;
  }
}
