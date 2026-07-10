import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import 'partner_detail_formatters.dart';
import 'partner_detail_section.dart';

class PartnerDetailOverviewTab extends StatelessWidget {
  const PartnerDetailOverviewTab({super.key, required this.detail});

  final PartnerDetailDto detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final phone = PartnerDetailFormatters.primaryPhone(detail)?.trim() ?? '';
    final email = PartnerDetailFormatters.primaryEmail(detail)?.trim() ?? '';
    final taxCode = PartnerDetailFormatters.taxCode(detail)?.trim() ?? '';
    final invoiceAddress =
        PartnerDetailFormatters.invoice(detail)?.invoiceAddress?.trim() ?? '';
    final delivery = PartnerDetailFormatters.formatDeliveryAddress(
      PartnerDetailFormatters.delivery(detail),
    ).trim();
    final createdDate = PartnerDetailFormatters.createdDateLabel(detail);
    final createdActivity = PartnerDetailFormatters.createdActivityText(detail);

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
            title: 'Thông tin chính',
            child: _mainInfoBody(phone: phone, email: email),
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerDetailSectionCard(
            title: 'Hóa đơn / thuế',
            child: _invoiceBody(taxCode: taxCode, invoiceAddress: invoiceAddress),
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
            title: 'Lịch sử gần đây',
            child: PartnerDetailEmptyHint(message: 'Chưa có lịch sử giao dịch.'),
          ),
        ],
      ),
    );
  }

  Widget _mainInfoBody({required String phone, required String email}) {
    final rows = <Widget>[];
    if (phone.isNotEmpty) {
      rows.add(
        PartnerDetailInfoRow(
          label: 'SĐT chính',
          value: phone,
          trailingIcon: Icons.phone_outlined,
          isLast: email.isEmpty,
        ),
      );
    }
    if (email.isNotEmpty) {
      rows.add(
        PartnerDetailInfoRow(
          label: 'Email',
          value: email,
          trailingIcon: Icons.mail_outline,
          isLast: true,
        ),
      );
    }
    if (rows.isEmpty) {
      return const PartnerDetailEmptyHint(message: 'Chưa có thông tin liên hệ.');
    }
    return Column(children: rows);
  }

  Widget _invoiceBody({
    required String taxCode,
    required String invoiceAddress,
  }) {
    final rows = <Widget>[];
    if (taxCode.isNotEmpty) {
      rows.add(
        PartnerDetailInfoRow(
          label: 'MST',
          value: taxCode,
          isLast: invoiceAddress.isEmpty,
        ),
      );
    }
    if (invoiceAddress.isNotEmpty) {
      rows.add(
        PartnerDetailInfoRow(
          label: 'Địa chỉ xuất HĐ',
          value: invoiceAddress,
          isLast: true,
        ),
      );
    }
    if (rows.isEmpty) {
      return const PartnerDetailEmptyHint(message: 'Chưa có thông tin hóa đơn / thuế.');
    }
    return Column(children: rows);
  }
}
