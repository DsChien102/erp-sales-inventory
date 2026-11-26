import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/address/vn_address_text.dart';
import 'package:flutter/material.dart';

import '../../shared/detail_layout.dart';
import '../models/organization_profile_ui_model.dart';
import 'legal_notice_box.dart';

/// Bố cục Hồ sơ tổ chức trên màn hình hẹp (iPhone).
class OrganizationProfileNarrow extends StatelessWidget {
  const OrganizationProfileNarrow({
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

    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        DetailHeaderNarrow(
          leading: const DetailIconTile(VIcons.apartment),
          title: profile.name,
        ),
        const SizedBox(height: VSpacing.space3),
        DetailSectionNarrow(
          title: 'Thông tin tổ chức',
          children: [
            DetailRow(label: 'Tên hiển thị', value: profile.name),
            DetailRow(label: 'Điện thoại', value: profile.phone),
            DetailRow(label: 'Email', value: profile.email),
            VnAddressBuilder(
              text: profile.address,
              provinceCode: profile.provinceCode,
              communeCode: profile.communeCode,
              builder: (_, address) => DetailRow(
                label: 'Địa chỉ',
                value: address,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.space3),
        DetailSectionNarrow(
          title: 'Hồ sơ pháp lý',
          children: legal == null
              ? [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LegalNoticeBox(
                        title: profile.legalNoticeTitle,
                        message: profile.legalNoticeMessage,
                        compact: true,
                      ),
                      // Prototype `.t1-orgm__add` kéo sát hộp vàng (margin-top -4).
                      const SizedBox(height: VSpacing.space2),
                      Row(
                        children: [
                          Expanded(
                            child: VText(
                              'Bổ sung hồ sơ pháp lý để xuất hoá đơn điện tử.',
                              variant: VTextVariant.bodySmall,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: VSpacing.space3),
                          VButton(
                            key: const Key('legal_profile_org_banner_add'),
                            label: 'Bổ sung',
                            variant: VButtonVariant.link,
                            onPressed: onLegal,
                          ),
                        ],
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
                        ),
                        const SizedBox(height: VSpacing.space3),
                        DetailRow(label: 'Tên pháp lý', value: legal.legalName),
                        const SizedBox(height: VSpacing.space3),
                        DetailRow(label: 'Mã số thuế', value: legal.taxCode),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: VSpacing.space3),
                          DetailRow(label: 'Địa chỉ đăng ký', value: address),
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
