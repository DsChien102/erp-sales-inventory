import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_detail_expandable_card.dart';

/// Card thông tin chính — field khớp form tạo; thiếu dữ liệu hiển thị trống.
class PartnerDetailMainInfoCard extends StatelessWidget {
  const PartnerDetailMainInfoCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  static const _empty = '—';

  @override
  Widget build(BuildContext context) {
    final isPerson = dto.partnerType == PartnerType.person;
    final title = isPerson ? 'Thông tin cá nhân' : 'Thông tin tổ chức';

    return PartnerDetailExpandableCard(
      title: title,
      icon: VIcons.person,
      initiallyExpanded: initiallyExpanded,
      child: isPerson ? _personFields(dto.personProfile) : _orgFields(dto.organizationProfile),
    );
  }

  Widget _personFields(PersonProfileDto? profile) {
    final title = profile?.title?.value.trim() ?? '';
    final fullName = profile?.fullName.trim() ?? '';
    final nickname = profile?.nickname?.trim() ?? '';
    final phone = profile?.phone.trim() ?? '';
    final phone2 = profile?.phone2?.trim() ?? '';
    final email = profile?.email?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(label: 'Danh xưng', value: title),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Họ và tên', value: fullName),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Tên thường gọi', value: nickname),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'SĐT chính', value: phone),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'SĐT phụ', value: phone2),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Email', value: email),
      ],
    );
  }

  Widget _orgFields(OrganizationProfileDto? profile) {
    final typeLabel = switch (profile?.organizationType) {
      OrganizationType.company => 'Công ty',
      OrganizationType.businessHousehold => 'Hộ kinh doanh',
      OrganizationType.other => 'Khác',
      null => '',
    };
    final name = profile?.organizationName.trim() ?? '';
    final shortName = profile?.shortName?.trim() ?? '';
    final intlName = profile?.intlName?.trim() ?? '';
    final phone = profile?.phone.trim() ?? '';
    final email = profile?.email?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(label: 'Loại tổ chức', value: typeLabel),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Tên tổ chức', value: name),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Tên viết tắt', value: shortName),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Tên quốc tế', value: intlName),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'SĐT chính', value: phone),
        const SizedBox(height: VSpacing.space3),
        _Field(label: 'Email', value: email),
      ],
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
    final isEmpty = value.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VText(
          label,
          style: VTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
        const VGap.xs(),
        VText(
          isEmpty ? PartnerDetailMainInfoCard._empty : value,
          variant: VTextVariant.bodyDefault,
          color: isEmpty ? colors.textMuted : colors.textPrimary,
          style: TextStyle(fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500),
        ),
      ],
    );
  }
}
