import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/address/vn_address_text.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../models/organization_profile_ui_model.dart';
import 'legal_notice_box.dart';

/// Bố cục Hồ sơ tổ chức trên màn hình rộng (web).
class OrganizationProfileWide extends StatelessWidget {
  const OrganizationProfileWide({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onLegal,
  });

  final OrganizationProfileUiModel profile;
  final VoidCallback onEdit;
  final VoidCallback onLegal;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final legal = profile.legalProfile;
    final subtitle = [
      profile.email,
      profile.phone,
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.screenMobile,
        VSpacing.lg,
        VSpacing.screenMobile,
        VSpacing.xl,
      ),
      children: [
        DetailHeaderWide(
          leading: const FlowIcon.medium(VIcons.apartment),
          title: profile.name,
          subtitle: subtitle.isEmpty ? null : subtitle,
        ),
        const SizedBox(height: VSpacing.lg),
        DetailSectionWide(
          title: 'Thông tin tổ chức',
          action: IconButton(
            tooltip: 'Chỉnh sửa thông tin tổ chức',
            icon: VIcon(
              icon: VIcons.edit,
              size: 20,
              color: colors.textSecondary,
            ),
            onPressed: onEdit,
          ),
          children: [
            DetailRow(
              label: 'Tên hiển thị',
              value: profile.name,
              muted: true,
            ),
            DetailRow(
              label: 'Điện thoại',
              value: profile.phone,
              muted: true,
            ),
            DetailRow(
              label: 'Email',
              value: profile.email,
              muted: true,
            ),
            VnAddressBuilder(
              text: profile.address,
              provinceCode: profile.provinceCode,
              communeCode: profile.communeCode,
              builder: (_, address) => DetailRow(
                label: 'Địa chỉ',
                value: address,
                muted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space4),
        DetailSectionWide(
          title: 'Hồ sơ pháp lý',
          action: legal != null
              ? IconButton(
                  tooltip: 'Chỉnh sửa hồ sơ pháp lý',
                  icon: VIcon(
                    icon: VIcons.edit,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  onPressed: onLegal,
                )
              : null,
          children: legal == null
              ? [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LegalNoticeBox(
                        title: profile.legalNoticeTitle,
                        message: profile.legalNoticeMessage,
                      ),
                      const SizedBox(height: VSpacing.space4),
                      VButton(
                        key: const Key('legal_profile_org_banner_add'),
                        label: 'Thêm hồ sơ pháp lý',
                        fullWidth: true,
                        onPressed: onLegal,
                      ),
                    ],
                  ),
                ]
              : [
                  // Dòng "Địa chỉ đăng ký" ẩn khi rỗng: dựng cả khối để không
                  // để lại khe trống.
                  VnAddressBuilder(
                    text: legal.registeredAddress,
                    provinceCode: legal.provinceCode,
                    communeCode: legal.communeCode,
                    builder: (_, address) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DetailRow(
                          label: 'Loại chủ thể',
                          value: legal.entityTypeLabel,
                          muted: true,
                        ),
                        const SizedBox(height: VSpacing.space3),
                        DetailRow(
                          label: 'Tên pháp lý',
                          value: legal.legalName,
                          muted: true,
                        ),
                        const SizedBox(height: VSpacing.space3),
                        DetailRow(
                          label: 'Mã số thuế',
                          value: legal.taxCode,
                          muted: true,
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: VSpacing.space3),
                          DetailRow(
                            label: 'Địa chỉ đăng ký',
                            value: address,
                            muted: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}
