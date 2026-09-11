import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_domain/domain.dart';

import '../bloc/partner_create_cubit.dart';
import 'partner_outlined_field.dart';

class PartnerInvoiceSection extends StatelessWidget {
  const PartnerInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnerCreateCubit>();
    final state = context.watch<PartnerCreateCubit>().state;
    final isOrganization = state.partnerType == PartnerType.organization;
    final invoiceWarning = _organizationInvoiceWarning(
      partnerType: state.partnerType,
      taxCode: state.taxCode,
      invoiceName: state.invoiceName,
      invoiceAddress: state.invoiceAddress,
    );

    return VPagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerOutlinedTextField(
            key: const Key('input_tax_code'),
            label: 'MST',
            hintText: 'Nhập MST',
            initialValue: state.taxCode,
            isRequired: isOrganization,
            errorText: state.errors['taxCode'],
            keyboardType: TextInputType.number,
            digitsOnly: true,
            onChanged: cubit.updateTaxCode,
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerOutlinedTextField(
            label: 'Tên xuất hóa đơn',
            hintText: 'Nhập tên xuất hóa đơn',
            initialValue: state.invoiceName,
            isRequired: isOrganization,
            onChanged: cubit.updateInvoiceName,
          ),
          const VGap.md(),
          PartnerOutlinedTextField(
            label: 'Email nhận hóa đơn',
            hintText: 'Nhập email nhận hóa đơn',
            initialValue: state.invoiceEmail,
            errorText: state.errors['invoiceEmail'],
            keyboardType: TextInputType.emailAddress,
            onChanged: cubit.updateInvoiceEmail,
          ),
          const SizedBox(height: VSpacing.space2),
          PartnerOutlinedMultilineTextField(
            key: const Key('input_invoice_address'),
            label: 'Địa chỉ xuất hóa đơn',
            hintText: 'Nhập địa chỉ xuất hóa đơn',
            initialValue: state.invoiceAddress,
            isRequired: isOrganization,
            minLines: 3,
            maxLines: 5,
            onChanged: cubit.updateInvoiceAddress,
          ),
          if (invoiceWarning != null) ...[
            const VGap.md(),
            _InvoiceWarning(message: invoiceWarning),
          ],
        ],
      ),
    );
  }
}

class _InvoiceWarning extends StatelessWidget {
  const _InvoiceWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return VBanner(
      status: VBannerStatus.warning,
      title: message,
      icon: VIcons.warning,
    );
  }
}

String? _organizationInvoiceWarning({
  required PartnerType partnerType,
  required String taxCode,
  required String invoiceName,
  required String invoiceAddress,
}) {
  if (partnerType != PartnerType.organization) return null;

  final missing = <String>[];
  if (taxCode.trim().isEmpty) missing.add('MST');
  if (invoiceName.trim().isEmpty) missing.add('tên xuất hóa đơn');
  if (invoiceAddress.trim().isEmpty) missing.add('địa chỉ hóa đơn');
  if (missing.isEmpty) return null;

  return 'Thiếu ${_joinInvoiceWarningLabels(missing)}. '
      'Vui lòng kiểm tra lại trước khi lưu.';
}

String _joinInvoiceWarningLabels(List<String> labels) {
  if (labels.length == 1) return labels.single;
  if (labels.length == 2) return '${labels[0]} và ${labels[1]}';
  final head = labels.sublist(0, labels.length - 1).join(', ');
  return '$head và ${labels.last}';
}
