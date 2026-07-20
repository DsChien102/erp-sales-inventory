import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';

import 'partner_detail_expandable_card.dart';
import 'partner_detail_formatters.dart';

/// Card «Hóa đơn / thuế» — đủ field như form tạo; tap header để mở/đóng.
class PartnerDetailInvoiceCard extends StatelessWidget {
  const PartnerDetailInvoiceCard({
    super.key,
    required this.dto,
    this.initiallyExpanded = false,
  });

  final PartnerDetailDto dto;
  final bool initiallyExpanded;

  static const _empty = '—';

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final taxCode = PartnerDetailFormatters.taxCode(dto)?.trim() ?? '';
    final invoice = PartnerDetailFormatters.invoice(dto);
    final invoiceName = invoice?.invoiceName?.trim() ?? '';
    final invoiceEmail = invoice?.invoiceEmail?.trim() ?? '';
    final invoiceAddress = invoice?.invoiceAddress?.trim() ?? '';
    final missingLabel = switch ((taxCode.isEmpty, invoiceAddress.isEmpty)) {
      (true, true) => 'Thiếu MST, địa chỉ',
      (true, false) => 'Thiếu MST',
      (false, true) => 'Thiếu địa chỉ',
      (false, false) => null,
    };

    return PartnerDetailExpandableCard(
      title: 'Hóa đơn / thuế',
      icon: VIcons.receipt,
      initiallyExpanded: initiallyExpanded,
      trailingWhenCollapsed: missingLabel != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(VRadius.r8),
              ),
              child: VText(
                missingLabel,
                style: VTypography.bodySmall.copyWith(
                  color: colors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InvoiceField(
            label: 'MST',
            value: taxCode.isEmpty ? _empty : taxCode,
          ),
          const SizedBox(height: VSpacing.space3),
          _InvoiceField(
            label: 'Tên xuất hóa đơn',
            value: invoiceName.isEmpty ? _empty : invoiceName,
          ),
          const SizedBox(height: VSpacing.space3),
          _InvoiceField(
            label: 'Email nhận hóa đơn',
            value: invoiceEmail.isEmpty ? _empty : invoiceEmail,
          ),
          const SizedBox(height: VSpacing.space3),
          _InvoiceField(
            label: 'Địa chỉ xuất hóa đơn',
            value: invoiceAddress.isEmpty ? _empty : invoiceAddress,
          ),
        ],
      ),
    );
  }
}

class _InvoiceField extends StatelessWidget {
  const _InvoiceField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEmpty = value == PartnerDetailInvoiceCard._empty;
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
          value,
          variant: VTextVariant.bodyDefault,
          color: isEmpty ? colors.textMuted : colors.textPrimary,
          style: TextStyle(fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500),
        ),
      ],
    );
  }
}
