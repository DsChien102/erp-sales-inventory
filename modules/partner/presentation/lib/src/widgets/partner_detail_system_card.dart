import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_detail_expandable_card.dart';
import 'partner_detail_formatters.dart';

/// Card «Thông tin hệ thống» — audit / metadata hồ sơ.
class PartnerDetailSystemCard extends StatelessWidget {
  const PartnerDetailSystemCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  static const _empty = '—';

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (dto.partnerType) {
      PartnerType.person => 'Cá nhân',
      PartnerType.organization => 'Tổ chức',
    };
    final statusLabel = switch (dto.status) {
      PartnerStatus.active => 'Đang hoạt động',
      PartnerStatus.inactive => 'Ngừng hoạt động',
      PartnerStatus.deleted => 'Đã xóa',
    };
    final created = PartnerDetailFormatters.formatDateTime(dto.createdAt);
    final updated = PartnerDetailFormatters.formatDateTime(dto.updatedAt);

    return PartnerDetailExpandableCard(
      title: 'Thông tin hệ thống',
      icon: Icons.settings_outlined,
      initiallyExpanded: initiallyExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: 'Mã hồ sơ', value: dto.partnerId),
          const SizedBox(height: VSpacing.space3),
          _Field(label: 'Loại hồ sơ', value: typeLabel),
          const SizedBox(height: VSpacing.space3),
          _Field(label: 'Trạng thái', value: statusLabel),
          const SizedBox(height: VSpacing.space3),
          _Field(label: 'Phiên bản', value: '${dto.expectedVersion}'),
          const SizedBox(height: VSpacing.space3),
          _Field(label: 'Ngày tạo', value: created ?? _empty),
          const SizedBox(height: VSpacing.space3),
          _Field(label: 'Cập nhật lần cuối', value: updated ?? _empty),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEmpty = value == PartnerDetailSystemCard._empty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: VTypography.bodyDefault.copyWith(
            color: isEmpty ? colors.textMuted : colors.textPrimary,
            fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
