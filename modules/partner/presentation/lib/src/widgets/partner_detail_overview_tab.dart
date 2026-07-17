import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_detail_formatters.dart';
import 'partner_detail_section.dart';

class PartnerDetailOverviewTab extends StatelessWidget {
  const PartnerDetailOverviewTab({super.key, required this.detail});

  final PartnerDetailDto detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final taxCode = PartnerDetailFormatters.taxCode(detail)?.trim() ?? '';
    final invoice = PartnerDetailFormatters.invoice(detail);
    final invoiceName = invoice?.invoiceName?.trim() ?? '';
    final invoiceEmail = invoice?.invoiceEmail?.trim() ?? '';
    final invoiceAddress = invoice?.invoiceAddress?.trim() ?? '';
    final delivery = PartnerDetailFormatters.formatDeliveryAddress(
      PartnerDetailFormatters.delivery(detail),
    ).trim();
    final note = PartnerDetailFormatters.note(detail)?.trim() ?? '';
    final createdDate = PartnerDetailFormatters.createdDateLabel(detail);
    final createdActivity = PartnerDetailFormatters.createdActivityText(detail);
    final mainTitle = detail.partnerType == PartnerType.person
        ? 'Thông tin cá nhân'
        : 'Thông tin tổ chức';

    return ColoredBox(
      color: colors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space2,
          VSpacing.space4,
          VSpacing.space4,
        ),
        children: [
          PartnerDetailSectionCard(
            title: mainTitle,
            child: _mainInfoBody(),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerDetailSectionCard(
            title: 'Hóa đơn / thuế',
            child: _invoiceBody(
              taxCode: taxCode,
              invoiceName: invoiceName,
              invoiceEmail: invoiceEmail,
              invoiceAddress: invoiceAddress,
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerDetailSectionCard(
            title: 'Địa chỉ giao hàng',
            child: delivery.isEmpty
                ? const PartnerDetailEmptyHint(message: 'Chưa có địa chỉ giao hàng.')
                : Text(
                    delivery,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerDetailSectionCard(
            title: 'Ghi chú',
            child: note.isEmpty
                ? const PartnerDetailEmptyHint(message: 'Chưa có ghi chú.')
                : Text(
                    note,
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerDetailSectionCard(
            title: 'Địa chỉ gần đây',
            child: createdDate == null
                ? const PartnerDetailEmptyHint(message: 'Chưa có hoạt động gần đây.')
                : PartnerDetailActivityRow(
                    dateLabel: createdDate,
                    activityText: createdActivity,
                  ),
          ),
          const SizedBox(height: VSpacing.space2),
          const PartnerDetailSectionCard(
            title: 'Lịch sử giao dịch',
            child: PartnerDetailEmptyHint(message: 'Chưa có lịch sử giao dịch.'),
          ),
        ],
      ),
    );
  }

  Widget _mainInfoBody() {
    if (detail.partnerType == PartnerType.person) {
      final profile = detail.personProfile;
      return Column(
        children: [
          PartnerDetailInfoRow(
            label: 'Danh xưng',
            value: _orEmpty(profile?.title?.value),
          ),
          PartnerDetailInfoRow(
            label: 'Họ và tên',
            value: _orEmpty(profile?.fullName),
          ),
          PartnerDetailInfoRow(
            label: 'Tên thường gọi',
            value: _orEmpty(profile?.nickname),
          ),
          PartnerDetailInfoRow(
            label: 'SĐT chính',
            value: _orEmpty(profile?.phone),
          ),
          PartnerDetailInfoRow(
            label: 'SĐT phụ',
            value: _orEmpty(profile?.phone2),
          ),
          PartnerDetailInfoRow(
            label: 'Email',
            value: _orEmpty(profile?.email),
            isLast: true,
          ),
        ],
      );
    }

    final profile = detail.organizationProfile;
    final typeLabel = switch (profile?.organizationType) {
      OrganizationType.company => 'Công ty',
      OrganizationType.businessHousehold => 'Hộ kinh doanh',
      OrganizationType.other => 'Khác',
      null => '',
    };
    return Column(
      children: [
        PartnerDetailInfoRow(label: 'Loại tổ chức', value: _orEmpty(typeLabel)),
        PartnerDetailInfoRow(
          label: 'Tên tổ chức',
          value: _orEmpty(profile?.organizationName),
        ),
        PartnerDetailInfoRow(
          label: 'Tên viết tắt',
          value: _orEmpty(profile?.shortName),
        ),
        PartnerDetailInfoRow(
          label: 'Tên quốc tế',
          value: _orEmpty(profile?.intlName),
        ),
        PartnerDetailInfoRow(
          label: 'SĐT chính',
          value: _orEmpty(profile?.phone),
        ),
        PartnerDetailInfoRow(
          label: 'Email',
          value: _orEmpty(profile?.email),
          isLast: true,
        ),
      ],
    );
  }

  String _orEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  Widget _invoiceBody({
    required String taxCode,
    required String invoiceName,
    required String invoiceEmail,
    required String invoiceAddress,
  }) {
    const empty = '—';
    return Column(
      children: [
        PartnerDetailInfoRow(
          label: 'MST',
          value: taxCode.isEmpty ? empty : taxCode,
        ),
        PartnerDetailInfoRow(
          label: 'Tên xuất hóa đơn',
          value: invoiceName.isEmpty ? empty : invoiceName,
        ),
        PartnerDetailInfoRow(
          label: 'Email nhận hóa đơn',
          value: invoiceEmail.isEmpty ? empty : invoiceEmail,
        ),
        PartnerDetailInfoRow(
          label: 'Địa chỉ xuất hóa đơn',
          value: invoiceAddress.isEmpty ? empty : invoiceAddress,
          isLast: true,
        ),
      ],
    );
  }
}
